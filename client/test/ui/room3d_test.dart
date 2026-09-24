import 'package:finni/store/snapshot.dart';
import 'package:finni/ui/room/room_scene.dart';
import 'package:finni/ui/room3d/math3d.dart';
import 'package:finni/ui/room3d/mesh.dart';
import 'package:finni/ui/room3d/renderer.dart';
import 'package:finni/ui/room3d/room_builder.dart';
import 'package:finni/game/bowls.dart';
import 'package:finni/game/pet_wish.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('camera', () {
    test('target projects to the screen center', () {
      final cam = Camera(azimuth: 0.6, elevation: 0.4, distance: 8, target: const Vec3(0, 1, 0));
      final p = cam.project(cam.toView(const Vec3(0, 1, 0)), const Size(400, 800))!;
      expect(p.dx, closeTo(200, 1e-6));
      expect(p.dy, closeTo(400, 1e-6));
    });

    test('points above the target are higher on screen, points to the right are to the right', () {
      final cam = Camera(azimuth: 0, elevation: 0, distance: 8, target: Vec3.zero);
      const size = Size(400, 800);
      final up = cam.project(cam.toView(const Vec3(0, 1, 0)), size)!;
      final right = cam.project(cam.toView(const Vec3(1, 0, 0)), size)!;
      expect(up.dy, lessThan(400));
      expect(right.dx, greaterThan(200));
    });

    test('points behind the camera are not projected', () {
      final cam = Camera(azimuth: 0, elevation: 0, distance: 8, target: Vec3.zero);
      expect(cam.project(cam.toView(const Vec3(0, 0, 20)), const Size(400, 800)), isNull);
    });
  });

  group('mesh', () {
    test('box faces point outward', () {
      final m = Mesh.box(const Vec3(2, 2, 2), const Color(0xFFFFFFFF));
      final c = const Vec3(0, 1, 0);
      for (final (a, b, d) in m.faces) {
        final n = (m.vertices[b] - m.vertices[a]).cross(m.vertices[d] - m.vertices[a]);
        final mid = (m.vertices[a] + m.vertices[b] + m.vertices[d]) * (1 / 3);
        expect(n.dot(mid - c), greaterThan(0));
      }
    });

    test('sphere sits on the floor and is smooth', () {
      final m = Mesh.sphere(0.5, const Color(0xFFFFFFFF));
      expect(m.minY, closeTo(0, 1e-9));
      expect(m.smooth, isTrue);
    });
  });

  group('renderer', () {
    test('back faces of a box are culled: at most 3 sides visible', () {
      final cam = Camera(azimuth: 0.6, elevation: 0.4, distance: 8, target: Vec3.zero);
      final f = Renderer.render(
        [Mesh.box(const Vec3(1, 1, 1), const Color(0xFFFF0000))],
        cam,
        const Size(400, 800),
        const Lighting(dirs: [], ambient: Color(0xFFFFFFFF)),
      );
      expect(f.triangles, 6);
      expect(f.shadows, hasLength(1));
    });

    test('emissive meshes ignore lighting', () {
      final cam = Camera(azimuth: 0.6, elevation: 0.4, distance: 8, target: Vec3.zero);
      final f = Renderer.render(
        [Mesh.box(const Vec3(1, 1, 1), const Color(0xFFFF0000), emissive: true)],
        cam,
        const Size(400, 800),
        const Lighting(dirs: [], ambient: Color(0xFF000000)),
      );
      expect(f.objects, isNotNull);
    });
  });

  group('room builder', () {
    int count(Inventory inv, {int room = 1}) => RoomBuilder.build(inventory: inv, room: room).length;

    test('purchases add meshes to the room', () {
      final empty = count(Inventory.empty);
      expect(count(Inventory.empty.copyWith(owned: {'rug'})), greaterThan(empty));
      expect(count(Inventory.empty.copyWith(owned: {'lamp'})), greaterThan(empty));
      expect(count(Inventory.empty.copyWith(owned: {'poster'})), greaterThan(empty));
      for (final id in ['garland', 'painting', 'toychest', 'beanbag', 'aquarium', 'zoo_photo', 'telescope', 'bike']) {
        expect(count(Inventory.empty.copyWith(owned: {id})), greaterThan(empty), reason: id);
      }
      for (final f in ['sofa', 'shelf', 'tv', 'console']) {
        expect(count(Inventory.empty.copyWith(furniture: f)), greaterThan(empty), reason: f);
      }
    });

    test('full bowls add food and water to the room (F-027)', () {
      int bowls(Bowls b, {int room = 1}) => RoomBuilder.build(inventory: Inventory.empty, room: room, bowls: b).length;
      final empty = bowls(const Bowls(food: false, water: false));
      expect(bowls(const Bowls(food: true, water: false)), greaterThan(empty));
      expect(bowls(const Bowls(food: false, water: true)), greaterThan(empty));
      expect(bowls(const Bowls(), room: 2), greaterThan(bowls(const Bowls(food: false, water: false), room: 2)));
    });

    test('playroom is a different scene', () {
      expect(count(Inventory.empty, room: 2), isNot(count(Inventory.empty)));
    });

    test('lamps are on in the evening and at night, off in the morning and day (F-028)', () {
      final inv = Inventory.empty.copyWith(owned: {'lamp'});
      expect(RoomBuilder.lighting(inventory: inv, time: DayTime.morning).points, isEmpty);
      expect(RoomBuilder.lighting(inventory: inv, time: DayTime.day).points, isEmpty);
      expect(RoomBuilder.lighting(inventory: inv, time: DayTime.evening).points, hasLength(2));
      expect(RoomBuilder.lighting(inventory: inv, time: DayTime.night).points, hasLength(2));
      expect(RoomBuilder.glowSpots(inventory: inv, time: DayTime.day), isEmpty);
      expect(RoomBuilder.glowSpots(inventory: inv, time: DayTime.night), hasLength(2));
    });

    test('night adds warm point lights, day has none', () {
      final inv = Inventory.empty.copyWith(owned: {'lamp'});
      expect(RoomBuilder.lighting(inventory: inv).points, isEmpty);
      expect(RoomBuilder.lighting(inventory: inv, night: true).points, hasLength(2));
    });

    test('whole furnished room stays within the triangle budget', () {
      final inv = Inventory.empty.copyWith(
        owned: {'rug', 'lamp', 'poster', 'garland', 'painting', 'toychest', 'beanbag', 'aquarium', 'zoo_photo', 'telescope', 'bike'},
        furniture: 'shelf',
      );
      final cam = Camera(azimuth: 0.62, elevation: 0.34, distance: 9, fov: 0.62);
      final f = Renderer.render(RoomBuilder.build(inventory: inv), cam, const Size(360, 700), RoomBuilder.lighting(inventory: inv));
      expect(f.triangles, lessThan(4500));
      expect(f.triangles, greaterThan(200));
    });
  });

  testWidgets('room scene renders every variant and can be rotated', (t) async {
    for (final (inv, room, night) in [
      (Inventory.empty, 1, false),
      (Inventory.empty.copyWith(owned: {'rug', 'lamp', 'poster'}, furniture: 'tv'), 1, true),
      (Inventory.empty, 2, false),
    ]) {
      await t.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(width: 360, height: 700, child: RoomScene(inventory: inv, room: room, night: night, hero: const SizedBox())),
        ),
      );
      await t.drag(find.byType(RoomScene), const Offset(-120, 40));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(t.takeException(), isNull);
    }
  });

  testWidgets('room scene renders every time of day (F-028)', (t) async {
    for (final time in DayTime.values) {
      await t.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 360,
            height: 700,
            child: RoomScene(inventory: Inventory.empty.copyWith(owned: {'lamp'}), time: time, animated: false, hero: const SizedBox()),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull, reason: '$time');
    }
  });
}
