import 'dart:math';
import 'dart:ui';

/// Поворот сферы: yaw — вокруг вертикали (вправо +), pitch — наклон вниз (+).
final class SpherePose {
  const SpherePose(this.yaw, this.pitch);
  final double yaw;
  final double pitch;
}

final class Projected {
  const Projected(this.offset, this.z);
  final Offset offset;

  /// Глубина: 1 — к зрителю, 0 — край, < 0 — обратная сторона.
  final double z;
  bool get visible => z > 0;
}

/// Проекция вектора в системе сферы: x вправо, y вниз, z к зрителю.
Projected projectVector(
  double x,
  double y,
  double z,
  SpherePose pose,
  Offset center,
  double radius,
) {
  final ca = cos(pose.yaw), sa = sin(pose.yaw);
  final x1 = x * ca + z * sa;
  final z1 = -x * sa + z * ca;
  final cb = cos(pose.pitch), sb = sin(pose.pitch);
  final y2 = y * cb + z1 * sb;
  final z2 = -y * sb + z1 * cb;
  return Projected(center + Offset(x1, y2) * radius, z2);
}

/// Точка на сфере по широте (вверх +) и долготе (0 — лицо, вправо +).
/// [lift] > 1 выносит точку над поверхностью (причёска, наушники).
Projected projectLatLon(
  double lat,
  double lon,
  SpherePose pose,
  Offset center,
  double radius, {
  double lift = 1,
}) {
  final c = cos(lat);
  return projectVector(
    c * sin(lon) * lift,
    -sin(lat) * lift,
    c * cos(lon) * lift,
    pose,
    center,
    radius,
  );
}
