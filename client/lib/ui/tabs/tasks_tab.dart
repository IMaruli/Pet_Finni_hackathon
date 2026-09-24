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

/// Задания (Figma 04): «Сегодня» и «На неделю» (SA F-017 BR-08).
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
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          DuoHeader(
            title: 'Задания',
            subtitle: 'День ${game.day} · сегодня и на неделю',
            trailing: CoinChip(value: game.economy.available.value),
          ),
          const DuoSection('Сегодня'),
          _row(
            context,
            key: 'tasks.plan',
            emoji: '🫙',
            color: FinniColors.primary,
            title: 'План дня',
            subtitle: 'Разложи монеты по трём банкам',
            done: game.planConfirmed,
            tag: 'сначала',
            onTap: () => _push(context, PlanScreen(game: game)),
          ),
          _row(
            context,
            key: 'tasks.needs',
            emoji: '🥣',
            color: FinniColors.orange,
            title: 'Закрыть нужное',
            subtitle: game.todaysNeeds.map((i) => '${i.emoji} ${i.title.toLowerCase()}').join(' · '),
            done: game.needsDone,
            tag: '${game.todaysNeedSum} 🪙',
            onTap: () => ShellScope.go(context, ShellTab.shop),
          ),
          _row(
            context,
            key: 'tasks.quest',
            emoji: '📜',
            color: FinniColors.teal,
            title: 'Квест: ${game.todaysQuest.title}',
            subtitle: 'Сцена с выбором',
            done: game.questDoneToday,
            tag: '+$reward',
            onTap: () => _push(context, QuestScreen(game: game)),
          ),
          _row(
            context,
            key: 'tasks.game',
            emoji: '🎮',
            color: FinniColors.blue,
            title: 'Игра дня',
            subtitle: 'Любая из игротеки',
            done: game.gameRewardToday,
            tag: '+$reward',
            onTap: () => ShellScope.go(context, ShellTab.games),
          ),
          _row(
            context,
            key: 'tasks.save',
            emoji: '🐷',
            color: FinniColors.save,
            title: 'Отложить в копилку',
            subtitle: plan == null ? 'Сколько — решишь в плане' : 'По плану ${plan.save.value}, отложено $savedToday',
            done: plan != null && savedToday > 0 && savedToday >= plan.save.value,
            tag: 'копилка',
            onTap: () => _push(context, SavingsScreen(game: game)),
          ),
          const DuoSection('На неделю', color: FinniColors.orange),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: DuoCard(
              key: const Key('tasks.goal'),
              onTap: () => _push(context, SavingsScreen(game: game)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal == null ? '🎯 Выбери цель копилки' : '${goal.emoji} Цель: ${goal.title.toLowerCase()}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  if (goal != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${min(game.economy.savings.value, goal.cost)} / ${goal.cost}',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: FinniColors.teal),
                    ),
                    const SizedBox(height: 8),
                    ProgressBar(value: game.economy.savings.value / goal.cost, color: FinniColors.teal),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: DuoCard(
              child: Row(
                children: [
                  const Text('🌱', style: TextStyle(fontSize: 30)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.stage >= 3 ? 'Герой — настоящий взрослый!' : 'Хорошие дни до роста',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                        ),
                        const Text('Нужное куплено + что-то отложено', style: TextStyle(color: FinniColors.muted)),
                        if (game.stage < 3) ...[
                          const SizedBox(height: 8),
                          ProgressBar(value: good / nextStageAt, color: FinniColors.orange),
                        ],
                      ],
                    ),
                  ),
                  if (game.stage < 3) ...[
                    const SizedBox(width: 10),
                    DuoChip(text: '$good / $nextStageAt', color: FinniColors.orange),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: DuoButton(
              key: const Key('tasks.sleep'),
              label: 'Закончить день',
              emoji: '🌙',
              color: const Color(0xFF6C74C9),
              onPressed: () => goToSleep(context, game),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required String key,
    required String emoji,
    required Color color,
    required String title,
    required String subtitle,
    required bool done,
    required String tag,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: DuoCard(
        key: Key(key),
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color.withValues(alpha: done ? 0.15 : 0.3), shape: BoxShape.circle),
              child: Text(done ? '✅' : emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: FinniColors.muted)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      DuoChip(text: done ? 'сделано' : 'доступно', color: done ? FinniColors.need : FinniColors.teal),
                      DuoChip(text: tag, color: FinniColors.coin),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: FinniColors.muted),
          ],
        ),
      ),
    );
  }
}
