import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../game/pet_wish.dart';
import 'mascot_look.dart';
import 'mascot_painter.dart';
import 'sphere.dart';

enum MascotAction { jump, shake, dance }

/// Пульт реакций героя: экраны дёргают его после действий игрока.
final class MascotController extends ChangeNotifier {
  MascotAction? _last;
  MascotAction? get last => _last;

  void jump() => _fire(MascotAction.jump);
  void shake() => _fire(MascotAction.shake);
  void dance() => _fire(MascotAction.dance);

  void _fire(MascotAction a) {
    _last = a;
    notifyListeners();
  }
}

final class MascotView extends StatefulWidget {
  const MascotView({
    super.key,
    required this.look,
    this.controller,
    this.size = 240,
    this.interactive = true,
    this.animated = true,
    this.semanticsLabel,
    this.onTap,
  });

  final MascotLook look;

  /// Тап по герою (помимо прыжка): например, реплика о самочувствии.
  final VoidCallback? onTap;
  final MascotController? controller;
  final double size;
  final bool interactive;
  final bool animated;
  final String? semanticsLabel;

  @override
  State<MascotView> createState() => _MascotViewState();
}

class _MascotViewState extends State<MascotView> with SingleTickerProviderStateMixin {
  static const _jumpTime = 0.65;
  static const _shakeTime = 0.6;
  static const _danceTime = 1.6;

  final _rand = Random();
  Ticker? _ticker;
  double _t = 0;
  double _lastTick = 0;

  double _dragYaw = 0;
  double _dragPitch = 0;
  bool _dragging = false;

  double _nextBlink = 1.5;
  double _blinkStart = -10;
  double _jumpStart = -10;
  double _shakeStart = -10;
  double _danceStart = -10;

  @override
  void initState() {
    super.initState();
    if (widget.animated) {
      _ticker = createTicker(_onTick)..start();
    }
    widget.controller?.addListener(_onAction);
  }

  @override
  void didUpdateWidget(MascotView old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_onAction);
      widget.controller?.addListener(_onAction);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onAction);
    _ticker?.dispose();
    super.dispose();
  }

  void _onAction() {
    switch (widget.controller?.last) {
      case MascotAction.jump:
        _jumpStart = _t;
      case MascotAction.shake:
        _shakeStart = _t;
      case MascotAction.dance:
        _danceStart = _t;
      case null:
        break;
    }
  }

  void _onTick(Duration elapsed) {
    final now = elapsed.inMicroseconds / 1e6;
    final dt = (now - _lastTick).clamp(0.0, 0.1);
    _lastTick = now;
    setState(() {
      _t = now;
      if (!_dragging) {
        final k = exp(-6 * dt);
        _dragYaw *= k;
        _dragPitch *= k;
      }
      if (_t > _nextBlink) {
        _blinkStart = _t;
        _nextBlink = _t + 2 + _rand.nextDouble() * 3;
      }
      // Восторг: сам подпрыгивает время от времени (F-020 BR-06).
      if (widget.look.emotion == PetEmotion.excited && _t - _jumpStart > 2.4) _jumpStart = _t;
    });
  }

  double _phase(double start, double length) {
    final p = (_t - start) / length;
    return p >= 0 && p <= 1 ? p : -1;
  }

  @override
  Widget build(BuildContext context) {
    var yaw = 0.18;
    var pitch = 0.04;
    var blink = 0.0;
    var hop = 0.0;
    var squash = 0.0;
    var roll = 0.0;

    final emotion = widget.look.emotion;
    if (widget.animated) {
      yaw = 0.22 * sin(0.7 * _t) + _dragYaw;
      pitch = 0.06 * sin(1.1 * _t) + _dragPitch;
      squash = 0.05 * sin(2.2 * _t);
      switch (emotion) {
        case PetEmotion.hungry || PetEmotion.thirsty || PetEmotion.grubby:
          roll = 0.08 * sin(1.6 * _t);
          yaw = 0.1 * sin(0.8 * _t) + _dragYaw;
        case PetEmotion.sleepy:
          pitch = 0.2 + 0.1 * sin(0.8 * _t) + _dragPitch;
          squash = 0.09 * sin(1.2 * _t);
          roll = 0.05 * sin(0.6 * _t);
        case PetEmotion.curious:
          yaw = 0.55 * sin(0.9 * _t) + _dragYaw;
          roll = 0.08 * sin(0.45 * _t);
        case PetEmotion.excited || PetEmotion.calm || null:
          break;
      }

      final b = (_t - _blinkStart) / 0.16;
      if (b >= 0 && b <= 1 && emotion != PetEmotion.sleepy) blink = 1 - (2 * b - 1).abs();

      final j = _phase(_jumpStart, _jumpTime);
      if (j >= 0) {
        if (j < 0.15) {
          squash = 0.6 * sin(j / 0.15 * pi);
        } else if (j < 0.85) {
          final q = (j - 0.15) / 0.7;
          hop = sin(pi * q) * 0.3;
          squash = -0.35 * cos(pi * q);
        } else {
          squash = 0.45 * (1 - (j - 0.85) / 0.15);
        }
      }

      final s = _phase(_shakeStart, _shakeTime);
      if (s >= 0) {
        roll = 0.22 * sin(s * 6 * pi) * (1 - s);
        yaw += 0.35 * sin(s * 6 * pi) * (1 - s);
      }

      final d = _phase(_danceStart, _danceTime);
      if (d >= 0) {
        final eased = d < 0.5 ? 2 * d * d : 1 - pow(-2 * d + 2, 2) / 2;
        yaw += 2 * pi * eased;
        hop = max(hop, (sin(d * 3 * pi)).abs() * 0.18);
        roll = 0.15 * sin(d * 4 * pi);
      }
    }

    Widget child = RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: MascotPainter(
          look: widget.look,
          pose: SpherePose(yaw, pitch),
          blink: blink,
          hop: hop,
          squash: squash,
          roll: roll,
        ),
      ),
    );

    if (widget.interactive && widget.animated) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _jumpStart = _t;
          widget.onTap?.call();
        },
        onPanStart: (_) => _dragging = true,
        onPanUpdate: (d) {
          _dragYaw = (_dragYaw + d.delta.dx * 0.012).clamp(-1.4, 1.4);
          _dragPitch = (_dragPitch + d.delta.dy * 0.006).clamp(-0.4, 0.4);
        },
        onPanEnd: (_) => _dragging = false,
        onPanCancel: () => _dragging = false,
        child: child,
      );
    }

    final sz = widget.size;
    final overlays = <Widget>[
      if (emotion == PetEmotion.sleepy && widget.animated)
        for (var i = 0; i < 3; i++) _floating(
          phase: (_t * 0.45 + i / 3) % 1.0,
          left: (ph) => sz * (0.66 + ph * 0.22),
          top: (ph) => sz * (0.2 - ph * 0.3),
          child: (ph) => Text('z', style: TextStyle(fontSize: sz * (0.13 + ph * 0.1), fontWeight: FontWeight.w700, color: const Color(0xFF5E5CE6))),
        ),
      if (widget.look.joy != null && widget.animated) ..._joy(widget.look.joy!, sz),
    ];
    if (overlays.isNotEmpty) child = Stack(clipBehavior: Clip.none, children: [child, ...overlays]);

    final name = widget.semanticsLabel ?? 'Герой';
    return Semantics(
      label: '$name: ${widget.look.moodLabel}, стадия ${widget.look.stage}',
      image: true,
      child: ExcludeSemantics(child: child),
    );
  }

  /// Частица, всплывающая по фазе 0→1 с появлением и исчезанием.
  Widget _floating({
    required double phase,
    required double Function(double) left,
    required double Function(double) top,
    required Widget Function(double) child,
  }) => Positioned(
    left: left(phase),
    top: top(phase),
    child: IgnorePointer(child: Opacity(opacity: sin(phase * pi).clamp(0.0, 1.0), child: child(phase))),
  );

  /// Радость хотелки дня вокруг героя (F-031).
  List<Widget> _joy(String joy, double sz) {
    final glyph = switch (joy) {
      'hearts' => '💖',
      'sparkles' => '✨',
      'notes' => '🎵',
      'stars' => '⭐',
      _ => null,
    };
    if (joy == 'balloon') {
      final bob = sin(_t * 1.6) * sz * 0.03;
      return [
        Positioned(
          left: sz * 0.78,
          top: sz * 0.02 + bob,
          child: IgnorePointer(
            child: CustomPaint(size: Size(sz * 0.28, sz * 0.62), painter: _BalloonPainter(sway: sin(_t * 1.1) * 0.08)),
          ),
        ),
      ];
    }
    if (joy == 'bubbles') {
      return [
        for (var i = 0; i < 6; i++)
          _floating(
            phase: (_t * 0.3 + i / 6) % 1.0,
            left: (ph) => sz * (0.12 + (i * 0.19) % 0.8 + sin(ph * 6 + i) * 0.03),
            top: (ph) => sz * (0.62 - ph * 0.62),
            child: (ph) => Container(
              width: sz * (0.1 + (i % 3) * 0.04),
              height: sz * (0.1 + (i % 3) * 0.04),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(center: Alignment(-0.4, -0.4), colors: [Color(0xEEFFFFFF), Color(0x7780D8FF), Color(0x66A78BFA)]),
                border: Border.all(color: const Color(0xDD4FC3F7), width: 1.5),
              ),
            ),
          ),
      ];
    }
    return [
      for (var i = 0; i < 4; i++)
        _floating(
          phase: (_t * 0.35 + i / 4) % 1.0,
          left: (ph) => sz * (i.isEven ? 0.08 + ph * 0.06 : 0.74 - ph * 0.06),
          top: (ph) => sz * (0.45 - ph * 0.42),
          child: (ph) => Text(glyph ?? '💖', style: TextStyle(fontSize: sz * (0.09 + ph * 0.05))),
        ),
    ];
  }
}

/// Воздушный шарик на ниточке (F-031).
class _BalloonPainter extends CustomPainter {
  _BalloonPainter({required this.sway});
  final double sway;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final ball = Rect.fromCenter(center: Offset(w / 2, w * 0.55), width: w * 0.9, height: w * 1.05);
    final knot = Offset(w / 2, ball.bottom);
    final end = Offset(w / 2 - w * 0.9 + sway * w, size.height);
    canvas.drawPath(
      Path()
        ..moveTo(knot.dx, knot.dy)
        ..quadraticBezierTo(w * 0.2, size.height * 0.7, end.dx, end.dy),
      Paint()
        ..color = const Color(0xFF9A8F85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawOval(
      ball,
      Paint()
        ..shader = const RadialGradient(center: Alignment(-0.35, -0.4), colors: [Color(0xFFFF9AA2), Color(0xFFFF4D6D), Color(0xFFD62846)]).createShader(ball),
    );
    canvas.drawPath(
      Path()
        ..moveTo(knot.dx - 4, knot.dy + 4)
        ..lineTo(knot.dx + 4, knot.dy + 4)
        ..lineTo(knot.dx, knot.dy - 2)
        ..close(),
      Paint()..color = const Color(0xFFD62846),
    );
    canvas.drawOval(Rect.fromCenter(center: ball.center + Offset(-w * 0.18, -w * 0.22), width: w * 0.16, height: w * 0.26), Paint()..color = const Color(0x88FFFFFF));
  }

  @override
  bool shouldRepaint(_BalloonPainter old) => old.sway != sway;
}
