import 'dart:math';

import 'package:flutter/rendering.dart';

/// Перспективная комната (SA F-017 §4.3): точка схода по центру, задняя стена — уменьшенный экран.
final class RoomGeometry {
  RoomGeometry(this.size)
    : back = Rect.fromLTRB(size.width * 0.12, size.height * 0.09, size.width * 0.88, size.height * 0.6),
      v = Offset(size.width * 0.5, size.height * 0.09 / (1 - 0.76));

  final Size size;

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

  /// Где стоят «ноги» героя: центр коврика.
  Offset get heroFeet => Offset(w * 0.5, h * 0.84);
}

Offset heroAnchor(Size size) => RoomGeometry(size).heroFeet;

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

final class RoomPainter extends CustomPainter {
  RoomPainter({required this.owned, this.furniture, this.room = 1, this.night = false});

  /// Купленные постоянные вещи: lamp, rug, poster.
  final Set<String> owned;

  /// Крупная мебель из цели: sofa|shelf|tv|console.
  final String? furniture;

  /// 1 — спальня, 2 — игровая.
  final int room;
  final bool night;

  bool get _play => room == 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final g = RoomGeometry(size);
    _shell(canvas, g);
    if (_play) {
      _playroom(canvas, g);
    } else {
      _window(canvas, g);
      _shelves(canvas, g);
      if (owned.contains('poster')) _poster(canvas, g);
      _lightOnFloor(canvas, g);
      if (owned.contains('rug')) _rug(canvas, g, const Color(0xFFE39A9A), const Color(0xFFF3C1BC));
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
      if (owned.contains('lamp')) _lamp(canvas, g);
    }
    _vignette(canvas, g);
    if (night) {
      _night(canvas, g);
      if (!_play && owned.contains('lamp')) _lamp(canvas, g);
    }
  }

  // ---------- Коробка комнаты ----------

  void _shell(Canvas canvas, RoomGeometry g) {
    final wallBase = _play ? const Color(0xFFBFE6DA) : const Color(0xFFF2BFA1);
    final b = g.back;

    // Потолок.
    _poly(canvas, [Offset.zero, Offset(g.w, 0), b.topRight, b.topLeft], _mix(wallBase, const Color(0xFFFFFFFF), 0.35));

    // Боковые стены (левая чуть темнее: окно на ней, свет идёт от неё).
    final leftPath = _path([Offset.zero, b.topLeft, b.bottomLeft, Offset(0, g.floorEdgeY)]);
    canvas.drawPath(
      leftPath,
      Paint()
        ..shader = LinearGradient(
          colors: [_mix(wallBase, const Color(0xFF000000), 0.12), _mix(wallBase, const Color(0xFF000000), 0.04)],
        ).createShader(Rect.fromLTRB(0, 0, b.left, g.h)),
    );
    final rightPath = _path([Offset(g.w, 0), b.topRight, b.bottomRight, Offset(g.w, g.floorEdgeY)]);
    canvas.drawPath(
      rightPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [_mix(wallBase, const Color(0xFF000000), 0.08), _mix(wallBase, const Color(0xFF000000), 0.02)],
        ).createShader(Rect.fromLTRB(b.right, 0, g.w, g.h)),
    );

    // Задняя стена с мягким светом из окна.
    canvas.drawRect(
      b,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.7, -0.2),
          radius: 1.3,
          colors: [_mix(wallBase, const Color(0xFFFFFFFF), 0.25), wallBase],
        ).createShader(b),
    );

    // Пол из досок.
    final floorPoly = [b.bottomLeft, b.bottomRight, Offset(g.w, g.floorEdgeY), Offset(g.w, g.h), Offset(0, g.h), Offset(0, g.floorEdgeY)];
    final wood = _play ? const Color(0xFFD8B98F) : const Color(0xFFD9A873);
    canvas.drawPath(
      _path(floorPoly),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_mix(wood, const Color(0xFF000000), 0.12), wood, _mix(wood, const Color(0xFFFFFFFF), 0.08)],
          stops: const [0, 0.5, 1],
        ).createShader(Rect.fromLTRB(0, b.bottom, g.w, g.h)),
    );
    canvas.save();
    canvas.clipPath(_path(floorPoly));
    final seam = Paint()
      ..color = const Color(0x2A5A3413)
      ..strokeWidth = 1.2;
    for (var i = -6; i <= 16; i++) {
      final x = i / 10;
      canvas.drawLine(g.floor(x, 0), g.floor(x, 1.2), seam);
    }
    // Поперечные стыки досок — чаще у задней стены.
    var depth = 0.04;
    var row = 0;
    while (depth < 1.05) {
      final y = g.back.bottom + (g.h - g.back.bottom) * depth;
      for (var i = -6; i <= 16; i += 2) {
        final x = (i + (row.isOdd ? 1 : 0)) / 10;
        final p = g.floor(x, depth);
        final q = g.floor(x + 0.1, depth);
        canvas.drawLine(Offset(p.dx, y), Offset(q.dx, y), seam);
      }
      depth = depth * 1.55 + 0.03;
      row++;
    }
    canvas.restore();

    // Плинтусы.
    final skirting = Paint()..color = _mix(wallBase, const Color(0xFFFFFFFF), 0.55);
    canvas.drawRect(Rect.fromLTRB(b.left, b.bottom - g.h * 0.012, b.right, b.bottom), skirting);
    _poly(canvas, [b.bottomLeft.translate(0, -g.h * 0.012), b.bottomLeft, Offset(0, g.floorEdgeY), Offset(0, g.floorEdgeY - g.h * 0.03)], skirting.color);
    _poly(canvas, [b.bottomRight.translate(0, -g.h * 0.012), b.bottomRight, Offset(g.w, g.floorEdgeY), Offset(g.w, g.floorEdgeY - g.h * 0.03)], skirting.color);

    // Углы комнаты — тонкие тени.
    final corner = Paint()
      ..color = const Color(0x1A000000)
      ..strokeWidth = 2;
    canvas.drawLine(b.topLeft, b.bottomLeft, corner);
    canvas.drawLine(b.topRight, b.bottomRight, corner);
  }

  void _window(Canvas canvas, RoomGeometry g) {
    final b = g.back;
    final frame = Rect.fromLTRB(b.left + b.width * 0.07, b.top + b.height * 0.12, b.left + b.width * 0.4, b.top + b.height * 0.66);
    canvas.drawRRect(RRect.fromRectAndRadius(frame.inflate(5), const Radius.circular(6)), Paint()..color = const Color(0x22000000));
    canvas.drawRRect(RRect.fromRectAndRadius(frame, const Radius.circular(4)), Paint()..color = const Color(0xFFFFFBF4));
    final glass = frame.deflate(frame.width * 0.07);
    canvas.drawRect(
      glass,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: night ? const [Color(0xFF141B4D), Color(0xFF34397F)] : const [Color(0xFF8FCDF3), Color(0xFFDDF2FF)],
        ).createShader(glass),
    );
    canvas.save();
    canvas.clipRect(glass);
    if (night) {
      canvas.drawCircle(glass.topRight.translate(-glass.width * 0.3, glass.height * 0.25), glass.width * 0.14, Paint()..color = const Color(0xFFFFF4B8));
      final star = Paint()..color = const Color(0xCCFFFFFF);
      for (final (x, y) in [(0.2, 0.15), (0.4, 0.4), (0.15, 0.55), (0.7, 0.6)]) {
        canvas.drawCircle(Offset(glass.left + glass.width * x, glass.top + glass.height * y), 1.6, star);
      }
    } else {
      canvas.drawCircle(glass.topRight.translate(-glass.width * 0.28, glass.height * 0.2), glass.width * 0.12, Paint()..color = const Color(0xFFFFE17A));
      canvas.drawCircle(Offset(glass.left + glass.width * 0.25, glass.bottom + glass.height * 0.05), glass.width * 0.45, Paint()..color = const Color(0xFF8CC47A));
      canvas.drawCircle(Offset(glass.right, glass.bottom), glass.width * 0.4, Paint()..color = const Color(0xFF79B368));
      final cloud = Paint()..color = const Color(0xEEFFFFFF);
      final c = Offset(glass.left + glass.width * 0.4, glass.top + glass.height * 0.3);
      canvas.drawCircle(c, glass.width * 0.1, cloud);
      canvas.drawCircle(c.translate(glass.width * 0.12, -glass.width * 0.04), glass.width * 0.12, cloud);
      canvas.drawCircle(c.translate(glass.width * 0.25, 0), glass.width * 0.09, cloud);
    }
    canvas.restore();
    final bar = Paint()
      ..color = const Color(0xFFFFFBF4)
      ..strokeWidth = frame.width * 0.04;
    canvas.drawLine(Offset(glass.center.dx, glass.top), Offset(glass.center.dx, glass.bottom), bar);
    canvas.drawLine(Offset(glass.left, glass.center.dy), Offset(glass.right, glass.center.dy), bar);
    // Подоконник.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(frame.left - 8, frame.bottom - 2, frame.right + 8, frame.bottom + 8), const Radius.circular(3)),
      Paint()..color = const Color(0xFFF7EEE2),
    );
    // Шторы со складками.
    for (final left in [true, false]) {
      final x0 = left ? frame.left - frame.width * 0.22 : frame.right - frame.width * 0.02;
      final r = Rect.fromLTWH(x0, frame.top - frame.height * 0.1, frame.width * 0.24, frame.height * 1.3);
      canvas.drawRRect(
        RRect.fromRectAndCorners(r, bottomLeft: const Radius.circular(10), bottomRight: const Radius.circular(10)),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFF7ECDD), Color(0xFFE8D5BE), Color(0xFFF7ECDD), Color(0xFFE2CDB4), Color(0xFFF4E8D8)],
          ).createShader(r),
      );
    }
    final rod = Paint()
      ..color = const Color(0xFFB08A63)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(frame.left - frame.width * 0.28, frame.top - frame.height * 0.1), Offset(frame.right + frame.width * 0.28, frame.top - frame.height * 0.1), rod);
  }

  void _lightOnFloor(Canvas canvas, RoomGeometry g) {
    if (night) return;
    final a = g.floor(0.07, 0.0);
    final b = g.floor(0.4, 0.0);
    final c = g.floor(0.75, 0.6);
    final d = g.floor(0.2, 0.7);
    final path = _path([a, b, c, d]);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x55FFF6DD)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
  }

  void _shelves(Canvas canvas, RoomGeometry g) {
    final b = g.back;
    final wood = const Color(0xFFD4A97A);
    for (final (x0, x1, y) in [(0.66, 0.95, 0.24), (0.6, 0.88, 0.42)]) {
      final top = b.top + b.height * y;
      final rect = Rect.fromLTRB(b.left + b.width * x0, top, b.left + b.width * x1, top + b.height * 0.025);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), Paint()..color = wood);
      canvas.drawRect(
        Rect.fromLTRB(rect.left + 4, rect.bottom, rect.right - 4, rect.bottom + b.height * 0.03),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x33000000), Color(0x00000000)],
          ).createShader(Rect.fromLTRB(rect.left, rect.bottom, rect.right, rect.bottom + b.height * 0.03)),
      );
    }
    // Растение на верхней полке.
    final shelfTop = b.top + b.height * 0.24;
    final potX = b.left + b.width * 0.86;
    final pot = Rect.fromCenter(center: Offset(potX, shelfTop - b.height * 0.035), width: b.width * 0.07, height: b.height * 0.07);
    canvas.drawRRect(RRect.fromRectAndRadius(pot, const Radius.circular(4)), Paint()..color = const Color(0xFFF5EFE6));
    final leaf = Paint()..color = const Color(0xFF6BA35A);
    for (var i = -2; i <= 2; i++) {
      canvas.save();
      canvas.translate(potX, pot.top);
      canvas.rotate(i * 0.45);
      canvas.drawOval(Rect.fromCenter(center: Offset(0, -b.height * 0.05), width: b.width * 0.035, height: b.height * 0.1), leaf);
      canvas.restore();
    }
  }

  void _poster(Canvas canvas, RoomGeometry g) {
    final b = g.back;
    final r = Rect.fromLTWH(b.left + b.width * 0.46, b.top + b.height * 0.18, b.width * 0.13, b.height * 0.2);
    canvas.drawRRect(RRect.fromRectAndRadius(r.inflate(4), const Radius.circular(4)), Paint()..color = const Color(0xFF9C6B43));
    canvas.drawRect(r, Paint()..color = const Color(0xFFFFF3D6));
    final c = r.center;
    final rad = r.width * 0.32;
    canvas.drawCircle(c, rad, Paint()..color = const Color(0xFFFFCC33));
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
  }

  void _rug(Canvas canvas, RoomGeometry g, Color outer, Color inner) {
    final c = Offset(g.w * 0.5, g.h * 0.83);
    final rect = Rect.fromCenter(center: c, width: g.w * 0.86, height: g.h * 0.16);
    canvas.drawOval(rect.translate(0, 3), Paint()..color = const Color(0x22000000));
    canvas.drawOval(rect, Paint()..color = outer);
    canvas.drawOval(rect.deflate(g.w * 0.03), Paint()..color = inner);
    canvas.drawOval(
      rect.deflate(g.w * 0.08),
      Paint()
        ..color = outer.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _shadow(Canvas canvas, Rect r) {
    canvas.drawOval(
      r,
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  void _lamp(Canvas canvas, RoomGeometry g) {
    final base = g.floor(0.2, 0.3);
    final s = g.w * 0.1;
    _shadow(canvas, Rect.fromCenter(center: base, width: s * 1.6, height: s * 0.4));
    canvas.drawCircle(
      base.translate(0, -s * 1.2),
      s * (night ? 3.2 : 2),
      Paint()
        ..color = const Color(0xFFFFE8A0).withValues(alpha: night ? 0.45 : 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: base.translate(0, -s * 0.45), width: s * 0.35, height: s * 0.9), Radius.circular(s * 0.1)),
      Paint()..color = const Color(0xFFF7EAD2),
    );
    final cap = Rect.fromCenter(center: base.translate(0, -s * 1.05), width: s * 1.4, height: s * 1.1);
    canvas.drawArc(
      cap,
      pi,
      pi,
      true,
      Paint()
        ..shader = const RadialGradient(colors: [Color(0xFFFFF6D8), Color(0xFFF6D98E)]).createShader(cap),
    );
  }

  void _sofa(Canvas canvas, RoomGeometry g) {
    final left = g.floor(0.42, 0.03);
    final right = g.floor(0.98, 0.03);
    final w = right.dx - left.dx;
    final seatTop = left.dy - w * 0.28;
    const fabric = Color(0xFFF1E4D2);
    final dark = _mix(fabric, const Color(0xFF000000), 0.12);
    _shadow(canvas, Rect.fromLTRB(left.dx, left.dy - 6, right.dx, left.dy + 10));
    // Спинка.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(left.dx + w * 0.06, seatTop - w * 0.2, right.dx - w * 0.06, seatTop + w * 0.05), Radius.circular(w * 0.06)),
      Paint()..color = dark,
    );
    // Сиденье.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(left.dx + w * 0.04, seatTop, right.dx - w * 0.04, left.dy - w * 0.04), Radius.circular(w * 0.05)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fabric, dark],
        ).createShader(Rect.fromLTRB(left.dx, seatTop, right.dx, left.dy)),
    );
    // Подлокотники.
    for (final x in [left.dx, right.dx - w * 0.12]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, seatTop - w * 0.08, w * 0.12, w * 0.3), Radius.circular(w * 0.05)),
        Paint()..color = _mix(fabric, const Color(0xFF000000), 0.06),
      );
    }
    // Подушки.
    for (final (i, color) in [(0, const Color(0xFFE8A0A8)), (1, const Color(0xFF9FB8E0)), (2, const Color(0xFFF2CF6B))]) {
      final cx = left.dx + w * (0.3 + i * 0.2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, seatTop - w * 0.03), width: w * 0.16, height: w * 0.14), Radius.circular(w * 0.04)),
        Paint()..color = color,
      );
    }
    // Ножки.
    final leg = Paint()..color = const Color(0xFF8A5A3B);
    for (final x in [left.dx + w * 0.08, right.dx - w * 0.1]) {
      canvas.drawRect(Rect.fromLTWH(x, left.dy - w * 0.04, w * 0.03, w * 0.04), leg);
    }
  }

  void _bookshelf(Canvas canvas, RoomGeometry g) {
    // Стоит у правой стены, у самого угла: лицевая грань + боковая.
    final frontL = g.floor(0.68, 0.05);
    final frontR = g.floor(0.95, 0.05);
    final w = frontR.dx - frontL.dx;
    final hgt = w * 1.8;
    final top = frontL.dy - hgt;
    _shadow(canvas, Rect.fromLTRB(frontL.dx, frontL.dy - 6, frontR.dx + 8, frontL.dy + 8));
    const wood = Color(0xFFC08A5A);
    // Боковая грань к правой стене.
    _poly(canvas, [Offset(frontR.dx, top), Offset(frontR.dx + w * 0.18, top - w * 0.1), Offset(frontR.dx + w * 0.18, frontR.dy - w * 0.1), frontR], _mix(wood, const Color(0xFF000000), 0.2));
    canvas.drawRect(Rect.fromLTRB(frontL.dx, top, frontR.dx, frontL.dy), Paint()..color = wood);
    final inner = Paint()..color = _mix(wood, const Color(0xFF000000), 0.3);
    const books = [Color(0xFFE07A5F), Color(0xFF5C84E0), Color(0xFFF2CF6B), Color(0xFF3FA58F), Color(0xFFE0668F)];
    for (var r = 0; r < 4; r++) {
      final y0 = top + hgt * (0.04 + r * 0.24);
      final y1 = y0 + hgt * 0.2;
      final cell = Rect.fromLTRB(frontL.dx + w * 0.07, y0, frontR.dx - w * 0.07, y1);
      canvas.drawRect(cell, inner);
      var x = cell.left + 2;
      var i = r;
      while (x < cell.right - w * 0.08) {
        final bw = w * (0.07 + (i % 3) * 0.02);
        final bh = cell.height * (0.7 + (i % 2) * 0.2);
        canvas.drawRect(Rect.fromLTWH(x, cell.bottom - bh, bw, bh), Paint()..color = books[i % books.length]);
        x += bw + 1.5;
        i++;
      }
    }
  }

  void _tv(Canvas canvas, RoomGeometry g) {
    final l = g.floor(0.5, 0.03);
    final r = g.floor(0.95, 0.03);
    final w = r.dx - l.dx;
    final standTop = l.dy - w * 0.22;
    _shadow(canvas, Rect.fromLTRB(l.dx, l.dy - 6, r.dx, l.dy + 8));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(l.dx, standTop, r.dx, l.dy), const Radius.circular(4)),
      Paint()..color = const Color(0xFFB98356),
    );
    canvas.drawRect(Rect.fromLTRB(l.dx + w * 0.05, standTop + w * 0.05, l.dx + w * 0.47, l.dy - w * 0.03), Paint()..color = const Color(0xFFA17047));
    canvas.drawRect(Rect.fromLTRB(l.dx + w * 0.53, standTop + w * 0.05, r.dx - w * 0.05, l.dy - w * 0.03), Paint()..color = const Color(0xFFA17047));
    final screen = Rect.fromLTRB(l.dx + w * 0.06, standTop - w * 0.5, r.dx - w * 0.06, standTop - w * 0.04);
    canvas.drawRRect(RRect.fromRectAndRadius(screen.inflate(4), const Radius.circular(6)), Paint()..color = const Color(0xFF22252B));
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
  }

  void _console(Canvas canvas, RoomGeometry g) {
    final c = g.floor(0.2, 0.62);
    final s = g.w * 0.14;
    _shadow(canvas, Rect.fromCenter(center: c.translate(0, s * 0.3), width: s * 1.8, height: s * 0.4));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: s * 1.4, height: s * 0.45), Radius.circular(s * 0.1)), Paint()..color = const Color(0xFFF4F4F6));
    canvas.drawRect(Rect.fromCenter(center: c.translate(0, s * 0.02), width: s * 1.3, height: s * 0.06), Paint()..color = const Color(0xFF26282E));
    final pad = c.translate(s * 1.2, s * 0.35);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: pad, width: s * 0.8, height: s * 0.36), Radius.circular(s * 0.18)), Paint()..color = const Color(0xFF3A3D45));
    canvas.drawCircle(pad.translate(s * 0.2, 0), s * 0.05, Paint()..color = const Color(0xFFE0668F));
    canvas.drawCircle(pad.translate(-s * 0.2, 0), s * 0.05, Paint()..color = const Color(0xFF5DB6A6));
  }

  void _playroom(Canvas canvas, RoomGeometry g) {
    final b = g.back;
    // Гирлянда флажков.
    const flags = [Color(0xFFE0668F), Color(0xFFF2CF6B), Color(0xFF5DB6A6), Color(0xFF8FA8E8)];
    for (var i = 0; i < 9; i++) {
      final x = b.left + b.width * (0.06 + i * 0.11);
      final y = b.top + b.height * 0.12 + sin(i / 8 * pi) * b.height * 0.05;
      _poly(canvas, [Offset(x, y), Offset(x + b.width * 0.08, y), Offset(x + b.width * 0.04, y + b.height * 0.1)], flags[i % flags.length]);
    }
    _rug(canvas, g, const Color(0xFF7CC6FE), const Color(0xFFB9E2FF));
    // Кубики.
    const cubes = [Color(0xFFE0668F), Color(0xFFF2CF6B), Color(0xFF5DB6A6)];
    for (var i = 0; i < 3; i++) {
      final p = g.floor(0.08 + i * 0.07, 0.25 - (i == 1 ? 0.08 : 0));
      final s = g.w * 0.06;
      final r = Rect.fromCenter(center: p.translate(0, -s / 2 - (i == 1 ? s : 0) * 0), width: s, height: s);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), Paint()..color = cubes[i]);
      canvas.drawRRect(RRect.fromRectAndRadius(r.deflate(s * 0.2), const Radius.circular(2)), Paint()..color = _mix(cubes[i], const Color(0xFFFFFFFF), 0.4));
    }
    // Воздушные шары.
    for (final (x, y, color) in [(0.82, 0.3, const Color(0xFFE0668F)), (0.9, 0.22, const Color(0xFF8FA8E8))]) {
      final c = Offset(g.w * x, g.h * y);
      canvas.drawLine(c.translate(0, g.w * 0.07), c.translate(-g.w * 0.02, g.h * 0.2), Paint()..color = const Color(0x66000000));
      canvas.drawOval(
        Rect.fromCenter(center: c, width: g.w * 0.12, height: g.w * 0.15),
        Paint()..shader = RadialGradient(center: const Alignment(-0.4, -0.4), colors: [_mix(color, const Color(0xFFFFFFFF), 0.4), color]).createShader(Rect.fromCenter(center: c, width: g.w * 0.12, height: g.w * 0.15)),
      );
    }
  }

  void _vignette(Canvas canvas, RoomGeometry g) {
    canvas.drawRect(
      Offset.zero & g.size,
      Paint()
        ..shader = const RadialGradient(
          radius: 0.95,
          colors: [Color(0x00000000), Color(0x22000000)],
          stops: [0.65, 1],
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
      old.night != night;
}
