import 'dart:math';

import 'package:flutter/material.dart';

import '../../game/game_controller.dart';
import '../screens/night_screen.dart';
import '../screens/plan_screen.dart';
import '../screens/quest_screen.dart';
import '../screens/savings_screen.dart';
import '../shell/main_shell.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/duo.dart';

/// Задания (Figma 04): «Сегодня» и «На неделю» (SA F-017 BR-08, F-018 BR-06).
class TasksTab extends StatelessWidget {
  const TasksTab({super.key, required this.game});
  final GameController game;

  void _push(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final reward = game.content.config.rewardWise;
    final plan = game.economy.plan;
    final savedToday = game.economy.savedThisPeriod.value;
    final good = game.economy.goodPeriods;
    final nextStageAt = good < 2 ? 2 : 4;
    final goal = game.goal;
    final doneCount = [
      game.planConfirmed,
      game.needsDone,
      game.questDoneToday,
      game.gameRewardToday,
      savedToday > 0,
    ].where((d) => d).length;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          DuoHeader(
            title: 'Задания',
            subtitle: 'День ${game.day} · выполнено $doneCount из 5',
            trailing: CoinChip(value: game.economy.available.value),
          ),
          GroupedSection(
            header: 'Сегодня',
            children: [
              GroupedRow(
                key: const Key('tasks.plan'),
                icon: Icons.pie_chart_rounded,
                iconColor: FinniColors.primary,
                title: 'План дня',
                subtitle: 'Три банки: нужное, хочу, отложить',
                done: game.planConfirmed,
                onTap: () => _push(context, PlanScreen(game: game)),
              ),
              GroupedRow(
                key: const Key('tasks.needs'),
                icon: Icons.shopping_basket_rounded,
                iconColor: FinniColors.need,
                title: 'Купить нужное',
                subtitle: game.todaysNeeds.map((i) => i.title.toLowerCase()).join(', '),
                value: '${game.todaysNeedSum}',
                done: game.needsDone,
                onTap: () => ShellScope.go(context, ShellTab.shop),
              ),
              GroupedRow(
                key: const Key('tasks.quest'),
                icon: Icons.auto_stories_rounded,
                iconColor: FinniColors.orange,
                title: 'Квест дня',
                subtitle: game.todaysQuest.title,
                trailing: game.questDoneToday ? null : DuoChip(text: '+$reward', color: FinniColors.coin),
                done: game.questDoneToday,
                onTap: () => _push(context, QuestScreen(game: game)),
              ),
              GroupedRow(
                key: const Key('tasks.game'),
                icon: Icons.sports_esports_rounded,
                iconColor: FinniColors.blue,
                title: 'Игра дня',
                subtitle: 'Любая из раздела «Игры»',
                trailing: game.gameRewardToday ? null : DuoChip(text: '+$reward', color: FinniColors.coin),
                done: game.gameRewardToday,
                onTap: () => ShellScope.go(context, ShellTab.games),
              ),
              GroupedRow(
                key: const Key('tasks.save'),
                icon: Icons.savings_rounded,
                iconColor: FinniColors.teal,
                title: 'Отложить в копилку',
                subtitle: plan == null ? 'Сумму решишь в плане' : 'По плану ${plan.save.value}, отложено $savedToday',
                done: plan != null && savedToday > 0 && savedToday >= plan.save.value,
                onTap: () => _push(context, SavingsScreen(game: game)),
              ),
            ],
          ),
          const DuoSection('На неделю'),
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
}
