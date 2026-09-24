import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../store/snapshot.dart';
import '../room3d/math3d.dart';
import '../room3d/mesh.dart';
import '../room3d/renderer.dart';
import '../room3d/room_builder.dart';

/// Полноэкранная 3D-комната с героем внутри (SA F-019). Пальцем комнату можно покрутить.
class RoomScene extends StatefulWidget {
  const RoomScene({
    super.key,
    required this.inventory,
    this.room = 1,
    this.night = false,
    this.hero,
    this.heroScale = 0.56,
    this.feetY = 0.68,
    this.animated = true,
  });

  final Inventory inventory;
  final int room;
  final bool night;
  final Widget? hero;

  /// Совместимость с F-017: размер героя теперь считается по перспективе.
  final double heroScale;

  /// Где стоит герой по высоте экрана (доля).
  final double feetY;

  /// Пружинный возврат камеры; в статичных превью выключается.
  final bool animated;

  @override
  State<RoomScene> createState() => _RoomSceneState();
}

class _RoomSceneState extends State<RoomScene> with SingleTickerProviderStateMixin {
  static const _az0 = 0.62, _el0 = 0.34;
  double _az = _az0, _el = _el0;
  bool _dragging = false;
  Ticker? _ticker;
  Duration _last = Duration.zero;

  List<Mesh>? _meshes;
  Lighting? _lighting;
  String? _key;

  @override
  void initState() {
    super.initState();
    if (widget.animated) _ticker = createTicker(_tick);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    if (_dragging) return;
    final k = exp(-7 * dt);
    setState(() {
      _az = _az0 + (_az - _az0) * k;
      _el = _el0 + (_el - _el0) * k;
    });
    if ((_az - _az0).abs() < 0.001 && (_el - _el0).abs() < 0.001) {
      _ticker?.stop();
      _last = Duration.zero;
    }
  }

  void _ensureScene() {
    final inv = widget.inventory;
    final key = '${inv.owned.toList()..sort()}|${inv.furniture}|${widget.room}|${widget.night}';
    if (key == _key) return;
    _key = key;
    _meshes = RoomBuilder.build(inventory: inv, room: widget.room, night: widget.night);
    _lighting = RoomBuilder.lighting(inventory: inv, room: widget.room, night: widget.night);
  }

  @override
  Widget build(BuildContext context) {
    _ensureScene();
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        if (size.isEmpty) return const SizedBox.shrink();
        final cam = Camera(azimuth: _az, elevation: _el, distance: 9, fov: 0.62);
        final (zoom, shift) = _framing(cam, size);
        final heroBase = cam.project(cam.toView(RoomBuilder.heroSpot), size, shift: shift, zoom: zoom)!;
        final heroTop = cam.project(cam.toView(RoomBuilder.heroSpot + const Vec3(0, 1, 0)), size, shift: shift, zoom: zoom)!;
        final unit = (heroBase.dy - heroTop.dy).abs();
        final heroSize = unit * 1.75;
        final glows = [
          if (widget.night)
            for (final g in RoomBuilder.glowSpots(inventory: widget.inventory, room: widget.room))
              cam.project(cam.toView(g), size, shift: shift, zoom: zoom),
        ].whereType<Offset>().toList();
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) {
            _dragging = true;
            _ticker?.stop();
            _last = Duration.zero;
          },
          onPanUpdate: (d) => setState(() {
            _az = (_az - d.delta.dx * 0.006).clamp(0.17, 1.22);
            _el = (_el + d.delta.dy * 0.004).clamp(0.26, 0.7);
          }),
          onPanEnd: (_) {
            _dragging = false;
            if (_ticker != null && !_ticker!.isActive) _ticker!.start();
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  size: size,
                  painter: _RoomPainter(
                    frame: Renderer.render(_meshes!, cam, size, _lighting!, shift: shift, zoom: zoom),
                    heroBase: heroBase,
                    heroUnit: unit,
                    glows: glows,
                    night: widget.night,
                  ),
                ),
              ),
              if (widget.hero != null)
                Positioned(
                  left: heroBase.dx - heroSize / 2,
                  top: heroBase.dy - heroSize * 0.9,
                  width: heroSize,
                  height: heroSize,
                  child: widget.hero!,
                ),
            ],
          ),
        );
      },
    );
  }

  /// Подбирает масштаб так, чтобы комната заняла ширину, а герой встал на [RoomScene.feetY].
  (double, Offset) _framing(Camera cam, Size size) {
    const corners = [
      Vec3(-2.14, -0.18, 2), Vec3(2, -0.18, 2), Vec3(2, -0.18, -2.14),
      Vec3(-2.14, RoomBuilder.h, -2.14), Vec3(2, RoomBuilder.h, -2.14), Vec3(-2.14, RoomBuilder.h, 2),
    ];
    var minX = double.infinity, maxX = -double.infinity;
    for (final c in corners) {
      final p = cam.project(cam.toView(c), size);
      if (p == null) continue;
      minX = min(minX, p.dx);
      maxX = max(maxX, p.dx);
    }
    final zoom = size.width * 1.32 / max(1, maxX - minX);
    final hero = cam.project(cam.toView(RoomBuilder.heroSpot), size, zoom: zoom)!;
    final target = Offset(size.width / 2, size.height * widget.feetY);
    return (zoom, target - hero);
  }
}

class _RoomPainter extends CustomPainter {
  _RoomPainter({required this.frame, required this.heroBase, required this.heroUnit, required this.glows, required this.night});
  final Frame frame;
  final Offset heroBase;
  final double heroUnit;
  final List<Offset> glows;
  final bool night;

  @override
  void paint(Canvas canvas, Size size) {
    // Фон за диорамой: мягкий градиент.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: night ? const [Color(0xFF1C1F3A), Color(0xFF2A2E52)] : const [Color(0xFFF2F2F7), Color(0xFFE4E2EA)],
        ).createShader(Offset.zero & size),
    );
    final paint = Paint();
    if (frame.background != null) canvas.drawVertices(frame.background!, BlendMode.dst, paint);
    if (frame.decals != null) canvas.drawVertices(frame.decals!, BlendMode.dst, paint);
    final shadow = Paint()
      ..color = const Color(0x40000000)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, heroUnit * 0.06);
    for (final s in frame.shadows) {
      canvas.drawPath(s, shadow);
    }
    // Тень героя.
    canvas.drawOval(Rect.fromCenter(center: heroBase, width: heroUnit * 1.05, height: heroUnit * 0.32), shadow);
    if (frame.objects != null) canvas.drawVertices(frame.objects!, BlendMode.dst, paint);
    for (final g in glows) {
      final r = heroUnit * 1.4;
      canvas.drawCircle(
        g,
        r,
        Paint()..shader = const RadialGradient(colors: [Color(0x66FFD98A), Color(0x00FFD98A)]).createShader(Rect.fromCircle(center: g, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(_RoomPainter old) => true;
}
