import 'package:finni/content/lesson_models.dart';
import 'package:finni/game/lesson_logic.dart';
import 'package:finni/game/quests.dart';
import 'package:finni/store/snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

LessonRun run(int day, {bool newTopic = false, bool review = false, List<String> kinds = const ['card'], bool resumed = false}) =>
    LessonRun(lessonId: 'x', day: day, newTopic: newTopic, review: review, kinds: kinds, resumed: resumed);

void main() {
  group('step checks (F-025)', () {
    const pick = PickStep(question: 'q', options: ['a', 'b', 'c'], answer: 1, why: 'w', hint: 'h');
    const sort = SortStep(
      prompt: 'p',
      bins: [(id: 'need', title: 'Нужное'), (id: 'want', title: 'Хотелка')],
      cards: [(text: 'Еда', bin: 'need'), (text: 'Наклейка', bin: 'want')],
      why: 'w',
      hint: 'h',
    );
    const pairs = PairsStep(prompt: 'p', pairs: [(left: 'Миска', right: 'Еда'), (left: 'Наклейка', right: 'Хотелка'), (left: 'Стакан', right: 'Вода')], why: 'w');
    const order = OrderStep(prompt: 'p', tiles: ['Сначала', 'нужное,', 'потом', 'хотелки'], extra: ['сразу'], why: 'w', hint: 'h');

    test('fill-in order: given words stay, only blanks are placed (F-063)', () {
      const fill = OrderStep(prompt: 'p', tiles: ['Сначала', 'нужное,', 'потом', 'хотелки'], extra: ['сразу'], why: 'w', hint: 'h', given: [0, 2]);
      expect(fill.blanks, [1, 3]);
      expect(blanksOk(fill, ['нужное,', 'хотелки']), isTrue);
      expect(blanksOk(fill, ['хотелки', 'нужное,']), isFalse);
      expect(blanksOk(fill, ['нужное,']), isFalse);
    });

    test('pick, sort, order', () {
      expect(pickOk(pick, 1), isTrue);
      expect(pickOk(pick, 0), isFalse);
      expect(sortOk(sort, 0, 'need'), isTrue);
      expect(sortOk(sort, 1, 'need'), isFalse);
      expect(orderOk(order, ['Сначала', 'нужное,', 'потом', 'хотелки']), isTrue);
      expect(orderOk(order, ['Сначала', 'потом', 'нужное,', 'хотелки']), isFalse);
      expect(orderOk(order, ['Сначала', 'нужное,', 'потом']), isFalse);
    });

    test('pairs: wrong pair explains without giving everything away', () {
      expect(pairOk(pairs, 1, 1), isTrue);
      expect(pairOk(pairs, 1, 0), isFalse);
      expect(pairMiss(pairs, 1, 0), 'Наклейка — хотелка, не еда.');
    });

    test('shuffle is a stable permutation that moves something', () {
      final a = shuffled(4, 7);
      expect(a.toSet(), {0, 1, 2, 3});
      expect(a, shuffled(4, 7));
      expect(a, isNot([0, 1, 2, 3]));
    });
  });

  group('daily quests (F-026)', () {
    test('three a day, never paired lessons or paired minutes', () {
      for (var day = 1; day <= 60; day++) {
        final q = pickDailyQuests(day: day, hasNewTopic: true, hasStarted: true);
        expect(q.length, 3, reason: 'day $day');
        expect(q.toSet().length, 3);
        expect(q.contains(QuestId.lesson1) && q.contains(QuestId.lesson2), isFalse, reason: 'day $day');
        expect(q.contains(QuestId.min5) && q.contains(QuestId.min10), isFalse, reason: 'day $day');
      }
    });

    test('new topic only while one is left, resume only if a lesson is started', () {
      for (var day = 1; day <= 60; day++) {
        final q = pickDailyQuests(day: day, hasNewTopic: false, hasStarted: false);
        expect(q, isNot(contains(QuestId.newTopic)));
        expect(q, isNot(contains(QuestId.resume)));
      }
    });

    test('same day, same quests', () {
      expect(pickDailyQuests(day: 3, hasNewTopic: true, hasStarted: false), pickDailyQuests(day: 3, hasNewTopic: true, hasStarted: false));
    });

    test('progress from facts', () {
      final f = LearnFacts(
        day: 2,
        runs: [run(1, newTopic: true), run(2, review: true, kinds: ['card', 'next', 'sort']), run(2, resumed: true)],
        learnSeconds: const {2: 320},
        needsDays: const [2],
      );
      expect(dailyProgress(QuestId.lesson1, f).done, isTrue);
      expect(dailyProgress(QuestId.lesson2, f).value, 2);
      expect(dailyProgress(QuestId.min5, f).done, isTrue);
      expect(dailyProgress(QuestId.min10, f).value, 5);
      expect(dailyProgress(QuestId.min10, f).target, 10);
      expect(dailyProgress(QuestId.review, f).done, isTrue);
      expect(dailyProgress(QuestId.newTopic, f).done, isFalse); // новая тема была вчера
      expect(dailyProgress(QuestId.nextStep, f).done, isTrue);
      expect(dailyProgress(QuestId.sortStep, f).done, isTrue);
      expect(dailyProgress(QuestId.needs, f).done, isTrue);
      expect(dailyProgress(QuestId.resume, f).done, isTrue);
    });
  });

  group('weekly quests (F-026)', () {
    test('a week is five game days', () {
      expect(weekOf(1), 0);
      expect(weekOf(5), 0);
      expect(weekOf(6), 1);
    });

    test('progress counts only this week', () {
      final f = LearnFacts(
        day: 7,
        runs: [run(4, newTopic: true), run(6, newTopic: true), run(7, review: true), run(7, review: true)],
        learnSeconds: const {6: 60, 7: 30, 3: 100},
        needsDays: const [5, 6, 7],
      );
      expect(weeklyProgress(WeeklyId.lessons8, f).value, 3);
      expect(weeklyProgress(WeeklyId.days4, f).value, 2);
      expect(weeklyProgress(WeeklyId.needs3, f).value, 2);
      expect(weeklyProgress(WeeklyId.newTopics2, f).value, 1);
      expect(weeklyProgress(WeeklyId.review3, f).value, 2);
      expect(weeklyProgress(WeeklyId.review3, f).target, 3);
    });
  });
}
