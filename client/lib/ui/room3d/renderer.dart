import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'math3d.dart';
import 'mesh.dart';

/// Направленный свет: [dir] — куда летят лучи.
final class DirLight {
  const DirLight(this.dir, this.color, this.intensity);
  final Vec3 dir;
  final Color color;
  final double intensity;
}

/// Точечный свет (ночник, светильник).
final class PointLight {
  const PointLight(this.pos, this.color, this.intensity, {this.radius = 2.5});
  final Vec3 pos;
  final Color color;
  final double intensity;
  final double radius;
}

final class Lighting {
  const Lighting({required this.dirs, required this.ambient, this.points = const []});
  final List<DirLight> dirs;
  final Color ambient;
  final List<PointLight> points;
}

/// Готовый кадр: слои треугольников + пятна теней.
final class Frame {
  const Frame({required this.background, required this.decals, required this.objects, required this.shadows, required this.triangles});
  final Vertices? background;
  final Vertices? decals;
  final Vertices? objects;
  final List<Path> shadows;
  final int triangles;
}

final class _Tri {
  _Tri(this.p, this.c, this.depth);
  final List<Offset> p;
  final List<int> c;
  final double depth;
}

/// Программный 3D-рендер на `Canvas.drawVertices` (SA F-019 BR-02, BR-03, BR-08).
abstract final class Renderer {
  static Frame render(
    List<Mesh> meshes,
    Camera cam,
    Size size,
    Lighting lighting, {
    Offset shift = Offset.zero,
    double zoom = 1,
  }) {
    final eye = cam.eye;
    final layers = {for (final l in MeshLayer.values) l: <_Tri>[]};
    final shadows = <Path>[];
    var count = 0;

    for (final m in meshes) {
      final view = [for (final v in m.vertices) cam.toView(v)];
      final screen = [for (final v in view) cam.project(v, size, shift: shift, zoom: zoom)];
      final vertexShade = m.smooth && m.center != null
          ? [for (var i = 0; i < m.vertices.length; i++) _shade(m, i, (m.vertices[i] - m.center!).normalized, lighting)]
          : null;

      for (final (a, b, c) in m.faces) {
        final pa = screen[a], pb = screen[b], pc = screen[c];
        if (pa == null || pb == null || pc == null) continue;
        final wa = m.vertices[a], wb = m.vertices[b], wc = m.vertices[c];
        final n = (wb - wa).cross(wc - wa).normalized;
        final mid = (wa + wb + wc) * (1 / 3);
        if (n.dot(eye - mid) <= 0) continue;
        final colors = vertexShade != null
            ? [vertexShade[a], vertexShade[b], vertexShade[c]]
            : [_shade(m, a, n, lighting), _shade(m, b, n, lighting), _shade(m, c, n, lighting)];
        layers[m.layer]!.add(_Tri([pa, pb, pc], colors, (view[a].z + view[b].z + view[c].z) / 3));
        count++;
      }

      if (m.castShadow && m.layer == MeshLayer.object && m.minY < 0.2) {
        final path = _shadowPath(m, cam, size, shift, zoom);
        if (path != null) shadows.add(path);
      }
    }

    return Frame(
      background: _vertices(layers[MeshLayer.background]!),
      // Накладки лежат на полу слоями: порядок добавления важнее глубины.
      decals: _vertices(layers[MeshLayer.decal]!, sort: false),
      objects: _vertices(layers[MeshLayer.object]!),
      shadows: shadows,
      triangles: count,
    );
  }

  /// Освещение вершины: фоновый + ламберт от направленных + точечные, затемнение у пола и в углах.
  static int _shade(Mesh m, int i, Vec3 n, Lighting l) {
    final base = m.vertexColors?[i] ?? m.color;
    if (m.emissive) return base.toARGB32();
    final p = m.vertices[i];
    var r = l.ambient.r, g = l.ambient.g, b = l.ambient.b;
    for (final d in l.dirs) {
      final k = max(0.0, n.dot(d.dir * -1)) * d.intensity;
      r += d.color.r * k;
      g += d.color.g * k;
      b += d.color.b * k;
    }
    for (final pl in l.points) {
      final to = pl.pos - p;
      final dist = to.length;
      if (dist > pl.radius * 2) continue;
      final k = max(0.0, n.dot(to.normalized)) * pl.intensity / (1 + dist * dist * 2.2);
      r += pl.color.r * k;
      g += pl.color.g * k;
      b += pl.color.b * k;
    }
    // Затемнение у пола и в углах комнаты (стыки со стенами x = −2 и z = −2).
    var ao = 1 - 0.22 * exp(-max(0, p.y) / 0.3);
    final corner = min(p.x + 2, p.z + 2);
    ao *= 1 - 0.2 * exp(-max(0, corner) / 0.45);
    r *= ao;
    g *= ao;
    b *= ao;
    int ch(double c, double k) => (min(1.0, c * k) * 255).round();
    return (0xFF << 24) | (ch(base.r, r) << 16) | (ch(base.g, g) << 8) | ch(base.b, b);
  }

  static Path? _shadowPath(Mesh m, Camera cam, Size size, Offset shift, double zoom) {
    final (x0, x1, z0, z1) = m.footprint;
    final cx = (x0 + x1) / 2, cz = (z0 + z1) / 2;
    final rx = (x1 - x0) / 2 * 1.15, rz = (z1 - z0) / 2 * 1.15;
    final pts = <Offset>[];
    for (var i = 0; i < 16; i++) {
      final a = i * 2 * pi / 16;
      final p = cam.project(cam.toView(Vec3(cx + cos(a) * rx, 0.004, cz + sin(a) * rz)), size, shift: shift, zoom: zoom);
      if (p == null) return null;
      pts.add(p);
    }
    return Path()..addPolygon(pts, true);
  }

  static Vertices? _vertices(List<_Tri> tris, {bool sort = true}) {
    if (tris.isEmpty) return null;
    if (sort) tris.sort((a, b) => b.depth.compareTo(a.depth));
    final pos = Float32List(tris.length * 6);
    final col = Int32List(tris.length * 3);
    var i = 0, j = 0;
    for (final t in tris) {
      for (var k = 0; k < 3; k++) {
        pos[i++] = t.p[k].dx;
        pos[i++] = t.p[k].dy;
        col[j++] = t.c[k];
      }
    }
    return Vertices.raw(VertexMode.triangles, pos, colors: col);
  }
}
