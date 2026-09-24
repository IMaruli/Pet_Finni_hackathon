import 'dart:convert';
import 'dart:io';

import 'package:finni/content/content_loader.dart';
import 'package:finni/content/game_content.dart';
import 'package:finni/game/game_controller.dart';
import 'package:finni/store/profile_store.dart';
import 'package:finni/ui/lesson/lesson_screen.dart';
import 'package:finni/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lesson_helpers.dart';

final content = GameContent.fromJson({
  for (final name in ContentLoader.files) name: jsonDecode(File('assets/content/$name.json').readAsStringSync()),
});

void main() {
  late GameController game;

  Future<void> open(WidgetTester t, String lessonId) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const SizedBox()); // чистый экран между уроками
    game = GameController(content: content, store: MemoryProfileStore(), newId: () => 'id');
    await game.init();
    await game.createProfile(playerName: 'Аня', petName: 'Финя', lookId: 'sun_tuft');
    await t.pumpWidget(
      MaterialApp(
        theme: finniTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open'),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LessonScreen(game: game, lesson: content.lesson(lessonId)))),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.byKey(const Key('open')));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('card, sort with demo, next, order — with mistakes, at 360dp', (t) async {
    await open(t, 'needs_1');
    await playLesson(t, content.lesson('needs_1'), mistakes: true);
    expect(find.text('Урок пройден!'), findsOneWidget);
    expect(find.text('+12 за урок'), findsOneWidget);
    expect(game.isLessonDone('needs_1'), isTrue);
    expect(t.takeException(), isNull);
  });

  testWidgets('pairs and pick — with mistakes', (t) async {
    await open(t, 'smart_1');
    await playLesson(t, content.lesson('smart_1'), mistakes: true);
    expect(find.text('Урок пройден!'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('every lesson in the pack can be finished', (t) async {
    for (final l in content.lessons) {
      await open(t, l.id);
      await playLesson(t, l);
      expect(find.text('Урок пройден!'), findsOneWidget, reason: l.id);
      expect(t.takeException(), isNull, reason: l.id);
    }
  });

  testWidgets('× keeps the step, reopening continues there', (t) async {
    await open(t, 'needs_1');
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.tap(find.byKey(const Key('lesson.check')));
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.tap(find.byKey(const Key('lesson.close')));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(game.lessonProgress!.step, 1);
    await t.tap(find.byKey(const Key('open')));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Смотри, как раскладывают'), findsOneWidget);
  });
}
