import 'dart:math';
import 'dart:ui';

import 'math3d.dart';

/// Слой отрисовки: фон (пол, стены) → плоские накладки (коврики) → тени → объекты.
enum MeshLayer { background, decal, object }

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
  });

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

  Mesh _map(Vec3 Function(Vec3) f, {Vec3? newCenter}) => Mesh(
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
  Mesh scaled(Vec3 k) => _map((v) => v.mul(k));
  Mesh rotatedY(double a) => _map((v) => v.rotatedY(a));
  Mesh rotatedX(double a) {
    final c = cos(a), s = sin(a);
    return _map((v) => Vec3(v.x, v.y * c - v.z * s, v.y * s + v.z * c));
  }

  Mesh lifted(double by) => copyWith(lift: by);

  Mesh copyWith({Color? color, bool? emissive, MeshLayer? layer, bool? castShadow, List<Color>? vertexColors, double? lift}) => Mesh(
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

  /// Цилиндр: основание на y = 0.
  static Mesh cylinder(double r, double h, Color color, {int seg = 18, bool castShadow = true, MeshLayer layer = MeshLayer.object, double topR = -1}) {
    final rt = topR < 0 ? r : topR;
    final v = <Vec3>[];
    for (var i = 0; i < seg; i++) {
      final a = i * 2 * pi / seg;
      v.add(Vec3(cos(a) * r, 0, sin(a) * r));
      v.add(Vec3(cos(a) * rt, h, sin(a) * rt));
    }
    final bottom = v.length;
    v.add(const Vec3(0, 0, 0));
    final top = v.length;
    v.add(Vec3(0, h, 0));
    final f = <(int, int, int)>[];
    for (var i = 0; i < seg; i++) {
      final j = (i + 1) % seg;
      f.add((i * 2, j * 2, j * 2 + 1));
      f.add((i * 2, j * 2 + 1, i * 2 + 1));
      f.add((bottom, j * 2, i * 2));
      if (rt > 0) f.add((top, i * 2 + 1, j * 2 + 1));
    }
    return Mesh(vertices: v, faces: _outward(v, f), color: color, castShadow: castShadow, layer: layer);
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
