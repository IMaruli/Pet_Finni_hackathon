import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Стеклянная банка с монетами. При росте суммы сверху падает монета.
class JarView extends StatefulWidget {
  const JarView({
    super.key,
    required this.title,
    required this.emoji,
    required this.color,
    required this.coins,
    required this.capacity,
    this.height = 150,
    this.showLabel = true,
  });

  final String title;
  final String emoji;
  final Color color;
  final int coins;
  final int capacity;
  final double height;
  final bool showLabel;

  @override
  State<JarView> createState() => _JarViewState();
}

class _JarViewState extends State<JarView> with SingleTickerProviderStateMixin {
  late final AnimationController _drop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  bool _bounce = false;

  @override
  void didUpdateWidget(JarView old) {
    super.didUpdateWidget(old);
    if (widget.coins > old.coins) {
      _bounce = false;
      _drop.forward(from: 0);
    } else if (widget.coins < old.coins) {
      _bounce = true;
      _drop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _drop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fill = widget.capacity <= 0 ? 0.0 : (widget.coins / widget.capacity).clamp(0.0, 1.0);
    final w = widget.height * 0.72;
    return Semantics(
      label: '${widget.title}: ${widget.coins} монет',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: w,
              height: widget.height,
              child: AnimatedBuilder(
                animation: _drop,
                builder: (context, _) {
                  final t = _drop.value;
                  final running = _drop.isAnimating;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Transform.scale(
                        scale: running ? 1 + 0.06 * sin(t * pi) : 1,
                        alignment: Alignment.bottomCenter,
                        child: CustomPaint(
                          size: Size(w, widget.height),
                          painter: _JarPainter(color: widget.color, fill: fill, coins: widget.coins),
                        ),
                      ),
                      if (running && !_bounce)
                        Positioned(
                          left: w / 2 - 12,
                          top: -20 + t * widget.height * 0.55,
                          child: Opacity(opacity: 1 - t * 0.6, child: const Text('🪙', style: TextStyle(fontSize: 24))),
                        ),
                      if (running && _bounce)
                        Positioned(
                          left: w / 2 - 12,
                          top: widget.height * 0.3 - t * widget.height * 0.5,
                          child: Opacity(opacity: 1 - t, child: const Text('🪙', style: TextStyle(fontSize: 24))),
                        ),
                      Positioned.fill(
                        top: widget.height * 0.3,
                        child: Center(
                          child: Text(
                            '${widget.coins}',
                            style: TextStyle(
                              fontSize: widget.height * 0.2,
                              fontWeight: FontWeight.w900,
                              color: FinniColors.ink,
                              shadows: const [Shadow(color: Colors.white, blurRadius: 6)],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (widget.showLabel) ...[
              const SizedBox(height: 6),
              Text(
                '${widget.emoji} ${widget.title}',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: widget.color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _JarPainter extends CustomPainter {
  _JarPainter({required this.color, required this.fill, required this.coins});
  final Color color;
  final double fill;
  final int coins;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final lidH = h * 0.1;
    final body = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.04, lidH * 0.8, w * 0.92, h - lidH * 0.8),
      topLeft: Radius.circular(w * 0.18),
      topRight: Radius.circular(w * 0.18),
      bottomLeft: Radius.circular(w * 0.22),
      bottomRight: Radius.circular(w * 0.22),
    );

    // Стекло.
    canvas.drawRRect(body, Paint()..color = color.withValues(alpha: 0.08));

    // Монеты: стопка эллипсов снизу.
    canvas.save();
    canvas.clipRRect(body);
    final inner = body.outerRect.deflate(w * 0.06);
    final level = inner.bottom - inner.height * fill;
    if (fill > 0) {
      canvas.drawRect(
        Rect.fromLTRB(inner.left - 10, level, inner.right + 10, body.outerRect.bottom),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFFFFD75E), const Color(0xFFE9A21B)],
          ).createShader(Rect.fromLTRB(0, level, w, h)),
      );
      final coinPaint = Paint()..color = const Color(0xFFFFE9A0);
      final rim = Paint()
        ..color = const Color(0xFFC98A12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final rows = ((inner.bottom - level) / (w * 0.12)).floor();
      for (var r = 0; r <= rows; r++) {
        final y = inner.bottom - r * w * 0.12 - w * 0.04;
        if (y < level - 2) break;
        for (var c = 0; c < 3; c++) {
          final x = inner.left + inner.width * (0.2 + 0.3 * c) + (r.isOdd ? inner.width * 0.12 : 0);
          final rect = Rect.fromCenter(center: Offset(x, y), width: w * 0.26, height: w * 0.1);
          canvas.drawOval(rect, coinPaint);
          canvas.drawOval(rect, rim);
        }
      }
    }
    canvas.restore();

    // Блик и контур стекла.
    canvas.drawRRect(
      body,
      Paint()
        ..color = color.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.14, h * 0.2, w * 0.08, h * 0.55), Radius.circular(w * 0.04)),
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );

    // Крышка.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.12, 0, w * 0.76, lidH), Radius.circular(lidH * 0.4)),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_JarPainter old) => old.fill != fill || old.color != color || old.coins != coins;
}
