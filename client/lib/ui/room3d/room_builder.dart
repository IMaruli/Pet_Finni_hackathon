import 'dart:math';
import 'dart:ui';

import '../../store/snapshot.dart';
import 'math3d.dart';
import '../../game/bowls.dart';
import 'mesh.dart';
import 'renderer.dart';

Color _rgb(double r, double g, double b) => Color.from(alpha: 1, red: r, green: g, blue: b);

/// Собирает 3D-комнату-диораму из примитивов (SA F-019 BR-04…BR-07, BR-11).
///
/// Мир: пол x, z ∈ [−2, 2], y вверх; задняя стена z = −2, левая x = −2 (с окном).
abstract final class RoomBuilder {
  static const h = 3.4;
  static const wall = 0.14;
  static const slab = 0.18;

  /// Где стоит Финик.
  static const heroSpot = Vec3(0.35, 0, 0.5);

  static const _lampPos = Vec3(-1.2, 0, 0.95);
  static const _pendantPos = Vec3(0.2, 2.75, -0.2);

  static List<Mesh> build({required Inventory inventory, int room = 1, bool night = false, Bowls bowls = const Bowls()}) {
    final play = room == 2;
    final meshes = <Mesh>[];
    _shell(meshes, play: play, night: night);
    if (play) {
      _playroom(meshes);
    } else {
      _decor(meshes, night: night);
      if (inventory.owned.contains('rug')) _rug(meshes, const Color(0xFFE2B8AE), const Color(0xFFF6E9E2));
      if (inventory.owned.contains('poster')) _poster(meshes);
      if (inventory.owned.contains('lamp')) _lamp(meshes, night: night);
      switch (inventory.furniture) {
        case 'sofa':
          _sofa(meshes);
        case 'shelf':
          _bookcase(meshes);
        case 'tv':
          _tv(meshes, night: night);
        case 'console':
          _console(meshes);
      }
    }
    _bowls(meshes, bowls);
    _pendant(meshes, night: night);
    return meshes;
  }

  /// Миски справа от героя: еда (тёплая керамика) и вода (голубая). Пустые — видно дно.
  static void _bowls(List<Mesh> m, Bowls b) {
    const food = Vec3(1.25, 0, 0.95);
    const water = Vec3(1.3, 0, 0.35);
    for (final (at, rim, inside) in [
      (food, const Color(0xFFE8744F), const Color(0xFFF7D9C9)),
      (water, const Color(0xFF4C9BE8), const Color(0xFFE9E7E3)),
    ]) {
      m.add(Mesh.cylinder(0.2, 0.12, rim, seg: 22, topR: 0.26).translated(at));
      // Внутренность миски: светлое дно с тёмным ободком — видно, что пусто.
      m.add(Mesh.cylinder(0.225, 0.003, Color.lerp(rim, const Color(0xFF000000), 0.25)!, seg: 22, castShadow: false).translated(at + const Vec3(0, 0.12, 0)));
      m.add(Mesh.cylinder(0.19, 0.004, inside, seg: 22, castShadow: false).translated(at + const Vec3(0, 0.121, 0)));
    }
    if (b.food) {
      m.add(Mesh.sphere(0.19, const Color(0xFFF1C27D), lat: 6, lon: 14, castShadow: false).scaled(const Vec3(1, 0.4, 1)).translated(food + const Vec3(0, 0.1, 0)));
      for (final (dx, dz) in [(-0.06, 0.03), (0.05, -0.04), (0.02, 0.07)]) {
        m.add(Mesh.sphere(0.035, const Color(0xFFD6334F), lat: 4, lon: 6, castShadow: false).translated(food + Vec3(dx, 0.17, dz)));
      }
    }
    if (b.water) {
      m.add(Mesh.cylinder(0.215, 0.006, const Color(0xFF38A8FF), seg: 22, castShadow: false).translated(water + const Vec3(0, 0.126, 0)));
      m.add(Mesh.cylinder(0.07, 0.004, const Color(0xFFE6F6FF), seg: 10, castShadow: false).translated(water + const Vec3(-0.06, 0.133, -0.05)));
    }
  }

  static Lighting lighting({required Inventory inventory, int room = 1, bool night = false}) {
    // Основной тёплый свет сверху-слева-спереди, заполняющий — со стороны камеры.
    final key = const Vec3(0.55, -0.75, -0.4).normalized;
    final fill = const Vec3(-0.6, -0.35, -0.7).normalized;
    if (!night) {
      return Lighting(
        dirs: [
          DirLight(key, _rgb(1, 0.95, 0.87), 0.5),
          DirLight(fill, _rgb(0.93, 0.95, 1), 0.34),
        ],
        ambient: _rgb(0.6, 0.59, 0.58),
      );
    }
    return Lighting(
      dirs: [DirLight(key, _rgb(0.55, 0.64, 1), 0.28), DirLight(fill, _rgb(0.5, 0.55, 0.9), 0.08)],
      ambient: _rgb(0.2, 0.22, 0.33),
      points: [
        if (room == 1 && inventory.owned.contains('lamp')) PointLight(_lampPos + const Vec3(0, 0.45, 0), _rgb(1, 0.82, 0.5), 1.6),
        PointLight(_pendantPos - const Vec3(0, 0.25, 0), _rgb(1, 0.85, 0.6), 1.1, radius: 3),
      ],
    );
  }

  /// Точки мягкого свечения ночью (рисуются поверх 2D).
  static List<Vec3> glowSpots({required Inventory inventory, int room = 1}) => [
    if (room == 1 && inventory.owned.contains('lamp')) _lampPos + const Vec3(0, 0.42, 0),
    _pendantPos - const Vec3(0, 0.22, 0),
  ];

  // ---------- Коробка комнаты ----------

  static void _shell(List<Mesh> m, {required bool play, required bool night}) {
    final wallC = play ? const Color(0xFFCFE3D7) : const Color(0xFFE9DED2);
    final panelC = play ? const Color(0xFFE6F0EA) : const Color(0xFFF3ECE3);
    final capC = const Color(0xFFFBF8F3);
    final woodA = play ? const Color(0xFFD9C09A) : const Color(0xFFC9A57C);
    const panelTop = 0.95;

    // Пол из досок (полосы вдоль z) + основание-срез диорамы.
    const n = 10;
    const tones = [0.0, 0.05, -0.04, 0.02, -0.06, 0.04, -0.02, 0.06, -0.03, 0.01];
    for (var i = 0; i < n; i++) {
      final x0 = -2 + 4 * i / n;
      final t = tones[i];
      final c = t >= 0 ? Color.lerp(woodA, const Color(0xFFFFFFFF), t)! : Color.lerp(woodA, const Color(0xFF000000), -t)!;
      m.add(Mesh.grid(Vec3(x0, 0, -2), const Vec3(0, 0, 4), const Vec3(4 / n, 0, 0), c, nu: 8, nv: 1));
    }
    const slabC = Color(0xFF9C7A57);
    m.add(Mesh.grid(const Vec3(-2 - wall, -slab, 2), const Vec3(4 + wall, 0, 0), const Vec3(0, slab, 0), slabC, nu: 1, nv: 1));
    m.add(Mesh.grid(const Vec3(2, -slab, 2), const Vec3(0, 0, -4 - wall), const Vec3(0, slab, 0), Color.lerp(slabC, const Color(0xFF000000), 0.15)!, nu: 1, nv: 1));

    // Задняя стена: панели снизу, стена сверху, срезы сверху и справа.
    m.add(Mesh.grid(const Vec3(-2, 0, -2), const Vec3(4, 0, 0), const Vec3(0, panelTop, 0), panelC, nu: 10, nv: 3));
    m.add(Mesh.grid(const Vec3(-2, panelTop, -2), const Vec3(4, 0, 0), const Vec3(0, h - panelTop, 0), wallC, nu: 10, nv: 6));
    m.add(Mesh.grid(const Vec3(-2 - wall, h, -2 - wall), const Vec3(0, 0, wall), const Vec3(4 + wall, 0, 0), capC, nu: 1, nv: 1));
    m.add(Mesh.grid(const Vec3(2, -slab, -2), const Vec3(0, 0, -wall), const Vec3(0, h + slab, 0), capC, nu: 1, nv: 1));

    // Левая стена с проёмом окна: z ∈ [−0.6, 0.8], y ∈ [1.0, 2.1].
    const wz0 = -0.6, wz1 = 0.8, wy0 = 1.0, wy1 = 2.1;
    void left(double z0, double z1, double y0, double y1, Color c, {int nu = 6, int nv = 3}) =>
        m.add(Mesh.grid(Vec3(-2, y0, z1), Vec3(0, 0, -(z1 - z0)), Vec3(0, y1 - y0, 0), c, nu: nu, nv: nv));
    left(-2, 2, 0, panelTop, panelC, nu: 10);
    left(-2, 2, panelTop, wy0, wallC, nu: 10, nv: 1);
    left(-2, 2, wy1, h, wallC, nu: 10, nv: 3);
    left(-2, wz0, wy0, wy1, wallC, nu: 4, nv: 3);
    left(wz1, 2, wy0, wy1, wallC, nu: 4, nv: 3);
    m.add(Mesh.grid(const Vec3(-2 - wall, h, 2), const Vec3(wall, 0, 0), const Vec3(0, 0, -4 - wall), capC, nu: 1, nv: 1));
    m.add(Mesh.grid(const Vec3(-2 - wall, -slab, 2), const Vec3(wall, 0, 0), const Vec3(0, h + slab, 0), capC, nu: 1, nv: 1));
    // Откосы проёма.
    const reveal = Color(0xFFF6F1EA);
    m.add(Mesh.grid(const Vec3(-2 - wall, wy0, wz1), const Vec3(wall, 0, 0), const Vec3(0, 0, -(wz1 - wz0)), reveal, nu: 1, nv: 1));
    m.add(Mesh.grid(const Vec3(-2 - wall, wy0, wz0), const Vec3(wall, 0, 0), const Vec3(0, wy1 - wy0, 0), reveal, nu: 1, nv: 1));
    // Стекло с небом (светится само).
    final sky = night
        ? [const Color(0xFF1B2250), const Color(0xFF1B2250), const Color(0xFF222A62), const Color(0xFF222A62), const Color(0xFF2D3478), const Color(0xFF2D3478), const Color(0xFF151B42), const Color(0xFF151B42)]
        : [const Color(0xFF9CCB84), const Color(0xFF9CCB84), const Color(0xFFD4ECFA), const Color(0xFFD4ECFA), const Color(0xFFA8D6F5), const Color(0xFFA8D6F5), const Color(0xFF7CBDEB), const Color(0xFF7CBDEB)];
    m.add(
      Mesh.grid(const Vec3(-2.1, wy0, wz1), const Vec3(0, 0, -(wz1 - wz0)), const Vec3(0, wy1 - wy0, 0), const Color(0xFFBFE0F5), nu: 1, nv: 3, colors: sky)
          .copyWith(emissive: true),
    );
    const frame = Color(0xFFFFFFFF);
    m.add(Mesh.box(const Vec3(0.05, wy1 - wy0, 0.05), frame, castShadow: false).translated(const Vec3(-2.08, wy0, (wz0 + wz1) / 2)));
    m.add(Mesh.box(const Vec3(0.05, 0.05, wz1 - wz0), frame, castShadow: false).translated(const Vec3(-2.08, (wy0 + wy1) / 2, (wz0 + wz1) / 2)));
    // Подоконник.
    m.add(Mesh.box(const Vec3(0.26, 0.05, wz1 - wz0 + 0.24), const Color(0xFFFFFCF7), castShadow: false).translated(const Vec3(-1.93, wy0 - 0.05, (wz0 + wz1) / 2)));

    // Плинтусы и рейка над панелями.
    const skirt = Color(0xFFFFFDFA);
    m.add(Mesh.box(const Vec3(4, 0.1, 0.03), skirt, castShadow: false).translated(const Vec3(0, 0, -1.985)));
    m.add(Mesh.box(const Vec3(0.03, 0.1, 4), skirt, castShadow: false).translated(const Vec3(-1.985, 0, 0)));
    m.add(Mesh.box(const Vec3(4, 0.035, 0.035), skirt, castShadow: false).translated(const Vec3(0, panelTop, -1.98)));
    m.add(Mesh.box(const Vec3(0.035, 0.035, 4), skirt, castShadow: false).translated(const Vec3(-1.98, panelTop, 0)));

    // Шторы.
    if (!play) {
      const curtain = Color(0xFFF4ECE0);
      for (final z in [wz0 - 0.22, wz1 + 0.22]) {
        m.add(Mesh.box(const Vec3(0.07, 1.55, 0.36), curtain, castShadow: false).translated(Vec3(-1.93, 0.72, z)));
      }
      m.add(Mesh.box(const Vec3(0.03, 0.03, wz1 - wz0 + 1.2), const Color(0xFFB08A63), castShadow: false).translated(Vec3(-1.9, 2.28, (wz0 + wz1) / 2)));
    }
  }

  // ---------- Декор, который есть всегда ----------

  static void _decor(List<Mesh> m, {required bool night}) {
    // Настенная полка с книгами и горшком.
    const wood = Color(0xFFCFA57A);
    m.add(Mesh.box(const Vec3(1.2, 0.05, 0.26), wood, castShadow: false).translated(const Vec3(1.1, 1.62, -1.87)));
    const books = [Color(0xFFE07A5F), Color(0xFF5C84E0), Color(0xFFF2CF6B), Color(0xFF3FA58F), Color(0xFF9B7ED6)];
    for (var i = 0; i < 5; i++) {
      final hgt = 0.22 + (i % 3) * 0.04;
      m.add(Mesh.box(Vec3(0.06, hgt, 0.18), books[i], castShadow: false).translated(Vec3(0.6 + i * 0.075, 1.67, -1.88)));
    }
    _pottedPlant(m, const Vec3(1.45, 1.67, -1.88), 0.5);

    // Часы на задней стене.
    m.add(Mesh.cylinder(0.24, 0.05, const Color(0xFFB9855A), castShadow: false).rotatedX(pi / 2).translated(const Vec3(-1.3, 1.95, -2)));
    m.add(Mesh.cylinder(0.2, 0.06, const Color(0xFFFFFBF2), castShadow: false).rotatedX(pi / 2).translated(const Vec3(-1.3, 1.95, -2)));
    m.add(Mesh.box(const Vec3(0.025, 0.14, 0.02), const Color(0xFF3B2A20), castShadow: false).translated(const Vec3(-1.3, 1.95, -1.93)));
    m.add(Mesh.box(const Vec3(0.11, 0.025, 0.02), const Color(0xFF3B2A20), castShadow: false).translated(const Vec3(-1.25, 1.94, -1.93)));

    // Монстера в углу у окна.
    const pot = Color(0xFFD08A5E);
    m.add(Mesh.cylinder(0.2, 0.42, pot, topR: 0.26).translated(const Vec3(-1.55, 0, -1.5)));
    const greens = [Color(0xFF4F8F48), Color(0xFF5DA153), Color(0xFF3F7D3B), Color(0xFF6AAE5E), Color(0xFF58994E)];
    final leafPos = [
      const Vec3(-1.55, 0.62, -1.5), const Vec3(-1.35, 0.8, -1.35), const Vec3(-1.72, 0.85, -1.4),
      const Vec3(-1.5, 1.05, -1.65), const Vec3(-1.32, 1.0, -1.62),
    ];
    for (var i = 0; i < leafPos.length; i++) {
      m.add(Mesh.sphere(0.2, greens[i], lat: 6, lon: 10, castShadow: false).scaled(const Vec3(1.2, 0.7, 1.2)).translated(leafPos[i] - const Vec3(0, 0.14, 0)));
    }
  }

  static void _pottedPlant(List<Mesh> m, Vec3 at, double s) {
    m.add(Mesh.cylinder(0.08 * s * 2, 0.14 * s * 2, const Color(0xFFF7F1E8), castShadow: false).translated(at));
    m.add(Mesh.sphere(0.12 * s * 2, const Color(0xFF6BA35A), lat: 6, lon: 10, castShadow: false).translated(at + Vec3(0, 0.12 * s * 2, 0)));
  }

  static void _pendant(List<Mesh> m, {required bool night}) {
    final p = _pendantPos;
    m.add(Mesh.box(Vec3(0.015, h - p.y - 0.2, 0.015), const Color(0xFF6B5A4A), castShadow: false).translated(p + const Vec3(0, 0.25, 0)));
    m.add(Mesh.cylinder(0.34, 0.3, const Color(0xFFE9C58E), topR: 0.1, castShadow: false).translated(p - const Vec3(0, 0.05, 0)));
    m.add(Mesh.sphere(0.07, night ? const Color(0xFFFFF2C6) : const Color(0xFFFFF6E0), lat: 6, lon: 8, castShadow: false, emissive: true).translated(p - const Vec3(0, 0.12, 0)));
  }

  // ---------- Покупки и цели ----------

  static void _rug(List<Mesh> m, Color outer, Color inner) {
    m.add(Mesh.cylinder(1.15, 0.012, outer, seg: 36, castShadow: false, layer: MeshLayer.decal).translated(heroSpot));
    m.add(Mesh.cylinder(0.92, 0.018, inner, seg: 36, castShadow: false, layer: MeshLayer.decal).translated(heroSpot));
    m.add(Mesh.cylinder(0.55, 0.022, outer.withValues(alpha: 1), seg: 30, castShadow: false, layer: MeshLayer.decal).translated(heroSpot).copyWith(color: Color.lerp(outer, inner, 0.5)));
  }

  static void _poster(List<Mesh> m) {
    const at = Vec3(-0.35, 1.05, -2);
    m.add(Mesh.box(const Vec3(0.72, 0.92, 0.04), const Color(0xFF9C6B43), castShadow: false).translated(at));
    m.add(Mesh.box(const Vec3(0.6, 0.8, 0.05), const Color(0xFFFFE3A8), castShadow: false).translated(at + const Vec3(0, 0.06, 0)));
    m.add(Mesh.cylinder(0.2, 0.06, const Color(0xFFFFC928), castShadow: false).rotatedX(pi / 2).translated(at + const Vec3(0, 0.46, 0.005)));
    for (final dx in [-0.07, 0.07]) {
      m.add(Mesh.box(const Vec3(0.035, 0.06, 0.02), const Color(0xFF2B1D14), castShadow: false).translated(at + Vec3(dx, 0.48, 0.065)));
    }
  }

  static void _lamp(List<Mesh> m, {required bool night}) {
    final p = _lampPos;
    m.add(Mesh.cylinder(0.14, 0.04, const Color(0xFFE9D8BD)).translated(p));
    m.add(Mesh.cylinder(0.05, 0.36, const Color(0xFFFFF6E6), castShadow: false).translated(p));
    m.add(
      Mesh.sphere(0.24, night ? const Color(0xFFFFF0B8) : const Color(0xFFF8DD95), castShadow: false, emissive: night)
          .scaled(const Vec3(1, 0.62, 1))
          .translated(p + const Vec3(0, 0.28, 0)),
    );
  }

  static void _sofa(List<Mesh> m) {
    const fabric = Color(0xFFEBDDC8);
    const at = Vec3(0.85, 0, -1.48);
    m.add(Mesh.box(const Vec3(2.0, 0.36, 0.84), Color.lerp(fabric, const Color(0xFF000000), 0.08)!).translated(at));
    for (final dx in [-0.47, 0.47]) {
      m.add(Mesh.box(const Vec3(0.92, 0.13, 0.66), fabric, castShadow: false).translated(at + Vec3(dx, 0.36, 0.06)));
    }
    m.add(Mesh.box(const Vec3(2.0, 0.55, 0.2), fabric, castShadow: false).translated(at + const Vec3(0, 0.3, -0.33)));
    for (final dx in [-0.92, 0.92]) {
      m.add(Mesh.box(const Vec3(0.18, 0.6, 0.84), Color.lerp(fabric, const Color(0xFF000000), 0.04)!, castShadow: false).translated(at + Vec3(dx, 0, 0)));
    }
    const pillows = [Color(0xFFE59AA3), Color(0xFF9DB6E0), Color(0xFFF1CC66)];
    for (var i = 0; i < 3; i++) {
      m.add(Mesh.box(const Vec3(0.34, 0.32, 0.12), pillows[i], castShadow: false).rotatedY((i - 1) * 0.15).translated(at + Vec3(-0.55 + i * 0.55, 0.5, -0.18)));
    }
    m.add(Mesh.box(const Vec3(0.5, 0.16, 0.7), const Color(0xFFB8A2D6), castShadow: false).translated(at + const Vec3(0.55, 0.38, 0.1)));
  }

  static void _bookcase(List<Mesh> m) {
    const wood = Color(0xFFBF8A5A);
    const at = Vec3(1.45, 0, -1.72);
    const w = 0.9, hh = 1.9, d = 0.4;
    m.add(Mesh.box(const Vec3(w, hh, 0.03), Color.lerp(wood, const Color(0xFF000000), 0.35)!, castShadow: false).translated(at + const Vec3(0, 0, -d / 2 + 0.02)));
    for (final dx in [-w / 2, w / 2]) {
      m.add(Mesh.box(const Vec3(0.04, hh, d), wood).translated(at + Vec3(dx, 0, 0)));
    }
    const books = [Color(0xFFE07A5F), Color(0xFF5C84E0), Color(0xFFF2CF6B), Color(0xFF3FA58F), Color(0xFFE0668F), Color(0xFF9B7ED6)];
    for (var r = 0; r < 5; r++) {
      final y = r * hh / 4.2;
      m.add(Mesh.box(const Vec3(w, 0.04, d), wood, castShadow: false).translated(at + Vec3(0, y, 0)));
      if (r == 4) continue;
      var x = -w / 2 + 0.06;
      var i = r * 2;
      while (x < w / 2 - 0.12) {
        final bw = 0.07 + (i % 3) * 0.02;
        final bh = 0.26 + (i % 3) * 0.05;
        m.add(Mesh.box(Vec3(bw, bh, d * 0.75), books[i % books.length], castShadow: false).translated(at + Vec3(x + bw / 2, y + 0.04, 0.02)));
        x += bw + 0.012;
        i++;
      }
    }
  }

  static void _tv(List<Mesh> m, {required bool night}) {
    const at = Vec3(0.9, 0, -1.72);
    m.add(Mesh.box(const Vec3(1.5, 0.48, 0.46), const Color(0xFFC08F63)).translated(at));
    for (final dx in [-0.37, 0.37]) {
      m.add(Mesh.box(const Vec3(0.68, 0.36, 0.02), const Color(0xFFB27D51), castShadow: false).translated(at + Vec3(dx, 0.06, 0.23)));
    }
    m.add(Mesh.box(const Vec3(0.2, 0.06, 0.14), const Color(0xFF1E2127), castShadow: false).translated(at + const Vec3(0, 0.48, -0.05)));
    m.add(Mesh.box(const Vec3(1.26, 0.74, 0.06), const Color(0xFF1E2127), castShadow: false).translated(at + const Vec3(0, 0.56, -0.08)));
    final screen = night
        ? [const Color(0xFF6A5CFF), const Color(0xFF4C6FFF), const Color(0xFF9B5CFF), const Color(0xFF7A6BFF)]
        : [const Color(0xFF2A2F3A), const Color(0xFF2A2F3A), const Color(0xFF3E4556), const Color(0xFF3E4556)];
    m.add(
      Mesh.grid(at + const Vec3(-0.59, 0.6, -0.045), const Vec3(1.18, 0, 0), const Vec3(0, 0.66, 0), screen.first, nu: 1, nv: 1, layer: MeshLayer.object, colors: screen)
          .copyWith(emissive: true),
    );
  }

  static void _console(List<Mesh> m) {
    const at = Vec3(-0.7, 0, 0.2);
    m.add(Mesh.box(const Vec3(0.5, 0.12, 0.36), const Color(0xFFF4F4F6)).rotatedY(0.3).translated(at));
    m.add(Mesh.box(const Vec3(0.46, 0.02, 0.02), const Color(0xFF26282E), castShadow: false).rotatedY(0.3).translated(at + const Vec3(0.05, 0.06, 0.17)));
    final pad = at + const Vec3(0.55, 0, 0.35);
    m.add(Mesh.box(const Vec3(0.34, 0.06, 0.18), const Color(0xFF3A3D45)).rotatedY(-0.4).translated(pad));
    m.add(Mesh.sphere(0.035, const Color(0xFFE0668F), lat: 4, lon: 6, castShadow: false).translated(pad + const Vec3(0.08, 0.05, 0)));
    m.add(Mesh.sphere(0.035, const Color(0xFF5DB6A6), lat: 4, lon: 6, castShadow: false).translated(pad + const Vec3(-0.08, 0.05, 0.02)));
  }

  // ---------- Игровая ----------

  static void _playroom(List<Mesh> m) {
    _rug(m, const Color(0xFFA9C7DD), const Color(0xFFE3EEF6));
    // Кубики.
    const cubes = [Color(0xFFE0668F), Color(0xFFF2CF6B), Color(0xFF5DB6A6), Color(0xFF8FA8E8)];
    final stack = [const Vec3(-1.3, 0, -1.1), const Vec3(-0.95, 0, -1.2), const Vec3(-1.12, 0.32, -1.15), const Vec3(-1.4, 0, -0.7)];
    for (var i = 0; i < stack.length; i++) {
      m.add(Mesh.box(const Vec3(0.32, 0.32, 0.32), cubes[i], castShadow: stack[i].y == 0).rotatedY(i * 0.4).translated(stack[i]));
    }
    // Мяч.
    m.add(Mesh.sphere(0.24, const Color(0xFFE85D5D)).translated(const Vec3(1.35, 0, 0.9)));
    // Палатка-шалаш.
    m.add(Mesh.cone(0.85, 1.4, const Color(0xFFF2D7B6), seg: 4).rotatedY(pi / 4).translated(const Vec3(1.2, 0, -1.2)));
    // Шарики на ниточках.
    const balloons = [(Vec3(-1.5, 1.7, -1.6), Color(0xFFE0668F)), (Vec3(-1.2, 1.95, -1.7), Color(0xFFF2CF6B)), (Vec3(-1.7, 2.0, -1.3), Color(0xFF8FA8E8))];
    for (final (p, c) in balloons) {
      m.add(Mesh.sphere(0.17, c, castShadow: false).scaled(const Vec3(1, 1.2, 1)).translated(p));
      m.add(Mesh.box(Vec3(0.01, p.y, 0.01), const Color(0xFF9A8F85), castShadow: false).translated(Vec3(p.x, 0, p.z)));
    }
  }
}
