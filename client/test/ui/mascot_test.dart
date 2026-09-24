import 'dart:math';

import 'package:finni/content/models.dart';
import 'package:finni/economy/economy_state.dart';
import 'package:finni/game/pet_wish.dart';
import 'package:finni/ui/mascot/mascot_look.dart';
import 'package:finni/ui/mascot/mascot_view.dart';
import 'package:finni/ui/mascot/sphere.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const center = Offset(100, 100);

  group('sphere projection', () {
    test('front point sits in the center when facing the viewer', () {
      final p = projectLatLon(0, 0, const SpherePose(0, 0), center, 50);
      expect(p.offset.dx, closeTo(100, 1e-9));
      expect(p.offset.dy, closeTo(100, 1e-9));
      expect(p.z, closeTo(1, 1e-9));
      expect(p.visible, isTrue);
    });

    test('turning 90 degrees moves the face to the edge', () {
      final p = projectLatLon(0, 0, const SpherePose(pi / 2, 0), center, 50);
      expect(p.offset.dx, closeTo(150, 1e-9));
      expect(p.z, closeTo(0, 1e-9));
    });

    test('back of the sphere is hidden', () {
      expect(projectLatLon(0, pi, const SpherePose(0, 0), center, 50).visible, isFalse);
    });

    test('north pole is up on screen', () {
      final p = projectLatLon(pi / 2, 0, const SpherePose(0, 0), center, 50);
      expect(p.offset.dy, closeTo(50, 1e-9));
    });

    test('pitch tilts the face down', () {
      final p = projectLatLon(0, 0, const SpherePose(0, 0.3), center, 50);
      expect(p.offset.dy, greaterThan(100));
    });

    test('lift pushes points outside the surface', () {
      final p = projectLatLon(0, pi / 2, const SpherePose(0, 0), center, 50, lift: 1.2);
      expect(p.offset.dx, closeTo(160, 1e-9));
    });
  });

  test('stage changes scale: little, grown-up, adult', () {
    MascotLook at(int s) => MascotLook(color: Colors.yellow, hair: 'tuft', mood: PetMood.steady, stage: s);
    expect(at(1).scale, lessThan(at(2).scale));
    expect(at(2).scale, lessThan(at(3).scale));
  });

  testWidgets('every look, mood, stage and accessory renders', (tester) async {
    const hairs = ['tuft', 'bangs', 'buns', 'unknown'];
    for (final hair in hairs) {
      for (final mood in PetMood.values) {
        for (var stage = 1; stage <= 3; stage++) {
          for (final skin in [null, 'finik', 'cat', 'bunny', 'monkey']) {
            await tester.pumpWidget(
              MaterialApp(
                home: MascotView(
                  look: MascotLook(
                    color: const Color(0xFFFFCC33),
                    hair: hair,
                    skin: skin,
                    accessories: const {'bandana', 'glasses', 'bow', 'headphones', 'cap', 'crown', 'scarf', 'bowtie', 'partyhat', 'flower', 'nope'},
                    mood: mood,
                    stage: stage,
                  ),
                  animated: false,
                ),
              ),
            );
            expect(tester.takeException(), isNull);
          }
        }
      }
    }
  });

  testWidgets('animated mascot jumps, shakes and dances without errors', (tester) async {
    final controller = MascotController();
    final look = MascotLook.fromLook(
      const Look(id: 'x', title: 'x', color: 0xFFFFCC33, hair: 'tuft'),
      mood: PetMood.glad,
      stage: 2,
    );
    await tester.pumpWidget(MaterialApp(home: Center(child: MascotView(look: look, controller: controller))));
    controller.jump();
    await tester.pump(const Duration(milliseconds: 300));
    controller.shake();
    await tester.pump(const Duration(milliseconds: 300));
    controller.dance();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.drag(find.byType(MascotView), const Offset(80, 0));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byType(MascotView));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel(RegExp('радуется')), findsOneWidget);
  });

  testWidgets('every emotion renders, animated and static', (tester) async {
    for (final e in PetEmotion.values) {
      for (final animated in [false, true]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: MascotView(
                look: MascotLook(color: const Color(0xFFFFCC33), hair: 'tuft', mood: PetMood.steady, stage: 2, emotion: e, grubby: animated),
                animated: animated,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 3));
        expect(tester.takeException(), isNull, reason: '$e');
      }
    }
  });

  testWidgets('every treat joy renders around the hero (F-031)', (tester) async {
    for (final joy in ['hearts', 'sparkles', 'bubbles', 'balloon', 'notes', 'stars']) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: MascotView(look: MascotLook(color: const Color(0xFFFFCC33), hair: 'tuft', mood: PetMood.glad, stage: 2, joy: joy)),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull, reason: joy);
    }
  });
}
