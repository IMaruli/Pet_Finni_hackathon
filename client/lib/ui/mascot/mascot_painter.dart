import 'dart:math';

import 'package:flutter/rendering.dart';

import '../../economy/economy_state.dart';
import 'mascot_look.dart';
import 'sphere.dart';

Color _lighten(Color c, double t) => Color.lerp(c, const Color(0xFFFFFFFF), t)!;
Color _darken(Color c, double t) => Color.lerp(c, const Color(0xFF000000), t)!;

const _ink = Color(0xFF2B1D14);

/// Рисует героя-шар в 3D (SA F-007). Вся геометрия — точки на сфере.
final class MascotPainter extends CustomPainter {
  MascotPainter({
    required this.look,
    required this.pose,
    this.blink = 0,
    this.hop = 0,
    this.squash = 0,
    this.roll = 0,
  });

  final MascotLook look;
  final SpherePose pose;

  /// 0 — глаза открыты, 1 — закрыты.
  final double blink;

  /// Высота прыжка, доля размера.
  final double hop;

  /// > 0 — сплющен, < 0 — вытянут.
  final double squash;

  /// Наклон вбок, радианы.
  final double roll;

  late Offset _c;
  late double _r;

  Projected _p(double lat, double lon, {double lift = 1}) =>
      projectLatLon(lat, lon, pose, _c, _r, lift: lift);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final s = min(size.width, size.height);
    _r = s * 0.34 * look.scale;
    final ground = Offset(size.width / 2, size.height / 2 + s * 0.40);
    _c = Offset(ground.dx, ground.dy - _r - hop * s * 0.35);

    _shadow(canvas, ground, s);

    canvas.save();
    final pivot = Offset(_c.dx, _c.dy + _r);
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(roll);
    canvas.scale(1 + squash * 0.14, 1 - squash * 0.14);
    canvas.translate(-pivot.dx, -pivot.dy);

    _feet(canvas);
    _back(canvas);
    _body(canvas);
    if (look.isMonkey) _muzzle(canvas);
    _cheeks(canvas);
    _eyes(canvas);
    _brows(canvas);
    _mouth(canvas);
    _hair(canvas, front: true);
    _accessories(canvas);
    canvas.restore();
  }

  // ---------- Слои ----------

  void _shadow(Canvas canvas, Offset ground, double s) {
    final k = 1 - hop * 1.4;
    canvas.drawOval(
      Rect.fromCenter(center: ground, width: _r * 1.7 * max(0.45, k), height: _r * 0.3 * max(0.45, k)),
      Paint()
        ..color = const Color(0xFF000000).withValues(alpha: 0.16 * max(0.35, k))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, _r * 0.06),
    );
  }

  void _feet(Canvas canvas) {
    final paint = Paint()..color = _darken(look.bodyColor, 0.28);
    for (final side in [-1.0, 1.0]) {
      final p = _p(-1.05, side * 0.55 + sin(pose.yaw) * 0.1);
      canvas.drawOval(Rect.fromCenter(center: p.offset + Offset(0, _r * 0.1), width: _r * 0.46, height: _r * 0.26), paint);
    }
  }

  void _back(Canvas canvas) {
    if (look.isMonkey) {
      for (final side in [-1.0, 1.0]) {
        final p = _p(0.18, side * 1.5, lift: 1.08);
        if (p.z < -0.35) continue;
        canvas.drawCircle(p.offset, _r * 0.3, Paint()..color = _darken(look.bodyColor, 0.1));
        canvas.drawCircle(p.offset, _r * 0.18, Paint()..color = const Color(0xFFE9B98C));
      }
    }
    if (look.hair == 'buns') _buns(canvas, front: false);
    if (look.accessories.contains('headphones')) _cups(canvas, front: false);
  }

  void _body(Canvas canvas) {
    final rect = Rect.fromCircle(center: _c, radius: _r);
    final base = look.bodyColor;
    canvas.drawCircle(
      _c,
      _r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.05,
          colors: [_lighten(base, 0.45), base, _darken(base, 0.25)],
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );
    // Отражённый свет снизу.
    canvas.drawCircle(
      _c,
      _r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.2, 1.1),
          radius: 0.7,
          colors: [_lighten(base, 0.25).withValues(alpha: 0.35), base.withValues(alpha: 0)],
        ).createShader(rect),
    );
    // Блик.
    canvas.save();
    canvas.translate(_c.dx - _r * 0.4, _c.dy - _r * 0.48);
    canvas.rotate(-0.55);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: _r * 0.42, height: _r * 0.24),
      Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.6)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, _r * 0.05),
    );
    canvas.restore();
  }

  void _muzzle(Canvas canvas) {
    _patch(canvas, 0.2, -0.3, 0.3, 0.28, const Color(0xFFF1C9A0));
    _patch(canvas, 0.2, 0.3, 0.3, 0.28, const Color(0xFFF1C9A0));
    _patch(canvas, -0.28, 0, 0.3, 0.5, const Color(0xFFF1C9A0));
  }

  void _cheeks(Canvas canvas) {
    final pink = const Color(0xFFFF7A8A).withValues(alpha: look.mood == PetMood.uneasy ? 0.18 : 0.42);
    for (final side in [-1.0, 1.0]) {
      _patch(canvas, -0.14, side * 0.58, 0.07, 0.12, pink, blur: 0.03);
    }
  }

  double get _eyeR => switch (look.stage) {
    1 => 0.17,
    2 => 0.145,
    _ => 0.125,
  };

  void _eyes(Canvas canvas) {
    final ry = _eyeR * (look.mood == PetMood.uneasy ? 0.88 : 1.0);
    final rx = ry * 0.72;
    for (final side in [-1.0, 1.0]) {
      final lon = side * 0.32;
      const lat = 0.13;
      if (blink > 0.85) {
        _line(canvas, [for (var u = -1.0; u <= 1.0; u += 0.2) (lat - 0.02 * (1 - u * u), lon + u * rx)], _ink, 0.045);
        continue;
      }
      final open = ry * (1 - blink);
      _patch(canvas, lat, lon, open, rx, _ink);
      if (open > ry * 0.4) {
        _patch(canvas, lat + open * 0.38, lon - rx * 0.3, 0.045, 0.04, const Color(0xFFFFFFFF));
        if (look.mood == PetMood.glad) {
          _patch(canvas, lat - open * 0.35, lon + rx * 0.35, 0.022, 0.02, const Color(0xFFFFFFFF));
        }
      }
    }
  }

  void _brows(Canvas canvas) {
    final w = 0.04;
    if (look.mood == PetMood.uneasy) {
      for (final side in [-1.0, 1.0]) {
        _line(canvas, [(0.40, side * 0.16), (0.33, side * 0.46)], _ink, w);
      }
    } else if (look.stage >= 3) {
      for (final side in [-1.0, 1.0]) {
        _line(canvas, [(0.38, side * 0.18), (0.41, side * 0.32), (0.39, side * 0.45)], _ink, w);
      }
    }
  }

  void _mouth(Canvas canvas) {
    switch (look.mood) {
      case PetMood.glad:
        final top = [for (var u = 0.0; u <= 1.0001; u += 0.1) (-0.2 - 0.03 * sin(pi * u), -0.3 + 0.6 * u)];
        final bottom = [for (var u = 1.0; u >= -0.0001; u -= 0.1) (-0.2 - 0.25 * sin(pi * u), -0.3 + 0.6 * u)];
        final pts = [for (final (lat, lon) in [...top, ...bottom]) _p(lat, lon)];
        if (pts.every((p) => p.z < 0.05)) return;
        final path = Path()..addPolygon([for (final p in pts) p.offset], true);
        canvas.drawPath(path, Paint()..color = const Color(0xFF7A2630));
        canvas.save();
        canvas.clipPath(path);
        _patch(canvas, -0.44, 0, 0.12, 0.2, const Color(0xFFFF7B8B));
        canvas.restore();
      case PetMood.steady:
        _line(canvas, [for (var u = 0.0; u <= 1.0001; u += 0.1) (-0.25 - 0.08 * sin(pi * u), -0.22 + 0.44 * u)], _ink, 0.05);
      case PetMood.uneasy:
        _line(canvas, [for (var u = 0.0; u <= 1.0001; u += 0.1) (-0.36 + 0.06 * sin(pi * u), -0.15 + 0.3 * u)], _ink, 0.045);
    }
  }

  Color get _hairColor => look.isMonkey
      ? _darken(look.bodyColor, 0.25)
      : Color.lerp(look.bodyColor, const Color(0xFF8A4B1F), 0.62)!;

  void _hair(Canvas canvas, {required bool front}) {
    final hairColor = _hairColor;
    switch (look.hair) {
      case 'tuft':
        final base = _p(1.3, 0, lift: 0.98);
        final dir = (base.offset - _c);
        final up = dir.distance == 0 ? const Offset(0, -1) : dir / dir.distance;
        final paint = Paint()..color = hairColor;
        for (final a in [-0.45, 0.0, 0.45]) {
          final d = Offset(up.dx * cos(a) - up.dy * sin(a), up.dx * sin(a) + up.dy * cos(a));
          final tip = base.offset + d * _r * (a == 0 ? 0.42 : 0.32);
          final n = Offset(-d.dy, d.dx) * _r * 0.09;
          final path = Path()
            ..moveTo(base.offset.dx + n.dx, base.offset.dy + n.dy)
            ..quadraticBezierTo(tip.dx + n.dx * 2.2, tip.dy + n.dy * 2.2, tip.dx, tip.dy)
            ..quadraticBezierTo(tip.dx - n.dx * 0.5, tip.dy - n.dy * 0.5, base.offset.dx - n.dx, base.offset.dy - n.dy)
            ..close();
          canvas.drawPath(path, paint);
        }
      case 'bangs':
        final top = [for (var u = 0.0; u <= 1.0001; u += 0.05) (1.45, -1.3 + 2.6 * u)];
        final bottom = [
          for (var u = 1.0; u >= -0.0001; u -= 0.02)
            (0.5 + 0.12 * (sin(u * pi * 6)).abs() + 0.25 * pow(2 * u - 1, 2), -1.3 + 2.6 * u),
        ];
        _polygon(canvas, [...top, ...bottom], hairColor, lift: 1.01);
      case 'buns':
        _buns(canvas, front: true);
    }
  }

  void _buns(Canvas canvas, {required bool front}) {
    final color = _hairColor;
    for (final side in [-1.0, 1.0]) {
      final p = _p(0.95, side * 0.75, lift: 1.1);
      if ((p.z >= 0.1) != front) continue;
      final rect = Rect.fromCircle(center: p.offset, radius: _r * 0.25);
      canvas.drawCircle(
        p.offset,
        _r * 0.25,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.4, -0.4),
            colors: [_lighten(color, 0.3), color, _darken(color, 0.2)],
          ).createShader(rect),
      );
    }
  }

  void _accessories(Canvas canvas) {
    final a = look.accessories;
    if (a.contains('bandana')) _bandana(canvas);
    if (a.contains('glasses')) _glasses(canvas);
    if (a.contains('bow')) _bow(canvas);
    if (a.contains('headphones')) {
      _headband(canvas);
      _cups(canvas, front: true);
    }
  }

  void _bandana(Canvas canvas) {
    const red = Color(0xFFE0413A);
    final top = [for (var u = 0.0; u <= 1.0001; u += 0.04) (0.72, -1.55 + 3.1 * u)];
    final bottom = [for (var u = 1.0; u >= -0.0001; u -= 0.04) (0.54, -1.55 + 3.1 * u)];
    _polygon(canvas, [...top, ...bottom], red, lift: 1.02);
    for (var lon = -1.2; lon <= 1.21; lon += 0.4) {
      _patch(canvas, 0.63, lon, 0.028, 0.035, const Color(0xFFFFFFFF), lift: 1.025);
    }
    final knot = _p(0.63, 1.45, lift: 1.06);
    if (knot.z > -0.2) {
      final paint = Paint()..color = _darken(red, 0.12);
      final o = knot.offset;
      canvas.drawPath(
        Path()
          ..moveTo(o.dx, o.dy)
          ..lineTo(o.dx + _r * 0.28, o.dy + _r * 0.08)
          ..lineTo(o.dx + _r * 0.22, o.dy + _r * 0.3)
          ..close(),
        paint,
      );
      canvas.drawCircle(o, _r * 0.07, paint);
    }
  }

  void _glasses(Canvas canvas) {
    final ry = _eyeR * 1.45;
    final rx = ry * 0.95;
    const lat = 0.13;
    for (final side in [-1.0, 1.0]) {
      final lon = side * 0.32;
      final ring = [
        for (var t = 0.0; t <= 2 * pi + 0.01; t += pi / 14) (lat + ry * sin(t), lon + rx * cos(t) / cos(lat)),
      ];
      _polygon(canvas, ring, const Color(0xFF1C2230).withValues(alpha: 0.72), lift: 1.03);
      _line(canvas, ring, const Color(0xFF111111), 0.05, lift: 1.03);
      _patch(canvas, lat + ry * 0.45, lon - rx * 0.45, 0.035, 0.07, const Color(0x66FFFFFF), lift: 1.035);
      _line(canvas, [(lat + 0.05, side * (0.32 + rx)), (lat + 0.08, side * 1.3)], const Color(0xFF111111), 0.04, lift: 1.03);
    }
    _line(canvas, [(lat + 0.05, -0.32 + rx), (lat + 0.09, 0), (lat + 0.05, 0.32 - rx)], const Color(0xFF111111), 0.045, lift: 1.03);
  }

  void _bow(Canvas canvas) {
    final p = _p(0.98, -0.6, lift: 1.04);
    if (p.z < 0) return;
    const pink = Color(0xFFFF5FA2);
    final o = p.offset;
    final paint = Paint()..color = pink;
    final dark = Paint()..color = _darken(pink, 0.2);
    canvas.save();
    canvas.translate(o.dx, o.dy);
    canvas.rotate(-0.5 + pose.yaw * 0.3);
    for (final side in [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(side * _r * 0.34, -_r * 0.26, side * _r * 0.34, 0)
          ..quadraticBezierTo(side * _r * 0.34, _r * 0.24, 0, 0)
          ..close(),
        paint,
      );
    }
    canvas.drawCircle(Offset.zero, _r * 0.08, dark);
    canvas.restore();
  }

  void _headband(Canvas canvas) {
    final pts = [
      for (var t = 0.0; t <= pi + 0.001; t += pi / 30) projectVector(cos(t) * 1.1, -sin(t) * 1.1, 0.0, pose, _c, _r),
    ];
    final path = Path()..moveTo(pts.first.offset.dx, pts.first.offset.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.offset.dx, p.offset.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF3A3F4B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _r * 0.11
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x55FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _r * 0.03,
    );
  }

  void _cups(Canvas canvas, {required bool front}) {
    for (final side in [-1.0, 1.0]) {
      final p = projectVector(side * 1.04, 0.05, 0, pose, _c, _r);
      final facing = projectVector(side * 1.0, 0, 0, pose, Offset.zero, 1);
      final isFront = p.z >= 0;
      if (isFront != front) continue;
      final w = _r * (0.1 + 0.14 * (1 - facing.offset.dx.abs()));
      final rect = Rect.fromCenter(center: p.offset, width: w * 2, height: _r * 0.5);
      canvas.drawOval(rect, Paint()..color = const Color(0xFFFF5A5F));
      canvas.drawOval(rect.deflate(_r * 0.07), Paint()..color = const Color(0xFFD63C48));
    }
  }

  // ---------- Примитивы на сфере ----------

  /// Эллипс на поверхности сферы вокруг (lat, lon) с полуосями ry, rx (радианы).
  void _patch(
    Canvas canvas,
    double lat,
    double lon,
    double ry,
    double rx,
    Color color, {
    double lift = 1.0,
    double blur = 0,
  }) {
    final pts = <Projected>[
      for (var t = 0.0; t < 2 * pi; t += pi / 12)
        _p(lat + ry * sin(t), lon + rx * cos(t) / max(0.2, cos(lat)), lift: lift),
    ];
    final avgZ = pts.fold(0.0, (s, p) => s + p.z) / pts.length;
    if (avgZ < 0.05) return;
    final paint = Paint()..color = color;
    if (blur > 0) paint.maskFilter = MaskFilter.blur(BlurStyle.normal, _r * blur);
    canvas.drawPath(Path()..addPolygon([for (final p in pts) p.offset], true), paint);
  }

  void _polygon(Canvas canvas, List<(double, double)> latLon, Color color, {double lift = 1.0}) {
    final pts = [for (final (lat, lon) in latLon) _p(lat, lon, lift: lift)];
    final visible = [for (final p in pts) if (p.z > -0.02) p.offset];
    if (visible.length < 3) return;
    canvas.drawPath(Path()..addPolygon(visible, true), Paint()..color = color);
  }

  void _line(Canvas canvas, List<(double, double)> latLon, Color color, double width, {double lift = 1.0}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _r * width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Path? path;
    for (final (lat, lon) in latLon) {
      final p = _p(lat, lon, lift: lift);
      if (p.z <= 0.02) {
        if (path != null) canvas.drawPath(path, paint);
        path = null;
        continue;
      }
      if (path == null) {
        path = Path()..moveTo(p.offset.dx, p.offset.dy);
      } else {
        path.lineTo(p.offset.dx, p.offset.dy);
      }
    }
    if (path != null) canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(MascotPainter old) =>
      old.look != look ||
      old.pose.yaw != pose.yaw ||
      old.pose.pitch != pose.pitch ||
      old.blink != blink ||
      old.hop != hop ||
      old.squash != squash ||
      old.roll != roll;
}
