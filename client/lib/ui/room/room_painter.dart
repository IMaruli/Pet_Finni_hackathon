import 'dart:math';

import 'package:flutter/rendering.dart';

/// Перспективная комната (SA F-017 §4.3): точка схода по центру, задняя стена — уменьшенный экран.
final class RoomGeometry {
  RoomGeometry(this.size, {this.feetY = 0.84})
    : back = Rect.fromLTRB(size.width * 0.12, size.height * 0.09, size.width * 0.88, size.height * min(0.6, feetY - 0.16)),
      v = Offset(size.width * 0.5, size.height * 0.09 / (1 - 0.76));

  final Size size;

  /// Где стоит герой по высоте (доля экрана). На Доме выше: снизу панель.
  final double feetY;

  /// Точка схода.
  final Offset v;

  /// Задняя стена.
  final Rect back;

  double get w => size.width;
  double get h => size.height;

  /// Где пол встречает край экрана (линия из точки схода через угол задней стены).
  double get floorEdgeY => v.dy + (back.bottom - v.dy) * (w * 0.5) / (back.right - v.dx);

  /// Точка на левой стене: u — от края экрана (0) к углу (1), t — сверху (0) вниз (1).
  Offset leftWall(double u, double t) {
    final top = Offset.lerp(Offset.zero, back.topLeft, u)!;
    final bottom = Offset.lerp(Offset(0, floorEdgeY), back.bottomLeft, u)!;
    return Offset.lerp(top, bottom, t)!;
  }

  Offset rightWall(double u, double t) {
    final top = Offset.lerp(Offset(w, 0), back.topRight, u)!;
    final bottom = Offset.lerp(Offset(w, floorEdgeY), back.bottomRight, u)!;
    return Offset.lerp(top, bottom, t)!;
  }

  /// Точка пола: x — доля ширины на линии задней стены, depth — 0 у задней стены, 1 у низа экрана.
  Offset floor(double x, double depth) {
    final atBack = Offset(back.left + back.width * x, back.bottom);
    final dir = atBack - v;
    final y = back.bottom + (h - back.bottom) * depth;
    final k = (y - v.dy) / dir.dy;
    return v + dir * k;
  }

  /// Окно на задней стене.
  Rect get window => Rect.fromLTRB(
    back.left + back.width * 0.07,
    back.top + back.height * 0.12,
    back.left + back.width * 0.4,
    back.top + back.height * 0.66,
  );

  /// Пятно света от окна на полу (четырёхугольник).
  List<Offset> get lightPatch => [floor(0.1, 0.02), floor(0.42, 0.02), floor(0.78, 0.62), floor(0.18, 0.72)];

  /// Где стоят «ноги» героя: центр коврика.
  Offset get heroFeet => Offset(w * 0.5, h * feetY);
}

Offset heroAnchor(Size size, {double feetY = 0.84}) => RoomGeometry(size, feetY: feetY).heroFeet;

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
Color _dark(Color c, double t) => _mix(c, const Color(0xFF000000), t);
Color _light(Color c, double t) => _mix(c, const Color(0xFFFFFFFF), t);

final class RoomPainter extends CustomPainter {
  RoomPainter({required this.owned, this.furniture, this.room = 1, this.night = false, this.feetY = 0.84});

  /// Купленные постоянные вещи: lamp, rug, poster.
  final Set<String> owned;

  /// Крупная мебель из цели: sofa|shelf|tv|console.
  final String? furniture;

  /// 1 — спальня, 2 — игровая.
  final int room;
  final bool night;
  final double feetY;

  bool get _play => room == 2;
  Color get _wall => _play ? const Color(0xFFBFE3D8) : const Color(0xFFF2BFA1);
  Color get _wood => _play ? const Color(0xFFD9BE96) : const Color(0xFFCF9A62);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final g = RoomGeometry(size, feetY: feetY);

    _ceiling(canvas, g);
    _walls(canvas, g);
    _floor(canvas, g);
    _trim(canvas, g);
    _ambientOcclusion(canvas, g);

    if (_play) {
      _playroom(canvas, g);
    } else {
      _window(canvas, g);
      _shelves(canvas, g);
      _clock(canvas, g);
      if (owned.contains('poster')) _poster(canvas, g);
    }
    _floorGloss(canvas, g);
    if (!_play) _bigPlant(canvas, g);

    if (!_play && owned.contains('rug')) {
      _rug(canvas, g, const Color(0xFFD98C8C), const Color(0xFFF3C6C0));
    }
    if (!_play) {
      switch (furniture) {
        case 'sofa':
          _sofa(canvas, g);
        case 'shelf':
          _bookshelf(canvas, g);
        case 'tv':
          _tv(canvas, g);
        case 'console':
          _console(canvas, g);
      }
    }
    _pendant(canvas, g);
    _godRays(canvas, g);
    if (!_play && owned.contains('lamp')) _lamp(canvas, g);
    _vignette(canvas, g);

    if (night) {
      _night(canvas, g);
      if (!_play && owned.contains('lamp')) _lampGlow(canvas, g);
      _pendantGlow(canvas, g);
    }
  }

  // ---------- Коробка комнаты ----------

  void _ceiling(Canvas canvas, RoomGeometry g) {
    final b = g.back;
    final path = _path([Offset.zero, Offset(g.w, 0), b.topRight, b.topLeft]);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_light(_wall, 0.2), _light(_wall, 0.45)],
        ).createShader(Rect.fromLTRB(0, 0, g.w, b.top)),
    );
  }

  void _walls(Canvas canvas, RoomGeometry g) {
    final b = g.back;
    // Боковые стены: темнее к зрителю, как в настоящей комнате.
    canvas.drawPath(
      _path([Offset.zero, b.topLeft, b.bottomLeft, Offset(0, g.floorEdgeY)]),
      Paint()..shader = LinearGradient(colors: [_dark(_wall, 0.16), _dark(_wall, 0.05)]).createShader(Rect.fromLTRB(0, 0, b.left, g.h)),
    );
    canvas.drawPath(
      _path([Offset(g.w, 0), b.topRight, b.bottomRight, Offset(g.w, g.floorEdgeY)]),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [_dark(_wall, 0.12), _dark(_wall, 0.03)],
        ).createShader(Rect.fromLTRB(b.right, 0, g.w, g.h)),
    );
    // Задняя стена: светлое пятно от окна.
    canvas.drawRect(
      b,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.45, -0.1),
          radius: 1.1,
          colors: [_light(_wall, 0.22), _wall, _dark(_wall, 0.04)],
          stops: const [0, 0.6, 1],
        ).createShader(b),
    );
    // Обои: тонкий узор из точек на верхней части задней стены.
    final dot = Paint()..color = _dark(_wall, 0.08).withValues(alpha: 0.35);
    final panelTop = b.top + b.height * 0.68;
    final step = b.width / 22;
    for (var y = b.top + step; y < panelTop - step * 0.5; y += step) {
      final row = ((y - b.top) / step).round();
      for (var x = b.left + step * (row.isOdd ? 1 : 0.5); x < b.right; x += step) {
        canvas.drawCircle(Offset(x, y), step * 0.07, dot);
      }
    }
    // Стеновые панели снизу.
    final panel = Rect.fromLTRB(b.left, panelTop, b.right, b.bottom);
    canvas.drawRect(panel, Paint()..color = _light(_wall, 0.3));
    final line = Paint()
      ..color = _dark(_wall, 0.1).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(
      panel.topLeft,
      panel.topRight,
      Paint()
        ..color = _light(_wall, 0.6)
        ..strokeWidth = 3,
    );
    const n = 5;
    for (var i = 0; i < n; i++) {
      final cell = Rect.fromLTWH(panel.left + panel.width * i / n, panel.top, panel.width / n, panel.height).deflate(panel.height * 0.18);
      canvas.drawRRect(RRect.fromRectAndRadius(cell, const Radius.circular(2)), line);
    }
    // Панели на боковых стенах.
    for (final left in [true, false]) {
      Offset pt(double u, double t) => left ? g.leftWall(u, t) : g.rightWall(u, t);
      _poly(canvas, [pt(0, 0.68), pt(1, 0.68), pt(1, 1), pt(0, 1)], _light(_dark(_wall, left ? 0.12 : 0.08), 0.28));
      canvas.drawLine(
        pt(0, 0.68),
        pt(1, 0.68),
        Paint()
          ..color = _light(_wall, 0.5)
          ..strokeWidth = 3,
      );
    }
  }

  void _floor(Canvas canvas, RoomGeometry g) {
    final b = g.back;
    final floorPoly = [b.bottomLeft, b.bottomRight, Offset(g.w, g.floorEdgeY), Offset(g.w, g.h), Offset(0, g.h), Offset(0, g.floorEdgeY)];
    final floorPath = _path(floorPoly);
    canvas.drawPath(floorPath, Paint()..color = _wood);
    canvas.save();
    canvas.clipPath(floorPath);
    // Доски разных оттенков: полосы между линиями к точке схода.
    const shades = [0.0, 0.06, -0.04, 0.03, -0.07, 0.05, -0.02];
    for (var i = -8; i < 18; i++) {
      final x0 = i / 10, x1 = (i + 1) / 10;
      final shade = shades[(i + 8) % shades.length];
      final color = shade >= 0 ? _light(_wood, shade) : _dark(_wood, -shade);
      _poly(canvas, [g.floor(x0, 0), g.floor(x1, 0), g.floor(x1, 1.3), g.floor(x0, 1.3)], color);
    }
    // Глубина: к задней стене темнее.
    canvas.drawRect(
      Rect.fromLTRB(0, b.bottom, g.w, g.h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_dark(_wood, 0.25).withValues(alpha: 0.6), const Color(0x00000000)],
          stops: const [0, 0.55],
        ).createShader(Rect.fromLTRB(0, b.bottom, g.w, g.h)),
    );
    final seam = Paint()
      ..color = _dark(_wood, 0.35).withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var i = -8; i <= 18; i++) {
      canvas.drawLine(g.floor(i / 10, 0), g.floor(i / 10, 1.3), seam);
    }
    // Поперечные стыки — чаще у стены.
    var depth = 0.03;
    var row = 0;
    while (depth < 1.1) {
      final y = b.bottom + (g.h - b.bottom) * depth;
      for (var i = -8; i <= 18; i += 3) {
        final x = (i + (row % 3)) / 10;
        final p = g.floor(x, depth), q = g.floor(x + 0.1, depth);
        canvas.drawLine(Offset(p.dx, y), Offset(q.dx, y), seam);
      }
      depth = depth * 1.5 + 0.035;
      row++;
    }
    canvas.restore();
  }

  void _trim(Canvas canvas, RoomGeometry g) {
    final b = g.back;
    final white = _light(_wall, 0.7);
    final h = g.h * 0.014;
    // Плинтусы.
    canvas.drawRect(Rect.fromLTRB(b.left, b.bottom - h, b.right, b.bottom), Paint()..color = white);
    _poly(canvas, [b.bottomLeft.translate(0, -h), b.bottomLeft, Offset(0, g.floorEdgeY), Offset(0, g.floorEdgeY - h * 2.6)], _dark(white, 0.06));
    _poly(canvas, [b.bottomRight.translate(0, -h), b.bottomRight, Offset(g.w, g.floorEdgeY), Offset(g.w, g.floorEdgeY - h * 2.6)], _dark(white, 0.04));
    // Карниз под потолком.
    canvas.drawRect(Rect.fromLTRB(b.left, b.top, b.right, b.top + h * 0.9), Paint()..color = white);
    _poly(canvas, [b.topLeft, b.topLeft.translate(0, h * 0.9), Offset(0, h * 2.4), Offset.zero], _dark(white, 0.05));
    _poly(canvas, [b.topRight, b.topRight.translate(0, h * 0.9), Offset(g.w, h * 2.4), Offset(g.w, 0)], _dark(white, 0.03));
  }

  void _ambientOcclusion(Canvas canvas, RoomGeometry g) {
    final b = g.back;
    final ao = g.w * 0.05;
    // Стык стены и пола.
    final seam = Rect.fromLTRB(b.left, b.bottom - ao, b.right, b.bottom);
    canvas.drawRect(
      seam,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0x26000000), Color(0x00000000)],
        ).createShader(seam),
    );
    // Вертикальные углы.
    for (final (x, dir) in [(b.left, 1.0), (b.right, -1.0)]) {
      final r = Rect.fromLTRB(min(x, x + dir * ao), b.top, max(x, x + dir * ao), b.bottom);
      canvas.drawRect(
        r,
        Paint()
          ..shader = LinearGradient(
            begin: dir > 0 ? Alignment.centerLeft : Alignment.centerRight,
            end: dir > 0 ? Alignment.centerRight : Alignment.centerLeft,
            colors: const [Color(0x22000000), Color(0x00000000)],
          ).createShader(r),
      );
    }
  }

  // ---------- Окно и свет ----------

  void _window(Canvas canvas, RoomGeometry g) {
    final frame = g.window;
    final depth = frame.width * 0.08;
    // Откос (толщина стены).
    canvas.drawRect(frame.inflate(depth * 0.6), Paint()..color = _light(_wall, 0.55));
    canvas.drawRect(frame, Paint()..color = _dark(_wall, 0.12));
    final glass = Rect.fromLTRB(frame.left + depth, frame.top + depth * 0.7, frame.right - depth * 0.4, frame.bottom - depth * 0.2);
    canvas.drawRect(
      glass,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: night ? const [Color(0xFF0F1640), Color(0xFF2E3580)] : const [Color(0xFF7CC3F0), Color(0xFFD6EFFF)],
        ).createShader(glass),
    );
    canvas.save();
    canvas.clipRect(glass);
    if (night) {
      final moon = glass.topRight.translate(-glass.width * 0.3, glass.height * 0.22);
      canvas.drawCircle(
        moon,
        glass.width * 0.22,
        Paint()
          ..color = const Color(0x33FFF4B8)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, glass.width * 0.08),
      );
      canvas.drawCircle(moon, glass.width * 0.12, Paint()..color = const Color(0xFFFFF4C8));
      final star = Paint()..color = const Color(0xDDFFFFFF);
      for (final (x, y, r) in [(0.18, 0.14, 1.6), (0.42, 0.4, 1.2), (0.12, 0.52, 1.4), (0.66, 0.62, 1.1), (0.3, 0.3, 0.9), (0.8, 0.45, 1.3)]) {
        canvas.drawCircle(Offset(glass.left + glass.width * x, glass.top + glass.height * y), r, star);
      }
    } else {
      final sun = glass.topRight.translate(-glass.width * 0.26, glass.height * 0.2);
      canvas.drawCircle(
        sun,
        glass.width * 0.2,
        Paint()
          ..color = const Color(0x55FFF2B0)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, glass.width * 0.1),
      );
      canvas.drawCircle(sun, glass.width * 0.1, Paint()..color = const Color(0xFFFFE27A));
      // Холмы и деревья.
      canvas.drawOval(
        Rect.fromCenter(center: Offset(glass.center.dx, glass.bottom + glass.height * 0.08), width: glass.width * 1.6, height: glass.height * 0.4),
        Paint()..color = const Color(0xFFA8D98C),
      );
      for (final (x, r, c) in [(0.15, 0.32, 0xFF7DB86A), (0.55, 0.26, 0xFF6DAA5C), (0.95, 0.3, 0xFF83BF70)]) {
        canvas.drawCircle(Offset(glass.left + glass.width * x, glass.bottom - glass.height * 0.1), glass.width * r, Paint()..color = Color(c));
      }
      final cloud = Paint()..color = const Color(0xF2FFFFFF);
      final c = Offset(glass.left + glass.width * 0.35, glass.top + glass.height * 0.28);
      for (final (dx, dy, r) in [(0.0, 0.0, 0.09), (0.1, -0.04, 0.11), (0.21, 0.0, 0.085), (0.1, 0.03, 0.09)]) {
        canvas.drawCircle(c.translate(glass.width * dx, glass.width * dy), glass.width * r, cloud);
      }
    }
    // Блик на стекле.
    _poly(canvas, [
      glass.topLeft.translate(glass.width * 0.1, 0),
      glass.topLeft.translate(glass.width * 0.28, 0),
      glass.bottomLeft.translate(glass.width * 0.02, 0),
      glass.bottomLeft.translate(-glass.width * 0.16, 0),
    ], const Color(0x1FFFFFFF));
    canvas.restore();
    // Рама и переплёт.
    final frameInk = Paint()
      ..color = const Color(0xFFFFFBF4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = frame.width * 0.035;
    canvas.drawRect(glass, frameInk);
    canvas.drawLine(Offset(glass.center.dx, glass.top), Offset(glass.center.dx, glass.bottom), frameInk);
    canvas.drawLine(Offset(glass.left, glass.top + glass.height * 0.42), Offset(glass.right, glass.top + glass.height * 0.42), frameInk);
    // Подоконник с горшком.
    final sill = Rect.fromLTRB(frame.left - depth, frame.bottom - 1, frame.right + depth, frame.bottom + g.h * 0.012);
    canvas.drawRRect(RRect.fromRectAndRadius(sill, const Radius.circular(2)), Paint()..color = const Color(0xFFFFF8EE));
    canvas.drawRect(Rect.fromLTRB(sill.left, sill.bottom, sill.right, sill.bottom + g.h * 0.008), Paint()..color = const Color(0x22000000));
    _smallPlant(canvas, Offset(frame.right - frame.width * 0.22, sill.top), frame.width * 0.18);
    // Шторы с подхватами.
    for (final left in [true, false]) {
      final w = frame.width * 0.26;
      final x0 = left ? frame.left - w * 0.85 : frame.right - w * 0.15;
      final top = frame.top - frame.height * 0.12;
      final bottom = frame.bottom + frame.height * 0.32;
      final tie = frame.top + frame.height * 0.62;
      final inner = left ? x0 + w : x0;
      final outer = left ? x0 : x0 + w;
      final waist = left ? x0 + w * 0.45 : x0 + w * 0.55;
      final path = Path()
        ..moveTo(outer, top)
        ..lineTo(inner, top)
        ..quadraticBezierTo(inner, tie - frame.height * 0.25, waist, tie)
        ..quadraticBezierTo(inner, bottom - frame.height * 0.12, inner, bottom)
        ..lineTo(outer, bottom)
        ..close();
      final bounds = Rect.fromLTRB(x0, top, x0 + w, bottom);
      canvas.drawPath(
        path.shift(const Offset(3, 4)),
        Paint()
          ..color = const Color(0x1A000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFBF1E4), Color(0xFFE6D2BA), Color(0xFFFBF1E4), Color(0xFFE2CCB1), Color(0xFFF7EADB)],
          ).createShader(bounds),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(waist, tie), width: w * 0.55, height: frame.height * 0.035), const Radius.circular(3)),
        Paint()..color = const Color(0xFFD9A06A),
      );
    }
    final rod = Paint()
      ..color = const Color(0xFFB08A63)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final rodY = frame.top - frame.height * 0.12;
    canvas.drawLine(Offset(frame.left - frame.width * 0.3, rodY), Offset(frame.right + frame.width * 0.3, rodY), rod);
    for (final x in [frame.left - frame.width * 0.3, frame.right + frame.width * 0.3]) {
      canvas.drawCircle(Offset(x, rodY), 4, Paint()..color = const Color(0xFF9A7350));
    }
  }

  void _godRays(Canvas canvas, RoomGeometry g) {
    if (_play) return;
    final win = g.window;
    final patch = g.lightPatch;
    final beam = _path([win.topLeft.translate(win.width * 0.1, win.height * 0.05), win.topRight, patch[2], patch[3]]);
    final color = night ? const Color(0xFFB8C6FF) : const Color(0xFFFFF4D2);
    canvas.drawPath(
      beam,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: night ? 0.12 : 0.22), color.withValues(alpha: 0)],
        ).createShader(beam.getBounds())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    // Пятно на полу.
    canvas.drawPath(
      _path(patch),
      Paint()
        ..color = color.withValues(alpha: night ? 0.16 : 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
  }

  void _floorGloss(Canvas canvas, RoomGeometry g) {
    if (_play) return;
    // Отражение окна на лакированном полу.
    final win = g.window;
    final c = Offset(win.center.dx + g.w * 0.03, g.back.bottom + (g.h - g.back.bottom) * 0.12);
    canvas.drawOval(
      Rect.fromCenter(center: c, width: win.width * 1.1, height: g.h * 0.06),
      Paint()
        ..color = (night ? const Color(0x22B8C6FF) : const Color(0x33FFFFFF))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
  }

  // ---------- Декор, который есть всегда ----------

  void _shelves(Canvas canvas, RoomGeometry g) {
    final b = g.back;
    const wood = Color(0xFFD4A97A);
    for (final (x0, x1, y) in [(0.62, 0.95, 0.22), (0.56, 0.86, 0.42)]) {
      final top = b.top + b.height * y;
      final rect = Rect.fromLTRB(b.left + b.width * x0, top, b.left + b.width * x1, top + b.height * 0.028);
      canvas.drawRect(
        rect.translate(0, rect.height),
        Paint()
          ..color = const Color(0x22000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), Paint()..color = wood);
      canvas.drawRect(Rect.fromLTRB(rect.left, rect.top, rect.right, rect.top + 2), Paint()..color = _light(wood, 0.3));
    }
    final s = b.width;
    // Верхняя полка: растение и книжки.
    final top1 = b.top + b.height * 0.22;
    _smallPlant(canvas, Offset(b.left + s * 0.88, top1), s * 0.07);
    const books = [Color(0xFFE07A5F), Color(0xFF5C84E0), Color(0xFFF2CF6B)];
    for (var i = 0; i < 3; i++) {
      final bh = s * (0.07 - i * 0.006);
      canvas.drawRect(Rect.fromLTWH(b.left + s * (0.66 + i * 0.026), top1 - bh, s * 0.022, bh), Paint()..color = books[i]);
    }
    // Нижняя полка: баночка-копилка и рамка.
    final top2 = b.top + b.height * 0.42;
    final jar = Rect.fromLTWH(b.left + s * 0.6, top2 - s * 0.06, s * 0.05, s * 0.06);
    canvas.drawRRect(RRect.fromRectAndRadius(jar, const Radius.circular(4)), Paint()..color = const Color(0x88CFE8F5));
    canvas.drawRect(Rect.fromLTWH(jar.left, jar.bottom - jar.height * 0.4, jar.width, jar.height * 0.4), Paint()..color = const Color(0xFFE8B23A));
    canvas.drawRect(Rect.fromLTWH(jar.left - 1, jar.top - 3, jar.width + 2, 4), Paint()..color = const Color(0xFF5C84E0));
    final photo = Rect.fromLTWH(b.left + s * 0.72, top2 - s * 0.075, s * 0.06, s * 0.075);
    canvas.drawRect(photo, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawRect(photo.deflate(3), Paint()..color = const Color(0xFF9FD3C7));
    canvas.drawCircle(photo.center.translate(0, 2), photo.width * 0.18, Paint()..color = const Color(0xFFFFCC33));
  }

  void _smallPlant(Canvas canvas, Offset base, double s) {
    final pot = Rect.fromLTRB(base.dx - s * 0.35, base.dy - s * 0.55, base.dx + s * 0.35, base.dy);
    final path = Path()
      ..moveTo(pot.left, pot.top)
      ..lineTo(pot.right, pot.top)
      ..lineTo(pot.right - s * 0.08, pot.bottom)
      ..lineTo(pot.left + s * 0.08, pot.bottom)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFF7F1E8));
    canvas.drawRect(Rect.fromLTWH(pot.left, pot.top, pot.width, s * 0.1), Paint()..color = const Color(0xFFE9DFD2));
    final leaf = Paint()..color = const Color(0xFF6BA35A);
    final leaf2 = Paint()..color = const Color(0xFF82B86E);
    for (var i = -2; i <= 2; i++) {
      canvas.save();
      canvas.translate(base.dx, pot.top);
      canvas.rotate(i * 0.42);
      canvas.drawOval(Rect.fromCenter(center: Offset(0, -s * 0.45), width: s * 0.3, height: s * 0.9), i.isEven ? leaf : leaf2);
      canvas.restore();
    }
  }

  void _clock(Canvas canvas, RoomGeometry g) {
    final c = g.rightWall(0.5, 0.3);
    final r = g.w * 0.07;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(0.55, 1); // сжатие в перспективе боковой стены
    canvas.drawCircle(
      const Offset(-3, 3),
      r,
      Paint()
        ..color = const Color(0x22000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(Offset.zero, r, Paint()..color = const Color(0xFFB9855A));
    canvas.drawCircle(Offset.zero, r * 0.84, Paint()..color = const Color(0xFFFFFBF2));
    final tick = Paint()
      ..color = const Color(0xFF6B4A33)
      ..strokeWidth = 2;
    for (var i = 0; i < 12; i++) {
      final a = i * pi / 6;
      canvas.drawLine(Offset(cos(a), sin(a)) * r * 0.66, Offset(cos(a), sin(a)) * r * 0.76, tick);
    }
    final hand = Paint()
      ..color = const Color(0xFF3B2A20)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, Offset(0, -r * 0.5), hand);
    canvas.drawLine(Offset.zero, Offset(r * 0.38, r * 0.1), hand);
    canvas.drawCircle(Offset.zero, 3, Paint()..color = const Color(0xFFE0668F));
    canvas.restore();
  }

  void _poster(Canvas canvas, RoomGeometry g) {
    final b = g.back;
    final r = Rect.fromLTWH(b.left + b.width * 0.53, b.top + b.height * 0.5, b.width * 0.12, b.height * 0.2);
    canvas.drawRect(
      r.inflate(5).translate(2, 3),
      Paint()
        ..color = const Color(0x22000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawRRect(RRect.fromRectAndRadius(r.inflate(5), const Radius.circular(3)), Paint()..color = const Color(0xFF9C6B43));
    canvas.drawRect(
      r,
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFE9B8), Color(0xFFFFD08A)]).createShader(r),
    );
    final c = r.center.translate(0, r.height * 0.05);
    final rad = r.width * 0.32;
    canvas.drawCircle(
      c,
      rad,
      Paint()..shader = const RadialGradient(center: Alignment(-0.3, -0.4), colors: [Color(0xFFFFE680), Color(0xFFF2B51E)]).createShader(Rect.fromCircle(center: c, radius: rad)),
    );
    final ink = Paint()..color = const Color(0xFF2B1D14);
    canvas.drawOval(Rect.fromCenter(center: c.translate(-rad * 0.35, -rad * 0.1), width: rad * 0.2, height: rad * 0.3), ink);
    canvas.drawOval(Rect.fromCenter(center: c.translate(rad * 0.35, -rad * 0.1), width: rad * 0.2, height: rad * 0.3), ink);
    canvas.drawArc(
      Rect.fromCenter(center: c.translate(0, rad * 0.15), width: rad * 0.8, height: rad * 0.6),
      0.2,
      pi - 0.4,
      false,
      Paint()
        ..color = const Color(0xFF2B1D14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (final (x, y) in [(0.15, 0.15), (0.85, 0.2), (0.8, 0.85)]) {
      canvas.drawCircle(Offset(r.left + r.width * x, r.top + r.height * y), 2, Paint()..color = const Color(0xFFFFFFFF));
    }
  }

  void _bigPlant(Canvas canvas, RoomGeometry g) {
    // Монстера в левом углу у стены.
    final base = g.floor(0.03, 0.06);
    final s = g.w * 0.16;
    _shadow(canvas, Rect.fromCenter(center: base, width: s * 0.9, height: s * 0.18));
    final pot = Rect.fromLTRB(base.dx - s * 0.3, base.dy - s * 0.55, base.dx + s * 0.3, base.dy);
    canvas.drawRRect(
      RRect.fromRectAndCorners(pot, bottomLeft: Radius.circular(s * 0.12), bottomRight: Radius.circular(s * 0.12)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFFE9A77A), Color(0xFFC77E52)]).createShader(pot),
    );
    canvas.drawRect(Rect.fromLTWH(pot.left - 2, pot.top, pot.width + 4, s * 0.08), Paint()..color = const Color(0xFFD48C5E));
    const leaves = [
      (-0.5, 1.05, Color(0xFF4F8F48)),
      (0.45, 1.0, Color(0xFF5DA153)),
      (-0.15, 1.3, Color(0xFF3F7D3B)),
      (0.2, 1.2, Color(0xFF6AAE5E)),
      (-0.85, 0.8, Color(0xFF5DA153)),
      (0.8, 0.75, Color(0xFF4F8F48)),
    ];
    for (final (angle, len, color) in leaves) {
      canvas.save();
      canvas.translate(base.dx, pot.top);
      canvas.rotate(angle);
      canvas.drawLine(
        Offset.zero,
        Offset(0, -s * len * 0.6),
        Paint()
          ..color = const Color(0xFF3F7D3B)
          ..strokeWidth = 2,
      );
      final leaf = Rect.fromCenter(center: Offset(0, -s * len * 0.75), width: s * 0.55, height: s * 0.5);
      canvas.drawOval(leaf, Paint()..color = color);
      canvas.drawLine(
        leaf.center.translate(0, leaf.height * 0.4),
        leaf.center.translate(0, -leaf.height * 0.45),
        Paint()
          ..color = _dark(color, 0.25)
          ..strokeWidth = 1.5,
      );
      canvas.restore();
    }
  }

  void _pendant(Canvas canvas, RoomGeometry g) {
    final top = Offset(g.w * 0.5, 0);
    final lampY = g.back.top + g.back.height * 0.08;
    canvas.drawLine(
      top,
      Offset(top.dx, lampY),
      Paint()
        ..color = const Color(0xFF6B5A4A)
        ..strokeWidth = 1.5,
    );
    final w = g.w * 0.14;
    final shade = Path()
      ..moveTo(top.dx - w * 0.2, lampY)
      ..lineTo(top.dx + w * 0.2, lampY)
      ..lineTo(top.dx + w * 0.5, lampY + w * 0.42)
      ..lineTo(top.dx - w * 0.5, lampY + w * 0.42)
      ..close();
    canvas.drawPath(shade, Paint()..shader = const LinearGradient(colors: [Color(0xFFF7D9A8), Color(0xFFE9B874)]).createShader(shade.getBounds()));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(top.dx, lampY + w * 0.42), width: w, height: w * 0.14),
      Paint()..color = night ? const Color(0xFFFFF1C0) : const Color(0xFFF8E6C4),
    );
  }

  void _pendantGlow(Canvas canvas, RoomGeometry g) {
    final c = Offset(g.w * 0.5, g.back.top + g.back.height * 0.08 + g.w * 0.07);
    canvas.drawCircle(
      c,
      g.w * 0.3,
      Paint()..shader = const RadialGradient(colors: [Color(0x55FFE3A0), Color(0x00FFE3A0)]).createShader(Rect.fromCircle(center: c, radius: g.w * 0.3)),
    );
  }

  // ---------- Покупки и цели ----------

  void _rug(Canvas canvas, RoomGeometry g, Color outer, Color inner) {
    final c = g.heroFeet.translate(0, -g.h * 0.01);
    final rect = Rect.fromCenter(center: c, width: g.w * 0.84, height: g.h * 0.15);
    canvas.drawOval(
      rect.translate(0, 4),
      Paint()
        ..color = const Color(0x2A000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawOval(rect, Paint()..color = outer);
    canvas.drawOval(rect.deflate(g.w * 0.025), Paint()..color = inner);
    canvas.drawOval(
      rect.deflate(g.w * 0.07),
      Paint()
        ..color = outer.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final dot = Paint()..color = outer.withValues(alpha: 0.7);
    final ring = rect.deflate(g.w * 0.045);
    for (var i = 0; i < 18; i++) {
      final a = i * 2 * pi / 18;
      canvas.drawCircle(Offset(ring.center.dx + cos(a) * ring.width / 2, ring.center.dy + sin(a) * ring.height / 2), 2.2, dot);
    }
    canvas.drawArc(
      rect,
      pi * 1.1,
      pi * 0.8,
      false,
      Paint()
        ..color = _light(outer, 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _shadow(Canvas canvas, Rect r) {
    canvas.drawOval(
      r,
      Paint()
        ..color = const Color(0x38000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  void _lamp(Canvas canvas, RoomGeometry g) {
    final base = g.floor(0.32, 0.12);
    final s = g.w * 0.1;
    _shadow(canvas, Rect.fromCenter(center: base, width: s * 1.6, height: s * 0.35));
    final glow = base.translate(0, -s * 1.1);
    canvas.drawCircle(
      glow,
      s * 1.8,
      Paint()..shader = const RadialGradient(colors: [Color(0x44FFE8A0), Color(0x00FFE8A0)]).createShader(Rect.fromCircle(center: glow, radius: s * 1.8)),
    );
    final stem = Rect.fromCenter(center: base.translate(0, -s * 0.42), width: s * 0.34, height: s * 0.85);
    canvas.drawRRect(
      RRect.fromRectAndRadius(stem, Radius.circular(s * 0.1)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFFFFF6E6), Color(0xFFE9D8BD)]).createShader(stem),
    );
    final cap = Rect.fromCenter(center: base.translate(0, -s * 1.0), width: s * 1.4, height: s * 1.1);
    canvas.drawArc(cap, pi, pi, true, Paint()..shader = const RadialGradient(center: Alignment(0, 0.6), colors: [Color(0xFFFFFBE6), Color(0xFFF6D98E)]).createShader(cap));
    for (final (dx, dy) in [(-0.3, -0.25), (0.25, -0.3), (0.0, -0.4)]) {
      canvas.drawCircle(cap.center.translate(s * dx, s * dy), s * 0.07, Paint()..color = const Color(0x99FFFFFF));
    }
  }

  void _lampGlow(Canvas canvas, RoomGeometry g) {
    final base = g.floor(0.32, 0.12);
    final s = g.w * 0.1;
    final c = base.translate(0, -s * 1.0);
    canvas.drawCircle(
      c,
      s * 3.2,
      Paint()..shader = const RadialGradient(colors: [Color(0x88FFE3A0), Color(0x00FFE3A0)]).createShader(Rect.fromCircle(center: c, radius: s * 3.2)),
    );
    canvas.drawArc(Rect.fromCenter(center: c, width: s * 1.4, height: s * 1.1), pi, pi, true, Paint()..color = const Color(0xFFFFF3C4));
  }

  void _sofa(Canvas canvas, RoomGeometry g) {
    final left = g.floor(0.46, 0.04);
    final right = g.floor(0.98, 0.04);
    final w = right.dx - left.dx;
    final seatY = left.dy - w * 0.2;
    const fabric = Color(0xFFF0E1CC);
    _shadow(canvas, Rect.fromLTRB(left.dx - 4, left.dy - 8, right.dx + 4, left.dy + 10));
    final backRect = Rect.fromLTRB(left.dx + w * 0.05, seatY - w * 0.24, right.dx - w * 0.05, seatY + w * 0.02);
    canvas.drawRRect(
      RRect.fromRectAndRadius(backRect, Radius.circular(w * 0.07)),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_light(fabric, 0.3), _dark(fabric, 0.12)]).createShader(backRect),
    );
    final seatTop = Rect.fromLTRB(left.dx + w * 0.06, seatY - w * 0.02, right.dx - w * 0.06, seatY + w * 0.08);
    canvas.drawRRect(RRect.fromRectAndRadius(seatTop, Radius.circular(w * 0.04)), Paint()..color = _light(fabric, 0.2));
    final front = Rect.fromLTRB(left.dx + w * 0.04, seatY + w * 0.06, right.dx - w * 0.04, left.dy - w * 0.03);
    canvas.drawRRect(
      RRect.fromRectAndRadius(front, Radius.circular(w * 0.04)),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [fabric, _dark(fabric, 0.15)]).createShader(front),
    );
    canvas.drawLine(
      Offset(seatTop.center.dx, seatTop.top + 2),
      Offset(seatTop.center.dx, front.bottom - 3),
      Paint()
        ..color = _dark(fabric, 0.18)
        ..strokeWidth = 1.2,
    );
    for (final x in [left.dx, right.dx - w * 0.13]) {
      final arm = Rect.fromLTWH(x, seatY - w * 0.08, w * 0.13, left.dy - seatY + w * 0.05);
      canvas.drawRRect(
        RRect.fromRectAndRadius(arm, Radius.circular(w * 0.06)),
        Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_light(fabric, 0.15), _dark(fabric, 0.1)]).createShader(arm),
      );
    }
    for (final (i, color) in [(0, const Color(0xFFE59AA3)), (1, const Color(0xFF9DB6E0)), (2, const Color(0xFFF1CC66))]) {
      final cx = left.dx + w * (0.28 + i * 0.22);
      final pillow = Rect.fromCenter(center: Offset.zero, width: w * 0.17, height: w * 0.15);
      canvas.save();
      canvas.translate(cx, seatY - w * 0.06);
      canvas.rotate((i - 1) * 0.12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(pillow, Radius.circular(w * 0.05)),
        Paint()..shader = RadialGradient(center: const Alignment(-0.3, -0.3), colors: [_light(color, 0.25), color]).createShader(pillow),
      );
      canvas.restore();
    }
    final throwRect = Rect.fromLTRB(right.dx - w * 0.32, seatY - w * 0.02, right.dx - w * 0.1, left.dy - w * 0.02);
    canvas.drawRRect(RRect.fromRectAndRadius(throwRect, Radius.circular(w * 0.03)), Paint()..color = const Color(0xFFB8A2D6));
    for (var i = 1; i < 4; i++) {
      final x = throwRect.left + throwRect.width * i / 4;
      canvas.drawLine(
        Offset(x, throwRect.top + 2),
        Offset(x, throwRect.bottom - 2),
        Paint()
          ..color = const Color(0x33FFFFFF)
          ..strokeWidth = 2,
      );
    }
    final leg = Paint()..color = const Color(0xFF8A5A3B);
    for (final x in [left.dx + w * 0.08, right.dx - w * 0.1]) {
      canvas.drawRect(Rect.fromLTWH(x, left.dy - w * 0.035, w * 0.025, w * 0.035), leg);
    }
  }

  void _bookshelf(Canvas canvas, RoomGeometry g) {
    final frontL = g.floor(0.66, 0.06);
    final frontR = g.floor(0.95, 0.06);
    final w = frontR.dx - frontL.dx;
    final hgt = w * 1.9;
    final top = frontL.dy - hgt;
    _shadow(canvas, Rect.fromLTRB(frontL.dx - 4, frontL.dy - 8, frontR.dx + 10, frontL.dy + 8));
    const wood = Color(0xFFC08A5A);
    _poly(canvas, [Offset(frontR.dx, top), Offset(frontR.dx + w * 0.16, top - w * 0.1), Offset(frontR.dx + w * 0.16, frontR.dy - w * 0.1), frontR], _dark(wood, 0.25));
    _poly(canvas, [Offset(frontL.dx, top), Offset(frontL.dx + w * 0.16, top - w * 0.1), Offset(frontR.dx + w * 0.16, top - w * 0.1), Offset(frontR.dx, top)], _light(wood, 0.2));
    final body = Rect.fromLTRB(frontL.dx, top, frontR.dx, frontL.dy);
    canvas.drawRect(body, Paint()..shader = LinearGradient(colors: [_light(wood, 0.08), _dark(wood, 0.08)]).createShader(body));
    final inner = Paint()..color = _dark(wood, 0.35);
    const books = [Color(0xFFE07A5F), Color(0xFF5C84E0), Color(0xFFF2CF6B), Color(0xFF3FA58F), Color(0xFFE0668F), Color(0xFF9B7ED6)];
    for (var r = 0; r < 4; r++) {
      final y0 = top + hgt * (0.04 + r * 0.24);
      final cell = Rect.fromLTRB(frontL.dx + w * 0.07, y0, frontR.dx - w * 0.07, y0 + hgt * 0.2);
      canvas.drawRect(cell, inner);
      canvas.drawRect(Rect.fromLTRB(cell.left, cell.top, cell.right, cell.top + cell.height * 0.25), Paint()..color = const Color(0x33000000));
      var x = cell.left + 2;
      var i = r * 2;
      while (x < cell.right - w * 0.1) {
        final bw = w * (0.07 + (i % 3) * 0.02);
        final bh = cell.height * (0.68 + (i % 3) * 0.1);
        final book = Rect.fromLTWH(x, cell.bottom - bh, bw, bh);
        canvas.drawRect(book, Paint()..color = books[i % books.length]);
        canvas.drawRect(Rect.fromLTWH(book.left, book.top + bh * 0.2, bw, 2), Paint()..color = const Color(0x55FFFFFF));
        x += bw + 1.5;
        i++;
      }
      if (r == 1) {
        // Мишка на полке.
        final c = Offset(cell.right - w * 0.12, cell.bottom - w * 0.08);
        final bear = Paint()..color = const Color(0xFFC08A5A);
        canvas.drawCircle(c, w * 0.08, bear);
        canvas.drawCircle(c.translate(-w * 0.06, -w * 0.06), w * 0.03, bear);
        canvas.drawCircle(c.translate(w * 0.06, -w * 0.06), w * 0.03, bear);
      }
    }
  }

  void _tv(Canvas canvas, RoomGeometry g) {
    final l = g.floor(0.5, 0.04);
    final r = g.floor(0.96, 0.04);
    final w = r.dx - l.dx;
    final standTop = l.dy - w * 0.2;
    _shadow(canvas, Rect.fromLTRB(l.dx - 4, l.dy - 8, r.dx + 4, l.dy + 8));
    final stand = Rect.fromLTRB(l.dx, standTop, r.dx, l.dy);
    canvas.drawRRect(
      RRect.fromRectAndRadius(stand, const Radius.circular(4)),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFC99467), Color(0xFFA87448)]).createShader(stand),
    );
    canvas.drawRect(Rect.fromLTRB(l.dx, standTop, r.dx, standTop + 3), Paint()..color = const Color(0xFFDDAE82));
    for (final (a, b2) in [(0.05, 0.47), (0.53, 0.95)]) {
      final door = Rect.fromLTRB(l.dx + w * a, standTop + w * 0.05, l.dx + w * b2, l.dy - w * 0.03);
      canvas.drawRRect(RRect.fromRectAndRadius(door, const Radius.circular(2)), Paint()..color = const Color(0xFFB27D51));
      canvas.drawCircle(Offset(b2 < 0.5 ? door.right - 5 : door.left + 5, door.center.dy), 2, Paint()..color = const Color(0xFF6B4A33));
    }
    final screen = Rect.fromLTRB(l.dx + w * 0.07, standTop - w * 0.5, r.dx - w * 0.07, standTop - w * 0.05);
    canvas.drawRRect(RRect.fromRectAndRadius(screen.inflate(4), const Radius.circular(6)), Paint()..color = const Color(0xFF1E2127));
    canvas.drawRect(
      screen,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: night ? const [Color(0xFF4C6FFF), Color(0xFF9B5CFF)] : const [Color(0xFF3A4150), Color(0xFF1C1F26)],
        ).createShader(screen),
    );
    _poly(canvas, [screen.topLeft, screen.topLeft.translate(screen.width * 0.35, 0), screen.bottomLeft.translate(screen.width * 0.12, 0), screen.bottomLeft], const Color(0x14FFFFFF));
    canvas.drawRect(Rect.fromCenter(center: Offset(screen.center.dx, standTop - w * 0.025), width: w * 0.12, height: w * 0.05), Paint()..color = const Color(0xFF1E2127));
    if (night) {
      canvas.drawRect(
        screen.inflate(w * 0.2),
        Paint()
          ..color = const Color(0x224C6FFF)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.1),
      );
    }
  }

  void _console(Canvas canvas, RoomGeometry g) {
    final c = g.floor(0.22, 0.5);
    final s = g.w * 0.14;
    _shadow(canvas, Rect.fromCenter(center: c.translate(0, s * 0.28), width: s * 1.8, height: s * 0.36));
    final body = Rect.fromCenter(center: c, width: s * 1.4, height: s * 0.45);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(s * 0.1)),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFFFF), Color(0xFFDCDDE3)]).createShader(body),
    );
    canvas.drawRect(Rect.fromCenter(center: c.translate(0, s * 0.02), width: s * 1.3, height: s * 0.05), Paint()..color = const Color(0xFF26282E));
    canvas.drawCircle(body.topRight.translate(-s * 0.15, s * 0.12), s * 0.035, Paint()..color = const Color(0xFF5DB6A6));
    final pad = c.translate(s * 1.2, s * 0.35);
    final padRect = Rect.fromCenter(center: pad, width: s * 0.8, height: s * 0.36);
    canvas.drawRRect(
      RRect.fromRectAndRadius(padRect, Radius.circular(s * 0.18)),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4A4E58), Color(0xFF2E3138)]).createShader(padRect),
    );
    canvas.drawCircle(pad.translate(s * 0.2, -s * 0.03), s * 0.045, Paint()..color = const Color(0xFFE0668F));
    canvas.drawCircle(pad.translate(s * 0.28, s * 0.04), s * 0.045, Paint()..color = const Color(0xFF5DB6A6));
    final cross = Paint()..color = const Color(0xFF9097A6);
    canvas.drawRect(Rect.fromCenter(center: pad.translate(-s * 0.22, 0), width: s * 0.16, height: s * 0.05), cross);
    canvas.drawRect(Rect.fromCenter(center: pad.translate(-s * 0.22, 0), width: s * 0.05, height: s * 0.16), cross);
  }

  void _playroom(Canvas canvas, RoomGeometry g) {
    final b = g.back;
    // Гирлянда флажков.
    const flags = [Color(0xFFE0668F), Color(0xFFF2CF6B), Color(0xFF5DB6A6), Color(0xFF8FA8E8)];
    final string = Path()
      ..moveTo(b.left, b.top + b.height * 0.1)
      ..quadraticBezierTo(b.center.dx, b.top + b.height * 0.24, b.right, b.top + b.height * 0.1);
    canvas.drawPath(
      string,
      Paint()
        ..color = const Color(0xFF8A7563)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    for (var i = 0; i < 9; i++) {
      final t = (i + 0.5) / 9;
      final x = b.left + b.width * t;
      final y = b.top + b.height * (0.1 + 0.56 * t * (1 - t));
      _poly(canvas, [Offset(x - b.width * 0.035, y), Offset(x + b.width * 0.035, y), Offset(x, y + b.height * 0.09)], flags[i % flags.length]);
    }
    // Облака на стене.
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (final (x, y) in [(0.2, 0.42), (0.72, 0.36)]) {
      final c = Offset(b.left + b.width * x, b.top + b.height * y);
      for (final (dx, r) in [(0.0, 0.05), (0.05, 0.065), (0.1, 0.045)]) {
        canvas.drawCircle(c.translate(b.width * dx, 0), b.width * r, cloud);
      }
    }
    _rug(canvas, g, const Color(0xFF6FB8F0), const Color(0xFFB9E2FF));
    // Кубики.
    const cubes = [Color(0xFFE0668F), Color(0xFFF2CF6B), Color(0xFF5DB6A6)];
    for (var i = 0; i < 3; i++) {
      final p = g.floor(0.06 + i * 0.08, 0.2);
      final s = g.w * 0.07;
      final lift = i == 1 ? s : 0.0;
      final r = Rect.fromCenter(center: p.translate(i == 1 ? -s * 0.4 : 0, -s / 2 - lift), width: s, height: s);
      _shadow(canvas, Rect.fromCenter(center: p, width: s * 1.2, height: s * 0.3));
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), Paint()..color = cubes[i]);
      _poly(canvas, [r.topLeft, r.topRight, r.topRight.translate(s * 0.15, -s * 0.12), r.topLeft.translate(s * 0.15, -s * 0.12)], _light(cubes[i], 0.35));
      canvas.drawRRect(RRect.fromRectAndRadius(r.deflate(s * 0.22), const Radius.circular(2)), Paint()..color = _light(cubes[i], 0.45));
    }
    // Воздушные шары.
    for (final (x, y, color) in [(0.84, 0.3, const Color(0xFFE0668F)), (0.92, 0.22, const Color(0xFF8FA8E8)), (0.76, 0.24, const Color(0xFFF2CF6B))]) {
      final c = Offset(g.w * x, g.h * y);
      final rect = Rect.fromCenter(center: c, width: g.w * 0.11, height: g.w * 0.14);
      canvas.drawLine(c.translate(0, g.w * 0.07), c.translate(-g.w * 0.03, g.h * 0.2), Paint()..color = const Color(0x66000000));
      canvas.drawOval(rect, Paint()..shader = RadialGradient(center: const Alignment(-0.4, -0.4), colors: [_light(color, 0.45), color]).createShader(rect));
    }
  }

  void _vignette(Canvas canvas, RoomGeometry g) {
    canvas.drawRect(
      Offset.zero & g.size,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.1),
          radius: 0.95,
          colors: [Color(0x00000000), Color(0x2A000000)],
          stops: [0.6, 1],
        ).createShader(Offset.zero & g.size),
    );
  }

  void _night(Canvas canvas, RoomGeometry g) {
    canvas.drawRect(
      Offset.zero & g.size,
      Paint()
        ..color = const Color(0xFF8A93D8)
        ..blendMode = BlendMode.multiply,
    );
    canvas.drawRect(Offset.zero & g.size, Paint()..color = const Color(0x22101840));
  }

  // ---------- Примитивы ----------

  Path _path(List<Offset> pts) => Path()..addPolygon(pts, true);

  void _poly(Canvas canvas, List<Offset> pts, Color color) => canvas.drawPath(_path(pts), Paint()..color = color);

  @override
  bool shouldRepaint(RoomPainter old) =>
      old.owned.length != owned.length ||
      !old.owned.containsAll(owned) ||
      old.furniture != furniture ||
      old.room != room ||
      old.night != night ||
      old.feetY != feetY;
}
