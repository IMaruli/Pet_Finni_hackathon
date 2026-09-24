import 'package:flutter/material.dart';

import '../../content/models.dart';
import '../../economy/catalog_item.dart';
import '../../game/game_controller.dart';
import '../screens/plan_screen.dart';
import '../screens/savings_screen.dart';
import '../theme.dart';
import '../widgets/buy_sheet.dart';
import '../widgets/common.dart';
import '../widgets/duo.dart';

/// Магазин (Figma 06) в стиле списков iOS (SA F-017 BR-10, F-018 BR-06).
class ShopTab extends StatelessWidget {
  const ShopTab({super.key, required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          DuoHeader(title: 'Магазин', trailing: CoinChip(value: game.economy.available.value)),
          if (!game.planConfirmed)
            GroupedSection(
              children: [
                GroupedRow(
                  icon: Icons.pie_chart_rounded,
                  title: 'Сначала план дня',
                  subtitle: 'Так видно, на что хватит монет',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlanScreen(game: game))),
                ),
              ],
            ),
          GroupedSection(
            header: 'Нужное на сегодня',
            footer: 'Нужное каждый день новое: завтра понадобится снова.',
            children: [for (final item in game.todaysNeeds) _itemRow(context, item)],
          ),
          GroupedSection(
            header: game.needsLeft.isEmpty ? 'Хочу' : 'Хочу · после нужного',
            children: [for (final item in game.content.wantItems) _itemRow(context, item)],
          ),
          GroupedSection(
            header: 'Копим',
            footer: 'Цели покупаются из копилки.',
            children: [for (final g in game.content.goals) _goalRow(context, g)],
          ),
        ],
      ),
    );
  }

  Widget _emojiTile(String emoji) => Container(
    width: 40,
    height: 40,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: FinniColors.fill, borderRadius: BorderRadius.circular(10)),
    child: Text(emoji, style: const TextStyle(fontSize: 22)),
  );

  Widget _price(int price, {bool locked = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: FinniColors.fill, borderRadius: BorderRadius.circular(20)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (locked) ...[const Icon(Icons.lock_rounded, size: 14, color: FinniColors.muted), const SizedBox(width: 4)],
        const CoinIcon(size: 15),
        const SizedBox(width: 5),
        Text('$price', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _itemRow(BuildContext context, ShopItem item) {
    final owned = item.slot != ItemSlot.consumable && game.inventory.owned.contains(item.id);
    final boughtNeed = item.kind == ItemKind.need && game.isBoughtToday(item.id);
    final done = owned || boughtNeed;
    return GroupedRow(
      key: Key('shopRow.${item.id}'),
      leading: _emojiTile(item.emoji),
      title: item.title,
      subtitle: itemSubtitle(item),
      trailing: done
          ? Text(owned ? '✓ есть' : '✓ куплено', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: FinniColors.need))
          : _price(item.price, locked: item.kind == ItemKind.want && game.needsLeft.isNotEmpty),
      chevron: false,
      onTap: done ? null : () => buyFlow(context, game, item),
    );
  }

  Widget _goalRow(BuildContext context, GoalDef g) {
    final done = game.inventory.goalsDone.contains(g.id);
    return GroupedRow(
      key: Key('shopGoal.${g.id}'),
      leading: _emojiTile(g.emoji),
      title: g.title,
      subtitle: done ? 'Получено' : 'Цель копилки',
      trailing: done ? const Icon(Icons.check_circle_rounded, color: FinniColors.need) : _price(g.cost),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SavingsScreen(game: game))),
    );
  }
}
