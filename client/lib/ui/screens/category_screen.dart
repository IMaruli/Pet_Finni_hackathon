import 'package:flutter/material.dart';

import '../../content/models.dart';
import '../../economy/catalog_item.dart';
import '../../game/game_controller.dart';
import '../theme.dart';
import '../widgets/buy_sheet.dart';
import '../widgets/common.dart';
import '../widgets/duo.dart';
import 'plan_screen.dart';

enum ShopCategory { needs, treats }

/// Раздел покупок одной категории: Нужное или Хотелки (SA F-022 BR-03, BR-04).
class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key, required this.game, required this.category});
  final GameController game;
  final ShopCategory category;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final needs = category == ShopCategory.needs;
        final items = needs ? game.todaysNeeds : game.content.treatItems;
        final locked = !needs && game.needsLeft.isNotEmpty;
        return Scaffold(
          appBar: AppBar(
            title: Text(needs ? 'Нужное' : 'Хотелки'),
            actions: [
              Padding(padding: const EdgeInsets.only(right: 16), child: CoinChip(value: game.economy.available.value)),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              if (!game.planConfirmed)
                GroupedSection(
                  children: [
                    GroupedRow(
                      key: const Key('category.plan'),
                      icon: Icons.pie_chart_rounded,
                      title: 'Сначала план дня',
                      subtitle: 'Так видно, на что хватит монет',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PlanScreen(game: game))),
                    ),
                  ],
                ),
              GroupedSection(
                header: needs ? 'На сегодня' : (locked ? 'После нужного' : 'Порадовать себя'),
                footer: needs
                    ? 'Нужное каждый день новое: завтра понадобится снова.'
                    : 'Вкусность радует героя до вечера. Платишь из банки «Хочу».',
                children: [for (final item in items) _row(context, item, locked: locked)],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(BuildContext context, ShopItem item, {required bool locked}) {
    final done = item.kind == ItemKind.need && game.isBoughtToday(item.id);
    return GroupedRow(
      key: Key('shopRow.${item.id}'),
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: FinniColors.fill, borderRadius: BorderRadius.circular(10)),
        child: Text(item.emoji, style: const TextStyle(fontSize: 22)),
      ),
      title: item.title,
      subtitle: item.effect,
      trailing: done
          ? const Text('✓ куплено', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: FinniColors.need))
          : PriceTag(price: item.price, locked: locked),
      chevron: false,
      onTap: done ? null : () => buyFlow(context, game, item),
    );
  }
}

/// Цена-капсула; с замком, пока вещь ждёт нужное (F-021).
class PriceTag extends StatelessWidget {
  const PriceTag({super.key, required this.price, this.locked = false});
  final int price;
  final bool locked;

  @override
  Widget build(BuildContext context) => Container(
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
}
