import 'package:flutter/material.dart';

import '../../content/models.dart';
import '../../economy/catalog_item.dart';
import '../../game/game_controller.dart';
import '../screens/savings_screen.dart';
import '../theme.dart';
import '../widgets/buy_sheet.dart';
import '../widgets/common.dart';
import '../widgets/duo.dart';

/// Магазин (Figma 06): строки с иконкой, типом и ценой (SA F-017 BR-10).
class ShopTab extends StatelessWidget {
  const ShopTab({super.key, required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          DuoHeader(title: 'Магазин', trailing: CoinChip(value: game.economy.available.value)),
          if (!game.planConfirmed)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: DuoCard(
                color: Color(0xFFFFF4D6),
                padding: EdgeInsets.all(12),
                child: Text('🫙 Сначала план дня — тогда видно, на что хватит.', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          const DuoSection('Нужное — на сегодня', color: FinniColors.need),
          for (final item in game.todaysNeeds) _itemRow(context, item),
          const DuoSection('Хочу — сразу в комнату или на героя', color: FinniColors.want),
          for (final item in game.content.wantItems) _itemRow(context, item),
          const DuoSection('Копим — цели', color: FinniColors.orange),
          for (final g in game.content.goals) _goalRow(context, g),
        ],
      ),
    );
  }

  Widget _itemRow(BuildContext context, ShopItem item) {
    final owned = item.slot != ItemSlot.consumable && game.inventory.owned.contains(item.id);
    final boughtNeed = item.kind == ItemKind.need && game.isBoughtToday(item.id);
    final done = owned || boughtNeed;
    return _row(
      key: Key('shopRow.${item.id}'),
      emoji: item.emoji,
      title: item.title,
      subtitle: itemSubtitle(item),
      price: done ? (owned ? '✓ есть' : '✓ куплено') : '${item.price}',
      done: done,
      onTap: done ? null : () => buyFlow(context, game, item),
    );
  }

  Widget _goalRow(BuildContext context, GoalDef g) {
    final done = game.inventory.goalsDone.contains(g.id);
    return _row(
      key: Key('shopGoal.${g.id}'),
      emoji: g.emoji,
      title: g.title,
      subtitle: 'копим · цель копилки',
      price: done ? '✓ есть' : '${g.cost}',
      done: done,
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SavingsScreen(game: game))),
    );
  }

  Widget _row({
    required Key key,
    required String emoji,
    required String title,
    required String subtitle,
    required String price,
    required bool done,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: DuoCard(
        key: key,
        onTap: onTap,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFFFBF1E1), borderRadius: BorderRadius.circular(16)),
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: FinniColors.muted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: done ? FinniColors.need.withValues(alpha: 0.15) : FinniColors.primary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                done ? price : '🪙 $price',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: done ? FinniColors.need : FinniColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
