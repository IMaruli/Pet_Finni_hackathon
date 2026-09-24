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
              const Center(child: IconTile(Icons.warning_amber_rounded, color: FinniColors.orange, size: 52)),
              const SizedBox(height: 12),
              Text('Снять $amount из копилки?', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
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
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: DuoCard(
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: JarView(
                                  title: 'Копилка',
                                  emoji: '🐷',
                                  color: FinniColors.save,
                                  coins: saved,
                                  capacity: goal?.cost ?? max(50, saved),
                                  height: 170,
                                ),
                              ),
                              SizedBox(width: 130, height: 150, child: MascotView(look: MascotLook.fromGame(game), controller: _mascot, size: 130)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (goal != null) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: Text(goal.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                                ),
                                Text('${min(saved, goal.cost)} / ${goal.cost}', style: const TextStyle(fontSize: 15, color: FinniColors.muted)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ProgressBar(value: saved / goal.cost, color: FinniColors.save),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                game.canRedeem
                                    ? 'Накоплено — можно забирать'
                                    : 'осталось ${game.goalRemaining} · примерно ${(game.goalRemaining / 5).ceil()} дн. по 5 монет',
                                style: const TextStyle(fontSize: 13, color: FinniColors.muted),
                              ),
                            ),
                            if (game.canRedeem) ...[
                              const SizedBox(height: 12),
                              DuoButton(key: const Key('goal.redeem'), label: 'Забрать: ${goal.title}', icon: Icons.celebration_rounded, color: FinniColors.need, onPressed: _redeem),
                            ],
                          ] else
                            const Text('Выбери цель ниже — и копилка станет мечтой.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: FinniColors.muted)),
                        ],
                      ),
                    ),
                  ),
                  const DuoSection('Отложить из кошелька'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        for (final a in [1, 5, 10]) ...[
                          Expanded(
                            child: DuoButton(
                              key: Key('save.$a'),
                              label: '+$a',
                              height: 44,
                              color: FinniColors.surface,
                              onPressed: wallet >= a ? () => _save(a) : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (planLeft > 0)
                          Expanded(
                            flex: 2,
                            child: DuoButton(
                              key: const Key('save.plan'),
                              label: 'По плану +$planLeft',
                              height: 44,
                              onPressed: wallet >= planLeft ? () => _save(planLeft) : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (saved > 0)
                    GroupedSection(
                      header: 'Снять из копилки',
                      footer: 'Цель отодвинется. Мы спросим ещё раз перед снятием.',
                      children: [
                        for (final a in [5, 10])
                          if (saved >= a)
                            GroupedRow(
                              key: Key('withdraw.$a'),
                              icon: Icons.remove_circle_outline_rounded,
                              iconColor: FinniColors.orange,
                              title: 'Снять $a',
                              onTap: () => _withdraw(a),
                            ),
                      ],
                    ),
                  GroupedSection(
                    header: 'Цели',
                    children: [for (final g in game.content.goals) _goalCard(g)],
                  ),
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
    return GroupedRow(
      key: Key('goal.${g.id}'),
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: FinniColors.fill, borderRadius: BorderRadius.circular(10)),
        child: Text(option?.emoji ?? g.emoji, style: const TextStyle(fontSize: 22)),
      ),
      title: option == null ? g.title : '${g.title}: ${option.title}',
      subtitle: g.description,
      trailing: done
          ? const Icon(Icons.check_circle_rounded, color: FinniColors.need)
          : selected
          ? const DuoChip(text: 'Копим', color: FinniColors.save)
          : Text('${g.cost}', style: const TextStyle(fontSize: 17, color: FinniColors.muted)),
      chevron: !done && !selected,
      onTap: done || selected ? null : () => _choose(g),
    );
  }
}
