import '../../game/bowls.dart';
import '../../game/pet_wish.dart';
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
    this.heroBadge,
    this.heroScale = 0.56,
    this.feetY = 0.68,
    this.animated = true,
    this.bowls = const Bowls(),
    this.time = DayTime.day,
    this.initialAzimuth,
    this.orbit = const [],
  });

  final Inventory inventory;

  /// Миски с едой и водой: полные, если нужное куплено (F-027).
  final Bowls bowls;

  /// Время суток (F-028); `night: true` — то же, что ночь.
  final DayTime time;

  /// Стартовый угол камеры (превью и проверки ракурсов).
  final double? initialAzimuth;
  DayTime get _time => night ? DayTime.night : time;
  final int room;
  final bool night;
  final Widget? hero;

  /// Подпись над головой героя (облачко «нужно»).
  final Widget? heroBadge;

  /// Пузыри вокруг героя: слева и справа по два в столбик (F-039).
  final List<Widget> orbit;

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
  late double _az = widget.initialAzimuth ?? _az0;
  double _el = _el0;
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
    final key = '${inv.owned.toList()..sort()}|${inv.furniture}|${widget.room}|${widget._time}|${widget.bowls.key}';
    if (key == _key) return;
    _key = key;
    _meshes = RoomBuilder.build(inventory: inv, room: widget.room, time: widget._time, bowls: widget.bowls);
    _lighting = RoomBuilder.lighting(inventory: inv, room: widget.room, time: widget._time);
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
        final heroSize = unit * widget.heroScale * 3.125;
        final glows = [
          for (final g in RoomBuilder.glowSpots(inventory: widget.inventory, room: widget.room, time: widget._time))
            cam.project(cam.toView(g), size, shift: shift, zoom: zoom),
        ].whereType<Offset>().toList();
        final window = [for (final c in RoomBuilder.windowCorners) cam.project(cam.toView(c), size, shift: shift, zoom: zoom)];
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
                    time: widget._time,
                    window: window.contains(null) ? null : window.cast<Offset>(),
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
              for (final (i, w) in widget.orbit.indexed)
                Positioned(
                  // Чётные — слева от героя (прижаты к нему правым краем), нечётные — справа.
                  left: i.isEven ? null : heroBase.dx + heroSize * 0.36,
                  right: i.isEven ? size.width - (heroBase.dx - heroSize * 0.36) : null,
                  top: heroBase.dy - heroSize * 0.46 + (i ~/ 2) * 50, // ниже облачка реплики
                  child: w,
                ),
              if (widget.heroBadge != null)
                Positioned(
                  left: 16,
                  right: 16,
                  top: heroBase.dy - heroSize * 0.78 - 44,
                  child: Center(child: widget.heroBadge!),
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
  _RoomPainter({
    required this.frame,
    required this.heroBase,
    required this.heroUnit,
    required this.glows,
    required this.time,
    required this.window,
  });
  final Frame frame;
  final Offset heroBase;
  final double heroUnit;
  final List<Offset> glows;
  final DayTime time;

  /// Углы стекла окна на экране (для солнца, облаков, звёзд).
  final List<Offset>? window;

  @override
  void paint(Canvas canvas, Size size) {
    // Фон за диорамой: мягкий градиент.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: switch (time) {
            DayTime.morning => const [Color(0xFFFBF3EA), Color(0xFFEFE6E0)],
            DayTime.day => const [Color(0xFFF2F2F7), Color(0xFFE4E2EA)],
            DayTime.evening => const [Color(0xFFE9DEEA), Color(0xFFD9CCDD)],
            DayTime.night => const [Color(0xFF1C1F3A), Color(0xFF2A2E52)],
          },
        ).createShader(Offset.zero & size),
    );
    final paint = Paint();
    if (frame.background != null) canvas.drawVertices(frame.background!, BlendMode.dst, paint);
    if (window != null) _sky(canvas, window!);
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

  /// Солнце, облака, закат, месяц и звёзды в окне — поверх неба, под рамой и шторами (F-028).
  void _sky(Canvas canvas, List<Offset> w) {
    // w: низ-ближний, низ-дальний, верх-дальний, верх-ближний. u — вдоль окна, v — снизу вверх.
    Offset at(double u, double v) => Offset.lerp(Offset.lerp(w[0], w[1], u)!, Offset.lerp(w[3], w[2], u)!, v)!;
    final height = (w[3] - w[0]).distance;
    canvas.save();
    canvas.clipPath(Path()..addPolygon(w, true));
    void glow(Offset c, double r, Color color) => canvas.drawCircle(
      c,
      r,
      Paint()..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    void cloud(Offset c, double s) {
      final p = Paint()..color = const Color(0xE6FFFFFF);
      for (final (dx, dy, r) in const [(-0.5, 0.1, 0.32), (0.0, -0.1, 0.42), (0.5, 0.1, 0.3), (0.2, 0.18, 0.3), (-0.2, 0.2, 0.3)]) {
        canvas.drawCircle(c + Offset(dx * s, dy * s), r * s, p);
      }
    }
    switch (time) {
      case DayTime.morning:
        final sun = at(0.32, 0.55);
        glow(sun, height * 0.45, const Color(0x99FFE7A0));
        canvas.drawCircle(sun, height * 0.11, Paint()..color = const Color(0xFFFFD66B));
        cloud(at(0.72, 0.7), height * 0.14);
      case DayTime.day:
        final sun = at(0.7, 0.78);
        glow(sun, height * 0.4, const Color(0x80FFF3B0));
        canvas.drawCircle(sun, height * 0.1, Paint()..color = const Color(0xFFFFE066));
        cloud(at(0.3, 0.62), height * 0.15);
        cloud(at(0.85, 0.35), height * 0.1);
      case DayTime.evening:
        final sun = at(0.5, 0.42);
        glow(sun, height * 0.6, const Color(0xAAFF8A4C));
        canvas.drawCircle(sun, height * 0.16, Paint()..color = const Color(0xFFFF7043));
        cloud(at(0.2, 0.6), height * 0.1);
      case DayTime.night:
        final moon = at(0.72, 0.72);
        glow(moon, height * 0.35, const Color(0x55CFD8FF));
        canvas.drawCircle(moon, height * 0.1, Paint()..color = const Color(0xFFFFF3C4));
        canvas.drawCircle(moon + Offset(height * 0.045, -height * 0.03), height * 0.085, Paint()..color = const Color(0xFF222A62));
        final star = Paint()..color = const Color(0xFFFFFFFF);
        for (final (u, v, r) in const [
          (0.12, 0.85, 1.0), (0.3, 0.62, 0.7), (0.22, 0.4, 0.8), (0.45, 0.88, 0.9), (0.52, 0.5, 0.6),
          (0.08, 0.55, 0.6), (0.9, 0.45, 0.8), (0.62, 0.28, 0.7), (0.38, 0.25, 0.5), (0.85, 0.9, 0.6),
        ]) {
          canvas.drawCircle(at(u, v), height * 0.012 * r + 0.8, star);
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RoomPainter old) => true;
}
