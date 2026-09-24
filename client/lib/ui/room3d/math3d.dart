import 'dart:math';
import 'dart:ui';

/// Вектор в мировых координатах: y вверх (SA F-019).
final class Vec3 {
  const Vec3(this.x, this.y, this.z);
  final double x, y, z;

  static const zero = Vec3(0, 0, 0);

  Vec3 operator +(Vec3 o) => Vec3(x + o.x, y + o.y, z + o.z);
  Vec3 operator -(Vec3 o) => Vec3(x - o.x, y - o.y, z - o.z);
  Vec3 operator *(double k) => Vec3(x * k, y * k, z * k);
  Vec3 mul(Vec3 o) => Vec3(x * o.x, y * o.y, z * o.z);
  double dot(Vec3 o) => x * o.x + y * o.y + z * o.z;
  Vec3 cross(Vec3 o) => Vec3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);
  double get length => sqrt(x * x + y * y + z * z);
  Vec3 get normalized {
    final l = length;
    return l == 0 ? this : this * (1 / l);
  }

  Vec3 rotatedY(double a) {
    final c = cos(a), s = sin(a);
    return Vec3(x * c + z * s, y, -x * s + z * c);
  }

  @override
  String toString() => 'Vec3($x, $y, $z)';
}

/// Камера на орбите вокруг цели. Азимут 0 — смотрим вдоль −z, положительный — заходим справа.
final class Camera {
  Camera({
    this.azimuth = 0.6,
    this.elevation = 0.5,
    this.distance = 8,
    this.fov = 0.72,
    this.target = const Vec3(0, 0.9, 0),
  });

  final double azimuth;
  final double elevation;
  final double distance;

  /// Вертикальный угол обзора, радианы.
  final double fov;
  final Vec3 target;

  Vec3 get eye => target + Vec3(sin(azimuth) * cos(elevation), sin(elevation), cos(azimuth) * cos(elevation)) * distance;

  /// Мир → камера: x вправо, y вверх, z — глубина (положительная перед камерой).
  Vec3 toView(Vec3 p) {
    final forward = (target - eye).normalized;
    final right = forward.cross(const Vec3(0, 1, 0)).normalized;
    final up = right.cross(forward);
    final d = p - eye;
    return Vec3(d.dot(right), d.dot(up), d.dot(forward));
  }

  /// Камера → экран. `null`, если точка за камерой.
  Offset? project(Vec3 view, Size size, {Offset shift = Offset.zero, double zoom = 1}) {
    if (view.z <= 0.05) return null;
    final f = size.height / 2 / tan(fov / 2) * zoom;
    return Offset(size.width / 2 + view.x / view.z * f, size.height / 2 - view.y / view.z * f) + shift;
  }
}
