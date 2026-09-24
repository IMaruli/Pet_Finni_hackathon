import 'dart:math';

import 'package:flutter/material.dart';

import '../../game/game_controller.dart';
import '../screens/night_screen.dart';
import '../screens/category_screen.dart';
import '../screens/plan_screen.dart';
import '../../game/quests.dart';
import '../lesson/lesson_screen.dart';
import '../screens/savings_screen.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/duo.dart';

/// Задания: 3 дня и 5 недели как квесты Duolingo, без монет сверху (SA F-026).
class TasksTab extends StatelessWidget {
  const TasksTab({super.key, required this.game});
  final GameController game;

  void _push(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final daily = game.dailyQuests;
    final weekly = game.weeklyQuests;
    final doneCount = daily.where((q) => q.$2.done).length;
    final good = game.economy.goodPeriods;
    final nextStageAt = good < 2 ? 2 : 4;
    final goal = game.goal;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          DuoHeader(
            title: 'Задания',
            subtitle: 'День ${game.day} · задания дня $doneCount из ${daily.length}',
            trailing: CoinChip(value: game.economy.available.value),
          ),
          GroupedSection(
            header: 'План',
            children: [
              GroupedRow(
                key: const Key('tasks.plan'),
                icon: Icons.pie_chart_rounded,
                iconColor: FinniColors.primary,
                title: 'План дня',
                subtitle: 'Все монеты — по трём банкам',
                done: game.planConfirmed,
                onTap: () => _push(context, PlanScreen(game: game)),
              ),
            ],
          ),
          const DuoSection('Задания дня'),
          for (final (id, p) in daily)
            _quest(
              context,
              key: 'tasks.q.${id.name}',
              title: game.content.text('quest.${id.name}'),
              progress: p,
              icon: _icon[id]!,
              onTap: () => id == QuestId.needs
                  ? _push(context, CategoryScreen(game: game, category: ShopCategory.needs))
                  : _push(context, LessonScreen(game: game, lesson: game.lessonFor(id))),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 2, 20, 0),
            child: Text('Задания ведут в урок. Монеты даёт сам урок — первый за день.', style: TextStyle(fontSize: 13, color: FinniColors.muted)),
          ),
          const DuoSection('Задания недели'),
          for (final (id, p) in weekly)
            _quest(
              context,
              key: 'tasks.w.${id.name}',
              title: game.content.text('weekly.${id.name}'),
              progress: p,
              icon: _weeklyIcon[id]!,
              onTap: () => id == WeeklyId.needs3
                  ? _push(context, CategoryScreen(game: game, category: ShopCategory.needs))
                  : _push(context, LessonScreen(game: game, lesson: game.recommendedLesson)),
            ),
          const DuoSection('Копилка и рост'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DuoCard(
              key: const Key('tasks.goal'),
              onTap: () => _push(context, SavingsScreen(game: game)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const IconTile(Icons.flag_rounded, color: FinniColors.save),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          goal == null ? 'Выбери цель копилки' : goal.title,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.4),
                        ),
                      ),
                      if (goal != null)
                        Text(
                          '${min(game.economy.savings.value, goal.cost)} / ${goal.cost}',
                          style: const TextStyle(fontSize: 15, color: FinniColors.muted, fontFeatures: [FontFeature.tabularFigures()]),
                        ),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFFC4C4C7)),
                    ],
                  ),
                  if (goal != null) ...[
                    const SizedBox(height: 12),
                    ProgressBar(value: game.economy.savings.value / goal.cost, color: FinniColors.save),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DuoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const IconTile(Icons.trending_up_rounded, color: FinniColors.need),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          game.stage >= 3 ? 'Герой — настоящий взрослый' : 'Рост героя',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.4),
                        ),
                      ),
                      if (game.stage < 3)
                        Text('$good / $nextStageAt', style: const TextStyle(fontSize: 15, color: FinniColors.muted)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Хороший день — нужное куплено и что-то отложено.',
                    style: TextStyle(fontSize: 13, color: FinniColors.muted),
                  ),
                  if (game.stage < 3) ...[
                    const SizedBox(height: 10),
                    ProgressBar(value: good / nextStageAt, color: FinniColors.need),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: DuoButton(
              key: const Key('tasks.sleep'),
              label: 'Завершить день',
              icon: Icons.bedtime_rounded,
              onPressed: () => goToSleep(context, game),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quest(
    BuildContext context, {
    required String key,
    required String title,
    required QuestProgress progress,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final done = progress.done;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: DuoCard(
        key: Key(key),
        padding: const EdgeInsets.all(14),
        onTap: done ? null : onTap,
        child: Row(
          children: [
            IconTile(done ? Icons.check_rounded : icon, color: done ? FinniColors.need : FinniColors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: ProgressBar(value: progress.ratio, color: done ? FinniColors.need : FinniColors.orange)),
                      const SizedBox(width: 10),
                      Text(
                        '${progress.value} / ${progress.target}',
                        style: const TextStyle(fontSize: 13, color: FinniColors.muted, fontFeatures: [FontFeature.tabularFigures()]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!done) const Icon(Icons.chevron_right_rounded, color: Color(0xFFC4C4C7)),
          ],
        ),
      ),
    );
  }
}

const _icon = {
  QuestId.lesson1: Icons.school_rounded,
  QuestId.lesson2: Icons.school_rounded,
  QuestId.min5: Icons.timer_rounded,
  QuestId.min10: Icons.timer_rounded,
  QuestId.review: Icons.replay_rounded,
  QuestId.newTopic: Icons.explore_rounded,
  QuestId.nextStep: Icons.alt_route_rounded,
  QuestId.sortStep: Icons.view_column_rounded,
  QuestId.needs: Icons.shopping_basket_rounded,
  QuestId.resume: Icons.play_arrow_rounded,
};

const _weeklyIcon = {
  WeeklyId.lessons8: Icons.school_rounded,
  WeeklyId.days4: Icons.calendar_month_rounded,
  WeeklyId.needs3: Icons.shopping_basket_rounded,
  WeeklyId.newTopics2: Icons.explore_rounded,
  WeeklyId.review3: Icons.replay_rounded,
};
