import 'dart:math';
import 'dart:ui';

import 'math3d.dart';

/// Слой отрисовки: фон (пол, стены) → картины на стене → плоские накладки (коврики) → тени → объекты.
/// [wall] и [decal] не сортируются: рисуются в порядке добавления, поэтому слои картин не мерцают (F-051).
enum MeshLayer { background, wall, decal, object }

/// Треугольная сетка с цветом (SA F-019 BR-01).
final class Mesh {
  Mesh({
    required this.vertices,
    required this.faces,
    required this.color,
    this.vertexColors,
    this.smooth = false,
    this.center,
    this.emissive = false,
    this.layer = MeshLayer.object,
    this.castShadow = false,
    this.lift = 0,
    this.normals,
  });

  /// Нормали вершин для плавного света (скруглённые коробки, бока цилиндров) (F-051).
  final List<Vec3>? normals;

  final List<Vec3> vertices;
  final List<(int, int, int)> faces;
  final Color color;

  /// Цвета по вершинам (градиент стекла, неба).
  final List<Color>? vertexColors;

  /// Плавное затенение: нормаль вершины = от [center] к вершине (сферы).
  final bool smooth;
  final Vec3? center;

  /// Светится сам: освещение не применяется.
  final bool emissive;
  final MeshLayer layer;
  final bool castShadow;

  /// Приоритет в сортировке по глубине: > 0 — рисуется поверх соседей на той же высоте
  /// (дно миски над ободом, стрелки над циферблатом). Без него плоские слои «мерцают» клиньями.
  final double lift;

  Mesh _map(Vec3 Function(Vec3) f, {Vec3? newCenter, Vec3 Function(Vec3)? nf}) => Mesh(
    normals: normals == null ? null : [for (final n in normals!) nf == null ? n : nf(n).normalized],
    vertices: [for (final v in vertices) f(v)],
    faces: faces,
    color: color,
    vertexColors: vertexColors,
    smooth: smooth,
    center: newCenter ?? (center == null ? null : f(center!)),
    emissive: emissive,
    layer: layer,
    castShadow: castShadow,
    lift: lift,
  );

  Mesh translated(Vec3 d) => _map((v) => v + d);
  Mesh scaled(Vec3 k) => _map((v) => v.mul(k), nf: (n) => Vec3(n.x / k.x, n.y / k.y, n.z / k.z));
  Mesh rotatedY(double a) => _map((v) => v.rotatedY(a), nf: (n) => n.rotatedY(a));
  Mesh rotatedX(double a) {
    final c = cos(a), s = sin(a);
    Vec3 r(Vec3 v) => Vec3(v.x, v.y * c - v.z * s, v.y * s + v.z * c);
    return _map(r, nf: r);
  }

  Mesh lifted(double by) => copyWith(lift: by);

  Mesh copyWith({Color? color, bool? emissive, MeshLayer? layer, bool? castShadow, List<Color>? vertexColors, double? lift}) => Mesh(
    normals: normals,
    vertices: vertices,
    faces: faces,
    color: color ?? this.color,
    vertexColors: vertexColors ?? this.vertexColors,
    smooth: smooth,
    center: center,
    emissive: emissive ?? this.emissive,
    layer: layer ?? this.layer,
    castShadow: castShadow ?? this.castShadow,
    lift: lift ?? this.lift,
  );

  /// Горизонтальные границы в плоскости пола (для тени).
  (double, double, double, double) get footprint {
    var minX = double.infinity, maxX = -double.infinity, minZ = double.infinity, maxZ = -double.infinity;
    for (final v in vertices) {
      minX = min(minX, v.x);
      maxX = max(maxX, v.x);
      minZ = min(minZ, v.z);
      maxZ = max(maxZ, v.z);
    }
    return (minX, maxX, minZ, maxZ);
  }

  double get minY => vertices.fold(double.infinity, (m, v) => min(m, v.y));

  // ---------- Примитивы ----------

  /// Разворачивает грани наружу у выпуклой фигуры.
  static List<(int, int, int)> _outward(List<Vec3> v, List<(int, int, int)> faces) {
    final c = v.fold(Vec3.zero, (s, p) => s + p) * (1 / v.length);
    return [
      for (final (a, b, d) in faces)
        () {
          final n = (v[b] - v[a]).cross(v[d] - v[a]);
          final mid = (v[a] + v[b] + v[d]) * (1 / 3);
          return n.dot(mid - c) >= 0 ? (a, b, d) : (a, d, b);
        }(),
    ];
  }

  /// Коробка: основание на y = 0, центр по x и z.
  static Mesh box(Vec3 size, Color color, {MeshLayer layer = MeshLayer.object, bool castShadow = true, bool emissive = false}) {
    final x = size.x / 2, y = size.y, z = size.z / 2;
    final v = [
      Vec3(-x, 0, -z), Vec3(x, 0, -z), Vec3(x, y, -z), Vec3(-x, y, -z),
      Vec3(-x, 0, z), Vec3(x, 0, z), Vec3(x, y, z), Vec3(-x, y, z),
    ];
    const f = [
      (0, 1, 2), (0, 2, 3), (4, 6, 5), (4, 7, 6), (0, 3, 7), (0, 7, 4),
      (1, 5, 6), (1, 6, 2), (3, 2, 6), (3, 6, 7), (0, 4, 5), (0, 5, 1),
    ];
    return Mesh(vertices: v, faces: _outward(v, f), color: color, layer: layer, castShadow: castShadow, emissive: emissive);
  }

  /// Цилиндр: основание на y = 0. От 8 сегментов бок — с плавным светом, крышки — отдельными вершинами (F-051).
  static Mesh cylinder(double r, double h, Color color, {int seg = 18, bool castShadow = true, MeshLayer layer = MeshLayer.object, double topR = -1}) {
    final rt = topR < 0 ? r : topR;
    final smooth = seg >= 8;
    final v = <Vec3>[];
    final n = <Vec3>[];
    final slope = h == 0 ? 0.0 : (r - rt) / h;
    for (var i = 0; i < seg; i++) {
      final a = i * 2 * pi / seg;
      final side = Vec3(cos(a), slope, sin(a)).normalized;
      v.add(Vec3(cos(a) * r, 0, sin(a) * r));
      v.add(Vec3(cos(a) * rt, h, sin(a) * rt));
      n
        ..add(side)
        ..add(side);
    }
    // Крышки — свои вершины, чтобы плавный свет бока не «заливал» их.
    final capBottom = v.length;
    for (var i = 0; i < seg; i++) {
      final a = i * 2 * pi / seg;
      v.add(Vec3(cos(a) * r, 0, sin(a) * r));
      n.add(const Vec3(0, -1, 0));
    }
    final capTop = v.length;
    for (var i = 0; i < seg; i++) {
      final a = i * 2 * pi / seg;
      v.add(Vec3(cos(a) * rt, h, sin(a) * rt));
      n.add(const Vec3(0, 1, 0));
    }
    final bottom = v.length;
    v.add(const Vec3(0, 0, 0));
    n.add(const Vec3(0, -1, 0));
    final top = v.length;
    v.add(Vec3(0, h, 0));
    n.add(const Vec3(0, 1, 0));
    final f = <(int, int, int)>[];
    for (var i = 0; i < seg; i++) {
      final j = (i + 1) % seg;
      f.add((i * 2, j * 2, j * 2 + 1));
      f.add((i * 2, j * 2 + 1, i * 2 + 1));
      f.add((bottom, capBottom + j, capBottom + i));
      if (rt > 0.001) f.add((top, capTop + i, capTop + j));
    }
    return Mesh(vertices: v, faces: _outward(v, f), color: color, castShadow: castShadow, layer: layer, normals: smooth ? n : null);
  }

  /// Скруглённая коробка (мягкая мебель, как у маскота): основание на y = 0, центр по x и z (F-051).
  static Mesh roundedBox(Vec3 size, double radius, Color color, {int seg = 3, bool castShadow = true, MeshLayer layer = MeshLayer.object}) {
    final h = Vec3(size.x / 2, size.y / 2, size.z / 2);
    final r = min(radius, min(h.x, min(h.y, h.z)) * 0.95);
    final inner = Vec3(h.x - r, h.y - r, h.z - r);
    final v = <Vec3>[];
    final n = <Vec3>[];
    final f = <(int, int, int)>[];
    // Шесть граней куба [−1, 1]³, каждая — сетка seg × seg; точки «надуваются» к скруглённой форме.
    const axes = [(0, 1, 2), (0, 2, 1), (1, 2, 0)];
    for (final (ua, va, wa) in axes) {
      for (final sgn in [-1.0, 1.0]) {
        final base = v.length;
        for (var i = 0; i <= seg; i++) {
          for (var j = 0; j <= seg; j++) {
            final c = List<double>.filled(3, 0);
            c[ua] = -1 + 2 * j / seg;
            c[va] = -1 + 2 * i / seg;
            c[wa] = sgn;
            final q = Vec3(c[0] * h.x, c[1] * h.y, c[2] * h.z);
            final k = Vec3(q.x.clamp(-inner.x, inner.x), q.y.clamp(-inner.y, inner.y), q.z.clamp(-inner.z, inner.z));
            final dir = (q - k).normalized;
            v.add(k + dir * r + Vec3(0, h.y, 0));
            n.add(dir);
          }
        }
        for (var i = 0; i < seg; i++) {
          for (var j = 0; j < seg; j++) {
            final a = base + i * (seg + 1) + j, b = a + 1, c = a + seg + 1, d = c + 1;
            f
              ..add((a, b, d))
              ..add((a, d, c));
          }
        }
      }
    }
    // Ориентация: нормаль грани смотрит по нормали вершин.
    final faces = [
      for (final (a, b, c) in f)
        () {
          final fn = (v[b] - v[a]).cross(v[c] - v[a]);
          return fn.dot(n[a] + n[b] + n[c]) >= 0 ? (a, b, c) : (a, c, b);
        }(),
    ];
    return Mesh(vertices: v, faces: faces, color: color, castShadow: castShadow, layer: layer, normals: n);
  }

  /// Плоский многоугольник (веером) лицом по [facing]: картины, горы, стрелки (F-051).
  static Mesh polygon(List<Vec3> pts, Color color, {Vec3 facing = const Vec3(0, 0, 1), MeshLayer layer = MeshLayer.wall, bool emissive = false}) {
    final f = <(int, int, int)>[];
    for (var i = 1; i + 1 < pts.length; i++) {
      final fn = (pts[i] - pts[0]).cross(pts[i + 1] - pts[0]);
      f.add(fn.dot(facing) >= 0 ? (0, i, i + 1) : (0, i + 1, i));
    }
    return Mesh(vertices: pts, faces: f, color: color, layer: layer, emissive: emissive);
  }

  /// Конус (или пирамида при малом числе сегментов).
  static Mesh cone(double r, double h, Color color, {int seg = 18, bool castShadow = true}) =>
      cylinder(r, h, color, seg: seg, castShadow: castShadow, topR: 0.0001);

  /// Сфера с центром в (0, r, 0) — стоит на полу.
  static Mesh sphere(double r, Color color, {int lat = 10, int lon = 16, bool castShadow = true, bool emissive = false}) {
    final v = <Vec3>[];
    for (var i = 0; i <= lat; i++) {
      final th = i * pi / lat;
      for (var j = 0; j < lon; j++) {
        final ph = j * 2 * pi / lon;
        v.add(Vec3(sin(th) * cos(ph) * r, r + cos(th) * r, sin(th) * sin(ph) * r));
      }
    }
    final f = <(int, int, int)>[];
    for (var i = 0; i < lat; i++) {
      for (var j = 0; j < lon; j++) {
        final a = i * lon + j, b = i * lon + (j + 1) % lon;
        final c = (i + 1) * lon + j, d = (i + 1) * lon + (j + 1) % lon;
        if (i != 0) f.add((a, b, d));
        if (i != lat - 1) f.add((a, d, c));
      }
    }
    return Mesh(
      vertices: v,
      faces: _outward(v, f),
      color: color,
      smooth: true,
      center: Vec3(0, r, 0),
      castShadow: castShadow,
      emissive: emissive,
    );
  }

  /// Плоский прямоугольник, разбитый на сетку (для плавного света и затенения углов).
  /// [origin] — угол, [u] и [v] — стороны. Лицевая сторона — по правилу u × v.
  static Mesh grid(Vec3 origin, Vec3 u, Vec3 v, Color color, {int nu = 6, int nv = 6, MeshLayer layer = MeshLayer.background, List<Color>? colors}) {
    final verts = <Vec3>[];
    for (var i = 0; i <= nv; i++) {
      for (var j = 0; j <= nu; j++) {
        verts.add(origin + u * (j / nu) + v * (i / nv));
      }
    }
    final f = <(int, int, int)>[];
    for (var i = 0; i < nv; i++) {
      for (var j = 0; j < nu; j++) {
        final a = i * (nu + 1) + j, b = a + 1, c = a + nu + 1, d = c + 1;
        f.add((a, b, d));
        f.add((a, d, c));
      }
    }
    return Mesh(vertices: verts, faces: f, color: color, layer: layer, vertexColors: colors);
  }
}
