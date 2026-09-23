import 'dart:math';

import 'package:flutter/material.dart';

final class ConfettiController extends ChangeNotifier {
  void fire() => notifyListeners();
}

/// Праздничный залп поверх [child].
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, required this.child, required this.controller});
  final Widget child;
  final ConfettiController controller;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _Piece {
  _Piece(Random r)
    : x = 0.5 + (r.nextDouble() - 0.5) * 0.3,
      vx = (r.nextDouble() - 0.5) * 1.6,
      vy = -1.2 - r.nextDouble() * 1.1,
      spin = (r.nextDouble() - 0.5) * 12,
      color = _colors[r.nextInt(_colors.length)],
      w = 6 + r.nextDouble() * 6;

  static const _colors = [
    Color(0xFFFF7A2F),
    Color(0xFF22A06B),
    Color(0xFFE8508F),
    Color(0xFF3F7FF0),
    Color(0xFFFFC233),
  ];

  final double x, vx, vy, spin, w;
  final Color color;
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  List<_Piece> _pieces = const [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_fire);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_fire);
    _anim.dispose();
    super.dispose();
  }

  void _fire() {
    setState(() => _pieces = List.generate(90, (_) => _Piece(_random)));
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, _) => _anim.isAnimating
                  ? CustomPaint(painter: _ConfettiPainter(_pieces, _anim.value))
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final time = t * 1.8;
    for (final p in pieces) {
      final x = (p.x + p.vx * time * 0.35) * size.width;
      final y = size.height * 0.45 + (p.vy * time + 1.6 * time * time) * size.height * 0.35;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * time);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.w, height: p.w * 0.5),
        Paint()..color = p.color.withValues(alpha: (1 - t).clamp(0, 1)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}
