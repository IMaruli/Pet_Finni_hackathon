import 'package:finni/content/lesson_models.dart';
import 'package:finni/ui/lesson/lesson_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _frames(WidgetTester t, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pump();
  await t.tap(f);
  await _frames(t);
}

Future<void> _key(WidgetTester t, String key) => _tap(t, find.byKey(Key(key)));

/// Проходит урок до экрана итога. [mistakes] — сначала ошибиться там, где можно (SA F-025 F-01).
Future<void> playLesson(WidgetTester t, Lesson lesson, {bool mistakes = false}) async {
  for (final step in lesson.steps) {
    switch (step) {
      case CardStep():
        await _frames(t, 10); // пауза перед «Дальше»
        await _key(t, 'lesson.check');
      case PickStep(:final options, :final answer):
        if (mistakes) {
          await _key(t, 'pick.${(answer + 1) % options.length}');
          await _key(t, 'lesson.check');
          expect(find.byKey(const Key('lesson.retry')), findsOneWidget);
          await _key(t, 'lesson.retry');
        }
        await _key(t, 'pick.$answer');
        await _key(t, 'lesson.check');
        await _key(t, 'lesson.next');
      case SortStep(:final cards, :final bins, :final demo):
        if (demo) await _key(t, 'lesson.check'); // «Теперь я»
        if (mistakes) {
          final wrong = bins.firstWhere((b) => b.id != cards.first.bin).id;
          for (final (i, c) in cards.indexed) {
            await _key(t, 'sort.card.$i');
            await _key(t, 'sort.bin.${i == 0 ? wrong : c.bin}');
          }
          await _key(t, 'lesson.check');
          expect(find.byKey(const Key('lesson.retry')), findsOneWidget);
          expect(find.byKey(const Key('sort.card.0')), findsOneWidget); // неверная выпала обратно
          await _key(t, 'lesson.retry');
          await _key(t, 'sort.card.0');
          await _key(t, 'sort.bin.${cards.first.bin}');
        } else {
          for (final (i, c) in cards.indexed) {
            await _key(t, 'sort.card.$i');
            await _key(t, 'sort.bin.${c.bin}');
          }
        }
        await _key(t, 'lesson.check');
        await _key(t, 'lesson.next');
      case PairsStep(:final pairs):
        if (mistakes) {
          await _key(t, 'pairs.left.0');
          await _key(t, 'pairs.right.1');
          expect(find.text('Эта пара не сошлась'), findsOneWidget);
          await _key(t, 'lesson.retry');
        }
        for (var i = 0; i < pairs.length; i++) {
          await _key(t, 'pairs.left.$i');
          await _key(t, 'pairs.right.$i');
        }
        await _key(t, 'lesson.next');
      case OrderStep(:final tiles):
        for (final w in tiles) {
          await _tap(t, find.widgetWithText(LessonTile, w).last);
        }
        await _key(t, 'lesson.check');
        await _key(t, 'lesson.next');
      case NextStep(:final outcomes):
        final bad = outcomes.indexWhere((o) => !o.good);
        if (mistakes && bad >= 0) {
          await _key(t, 'next.outcome.$bad');
          await _key(t, 'lesson.check');
          expect(find.text(outcomes[bad].result.replaceAll('{pet}', 'Финя')), findsOneWidget); // последствие
          await _key(t, 'lesson.retry'); // «Выбрать снова»
        }
        await _key(t, 'next.outcome.${outcomes.indexWhere((o) => o.good)}');
        await _key(t, 'lesson.check');
        await _key(t, 'lesson.next');
    }
  }
  await _frames(t, 10);
}
