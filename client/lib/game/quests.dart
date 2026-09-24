import 'dart:math';

import '../store/snapshot.dart';

/// Задания дня и недели как квесты Duolingo: ведут в урок, монет не платят (SA F-026).

enum QuestId { lesson1, lesson2, min5, min10, review, newTopic, nextStep, sortStep, needs, resume }

enum WeeklyId { lessons8, days4, needs3, newTopics2, review3 }

final class QuestProgress {
  const QuestProgress(this.value, this.target);
  final int value;
  final int target;
  bool get done => value >= target;
  double get ratio => target == 0 ? 1 : (value / target).clamp(0, 1);
}

/// Всё, из чего считается прогресс.
final class LearnFacts {
  const LearnFacts({required this.day, required this.runs, required this.learnSeconds, required this.needsDays});
  final int day;
  final List<LessonRun> runs;
  final Map<int, int> learnSeconds;
  final List<int> needsDays;
}

/// Неделя — пять игровых дней демо.
int weekOf(int day) => (day - 1) ~/ 5;

const _exclusive = [
  {QuestId.lesson1, QuestId.lesson2},
  {QuestId.min5, QuestId.min10},
];

/// Три задания дня (BR-02): детерминированы днём, без запрещённых пар.
List<QuestId> pickDailyQuests({required int day, required bool hasNewTopic, required bool hasStarted}) {
  final pool = [
    for (final q in QuestId.values)
      if (!(q == QuestId.newTopic && !hasNewTopic) && !(q == QuestId.resume && !hasStarted)) q,
  ]..shuffle(Random(day * 7919));
  final picked = <QuestId>[];
  for (final q in pool) {
    if (picked.length == 3) break;
    final clash = _exclusive.any((pair) => pair.contains(q) && picked.any(pair.contains));
    if (!clash) picked.add(q);
  }
  return picked;
}

QuestProgress dailyProgress(QuestId id, LearnFacts f) {
  final today = [
    for (final r in f.runs)
      if (r.day == f.day) r,
  ];
  final minutes = (f.learnSeconds[f.day] ?? 0) ~/ 60;
  int any(bool Function(LessonRun r) test) => today.any(test) ? 1 : 0;
  return switch (id) {
    QuestId.lesson1 => QuestProgress(min(today.length, 1), 1),
    QuestId.lesson2 => QuestProgress(min(today.length, 2), 2),
    QuestId.min5 => QuestProgress(min(minutes, 5), 5),
    QuestId.min10 => QuestProgress(min(minutes, 10), 10),
    QuestId.review => QuestProgress(any((r) => r.review), 1),
    QuestId.newTopic => QuestProgress(any((r) => r.newTopic), 1),
    QuestId.nextStep => QuestProgress(any((r) => r.kinds.contains('next')), 1),
    QuestId.sortStep => QuestProgress(any((r) => r.kinds.contains('sort')), 1),
    QuestId.needs => QuestProgress(f.needsDays.contains(f.day) ? 1 : 0, 1),
    QuestId.resume => QuestProgress(any((r) => r.resumed), 1),
  };
}

QuestProgress weeklyProgress(WeeklyId id, LearnFacts f) {
  final week = weekOf(f.day);
  bool inWeek(int day) => weekOf(day) == week && day <= f.day;
  final runs = [
    for (final r in f.runs)
      if (inWeek(r.day)) r,
  ];
  final learnDays = {
    for (final r in runs) r.day,
    for (final e in f.learnSeconds.entries)
      if (inWeek(e.key) && e.value > 0) e.key,
  };
  return switch (id) {
    WeeklyId.lessons8 => QuestProgress(min(runs.length, 8), 8),
    WeeklyId.days4 => QuestProgress(min(learnDays.length, 4), 4),
    WeeklyId.needs3 => QuestProgress(min(f.needsDays.where(inWeek).toSet().length, 3), 3),
    WeeklyId.newTopics2 => QuestProgress(min(runs.where((r) => r.newTopic).length, 2), 2),
    WeeklyId.review3 => QuestProgress(min(runs.where((r) => r.review).length, 3), 3),
  };
}
