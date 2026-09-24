import 'dart:math';

import 'package:flutter/rendering.dart';

import '../../economy/economy_state.dart';
import '../../game/pet_wish.dart';
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
    if (look.isGiraffe) _giraffeSpots(canvas);
    if (look.isBear) _bearSnout(canvas);
    if (look.grubby) _mud(canvas);
    _cheeks(canvas);
    if (look.isCat) _whiskers(canvas);
    _eyes(canvas);
    _brows(canvas);
    _mouth(canvas);
    if (look.isElephant) _trunk(canvas);
    if (look.isGiraffe) _ossicones(canvas);
    if (look.hasHair) _hair(canvas, front: true);
    _accessories(canvas);
    if (look.grubby) _stink(canvas);
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
    if (look.isCat) _catEars(canvas);
    if (look.isBunny) _bunnyEars(canvas);
    if (look.isBear) _bearEars(canvas);
    if (look.isElephant) _elephantEars(canvas);
    if (look.hasHair && look.hair == 'buns') _buns(canvas, front: false);
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
    final e = look.emotion;
    final ry = _eyeR * (look.mood == PetMood.uneasy && e == null ? 0.88 : 1.0);
    final rx = ry * 0.72;
    for (final side in [-1.0, 1.0]) {
      final lon = side * 0.32;
      const lat = 0.13;
      if (e == PetEmotion.excited) {
        // Счастливые дуги «^ ^».
        _line(canvas, [for (var u = -1.0; u <= 1.0; u += 0.2) (lat - 0.02 + 0.07 * (1 - u * u), lon + u * rx * 1.1)], _ink, 0.055);
        continue;
      }
      if (e == PetEmotion.sleepy) {
        // Сонные веки: нижняя половинка глаза и тяжёлое веко сверху.
        _patch(canvas, lat - ry * 0.35, lon, ry * 0.32, rx, _ink);
        _line(canvas, [for (var u = -1.0; u <= 1.0; u += 0.2) (lat - ry * 0.2 + 0.015 * (1 - u * u), lon + u * rx * 1.15)], _ink, 0.04);
        continue;
      }
      if (blink > 0.85) {
        _line(canvas, [for (var u = -1.0; u <= 1.0; u += 0.2) (lat - 0.02 * (1 - u * u), lon + u * rx)], _ink, 0.045);
        continue;
      }
      final k = e == PetEmotion.curious && side > 0 ? 1.15 : 1.0;
      final open = ry * k * (1 - blink);
      _patch(canvas, lat, lon, open, rx * k, _ink);
      if (open > ry * 0.4) {
        _patch(canvas, lat + open * 0.38, lon - rx * 0.3, 0.045, 0.04, const Color(0xFFFFFFFF));
        if (look.mood == PetMood.glad || e == PetEmotion.hungry || e == PetEmotion.thirsty) {
          _patch(canvas, lat - open * 0.35, lon + rx * 0.35, 0.022, 0.02, const Color(0xFFFFFFFF));
        }
      }
    }
  }

  void _brows(Canvas canvas) {
    const w = 0.04;
    switch (look.emotion) {
      case PetEmotion.hungry || PetEmotion.thirsty || PetEmotion.grubby:
        for (final side in [-1.0, 1.0]) {
          _line(canvas, [(0.41, side * 0.17), (0.37, side * 0.44)], _ink, w);
        }
        return;
      case PetEmotion.curious:
        _line(canvas, [(0.38, -0.18), (0.39, -0.32), (0.37, -0.45)], _ink, w);
        _line(canvas, [(0.44, 0.17), (0.49, 0.32), (0.45, 0.46)], _ink, w);
        return;
      case PetEmotion.sleepy || PetEmotion.excited:
        return;
      case PetEmotion.calm || null:
        break;
    }
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

  void _bigSmile(Canvas canvas) {
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
  }

  void _mouth(Canvas canvas) {
    switch (look.emotion) {
      case PetEmotion.excited:
        _bigSmile(canvas);
        return;
      case PetEmotion.hungry:
        _patch(canvas, -0.29, 0, 0.085, 0.075, const Color(0xFF7A2630));
        return;
      case PetEmotion.thirsty:
        _patch(canvas, -0.28, 0, 0.07, 0.09, const Color(0xFF7A2630));
        _patch(canvas, -0.37, 0.02, 0.06, 0.06, const Color(0xFFFF7B8B));
        return;
      case PetEmotion.grubby:
        _line(canvas, [for (var u = 0.0; u <= 1.0001; u += 0.1) (-0.3 + 0.025 * sin(u * 3 * pi), -0.16 + 0.32 * u)], _ink, 0.045);
        return;
      case PetEmotion.sleepy:
        _patch(canvas, -0.3, 0, 0.05, 0.045, const Color(0xFF7A2630));
        return;
      case PetEmotion.curious:
        _line(canvas, [for (var u = 0.0; u <= 1.0001; u += 0.1) (-0.26 - 0.05 * sin(pi * u), -0.02 + 0.26 * u)], _ink, 0.05);
        return;
      case PetEmotion.calm || null:
        break;
    }
    switch (look.mood) {
      case PetMood.glad:
        _bigSmile(canvas);
      case PetMood.steady:
        _line(canvas, [for (var u = 0.0; u <= 1.0001; u += 0.1) (-0.25 - 0.08 * sin(pi * u), -0.22 + 0.44 * u)], _ink, 0.05);
      case PetMood.uneasy:
        _line(canvas, [for (var u = 0.0; u <= 1.0001; u += 0.1) (-0.36 + 0.06 * sin(pi * u), -0.15 + 0.3 * u)], _ink, 0.045);
    }
  }

  // ---------- Скины F-023 ----------

  static const _innerEar = Color(0xFFFFB3C7);

  void _catEars(Canvas canvas) {
    for (final side in [-1.0, 1.0]) {
      final a = _p(0.98, side * 0.28);
      final b = _p(0.55, side * 1.0);
      final tip = _p(1.0, side * 0.72, lift: 1.55);
      if (tip.z < -0.4) continue;
      Path tri(Offset p, Offset q, Offset t) => Path()
        ..moveTo(p.dx, p.dy)
        ..quadraticBezierTo((p.dx + t.dx) / 2 - (q.dx - p.dx) * 0.08, (p.dy + t.dy) / 2, t.dx, t.dy)
        ..quadraticBezierTo((q.dx + t.dx) / 2 + (q.dx - p.dx) * 0.08, (q.dy + t.dy) / 2, q.dx, q.dy)
        ..close();
      canvas.drawPath(tri(a.offset, b.offset, tip.offset), Paint()..color = _darken(look.bodyColor, 0.06));
      Offset toward(Offset o, double k) => Offset.lerp(o, tip.offset, k)!;
      canvas.drawPath(
        tri(toward(a.offset, 0.35), toward(b.offset, 0.35), toward(tip.offset, 0) + (a.offset + b.offset - tip.offset * 2) * 0.08),
        Paint()..color = _innerEar,
      );
    }
  }

  void _bunnyEars(Canvas canvas) {
    for (final side in [-1.0, 1.0]) {
      final base = _p(1.12, side * 0.42);
      final tip = _p(1.18, side * 0.62, lift: 2.05);
      if (tip.z < -0.4) continue;
      final d = tip.offset - base.offset;
      final len = d.distance;
      canvas.save();
      canvas.translate((base.offset.dx + tip.offset.dx) / 2, (base.offset.dy + tip.offset.dy) / 2);
      canvas.rotate(atan2(d.dy, d.dx) + pi / 2);
      final outer = Rect.fromCenter(center: Offset.zero, width: _r * 0.36, height: len * 1.1);
      canvas.drawOval(
        outer,
        Paint()
          ..shader = LinearGradient(
            colors: [_lighten(look.bodyColor, 0.25), look.bodyColor, _darken(look.bodyColor, 0.12)],
          ).createShader(outer),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(0, -len * 0.04), width: _r * 0.16, height: len * 0.8),
        Paint()..color = _innerEar,
      );
      canvas.restore();
    }
  }

  void _whiskers(Canvas canvas) {
    final paint = Paint()
      ..color = _ink.withValues(alpha: 0.55)
      ..strokeWidth = _r * 0.022
      ..strokeCap = StrokeCap.round;
    for (final side in [-1.0, 1.0]) {
      final p = _p(-0.16, side * 0.6);
      if (p.z < 0.15) continue;
      for (final tilt in [-0.07, 0.07]) {
        canvas.drawLine(p.offset, p.offset + Offset(side * _r * 0.42, tilt * _r * 1.6), paint);
      }
    }
  }

  // ---------- Мишка, Жираф, Слон (F-037) ----------

  void _bearEars(Canvas canvas) {
    for (final side in [-1.0, 1.0]) {
      final p = _p(0.95, side * 0.78, lift: 1.08);
      if (p.z < -0.45) continue;
      canvas.drawCircle(p.offset, _r * 0.27, Paint()..color = _darken(look.bodyColor, 0.1));
      canvas.drawCircle(p.offset, _r * 0.15, Paint()..color = _lighten(look.bodyColor, 0.35));
    }
  }

  void _bearSnout(Canvas canvas) {
    _patch(canvas, -0.2, 0, 0.2, 0.27, _lighten(look.bodyColor, 0.4));
    _patch(canvas, -0.06, 0, 0.05, 0.08, const Color(0xFF3B2A20));
  }

  void _giraffeSpots(Canvas canvas) {
    final spot = _darken(Color.lerp(look.bodyColor, const Color(0xFFB9772E), 0.6)!, 0.1);
    for (final (lat, lon, ry, rx) in const [
      (0.6, -0.9, 0.12, 0.14), (0.35, 1.05, 0.1, 0.12), (-0.55, -0.7, 0.11, 0.13), (-0.6, 0.62, 0.1, 0.11),
      (0.85, 0.35, 0.08, 0.1), (-0.15, -1.2, 0.1, 0.09), (0.05, 1.25, 0.09, 0.08), (-0.85, 0.05, 0.08, 0.12),
    ]) {
      _patch(canvas, lat, lon, ry, rx, spot);
    }
  }

  void _ossicones(Canvas canvas) {
    final stick = Paint()
      ..color = _darken(look.bodyColor, 0.3)
      ..strokeWidth = _r * 0.09
      ..strokeCap = StrokeCap.round;
    for (final side in [-1.0, 1.0]) {
      final base = _p(1.18, side * 0.4, lift: 0.98);
      if (base.z < -0.3) continue;
      final top = base.offset + Offset(side * _r * 0.06, -_r * 0.42);
      canvas.drawLine(base.offset, top, stick);
      canvas.drawCircle(top, _r * 0.09, Paint()..color = const Color(0xFF8B5A2B));
    }
  }

  void _elephantEars(Canvas canvas) {
    for (final side in [-1.0, 1.0]) {
      final p = _p(0.12, side * 1.35, lift: 1.0);
      if (p.z < -0.7) continue;
      final c = p.offset + Offset(side * _r * 0.28, 0);
      final flap = 1 + 0.06 * sin(pose.yaw * 4);
      final rect = Rect.fromCenter(center: c, width: _r * 0.85 * flap, height: _r * 1.1);
      canvas.drawOval(rect, Paint()..color = _darken(look.bodyColor, 0.08));
      canvas.drawOval(rect.deflate(_r * 0.12), Paint()..color = Color.lerp(look.bodyColor, const Color(0xFFFFB3C7), 0.45)!);
    }
  }

  void _trunk(Canvas canvas) {
    final start = _p(-0.02, 0, lift: 1.02);
    if (start.z < 0.1) return;
    final s = start.offset;
    final path = Path()
      ..moveTo(s.dx, s.dy)
      ..quadraticBezierTo(s.dx - _r * 0.08, s.dy + _r * 0.5, s.dx + _r * 0.14, s.dy + _r * 0.7)
      ..quadraticBezierTo(s.dx + _r * 0.36, s.dy + _r * 0.82, s.dx + _r * 0.42, s.dy + _r * 0.58);
    canvas.drawPath(
      path,
      Paint()
        ..color = _darken(look.bodyColor, 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _r * 0.27
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = _lighten(look.bodyColor, 0.25).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _r * 0.05
        ..strokeCap = StrokeCap.round,
    );
  }

  // ---------- Неухоженный (F-027) ----------

  /// Мультяшные пятна грязи: мягкие, не страшные.
  void _mud(Canvas canvas) {
    const mud = Color(0xFF8B6A4A);
    for (final (lat, lon, ry, rx, a) in const [
      (-0.55, -0.55, 0.13, 0.17, 0.55),
      (-0.7, 0.35, 0.09, 0.12, 0.5),
      (0.45, 0.75, 0.08, 0.1, 0.45),
      (-0.2, 1.05, 0.1, 0.08, 0.5),
      (0.25, -0.95, 0.07, 0.09, 0.45),
    ]) {
      _patch(canvas, lat, lon, ry, rx, mud.withValues(alpha: a), blur: 0.012);
    }
    // брызги
    for (final (lat, lon) in const [(-0.4, -0.2), (-0.85, 0.05), (0.1, 0.95), (-0.3, -1.1)]) {
      _patch(canvas, lat, lon, 0.025, 0.025, mud.withValues(alpha: 0.6));
    }
  }

  /// Волнистые линии «запаха» над головой.
  void _stink(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFF7FA34A).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _r * 0.045
      ..strokeCap = StrokeCap.round;
    // По бокам головы, чтобы не прятались под облачком реплики.
    for (final dx in [-1.08, -0.9, 0.9, 1.08]) {
      final x0 = _c.dx + dx * _r + sin(pose.yaw * 3 + dx) * _r * 0.04;
      final y0 = _c.dy - _r * (dx.abs() > 1 ? 0.2 : 0.55);
      final path = Path()..moveTo(x0, y0);
      for (var k = 1; k <= 5; k++) {
        path.lineTo(x0 + sin(k * 1.5 + dx * 5) * _r * 0.06, y0 - k * _r * 0.075);
      }
      canvas.drawPath(path, paint);
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
    if (a.contains('scarf')) _scarf(canvas);
    if (a.contains('bowtie')) _bowtie(canvas);
    if (a.contains('cap')) _cap(canvas);
    if (a.contains('crown')) _crown(canvas);
    if (a.contains('partyhat')) _partyHat(canvas);
    if (a.contains('flower')) _flower(canvas);
  }

  // ---------- Гардероб F-030 ----------

  /// Точки линии на сфере (широта [lat]) спереди, слева направо, в экранных координатах.
  List<Offset> _band(double lat, {double from = -1.5, double to = 1.5, double lift = 1.0}) => [
    for (var u = 0.0; u <= 1.0001; u += 0.05) _p(lat, from + (to - from) * u, lift: lift).offset,
  ];

  void _cap(Canvas canvas) {
    const blue = Color(0xFF3D7BD9);
    // Купол: всё, что выше линии широты 0.55, в пределах силуэта головы.
    final edge = _band(0.55, from: -1.7, to: 1.7);
    final above = Path()..moveTo(edge.first.dx, edge.first.dy);
    for (final p in edge.skip(1)) {
      above.lineTo(p.dx, p.dy);
    }
    above
      ..lineTo(edge.last.dx + _r, edge.last.dy)
      ..lineTo(edge.last.dx + _r, _c.dy - _r * 3)
      ..lineTo(edge.first.dx - _r, _c.dy - _r * 3)
      ..lineTo(edge.first.dx - _r, edge.first.dy)
      ..close();
    final head = Path()..addOval(Rect.fromCircle(center: _c, radius: _r * 1.04));
    final dome = Path.combine(PathOperation.intersect, above, head);
    canvas.drawPath(
      dome,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.6),
          colors: [_lighten(blue, 0.3), blue, _darken(blue, 0.2)],
        ).createShader(Rect.fromCircle(center: _c, radius: _r)),
    );
    // Козырёк: полукруг вперёд-вниз от середины линии.
    final mid = _p(0.52, 0, lift: 1.02);
    if (mid.z > 0) {
      final o = mid.offset;
      canvas.drawPath(
        Path()..addArc(Rect.fromCenter(center: o, width: _r * 1.3, height: _r * 0.42), 0, pi),
        Paint()..color = _darken(blue, 0.22),
      );
    }
    final btn = _p(1.5, 0, lift: 1.05);
    canvas.drawCircle(btn.offset, _r * 0.07, Paint()..color = _darken(blue, 0.3));
  }

  void _crown(Canvas canvas) {
    const gold = Color(0xFFF5C518);
    final base = _band(0.78, from: -0.95, to: 0.95, lift: 1.02);
    final up = Offset(0, -_r * 0.34);
    final path = Path()..moveTo(base.first.dx, base.first.dy);
    // Зубцы вверх по экрану: 5 пиков.
    const peaks = 5;
    for (var i = 0; i <= peaks * 2; i++) {
      final k = i / (peaks * 2);
      final p = base[(k * (base.length - 1)).round()];
      path.lineTo(p.dx + (i.isOdd ? 0 : 0), p.dy + (i.isEven ? up.dy : up.dy * 0.35));
    }
    path.lineTo(base.last.dx, base.last.dy);
    for (final p in base.reversed) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = gold);
    canvas.drawPath(
      path,
      Paint()
        ..color = _darken(gold, 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _r * 0.03,
    );
    for (var i = 0; i <= peaks * 2; i += 2) {
      final k = i / (peaks * 2);
      final p = base[(k * (base.length - 1)).round()] + up;
      canvas.drawCircle(p, _r * 0.05, Paint()..color = const Color(0xFFFFF3B0));
    }
    for (final (k, c) in [(0.25, const Color(0xFFE53935)), (0.5, const Color(0xFF1E88E5)), (0.75, const Color(0xFF43A047))]) {
      final p = base[(k * (base.length - 1)).round()] + Offset(0, up.dy * 0.2);
      canvas.drawCircle(p, _r * 0.055, Paint()..color = c);
    }
  }

  void _scarf(Canvas canvas) {
    const red = Color(0xFFE53950);
    final top = [for (var u = 0.0; u <= 1.0001; u += 0.04) (-0.34, -1.6 + 3.2 * u)];
    final bottom = [for (var u = 1.0; u >= -0.0001; u -= 0.04) (-0.56, -1.6 + 3.2 * u)];
    _polygon(canvas, [...top, ...bottom], red, lift: 1.04);
    for (var lon = -1.2; lon <= 1.21; lon += 0.3) {
      _patch(canvas, -0.45, lon, 0.1, 0.035, const Color(0xE6FFFFFF), lift: 1.045);
    }
    final end = _p(-0.5, 0.75, lift: 1.06);
    if (end.z > -0.1) {
      final o = end.offset;
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(o.dx - _r * 0.1, o.dy, _r * 0.2, _r * 0.5), Radius.circular(_r * 0.05));
      canvas.drawRRect(r, Paint()..color = _darken(red, 0.08));
      canvas.drawRect(Rect.fromLTWH(o.dx - _r * 0.1, o.dy + _r * 0.2, _r * 0.2, _r * 0.06), Paint()..color = const Color(0xE6FFFFFF));
    }
  }

  void _bowtie(Canvas canvas) {
    final p = _p(-0.8, 0, lift: 1.05);
    if (p.z < 0) return;
    const purple = Color(0xFF7E57C2);
    final o = p.offset;
    final paint = Paint()..color = purple;
    for (final side in [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(o.dx, o.dy)
          ..lineTo(o.dx + side * _r * 0.3, o.dy - _r * 0.15)
          ..lineTo(o.dx + side * _r * 0.3, o.dy + _r * 0.15)
          ..close(),
        paint,
      );
    }
    canvas.drawCircle(o, _r * 0.07, Paint()..color = _darken(purple, 0.2));
  }

  void _partyHat(Canvas canvas) {
    final base = projectVector(0, -0.9, 0.2, pose, _c, _r).offset;
    final apex = projectVector(0.15, -1.75, 0.1, pose, _c, _r).offset;
    final axis = apex - base;
    final n = Offset(-axis.dy, axis.dx) / axis.distance * _r * 0.34;
    final cone = Path()
      ..moveTo(base.dx + n.dx, base.dy + n.dy)
      ..lineTo(apex.dx, apex.dy)
      ..lineTo(base.dx - n.dx, base.dy - n.dy)
      ..close();
    canvas.drawPath(cone, Paint()..color = const Color(0xFF26C6DA));
    canvas.save();
    canvas.clipPath(cone);
    final stripe = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..strokeWidth = _r * 0.1;
    for (final k in [0.25, 0.55]) {
      final c = Offset.lerp(base, apex, k)!;
      canvas.drawLine(c - n * 2 + axis * 0.08, c + n * 2 - axis * 0.08, stripe);
    }
    canvas.restore();
    canvas.drawOval(Rect.fromCenter(center: base, width: n.distance * 2.2, height: _r * 0.12), Paint()..color = const Color(0xFF00ACC1));
    canvas.drawCircle(apex, _r * 0.1, Paint()..color = const Color(0xFFFF5FA2));
  }

  void _flower(Canvas canvas) {
    final p = _p(0.72, -0.95, lift: 1.06);
    if (p.z < -0.1) return;
    final o = p.offset;
    final petal = Paint()..color = const Color(0xFFFF8FB8);
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * pi / 5 + pose.yaw * 0.2;
      canvas.drawCircle(o + Offset(cos(a), sin(a)) * _r * 0.1, _r * 0.08, petal);
    }
    canvas.drawCircle(o, _r * 0.065, Paint()..color = const Color(0xFFFFD54F));
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
