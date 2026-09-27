import 'dart:math';
import 'dart:ui';

import '../../store/snapshot.dart';
import 'math3d.dart';
import '../../game/bowls.dart';
import '../../game/pet_wish.dart';
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

  /// Комната во весь экран (F-048): стены и пол уходят за края кадра.
  /// [far] — докуда тянутся пол, задняя и левая стены к камере и вправо; [top] — высота стен.
  static const far = 6.0, top = 6.0;

  /// Двойная комната (F-065): игровая сдвинута вправо на [annexShift], граница обоев — [annexWall].
  static const annexShift = 4.2, annexWall = 2.2;

  static const _lampPos = Vec3(-1.2, 0, 0.95);
  static const _pendantPos = Vec3(0.2, 2.75, -0.2);

  static List<Mesh> build({
    required Inventory inventory,
    int room = 1,
    bool night = false,
    Bowls bowls = const Bowls(),
    DayTime time = DayTime.day,
    bool fullBleed = false,
    bool annex = false,
  }) {
    if (night) time = DayTime.night;
    night = time == DayTime.night;
    final lampsOn = night || time == DayTime.evening; // вечером лампы уже горят
    final play = room == 2;
    final meshes = <Mesh>[];
    _shell(meshes, play: play, time: time, fullBleed: fullBleed, annex: annex && !play);
    if (play) {
      _playroom(meshes);
    } else {
      // Двойная комната (F-065): игровая пристроена справа от спальни.
      if (annex) {
        final extra = <Mesh>[];
        _playroom(extra);
        meshes.addAll([for (final e in extra) e.translated(const Vec3(annexShift, 0, 0))]);
        _annexArch(meshes);
      }
      _decor(meshes, night: night);
      if (inventory.owned.contains('rug')) _rug(meshes, const Color(0xFFE2B8AE), const Color(0xFFF6E9E2));
      if (inventory.owned.contains('poster')) _poster(meshes);
      if (inventory.owned.contains('lamp')) _lamp(meshes, night: lampsOn);
      final owned = inventory.owned;
      if (owned.contains('painting')) _painting(meshes);
      if (owned.contains('garland')) _garland(meshes, on: lampsOn);
      if (owned.contains('toychest')) _toyChest(meshes);
      if (owned.contains('beanbag')) _beanbag(meshes);
      if (owned.contains('aquarium')) _aquarium(meshes);
      // Награды целей копилки (F-029).
      if (owned.contains('zoo_photo')) _zooPhoto(meshes);
      if (owned.contains('telescope')) _telescope(meshes);
      if (owned.contains('bike')) _bike(meshes);
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
    _pendant(meshes, night: lampsOn, ceiling: fullBleed ? top : h);
    return meshes;
  }

  /// Миски справа от героя: еда (тёплая керамика) и вода (голубая). Пустые — видно дно.
  static void _bowls(List<Mesh> m, Bowls b) {
    const food = Vec3(1.25, 0, 0.95);
    const water = Vec3(1.3, 0, 0.35);
    for (final (at, rim, inside) in [(food, const Color(0xFFE8744F), const Color(0xFFF7D9C9)), (water, const Color(0xFF4C9BE8), const Color(0xFFE9E7E3))]) {
      m.add(Mesh.cylinder(0.2, 0.12, rim, seg: 22, topR: 0.26).translated(at));
      // Внутренность миски: светлое дно с тёмным ободком — видно, что пусто.
      m.add(
        Mesh.cylinder(
          0.225,
          0.003,
          Color.lerp(rim, const Color(0xFF000000), 0.25)!,
          seg: 22,
          castShadow: false,
        ).translated(at + const Vec3(0, 0.12, 0)).lifted(0.3),
      );
      m.add(Mesh.cylinder(0.19, 0.004, inside, seg: 22, castShadow: false).translated(at + const Vec3(0, 0.124, 0)).lifted(0.45));
    }
    if (b.food) {
      m.add(
        Mesh.sphere(
          0.19,
          const Color(0xFFF1C27D),
          lat: 6,
          lon: 14,
          castShadow: false,
        ).scaled(const Vec3(1, 0.4, 1)).translated(food + const Vec3(0, 0.1, 0)).lifted(0.6),
      );
      for (final (dx, dz) in [(-0.06, 0.03), (0.05, -0.04), (0.02, 0.07)]) {
        m.add(Mesh.sphere(0.035, const Color(0xFFD6334F), lat: 4, lon: 6, castShadow: false).translated(food + Vec3(dx, 0.17, dz)).lifted(0.8));
      }
    }
    if (b.water) {
      m.add(Mesh.cylinder(0.215, 0.006, const Color(0xFF38A8FF), seg: 22, castShadow: false).translated(water + const Vec3(0, 0.13, 0)).lifted(0.6));
      m.add(Mesh.cylinder(0.07, 0.004, const Color(0xFFE6F6FF), seg: 10, castShadow: false).translated(water + const Vec3(-0.06, 0.137, -0.05)).lifted(0.8));
    }
  }

  /// Свет по времени суток (SA F-028): утро тёплое и мягкое, день яркий, вечер — закат и лампы, ночь — только лампы.
  static Lighting lighting({required Inventory inventory, int room = 1, bool night = false, DayTime time = DayTime.day}) {
    if (night) time = DayTime.night;
    // Основной свет сверху-слева-спереди (со стороны окна), заполняющий — со стороны камеры.
    final key = const Vec3(0.55, -0.75, -0.4).normalized;
    final low = const Vec3(0.85, -0.35, -0.2).normalized; // низкое солнце через окно
    final fill = const Vec3(-0.6, -0.35, -0.7).normalized;
    List<PointLight> lamps(double k) => [
      if (room == 1 && inventory.owned.contains('lamp')) PointLight(_lampPos + const Vec3(0, 0.45, 0), _rgb(1, 0.82, 0.5), 1.6 * k),
      PointLight(_pendantPos - const Vec3(0, 0.25, 0), _rgb(1, 0.85, 0.6), 1.1 * k, radius: 3),
    ];
    return switch (time) {
      DayTime.morning => Lighting(dirs: [DirLight(low, _rgb(1, 0.86, 0.66), 0.5), DirLight(fill, _rgb(0.95, 0.93, 1), 0.3)], ambient: _rgb(0.6, 0.56, 0.52)),
      DayTime.day => Lighting(dirs: [DirLight(key, _rgb(1, 0.95, 0.87), 0.5), DirLight(fill, _rgb(0.93, 0.95, 1), 0.34)], ambient: _rgb(0.6, 0.59, 0.58)),
      DayTime.evening => Lighting(
        dirs: [DirLight(low, _rgb(1, 0.6, 0.38), 0.42), DirLight(fill, _rgb(0.75, 0.68, 0.95), 0.16)],
        ambient: _rgb(0.45, 0.38, 0.42),
        points: lamps(0.7),
      ),
      DayTime.night => Lighting(
        dirs: [DirLight(key, _rgb(0.55, 0.64, 1), 0.28), DirLight(fill, _rgb(0.5, 0.55, 0.9), 0.08)],
        ambient: _rgb(0.2, 0.22, 0.33),
        points: lamps(1),
      ),
    };
  }

  /// Точки мягкого свечения ламп вечером и ночью (рисуются поверх 2D).
  static List<Vec3> glowSpots({required Inventory inventory, int room = 1, DayTime time = DayTime.night}) => [
    if (time == DayTime.evening || time == DayTime.night) ...[
      if (room == 1 && inventory.owned.contains('lamp')) _lampPos + const Vec3(0, 0.42, 0),
      _pendantPos - const Vec3(0, 0.22, 0),
    ],
  ];

  /// Углы стекла окна (снаружи стены): низ-ближний, низ-дальний, верх-дальний, верх-ближний.
  static const windowCorners = [Vec3(-2.1, 1.35, 0.85), Vec3(-2.1, 1.35, -0.75), Vec3(-2.1, 2.75, -0.75), Vec3(-2.1, 2.75, 0.85)];

  // ---------- Коробка комнаты ----------

  static void _shell(List<Mesh> m, {required bool play, required DayTime time, bool fullBleed = false, bool annex = false}) {
    // Во весь экран: пол и стены длиннее и выше, срезов диорамы нет (F-048). С игровой — ещё шире (F-065).
    final x1 = fullBleed ? (annex ? far + annexShift : far) : 2.0, z1 = fullBleed ? far : 2.0, wh = fullBleed ? top : h;
    final wallC = play ? const Color(0xFFCFE3D7) : const Color(0xFFE9DED2);
    final panelC = play ? const Color(0xFFE6F0EA) : const Color(0xFFF3ECE3);
    final capC = const Color(0xFFFBF8F3);
    final woodA = play ? const Color(0xFFD9C09A) : const Color(0xFFC9A57C);
    const panelTop = 0.95;

    // Пол из досок (полосы вдоль z) + основание-срез диорамы.
    const plank = 0.4;
    const tones = [0.0, 0.05, -0.04, 0.02, -0.06, 0.04, -0.02, 0.06, -0.03, 0.01];
    final n = ((x1 + 2) / plank).round();
    final nz = ((z1 + 2) / 0.5).round();
    for (var i = 0; i < n; i++) {
      final x0 = -2 + plank * i;
      final t = tones[i % tones.length];
      final c = t >= 0 ? Color.lerp(woodA, const Color(0xFFFFFFFF), t)! : Color.lerp(woodA, const Color(0xFF000000), -t)!;
      m.add(Mesh.grid(Vec3(x0, 0, -2), Vec3(0, 0, z1 + 2), const Vec3(plank, 0, 0), c, nu: nz, nv: 1));
    }
    if (!fullBleed) {
      const slabC = Color(0xFF9C7A57);
      m.add(Mesh.grid(const Vec3(-2 - wall, -slab, 2), const Vec3(4 + wall, 0, 0), const Vec3(0, slab, 0), slabC, nu: 1, nv: 1));
      m.add(
        Mesh.grid(
          const Vec3(2, -slab, 2),
          const Vec3(0, 0, -4 - wall),
          const Vec3(0, slab, 0),
          Color.lerp(slabC, const Color(0xFF000000), 0.15)!,
          nu: 1,
          nv: 1,
        ),
      );
    }

    // Задняя стена: панели снизу, стена сверху, срезы сверху и справа.
    final nx = ((x1 + 2) / 0.4).round();
    m.add(Mesh.grid(const Vec3(-2, 0, -2), Vec3(x1 + 2, 0, 0), const Vec3(0, panelTop, 0), panelC, nu: nx, nv: 3));
    if (play) {
      m.add(Mesh.grid(const Vec3(-2, panelTop, -2), Vec3(x1 + 2, 0, 0), Vec3(0, wh - panelTop, 0), wallC, nu: nx, nv: fullBleed ? 10 : 6));
    } else if (annex) {
      // Спальня — полоски, игровая за аркой — свои зелёные обои (F-065).
      _stripes(m, -2, annexWall, panelTop, wh, back: true, nv: fullBleed ? 10 : 6);
      m.add(Mesh.grid(const Vec3(annexWall, panelTop, -2), Vec3(x1 - annexWall, 0, 0), Vec3(0, wh - panelTop, 0), const Color(0xFFCFE3D7), nu: ((x1 - annexWall) / 0.4).round(), nv: 10));
    } else {
      _stripes(m, -2, x1, panelTop, wh, back: true, nv: fullBleed ? 10 : 6); // обои в полоску (F-052)
    }
    if (!fullBleed) {
      m.add(Mesh.grid(const Vec3(-2 - wall, h, -2 - wall), const Vec3(0, 0, wall), const Vec3(4 + wall, 0, 0), capC, nu: 1, nv: 1));
      m.add(Mesh.grid(const Vec3(2, -slab, -2), const Vec3(0, 0, -wall), const Vec3(0, h + slab, 0), capC, nu: 1, nv: 1));
    }

    // Левая стена с проёмом окна: z ∈ [−0.6, 0.8], y ∈ [1.0, 2.1].
    // Окно высокое: небо видно над облачком реплики героя (F-028).
    const wz0 = -0.75, wz1 = 0.85, wy0 = 1.35, wy1 = 2.75;
    void left(double z0, double z1, double y0, double y1, Color c, {int nu = 6, int nv = 3}) =>
        m.add(Mesh.grid(Vec3(-2, y0, z1), Vec3(0, 0, -(z1 - z0)), Vec3(0, y1 - y0, 0), c, nu: nu, nv: nv));
    final nzw = ((z1 + 2) / 0.4).round();
    left(-2, z1, 0, panelTop, panelC, nu: nzw);
    if (play) {
      left(-2, z1, panelTop, wy0, wallC, nu: nzw, nv: 1);
      left(-2, z1, wy1, wh, wallC, nu: nzw, nv: fullBleed ? 8 : 3);
      left(-2, wz0, wy0, wy1, wallC, nu: 4, nv: 3);
      left(wz1, z1, wy0, wy1, wallC, nu: fullBleed ? 8 : 4, nv: 3);
    } else {
      // Полосы идут по общей сетке, поэтому совпадают в углу и вокруг окна (F-052).
      _stripes(m, -2, z1, panelTop, wy0, back: false, nv: 1);
      _stripes(m, -2, z1, wy1, wh, back: false, nv: fullBleed ? 8 : 3);
      _stripes(m, -2, wz0, wy0, wy1, back: false, nv: 3);
      _stripes(m, wz1, z1, wy0, wy1, back: false, nv: 3);
    }
    if (!fullBleed) {
      m.add(Mesh.grid(const Vec3(-2 - wall, h, 2), const Vec3(wall, 0, 0), const Vec3(0, 0, -4 - wall), capC, nu: 1, nv: 1));
      m.add(Mesh.grid(const Vec3(-2 - wall, -slab, 2), const Vec3(wall, 0, 0), const Vec3(0, h + slab, 0), capC, nu: 1, nv: 1));
    }
    // Откосы проёма.
    const reveal = Color(0xFFF6F1EA);
    m.add(Mesh.grid(const Vec3(-2 - wall, wy0, wz1), const Vec3(wall, 0, 0), const Vec3(0, 0, -(wz1 - wz0)), reveal, nu: 1, nv: 1));
    m.add(Mesh.grid(const Vec3(-2 - wall, wy0, wz0), const Vec3(wall, 0, 0), const Vec3(0, wy1 - wy0, 0), reveal, nu: 1, nv: 1));
    // Стекло с небом (светится само).
    // Небо снизу вверх (4 ряда вершин): горизонт → зенит.
    List<Color> rows(Color a, Color b, Color c, Color d) => [a, a, b, b, c, c, d, d];
    final sky = switch (time) {
      DayTime.morning => rows(const Color(0xFFA9CF8C), const Color(0xFFFFE3B8), const Color(0xFFFFD6C2), const Color(0xFFB9DDF5)),
      DayTime.day => rows(const Color(0xFF9CCB84), const Color(0xFFD4ECFA), const Color(0xFFA8D6F5), const Color(0xFF7CBDEB)),
      DayTime.evening => rows(const Color(0xFF6E7F5A), const Color(0xFFFFA566), const Color(0xFFF07A8C), const Color(0xFF6D5BA8)),
      DayTime.night => rows(const Color(0xFF1B2250), const Color(0xFF222A62), const Color(0xFF2D3478), const Color(0xFF151B42)),
    };
    m.add(
      Mesh.grid(
        const Vec3(-2.1, wy0, wz1),
        const Vec3(0, 0, -(wz1 - wz0)),
        const Vec3(0, wy1 - wy0, 0),
        const Color(0xFFBFE0F5),
        nu: 1,
        nv: 3,
        colors: sky,
      ).copyWith(emissive: true),
    );
    const frame = Color(0xFFFFFFFF);
    m.add(Mesh.box(const Vec3(0.05, wy1 - wy0, 0.05), frame, castShadow: false).translated(const Vec3(-2.08, wy0, (wz0 + wz1) / 2)));
    m.add(Mesh.box(const Vec3(0.05, 0.05, wz1 - wz0), frame, castShadow: false).translated(const Vec3(-2.08, (wy0 + wy1) / 2, (wz0 + wz1) / 2)));
    // Подоконник.
    m.add(
      Mesh.box(const Vec3(0.26, 0.05, wz1 - wz0 + 0.24), const Color(0xFFFFFCF7), castShadow: false).translated(const Vec3(-1.93, wy0 - 0.05, (wz0 + wz1) / 2)),
    );

    // Плинтусы и рейка над панелями.
    const skirt = Color(0xFFFFFDFA);
    // Плинтус и молдинг — короткими кусками: у длинной планки центр ближе к камере,
    // и она «прорезала» предметы в углу (монстеру). Куски сортируются каждый на своём месте.
    final pieces = fullBleed ? 12 : 8;
    final len = (x1 + 2) / pieces, lenZ = (z1 + 2) / pieces;
    for (var i = 0; i < pieces; i++) {
      final c = -2 + len * (i + 0.5), cz = -2 + lenZ * (i + 0.5);
      m.add(Mesh.box(Vec3(len, 0.1, 0.03), skirt, castShadow: false).translated(Vec3(c, 0, -1.985)));
      m.add(Mesh.box(Vec3(0.03, 0.1, lenZ), skirt, castShadow: false).translated(Vec3(-1.985, 0, cz)));
      m.add(Mesh.box(Vec3(len, 0.035, 0.035), skirt, castShadow: false).translated(Vec3(c, panelTop, -1.98)));
      m.add(Mesh.box(Vec3(0.035, 0.035, lenZ), skirt, castShadow: false).translated(Vec3(-1.98, panelTop, cz)));
    }

    // Шторы.
    if (!play) {
      const curtain = Color(0xFFF4ECE0);
      for (final z in [wz0 - 0.22, wz1 + 0.22]) {
        m.add(Mesh.box(const Vec3(0.07, 1.65, 0.36), curtain, castShadow: false).translated(Vec3(-1.93, 1.2, z)));
      }
      m.add(Mesh.box(const Vec3(0.03, 0.03, wz1 - wz0 + 1.2), const Color(0xFFB08A63), castShadow: false).translated(Vec3(-1.9, 2.86, (wz0 + wz1) / 2)));
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

    // Часы на задней стене — плоскими слоями стены: обод → тень → циферблат → метки → стрелки (F-051).
    const clock = Vec3(-1.3, 2.07, 0);
    _wallDisc(m, clock, 0.25, const Color(0xFF9C6B43));
    _wallDisc(m, clock, 0.22, const Color(0xFFB9855A));
    _wallDisc(m, clock, 0.19, const Color(0xFFFFFBF2));
    for (var i = 0; i < 12; i++) {
      final a = i * pi / 6;
      final len = i % 3 == 0 ? 0.035 : 0.018;
      _wallRod(
        m,
        clock + Vec3(sin(a) * (0.165 - len), cos(a) * (0.165 - len), 0),
        clock + Vec3(sin(a) * 0.165, cos(a) * 0.165, 0),
        i % 3 == 0 ? 0.016 : 0.009,
        const Color(0xFF8A7B6E),
      );
    }
    _wallRod(m, clock, clock + const Vec3(0.0, 0.12, 0), 0.02, const Color(0xFF3B2A20));
    _wallRod(m, clock, clock + const Vec3(0.085, -0.02, 0), 0.02, const Color(0xFF3B2A20));
    _wallDisc(m, clock, 0.022, const Color(0xFFE0668F));

    // Монстера в углу у окна.
    const pot = Color(0xFFD08A5E);
    m.add(Mesh.cylinder(0.2, 0.42, pot, topR: 0.26).translated(const Vec3(-1.55, 0, -1.5)));
    const greens = [Color(0xFF4F8F48), Color(0xFF5DA153), Color(0xFF3F7D3B), Color(0xFF6AAE5E), Color(0xFF58994E)];
    final leafPos = [
      const Vec3(-1.55, 0.62, -1.5),
      const Vec3(-1.35, 0.8, -1.35),
      const Vec3(-1.72, 0.85, -1.4),
      const Vec3(-1.5, 1.05, -1.65),
      const Vec3(-1.32, 1.0, -1.62),
    ];
    for (var i = 0; i < leafPos.length; i++) {
      m.add(Mesh.sphere(0.2, greens[i], lat: 6, lon: 10, castShadow: false).scaled(const Vec3(1.2, 0.7, 1.2)).translated(leafPos[i] - const Vec3(0, 0.14, 0)));
    }
  }

  static void _pottedPlant(List<Mesh> m, Vec3 at, double s) {
    m.add(Mesh.cylinder(0.08 * s * 2, 0.14 * s * 2, const Color(0xFFF7F1E8), castShadow: false).translated(at));
    m.add(Mesh.sphere(0.12 * s * 2, const Color(0xFF6BA35A), lat: 6, lon: 10, castShadow: false).translated(at + Vec3(0, 0.12 * s * 2, 0)));
  }

  /// Обои в вертикальную полоску, белую и розовую (F-052). [back] — задняя стена (вдоль x), иначе левая (вдоль z).
  static const stripe = 0.2;
  static const stripeLight = Color(0xFFFBF5F2), stripePink = Color(0xFFF4D3DA);

  static void _stripes(List<Mesh> m, double a0, double a1, double y0, double y1, {required bool back, int nv = 3}) {
    var k = ((a0 + 2) / stripe).floor();
    while (true) {
      final s0 = max(a0, -2 + k * stripe), s1 = min(a1, -2 + (k + 1) * stripe);
      if (s0 >= a1) break;
      if (s1 > s0 + 1e-6) {
        final c = k.isEven ? stripeLight : stripePink;
        m.add(
          back
              ? Mesh.grid(Vec3(s0, y0, -2), Vec3(s1 - s0, 0, 0), Vec3(0, y1 - y0, 0), c, nu: 1, nv: nv)
              : Mesh.grid(Vec3(-2, y0, s1), Vec3(0, 0, -(s1 - s0)), Vec3(0, y1 - y0, 0), c, nu: 1, nv: nv),
        );
      }
      k++;
    }
  }

  /// Арка на задней стене между спальней и игровой (F-065): белые пилястры и перемычка.
  static void _annexArch(List<Mesh> m) {
    const c = Color(0xFFFBF8F3);
    for (final x in [annexWall - 0.08, annexWall + 0.08]) {
      m.add(Mesh.box(const Vec3(0.12, 2.9, 0.06), c, castShadow: false).translated(Vec3(x, 0, -1.97)));
    }
    m.add(Mesh.roundedBox(const Vec3(0.5, 0.14, 0.08), 0.04, c, seg: 2, castShadow: false).translated(const Vec3(annexWall, 2.9, -1.97)));
    // Табличка «Игровая».
    m.add(Mesh.roundedBox(const Vec3(0.44, 0.2, 0.03), 0.04, const Color(0xFF5DB6A6), seg: 2, castShadow: false).translated(const Vec3(annexWall + 1.3, 2.3, -1.97)));
  }

  static void _pendant(List<Mesh> m, {required bool night, double ceiling = h}) {
    final p = _pendantPos;
    m.add(Mesh.box(Vec3(0.015, ceiling - p.y - 0.2, 0.015), const Color(0xFF6B5A4A), castShadow: false).translated(p + const Vec3(0, 0.25, 0)));
    m.add(Mesh.cylinder(0.34, 0.3, const Color(0xFFE9C58E), topR: 0.1, castShadow: false).translated(p - const Vec3(0, 0.05, 0)));
    m.add(
      Mesh.sphere(
        0.07,
        night ? const Color(0xFFFFF2C6) : const Color(0xFFFFF6E0),
        lat: 6,
        lon: 8,
        castShadow: false,
        emissive: true,
      ).translated(p - const Vec3(0, 0.12, 0)),
    );
  }

  // ---------- Покупки и цели ----------

  static void _rug(List<Mesh> m, Color outer, Color inner) {
    m.add(Mesh.cylinder(1.15, 0.012, outer, seg: 36, castShadow: false, layer: MeshLayer.decal).translated(heroSpot));
    m.add(Mesh.cylinder(0.92, 0.018, inner, seg: 36, castShadow: false, layer: MeshLayer.decal).translated(heroSpot));
    m.add(
      Mesh.cylinder(
        0.55,
        0.022,
        outer.withValues(alpha: 1),
        seg: 30,
        castShadow: false,
        layer: MeshLayer.decal,
      ).translated(heroSpot).copyWith(color: Color.lerp(outer, inner, 0.5)),
    );
  }

  /// Портрет героя в рамке — плоскими слоями стены, без мерцания (F-051).
  static void _poster(List<Mesh> m) {
    const c = Vec3(-0.35, 1.51, 0);
    _wallRect(m, c, 0.74, 0.94, const Color(0xFF7A5537));
    _wallRect(m, c, 0.66, 0.86, const Color(0xFF9C6B43));
    _wallRect(m, c, 0.58, 0.78, const Color(0xFFFFF6E3));
    _wallRect(m, c + const Vec3(0, -0.18, 0), 0.58, 0.42, const Color(0xFFFFE3A8)); // пол-подложка
    const head = Vec3(-0.35, 1.56, 0);
    _wallDisc(m, head + const Vec3(0.012, -0.012, 0), 0.2, const Color(0xFFE8B21E)); // тень
    _wallDisc(m, head, 0.2, const Color(0xFFFFCF3A));
    _wallDisc(m, head + const Vec3(-0.06, 0.07, 0), 0.07, const Color(0xFFFFE27A)); // блик
    _wallPoly(m, [
      head + const Vec3(-0.02, 0.19, 0),
      head + const Vec3(0.02, 0.19, 0),
      head + const Vec3(0.05, 0.3, 0),
      head + const Vec3(-0.03, 0.26, 0),
    ], const Color(0xFFB9772E)); // хохолок
    for (final dx in [-0.07, 0.07]) {
      _wallDisc(m, head + Vec3(dx, 0.02, 0), 0.032, const Color(0xFF2B1D14));
      _wallDisc(m, head + Vec3(dx + 0.01, 0.035, 0), 0.01, const Color(0xFFFFFFFF));
      _wallDisc(m, head + Vec3(dx * 1.7, -0.06, 0), 0.03, const Color(0xFFFF9EAA));
    }
    _wallPoly(m, [for (var i = 0; i <= 8; i++) head + Vec3(-0.07 + 0.14 * i / 8, -0.07 - 0.035 * sin(pi * i / 8), 0)], const Color(0xFF8A2E3B)); // улыбка
  }

  /// Ночник-луна: полумесяц на деревянной подставке и звёздочка на проволоке (F-029).
  static void _lamp(List<Mesh> m, {required bool night}) {
    final p = _lampPos;
    const wood = Color(0xFFC89B6D);
    m.add(Mesh.cylinder(0.17, 0.06, wood, seg: 20).translated(p));
    m.add(Mesh.cylinder(0.02, 0.2, const Color(0xFF8C6A4A), seg: 8, castShadow: false).translated(p + const Vec3(0, 0.06, 0)));
    final glow = night ? const Color(0xFFFFE9A6) : const Color(0xFFF6DC8E);
    // Полумесяц «)» в плоскости, повёрнутой к камере (азимут 0.62): дуга из шариков, толще в середине.
    final c = p + const Vec3(0, 0.52, 0);
    const n = 13;
    for (var i = 0; i < n; i++) {
      final a = -1.75 + 3.5 * i / (n - 1);
      final t = cos(a * 0.9);
      final local = Vec3(0.2 * cos(a), 0.2 * sin(a), 0);
      m.add(Mesh.sphere(0.022 + 0.05 * t, glow, lat: 5, lon: 8, castShadow: false, emissive: night).translated(local.rotatedY(0.62) + c).lifted(0.05 * t));
    }
    // Звёздочка рядом.
    m.add(Mesh.box(const Vec3(0.01, 0.34, 0.01), const Color(0xFF8C6A4A), castShadow: false).translated(p + const Vec3(0.12, 0.06, 0.05)));
    m.add(
      Mesh.sphere(
        0.07,
        night ? const Color(0xFFFFF3C4) : const Color(0xFFF2CF6B),
        lat: 4,
        lon: 5,
        castShadow: false,
        emissive: night,
      ).scaled(const Vec3(0.35, 1, 1)).translated(p + const Vec3(0.12, 0.44, 0.05)).lifted(0.2),
    );
  }

  static void _painting(List<Mesh> m) {
    // Задняя стена справа: горы и солнце — плоскими слоями стены (F-051).
    const c = Vec3(1.15, 2.35, 0);
    _wallRect(m, c, 0.84, 0.64, const Color(0xFF6B4A31));
    _wallRect(m, c, 0.76, 0.56, const Color(0xFF8A5E3F));
    _wallRect(m, c, 0.68, 0.48, const Color(0xFFBFE3F7));
    _wallRect(m, c + const Vec3(0, 0.12, 0), 0.68, 0.24, const Color(0xFFD7EEFA));
    _wallDisc(m, c + const Vec3(0.2, 0.12, 0), 0.06, const Color(0xFFFFD66B));
    const base = -0.24;
    _wallPoly(m, [c + const Vec3(-0.34, base, 0), c + const Vec3(-0.12, 0.1, 0), c + const Vec3(0.1, base, 0)], const Color(0xFF6A9E6E));
    _wallPoly(m, [c + const Vec3(-0.16, 0.05, 0), c + const Vec3(-0.12, 0.1, 0), c + const Vec3(-0.08, 0.05, 0)], const Color(0xFFFFFFFF)); // снег
    _wallPoly(m, [c + const Vec3(-0.04, base, 0), c + const Vec3(0.16, 0.02, 0), c + const Vec3(0.34, base, 0)], const Color(0xFF8DBA7B));
    _wallRect(m, c + const Vec3(0, -0.21, 0), 0.68, 0.06, const Color(0xFF7FB069));
  }

  static void _garland(List<Mesh> m, {required bool on}) {
    // Провисающие огоньки над полкой по задней стене.
    const colors = [Color(0xFFFF6B6B), Color(0xFFFFD166), Color(0xFF6BCB77), Color(0xFF4D96FF), Color(0xFFC77DFF)];
    const n = 15;
    for (var i = 0; i < n; i++) {
      final x = -1.8 + 3.6 * i / (n - 1);
      final sag = 0.12 * sin(pi * ((i % 5) / 4));
      final at = Vec3(x, 2.95 - sag, -1.95);
      m.add(Mesh.box(Vec3(3.6 / (n - 1), 0.012, 0.012), const Color(0xFF5B4B3D), castShadow: false).translated(at + Vec3(1.8 / (n - 1), 0.02, 0)));
      final c = colors[i % colors.length];
      m.add(
        Mesh.sphere(
          0.05,
          on ? Color.lerp(c, const Color(0xFFFFFFFF), 0.35)! : c,
          lat: 4,
          lon: 6,
          castShadow: false,
          emissive: on,
        ).scaled(const Vec3(1, 1.3, 1)).translated(at).lifted(0.2),
      );
    }
  }

  static void _toyChest(List<Mesh> m) {
    // У задней стены слева — подальше от мисок (справа спереди). Мягкие скруглённые формы (F-051).
    const at = Vec3(-0.75, 0, -1.72);
    m.add(Mesh.roundedBox(const Vec3(0.62, 0.36, 0.42), 0.05, const Color(0xFF6C9BD2)).translated(at));
    m.add(Mesh.roundedBox(const Vec3(0.68, 0.07, 0.47), 0.03, const Color(0xFF4F7FB8), castShadow: false).translated(at + const Vec3(0, 0.34, 0)));
    m.add(Mesh.roundedBox(const Vec3(0.26, 0.09, 0.02), 0.01, const Color(0xFFF2CF6B), seg: 2, castShadow: false).translated(at + const Vec3(0, 0.15, 0.215)));
    // Мишка сидит сверху, рядом мяч.
    const bear = Color(0xFFB9855A);
    m.add(Mesh.sphere(0.13, bear, lat: 8, lon: 14).translated(at + const Vec3(-0.08, 0.41, 0)));
    m.add(Mesh.sphere(0.09, bear, lat: 8, lon: 12, castShadow: false).translated(at + const Vec3(-0.08, 0.62, 0.02)));
    for (final dx in [-0.07, 0.07]) {
      m.add(Mesh.sphere(0.035, bear, lat: 6, lon: 10, castShadow: false).translated(at + Vec3(-0.08 + dx, 0.7, 0.02)));
    }
    m.add(Mesh.sphere(0.035, const Color(0xFFE9C9A6), lat: 6, lon: 10, castShadow: false).translated(at + const Vec3(-0.08, 0.63, 0.1)));
    m.add(Mesh.sphere(0.1, const Color(0xFFE85D5D), lat: 8, lon: 12).translated(at + const Vec3(0.45, 0, 0.2)));
  }

  static void _beanbag(List<Mesh> m) {
    // Справа между задней мебелью и мисками.
    const at = Vec3(1.5, 0, -0.45);
    const c = Color(0xFFE88A6B);
    m.add(Mesh.sphere(0.42, c, lat: 11, lon: 18).scaled(const Vec3(1.1, 0.55, 1)).translated(at));
    m.add(
      Mesh.sphere(
        0.3,
        Color.lerp(c, const Color(0xFF000000), 0.08)!,
        lat: 12,
        lon: 18,
        castShadow: false,
      ).scaled(const Vec3(1, 0.7, 0.6)).translated(at + const Vec3(0.12, 0.22, -0.2)),
    );
  }

  static void _aquarium(List<Mesh> m) {
    // Тумба под окном и аквариум: вода заметно ниже крышки, всё скруглённое — без «треугольников» сверху (F-051).
    const at = Vec3(-1.72, 0, 0.25);
    m.add(Mesh.roundedBox(const Vec3(0.42, 0.5, 0.72), 0.04, const Color(0xFFEFE6DA)).translated(at));
    m.add(Mesh.roundedBox(const Vec3(0.36, 0.07, 0.62), 0.02, const Color(0xFFE8D7A8), seg: 3, castShadow: false).translated(at + const Vec3(0, 0.5, 0)));
    m.add(
      Mesh.roundedBox(
        const Vec3(0.36, 0.26, 0.62),
        0.02,
        const Color(0xFF7FC8E8),
        seg: 3,
        castShadow: false,
      ).translated(at + const Vec3(0, 0.57, 0)).copyWith(emissive: true),
    );
    // Крышка с заметным зазором над водой.
    m.add(Mesh.roundedBox(const Vec3(0.4, 0.045, 0.66), 0.02, const Color(0xFF3F6E8C), seg: 3, castShadow: false).translated(at + const Vec3(0, 0.9, 0)));
    // Рыбки и водоросль — на лицевом стекле (смотрит в комнату), чуть снаружи.
    for (final (dz, y, c) in [(-0.14, 0.7, const Color(0xFFFF8C42)), (0.12, 0.76, const Color(0xFFFFD166)), (0.0, 0.64, const Color(0xFFFF6B9D))]) {
      m.add(Mesh.sphere(0.03, c, lat: 6, lon: 10, castShadow: false).scaled(const Vec3(0.4, 0.8, 1.5)).translated(at + Vec3(0.185, y - 0.024, dz)).lifted(0.2));
      m.add(
        Mesh.polygon(
          [at + Vec3(0.19, y, dz - 0.04), at + Vec3(0.19, y + 0.025, dz - 0.075), at + Vec3(0.19, y - 0.025, dz - 0.075)],
          c,
          facing: const Vec3(1, 0, 0),
          layer: MeshLayer.object,
        ).lifted(0.2),
      );
    }
    for (final (dz, hh) in [(0.22, 0.2), (0.18, 0.14), (-0.2, 0.12)]) {
      m.add(
        Mesh.roundedBox(Vec3(0.012, hh, 0.03), 0.006, const Color(0xFF3FA55B), seg: 2, castShadow: false).translated(at + Vec3(0.185, 0.57, dz)).lifted(0.2),
      );
    }
  }

  static void _zooPhoto(List<Mesh> m) {
    // Фото с жирафом высоко на задней стене правее лампы — плоскими слоями стены (F-047, F-051).
    const c = Vec3(0.22, 2.65, 0);
    _wallRect(m, c, 0.66, 0.52, const Color(0xFF7A5537));
    _wallRect(m, c, 0.6, 0.46, const Color(0xFFFFFFFF));
    _wallRect(m, c + const Vec3(0, 0.03, 0), 0.52, 0.34, const Color(0xFFBFE3F7));
    _wallRect(m, c + const Vec3(0, -0.1, 0), 0.52, 0.08, const Color(0xFF9BD27A));
    _wallDisc(m, c + const Vec3(-0.18, 0.13, 0), 0.04, const Color(0xFFFFD66B));
    _wallDisc(m, c + const Vec3(-0.12, -0.02, 0), 0.07, const Color(0xFF6AAE5E)); // куст
    const g = Color(0xFFF2B84B), spot = Color(0xFFB9772E);
    final body = c + const Vec3(0.06, -0.07, 0);
    for (final dx in [-0.05, -0.02, 0.04, 0.07]) {
      _wallRod(m, body + Vec3(dx, -0.07, 0), body + Vec3(dx, 0, 0), 0.016, g); // ноги
    }
    _wallRect(m, body + const Vec3(0.01, 0.015, 0), 0.15, 0.06, g);
    _wallRod(m, body + const Vec3(0.06, 0.02, 0), body + const Vec3(0.1, 0.19, 0), 0.035, g); // шея
    _wallRect(m, body + const Vec3(0.12, 0.2, 0), 0.07, 0.035, g); // голова
    _wallRod(m, body + const Vec3(0.095, 0.215, 0), body + const Vec3(0.095, 0.25, 0), 0.008, spot); // рожки
    _wallRod(m, body + const Vec3(0.11, 0.215, 0), body + const Vec3(0.11, 0.25, 0), 0.008, spot);
    for (final (dx, dy) in [(-0.03, 0.02), (0.03, 0.01), (0.075, 0.08), (0.09, 0.14)]) {
      _wallDisc(m, body + Vec3(dx, dy, 0), 0.011, spot);
    }
  }

  // ---------- Плоские слои стены (F-051) ----------

  /// Задняя стена: плоскость z = −2 + 0,01, лицом в комнату. Порядок добавления = порядок отрисовки.
  static const _wallZ = -1.99;

  static void _wallPoly(List<Mesh> m, List<Vec3> pts, Color c) => m.add(Mesh.polygon([for (final p in pts) Vec3(p.x, p.y, _wallZ)], c));

  static void _wallRect(List<Mesh> m, Vec3 center, double w, double h, Color c) =>
      _wallPoly(m, [center + Vec3(-w / 2, -h / 2, 0), center + Vec3(w / 2, -h / 2, 0), center + Vec3(w / 2, h / 2, 0), center + Vec3(-w / 2, h / 2, 0)], c);

  static void _wallDisc(List<Mesh> m, Vec3 center, double r, Color c, {int seg = 24}) =>
      _wallPoly(m, [for (var i = 0; i < seg; i++) center + Vec3(cos(i * 2 * pi / seg) * r, sin(i * 2 * pi / seg) * r, 0)], c);

  /// Палочка толщиной [w] от [a] до [b] в плоскости стены.
  static void _wallRod(List<Mesh> m, Vec3 a, Vec3 b, double w, Color c) {
    final d = b - a;
    final side = Vec3(-d.y, d.x, 0).normalized * (w / 2);
    _wallPoly(m, [a - side, b - side, b + side, a + side], c);
  }

  /// Стержень-цилиндр между двумя точками (ножки, трубы) (F-051).
  static Mesh _rod(Vec3 a, Vec3 b, double r, Color c, {int seg = 10, bool castShadow = false}) {
    final d = b - a;
    final len = d.length;
    final dir = d * (1 / len);
    return Mesh.cylinder(r, len, c, seg: seg, castShadow: castShadow).rotatedX(acos(dir.y.clamp(-1.0, 1.0))).rotatedY(atan2(dir.x, dir.z)).translated(a);
  }

  static void _telescope(List<Mesh> m) {
    // Штатив: три ноги сходятся в головке, на ней крепление и труба с объективом и окуляром (F-051).
    const at = Vec3(-1.3, 0, 1.45);
    const leg = Color(0xFF4A4A55), metal = Color(0xFF8C8C96);
    const head = Vec3(-1.3, 0.92, 1.45);
    for (final a in [0.3, 2.4, 4.5]) {
      final foot = at + Vec3(0.3 * sin(a), 0, 0.3 * cos(a));
      m.add(_rod(foot, head, 0.018, leg, seg: 8));
      m.add(Mesh.sphere(0.028, const Color(0xFF2E2E34), lat: 4, lon: 8, castShadow: false).translated(foot - const Vec3(0, 0.01, 0))); // резиновые пятки
    }
    // Полочка между ногами.
    m.add(Mesh.cylinder(0.12, 0.015, metal, seg: 16, castShadow: false).translated(at + const Vec3(0, 0.45, 0)));
    m.add(Mesh.sphere(0.055, metal, lat: 6, lon: 10, castShadow: false).translated(head - const Vec3(0, 0.05, 0)));
    m.add(Mesh.roundedBox(const Vec3(0.09, 0.08, 0.09), 0.02, const Color(0xFF5A5A66), seg: 2, castShadow: false).translated(head + const Vec3(0, 0.02, 0)));
    // Труба наклонена к окну (влево-вверх), крепится к головке посередине.
    final dir = const Vec3(-0.8, 0.4, -0.45).normalized;
    final mid = head + const Vec3(0, 0.13, 0);
    final back = mid - dir * 0.3, front = mid + dir * 0.36;
    m.add(_rod(back, front, 0.065, const Color(0xFFF4F4F6), seg: 16));
    m.add(_rod(front - dir * 0.02, front + dir * 0.08, 0.078, const Color(0xFF4D96FF), seg: 16)); // бленда
    m.add(_rod(back - dir * 0.1, back + dir * 0.02, 0.03, const Color(0xFF2E2E34), seg: 10)); // окуляр
    m.add(_rod(head + const Vec3(0, 0.06, 0), mid, 0.02, metal, seg: 8)); // крепление к трубе
    m.add(_rod(mid + dir * 0.05 + const Vec3(0, 0.07, 0), mid + dir * 0.2 + const Vec3(0, 0.07, 0), 0.02, const Color(0xFF5A5A66), seg: 8)); // искатель
  }

  static void _bike(List<Mesh> m) {
    // У левой стены: колёса, рама, руль, седло.
    const x = -1.82, z0 = -1.05, z1 = -0.15;
    const tyre = Color(0xFF2E2E34), frame = Color(0xFFE85D5D);
    for (final z in [z0, z1]) {
      m.add(Mesh.cylinder(0.26, 0.04, tyre, seg: 20).rotatedX(pi / 2).rotatedY(pi / 2).translated(Vec3(x, 0.26, z)));
      m.add(
        Mesh.cylinder(
          0.12,
          0.045,
          const Color(0xFFD9D9DE),
          seg: 12,
          castShadow: false,
        ).rotatedX(pi / 2).rotatedY(pi / 2).translated(Vec3(x, 0.26, z)).lifted(0.2),
      );
    }
    m.add(Mesh.box(const Vec3(0.04, 0.04, 0.72), frame, castShadow: false).translated(const Vec3(x, 0.5, (z0 + z1) / 2)).lifted(0.3));
    m.add(Mesh.box(const Vec3(0.04, 0.34, 0.04), frame, castShadow: false).translated(Vec3(x, 0.26, z0 + 0.3)).lifted(0.3));
    m.add(Mesh.box(const Vec3(0.04, 0.34, 0.04), frame, castShadow: false).translated(Vec3(x, 0.3, z1)).lifted(0.3));
    m.add(Mesh.box(const Vec3(0.3, 0.03, 0.03), const Color(0xFF3B2A20), castShadow: false).translated(Vec3(x, 0.66, z1)).lifted(0.4));
    m.add(Mesh.box(const Vec3(0.1, 0.04, 0.16), const Color(0xFF3B2A20), castShadow: false).translated(Vec3(x, 0.62, z0 + 0.25)).lifted(0.4));
  }

  static void _sofa(List<Mesh> m) {
    // Мягкий диван из скруглённых форм с плавным светом — как маскот (F-051).
    const fabric = Color(0xFFEBDDC8);
    final shade = Color.lerp(fabric, const Color(0xFF000000), 0.08)!;
    const at = Vec3(0.85, 0, -1.48);
    m.add(Mesh.roundedBox(const Vec3(1.66, 0.34, 0.8), 0.07, shade).translated(at + const Vec3(0, 0.02, 0.02)));
    m.add(Mesh.roundedBox(const Vec3(2.0, 0.66, 0.26), 0.11, fabric, castShadow: false).translated(at + const Vec3(0, 0.02, -0.3)));
    for (final dx in [-0.9, 0.9]) {
      m.add(
        Mesh.roundedBox(
          const Vec3(0.22, 0.56, 0.84),
          0.1,
          Color.lerp(fabric, const Color(0xFF000000), 0.04)!,
          castShadow: false,
        ).translated(at + Vec3(dx, 0.02, 0.02)),
      );
    }
    for (final dx in [-0.4, 0.4]) {
      m.add(Mesh.roundedBox(const Vec3(0.78, 0.13, 0.6), 0.06, fabric, castShadow: false).translated(at + Vec3(dx, 0.36, 0.08)));
    }
    const pillows = [Color(0xFFE59AA3), Color(0xFF9DB6E0), Color(0xFFF1CC66)];
    for (var i = 0; i < 3; i++) {
      m.add(
        Mesh.roundedBox(
          const Vec3(0.34, 0.3, 0.12),
          0.06,
          pillows[i],
          castShadow: false,
        ).rotatedY((i - 1) * 0.15).translated(at + Vec3(-0.5 + i * 0.5, 0.49, -0.12)),
      );
    }
    m.add(Mesh.roundedBox(const Vec3(0.44, 0.05, 0.62), 0.02, const Color(0xFFB8A2D6), castShadow: false).translated(at + const Vec3(0.55, 0.49, 0.1))); // плед
    for (final dx in [-0.72, 0.72]) {
      m.add(Mesh.cylinder(0.035, 0.05, const Color(0xFF8A6A4A), seg: 10, castShadow: false).translated(at + Vec3(dx, -0.03, 0.3)));
    }
  }

  static void _bookcase(List<Mesh> m) {
    const wood = Color(0xFFBF8A5A);
    const at = Vec3(1.45, 0, -1.72);
    const w = 0.9, hh = 1.9, d = 0.4;
    m.add(
      Mesh.box(const Vec3(w, hh, 0.03), Color.lerp(wood, const Color(0xFF000000), 0.35)!, castShadow: false).translated(at + const Vec3(0, 0, -d / 2 + 0.02)),
    );
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
    m.add(Mesh.roundedBox(const Vec3(1.5, 0.48, 0.46), 0.04, const Color(0xFFC08F63)).translated(at));
    for (final dx in [-0.37, 0.37]) {
      m.add(Mesh.roundedBox(const Vec3(0.66, 0.34, 0.02), 0.01, const Color(0xFFB27D51), seg: 2, castShadow: false).translated(at + Vec3(dx, 0.07, 0.235)));
    }
    m.add(Mesh.box(const Vec3(0.2, 0.06, 0.14), const Color(0xFF1E2127), castShadow: false).translated(at + const Vec3(0, 0.48, -0.05)));
    m.add(Mesh.box(const Vec3(1.26, 0.74, 0.06), const Color(0xFF1E2127), castShadow: false).translated(at + const Vec3(0, 0.56, -0.08)));
    final screen = night
        ? [const Color(0xFF6A5CFF), const Color(0xFF4C6FFF), const Color(0xFF9B5CFF), const Color(0xFF7A6BFF)]
        : [const Color(0xFF2A2F3A), const Color(0xFF2A2F3A), const Color(0xFF3E4556), const Color(0xFF3E4556)];
    m.add(
      Mesh.grid(
        at + const Vec3(-0.59, 0.6, -0.045),
        const Vec3(1.18, 0, 0),
        const Vec3(0, 0.66, 0),
        screen.first,
        nu: 1,
        nv: 1,
        layer: MeshLayer.object,
        colors: screen,
      ).copyWith(emissive: true),
    );
  }

  static void _console(List<Mesh> m) {
    const at = Vec3(-0.7, 0, 0.2);
    m.add(Mesh.roundedBox(const Vec3(0.5, 0.12, 0.36), 0.03, const Color(0xFFF4F4F6)).rotatedY(0.3).translated(at));
    m.add(Mesh.box(const Vec3(0.46, 0.02, 0.02), const Color(0xFF26282E), castShadow: false).rotatedY(0.3).translated(at + const Vec3(0.05, 0.06, 0.17)));
    final pad = at + const Vec3(0.55, 0, 0.35);
    m.add(Mesh.roundedBox(const Vec3(0.34, 0.06, 0.18), 0.03, const Color(0xFF3A3D45)).rotatedY(-0.4).translated(pad));
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
    m.add(Mesh.sphere(0.24, const Color(0xFFE85D5D)).translated(const Vec3(-0.6, 0, 1.45))); // мяч не на мисках
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
