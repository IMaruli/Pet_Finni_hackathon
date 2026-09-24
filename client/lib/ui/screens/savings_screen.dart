import 'dart:math';

import 'package:flutter/material.dart';

import '../../content/models.dart';
import '../../game/game_controller.dart';
import '../mascot/mascot_look.dart';
import '../mascot/mascot_view.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/duo.dart';
import '../widgets/confetti.dart';
import '../widgets/jar_view.dart';

/// Копилка и цели (SA F-014).
class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key, required this.game});
  final GameController game;

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final _mascot = MascotController();
  final _confetti = ConfettiController();
  final _scroll = ScrollController();

  GameController get game => widget.game;

  @override
  void dispose() {
    _mascot.dispose();
    _confetti.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _save(int amount) async {
    final f = await game.toSavings(amount);
    if (!mounted) return;
    if (f.ok) {
      _mascot.jump();
      buzz(Buzz.light);
    } else {
      _mascot.shake();
    }
    showToast(context, f.messages, emoji: f.ok ? '🐷' : '😮', color: f.ok ? FinniColors.save : null);
  }

  Future<void> _withdraw(int amount) async {
    final goal = game.goal;
    final before = game.economy.savings.value;
    final f = await game.requestWithdraw(amount);
    if (!mounted) return;
    if (!f.ok) {
      showToast(context, f.messages, emoji: '🤔');
      return;
    }
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('⚠️', textAlign: TextAlign.center, style: TextStyle(fontSize: 44)),
              Text('Снять $amount 🪙 из копилки?', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Panel(
                padding: const EdgeInsets.all(12),
                child: Text(
                  goal == null
                      ? 'В копилке было $before, станет ${before - amount}.'
                      : 'Цель «${goal.title}» отодвинется:\nбыло $before из ${goal.cost}, станет ${before - amount} из ${goal.cost}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 16),
              DuoButton(
                key: const Key('withdraw.keep'),
                label: 'Оставить в копилке',
                color: FinniColors.teal,
                onPressed: () => Navigator.of(sheet).pop(false),
              ),
              const SizedBox(height: 10),
              DuoButton(
                key: const Key('withdraw.confirm'),
                label: 'Да, снять',
                color: FinniColors.surface,
                onPressed: () => Navigator.of(sheet).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) {
      final done = await game.confirmWithdraw();
      if (mounted) showToast(context, done.messages, emoji: '👛');
    } else {
      await game.cancelWithdraw();
      if (mounted) showToast(context, const ['Копилка не тронута. Цель ждёт!'], emoji: '🐷', color: FinniColors.save);
    }
  }

  Future<void> _redeem() async {
    final goal = game.goal!;
    final f = await game.redeemGoal();
    if (!mounted) return;
    if (f.ok) {
      _confetti.fire();
      _mascot.dance();
      buzz(Buzz.heavy);
      showToast(context, [...f.messages, '${goal.emoji} ${goal.title} — теперь в доме!'], emoji: '🎉', color: FinniColors.need);
    } else {
      showToast(context, f.messages, emoji: '⏳');
    }
  }

  Future<void> _choose(GoalDef goal, {String? option}) async {
    if (goal.reward == GoalReward.furniture && option == null) {
      option = await showModalBottomSheet<String>(
        context: context,
        builder: (sheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Какую вещь хочешь?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final o in goal.options)
                      ActionChip(
                        key: Key('goal.option.${o.id}'),
                        avatar: Text(o.emoji, style: const TextStyle(fontSize: 22)),
                        label: Text(o.title, style: const TextStyle(fontSize: 16)),
                        onPressed: () => Navigator.of(sheet).pop(o.id),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      if (option == null) return;
    }
    final f = await game.chooseGoal(goal.id, option: option);
    if (!mounted) return;
    showToast(context, f.messages, emoji: goal.emoji);
    if (f.ok && _scroll.hasClients) {
      _mascot.jump();
      await _scroll.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final goal = game.goal;
        final saved = game.economy.savings.value;
        final wallet = game.economy.available.value;
        final plan = game.economy.plan;
        final planLeft = plan == null ? 0 : max(0, plan.save.value - game.economy.savedThisPeriod.value);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Копилка'),
            actions: [Padding(padding: const EdgeInsets.only(right: 12), child: CoinChip(value: wallet))],
          ),
          body: ConfettiBurst(
            controller: _confetti,
            child: SafeArea(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            if (goal != null) Text(goal.emoji, style: const TextStyle(fontSize: 44)),
                            JarView(
                              title: 'Копилка',
                              emoji: '🐷',
                              color: FinniColors.save,
                              coins: saved,
                              capacity: goal?.cost ?? max(50, saved),
                              height: 190,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 130, height: 150, child: MascotView(look: MascotLook.fromGame(game), controller: _mascot, size: 130)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (goal != null) ...[
                    Text('Цель: ${goal.title}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ProgressBar(value: saved / goal.cost, color: FinniColors.save, height: 18),
                    const SizedBox(height: 6),
                    Text(
                      game.canRedeem
                          ? 'Накоплено! Можно забирать 🎉'
                          : '${min(saved, goal.cost)} из ${goal.cost} · осталось ${game.goalRemaining} · '
                                '≈ ${(game.goalRemaining / 5).ceil()} дн., если откладывать по 5',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: FinniColors.muted, fontWeight: FontWeight.w600),
                    ),
                    if (game.canRedeem) ...[
                      const SizedBox(height: 10),
                      DuoButton(
                        key: const Key('goal.redeem'),
                        label: 'Забрать: ${goal.title} 🎉',
                        color: FinniColors.need,
                        onPressed: _redeem,
                      ),
                    ],
                  ] else
                    const Text('Выбери цель ниже — и копилка станет мечтой.', textAlign: TextAlign.center, style: TextStyle(fontSize: 17)),
                  const SizedBox(height: 16),
                  const Text('Отложить из кошелька', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final a in [1, 5, 10])
                        DuoButton(
                          key: Key('save.$a'),
                          label: '+$a 🪙',
                          expand: false,
                          height: 48,
                          color: FinniColors.primary,
                          onPressed: wallet >= a ? () => _save(a) : null,
                        ),
                      if (planLeft > 0)
                        DuoButton(
                          key: const Key('save.plan'),
                          label: 'По плану: +$planLeft',
                          expand: false,
                          height: 48,
                          color: FinniColors.save,
                          onPressed: wallet >= planLeft ? () => _save(planLeft) : null,
                        ),
                    ],
                  ),
                  if (saved > 0) ...[
                    const SizedBox(height: 16),
                    const Text('Снять из копилки', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text('Можно, но цель отодвинется. Мы спросим дважды.', style: TextStyle(color: FinniColors.muted)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final a in [5, 10])
                          if (saved >= a)
                            DuoButton(key: Key('withdraw.$a'), label: 'Снять $a', expand: false, height: 44, color: FinniColors.surface, onPressed: () => _withdraw(a)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text('Цели', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  for (final g in game.content.goals) _goalCard(g),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _goalCard(GoalDef g) {
    final done = game.inventory.goalsDone.contains(g.id);
    final selected = game.snapshot.goalId == g.id;
    final option = selected && game.snapshot.goalOption != null
        ? g.options.firstWhere((o) => o.id == game.snapshot.goalOption)
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        key: Key('goal.${g.id}'),
        color: selected ? const Color(0xFFE8F0FF) : null,
        onTap: done || selected ? null : () => _choose(g),
        child: Row(
          children: [
            Text(option?.emoji ?? g.emoji, style: const TextStyle(fontSize: 38)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option == null ? g.title : '${g.title}: ${option.title}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  Text(g.description, style: const TextStyle(color: FinniColors.muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              done ? 'Есть ✓' : (selected ? 'Копим' : '${g.cost} 🪙'),
              style: TextStyle(fontWeight: FontWeight.w700, color: done ? FinniColors.need : FinniColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}
