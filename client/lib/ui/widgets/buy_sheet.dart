import 'package:flutter/material.dart';

import '../../content/models.dart';
import '../../economy/catalog_item.dart';
import '../../game/game_controller.dart';
import '../../game/game_feedback.dart';
import '../mascot/mascot_look.dart';
import '../mascot/mascot_view.dart';
import '../screens/plan_screen.dart';
import '../screens/quest_screen.dart';
import '../shell/main_shell.dart';
import '../theme.dart';
import 'common.dart';
import 'duo.dart';

String itemSubtitle(ShopItem item) => switch ((item.kind, item.slot)) {
  (ItemKind.need, _) => 'нужное · на сегодня',
  (_, ItemSlot.hero) => 'хочу · на героя',
  (_, ItemSlot.room) => 'хочу · в комнату',
  _ => 'хочу · съесть',
};

/// Покупка с подтверждением, отказом и путями восстановления (SA F-011).
/// [mascot] реагирует прыжком или «ой».
Future<void> buyFlow(BuildContext context, GameController game, ShopItem item, {MascotController? mascot}) async {
  if (!game.planConfirmed) {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => _Sheet(
        emoji: '🫙',
        title: 'Сначала план',
        text: game.content.text('exp.need_plan'),
        actions: [
          DuoButton(
            label: 'Разложить монеты',
            onPressed: () {
              Navigator.of(sheet).pop();
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlanScreen(game: game)));
            },
          ),
        ],
      ),
    );
    return;
  }
  final result = await showModalBottomSheet<GameFeedback>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _BuySheet(game: game, item: item),
  );
  if (!context.mounted || result == null) return;
  if (result.ok) {
    mascot?.jump();
    buzz(Buzz.medium);
    showToast(context, result.messages, emoji: item.emoji, color: basketOf(item.kind).color);
  } else if (result.reason == FeedbackReason.insufficient) {
    mascot?.shake();
    buzz(Buzz.heavy);
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => _Sheet(
        emoji: '😮',
        title: 'Не хватает ${result.missing} 🪙',
        text: 'Монеты не списаны. Что можно сделать:',
        actions: [
          DuoButton(
            label: 'Заработать заданием',
            icon: Icons.auto_stories_rounded,
            color: FinniColors.teal,
            onPressed: () {
              Navigator.of(sheet).pop();
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => QuestScreen(game: game)));
            },
          ),
          const SizedBox(height: 10),
          DuoButton(
            label: 'Сыграть в игру',
            icon: Icons.sports_esports_rounded,
            color: FinniColors.blue,
            onPressed: () {
              Navigator.of(sheet).pop();
              ShellScope.go(context, ShellTab.games);
            },
          ),
          const SizedBox(height: 10),
          DuoButton(
            label: 'Выбрать дешевле или подождать',
            color: FinniColors.surface,
            onPressed: () => Navigator.of(sheet).pop(),
          ),
        ],
      ),
    );
  } else {
    mascot?.shake();
    if (context.mounted) showToast(context, result.messages, emoji: '🤔');
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.emoji, required this.title, required this.text, required this.actions});
  final String emoji;
  final String title;
  final String text;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(emoji, textAlign: TextAlign.center, style: const TextStyle(fontSize: 52)),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: FinniColors.muted, fontSize: 16)),
            const SizedBox(height: 18),
            ...actions,
          ],
        ),
      ),
    );
  }
}

class _BuySheet extends StatefulWidget {
  const _BuySheet({required this.game, required this.item});
  final GameController game;
  final ShopItem item;

  @override
  State<_BuySheet> createState() => _BuySheetState();
}

class _BuySheetState extends State<_BuySheet> {
  late final String _commandId = widget.game.newCommandId();
  bool _busy = false;

  Future<void> _buy() async {
    if (_busy) return;
    setState(() => _busy = true);
    final f = await widget.game.buy(widget.item.id, commandId: _commandId);
    if (mounted) Navigator.of(context).pop(f);
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final item = widget.item;
    final wallet = game.economy.available.value;
    final after = wallet - item.price;
    final base = MascotLook.fromGame(game);
    final preview = item.slot == ItemSlot.hero
        ? MascotLook(
            color: base.color,
            hair: base.hair,
            skin: base.skin,
            mood: base.mood,
            stage: base.stage,
            accessories: {...base.accessories, ?item.accessory},
          )
        : null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (preview != null)
              Center(child: MascotView(look: preview, size: 170))
            else
              Text(item.emoji, textAlign: TextAlign.center, style: const TextStyle(fontSize: 64)),
            Text(item.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Center(child: DuoChip(text: itemSubtitle(item), color: basketOf(item.kind).color)),
            const SizedBox(height: 8),
            Text(item.effect, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17)),
            const SizedBox(height: 14),
            DuoCard(
              padding: const EdgeInsets.all(12),
              child: Text(
                after >= 0 ? 'В кошельке $wallet 🪙 → останется $after 🪙' : 'В кошельке $wallet 🪙, а стоит ${item.price} 🪙',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            if (item.kind == ItemKind.want && game.planConfirmed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'В банке «Хочу» по плану ${game.economy.plan!.want.value} 🪙, потрачено ${game.economy.spentWant.value}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: FinniColors.muted),
                ),
              ),
            const SizedBox(height: 16),
            DuoButton(key: const Key('shop.buy'), label: 'Купить за ${item.price} 🪙', onPressed: _busy ? null : _buy),
            const SizedBox(height: 10),
            DuoButton(label: 'Не сейчас', color: FinniColors.surface, onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}
