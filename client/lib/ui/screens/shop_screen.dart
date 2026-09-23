import 'package:flutter/material.dart';

import '../../content/models.dart';
import '../../economy/catalog_item.dart';
import '../../game/game_controller.dart';
import '../../game/game_feedback.dart';
import '../games/games_hub.dart';
import '../mascot/mascot_look.dart';
import '../mascot/mascot_view.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'plan_screen.dart';
import 'quest_screen.dart';

/// Магазин и гардероб (SA F-011).
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, required this.game, this.initialTab = 0});
  final GameController game;
  final int initialTab;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _mascot = MascotController();

  GameController get game => widget.game;

  @override
  void dispose() {
    _mascot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) => DefaultTabController(
        length: 3,
        initialIndex: widget.initialTab,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Магазин'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CoinChip(value: game.economy.available.value),
              ),
            ],
            bottom: const TabBar(
              labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              tabs: [
                Tab(key: Key('shop.tab.need'), text: '🥣 Нужное'),
                Tab(key: Key('shop.tab.want'), text: '🎁 Хочу'),
                Tab(key: Key('shop.tab.wardrobe'), text: '👕 Гардероб'),
              ],
            ),
          ),
          body: Column(
            children: [
              SizedBox(
                height: 130,
                child: MascotView(look: MascotLook.fromGame(game), controller: _mascot, size: 130),
              ),
              if (!game.planConfirmed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Panel(
                    color: const Color(0xFFFFF0DE),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Expanded(child: Text('Сначала план: так ты заранее знаешь, на что хватит.')),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(builder: (_) => PlanScreen(game: game)),
                          ),
                          child: const Text('К плану'),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: TabBarView(
                  children: [
                    _grid(game.todaysNeeds, needs: true),
                    _grid(game.content.wantItems),
                    _wardrobe(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grid(List<ShopItem> items, {bool needs = false}) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (needs)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Это нужно сегодня. Завтра понадобится снова.', style: TextStyle(color: FinniColors.muted)),
          ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.82,
          children: [for (final item in items) _card(item)],
        ),
      ],
    );
  }

  Widget _card(ShopItem item) {
    final owned = item.slot != ItemSlot.consumable && game.inventory.owned.contains(item.id);
    final boughtNeed = item.kind == ItemKind.need && game.isBoughtToday(item.id);
    final done = owned || boughtNeed;
    return Panel(
      key: Key('shop.item.${item.id}'),
      padding: const EdgeInsets.all(12),
      onTap: done ? null : () => _openBuy(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BasketBadge(basketOf(item.kind), small: true),
          Expanded(child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 48)))),
          Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800), maxLines: 2),
          Text(item.effect, style: const TextStyle(fontSize: 13, color: FinniColors.muted), maxLines: 2),
          const SizedBox(height: 6),
          Text(
            done ? (owned ? 'Уже есть ✓' : 'Куплено ✓') : '${item.price} 🪙',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: done ? FinniColors.need : FinniColors.ink),
          ),
        ],
      ),
    );
  }

  Future<void> _openBuy(ShopItem item) async {
    final result = await showModalBottomSheet<GameFeedback>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BuySheet(game: game, item: item),
    );
    if (!mounted || result == null) return;
    if (result.ok) {
      _mascot.jump();
      buzz(Buzz.medium);
      showToast(context, result.messages, emoji: item.emoji, color: basketOf(item.kind).color);
    } else if (result.reason == FeedbackReason.insufficient) {
      _mascot.shake();
      buzz(Buzz.heavy);
      await _showShortage(result);
    } else {
      _mascot.shake();
      showToast(context, result.messages, emoji: '🤔');
    }
  }

  Future<void> _showShortage(GameFeedback f) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('😮', textAlign: TextAlign.center, style: TextStyle(fontSize: 48)),
              Text(
                'Не хватает ${f.missing} 🪙',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Монеты не списаны. Вот что можно сделать:',
                textAlign: TextAlign.center,
                style: TextStyle(color: FinniColors.muted),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(sheet).pop();
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => QuestScreen(game: game)));
                },
                child: const Text('📜 Заработать заданием'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(sheet).pop();
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GamesHub(game: game)));
                },
                child: const Text('🎮 Сыграть в игру'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(sheet).pop(),
                child: const Text('🔎 Выбрать что-то дешевле или подождать до завтра'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wardrobe() {
    final owned = [
      for (final i in game.content.wantItems)
        if (i.slot == ItemSlot.hero && game.inventory.owned.contains(i.id)) i,
    ];
    if (owned.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Пока пусто. Купи налепку во вкладке «Хочу», и она появится здесь.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, color: FinniColors.muted),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Надевай и снимай бесплатно: вещи уже твои.', style: TextStyle(color: FinniColors.muted)),
        const SizedBox(height: 8),
        for (final item in owned)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Panel(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: SwitchListTile(
                key: Key('wardrobe.${item.id}'),
                contentPadding: EdgeInsets.zero,
                title: Text('${item.emoji}  ${item.title}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                value: game.inventory.worn.contains(item.id),
                onChanged: (_) {
                  game.toggleWear(item.id);
                  _mascot.jump();
                },
              ),
            ),
          ),
      ],
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
            Text(item.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Center(child: BasketBadge(basketOf(item.kind))),
            const SizedBox(height: 8),
            Text(item.effect, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17)),
            const SizedBox(height: 12),
            Panel(
              padding: const EdgeInsets.all(12),
              child: Text(
                after >= 0
                    ? 'В кошельке $wallet 🪙 → останется $after 🪙'
                    : 'В кошельке $wallet 🪙, а стоит ${item.price} 🪙',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            if (item.kind == ItemKind.want && game.planConfirmed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'В банке «Хочу» по плану: ${game.economy.plan!.want.value} 🪙, уже потрачено ${game.economy.spentWant.value}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: FinniColors.muted),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('shop.buy'),
              onPressed: _busy ? null : _buy,
              child: Text('Купить за ${item.price} 🪙'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Не сейчас')),
          ],
        ),
      ),
    );
  }
}
