import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'room_painter.dart';

/// Пылинки, плавающие в луче света из окна (SA F-017 BR-16, BR-19).
/// Анимируется только этот слой; статичная комната не перерисовывается.
class RoomAmbience extends StatefulWidget {
  const RoomAmbience({super.key, this.feetY = 0.84, this.night = false, this.animated = true});
  final double feetY;
  final bool night;
  final bool animated;

  @override
  State<RoomAmbience> createState() => _RoomAmbienceState();
}

class _RoomAmbienceState extends State<RoomAmbience> with SingleTickerProviderStateMixin {
  final _time = ValueNotifier<double>(0);
  Ticker? _ticker;

  @override
  void initState() {
    super.initState();
    if (widget.animated) {
      _ticker = createTicker((e) => _time.value = e.inMicroseconds / 1e6)..start();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _DustPainter(time: _time, feetY: widget.feetY, night: widget.night),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Mote {
  _Mote(Random r)
    : u = r.nextDouble(),
      v = r.nextDouble(),
      speed = 0.015 + r.nextDouble() * 0.03,
      sway = r.nextDouble() * 2 * pi,
      size = 0.8 + r.nextDouble() * 1.8;
  final double u, v, speed, sway, size;
}

class _DustPainter extends CustomPainter {
  _DustPainter({required this.time, required this.feetY, required this.night}) : super(repaint: time);
  final ValueNotifier<double> time;
  final double feetY;
  final bool night;

  static final _motes = List.generate(34, (i) => _Mote(Random(i * 31 + 7)));

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final g = RoomGeometry(size, feetY: feetY);
    final win = g.window;
    final patch = g.lightPatch;
    // Луч: верх — окно, низ — пятно на полу.
    final topL = win.topLeft.translate(win.width * 0.1, win.height * 0.05);
    final topR = win.topRight;
    final botR = patch[2];
    final botL = patch[3];
    final t = time.value;
    final color = night ? const Color(0xFFD7DEFF) : const Color(0xFFFFF7DC);
    for (final m in _motes) {
      // Медленно поднимаются, колышутся из стороны в сторону.
      final v = (m.v - t * m.speed) % 1.0;
      final u = (m.u + 0.04 * sin(t * 0.6 + m.sway)).clamp(0.0, 1.0);
      final left = Offset.lerp(topL, botL, v)!;
      final right = Offset.lerp(topR, botR, v)!;
      final p = Offset.lerp(left, right, u)!;
      final fade = sin(v * pi); // гаснут у краёв луча
      final twinkle = 0.6 + 0.4 * sin(t * 2 + m.sway * 3);
      canvas.drawCircle(p, m.size, Paint()..color = color.withValues(alpha: 0.75 * fade * twinkle));
    }
  }

  @override
  bool shouldRepaint(_DustPainter old) => old.feetY != feetY || old.night != night;
}
