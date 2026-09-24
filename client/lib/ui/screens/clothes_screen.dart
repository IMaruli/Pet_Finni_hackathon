import 'package:flutter/material.dart';

import '../../content/models.dart';
import '../../game/game_controller.dart';
import '../mascot/mascot_look.dart';
import '../mascot/mascot_view.dart';
import '../theme.dart';
import '../widgets/buy_sheet.dart';
import '../widgets/duo.dart';

/// Одежда (Figma 07): рамка с героем и шкаф налепок, тап = примерка (SA F-017 BR-11).
class ClothesScreen extends StatefulWidget {
  const ClothesScreen({super.key, required this.game, this.embedded = false});
  final GameController game;

  /// Вкладка раздела «Образ» — без своей шапки (F-041).
  final bool embedded;

  @override
  State<ClothesScreen> createState() => _ClothesScreenState();
}

class _ClothesScreenState extends State<ClothesScreen> {
  final _mascot = MascotController();

  /// Примерка не купленной вещи (без покупки).
  String? _trying;

  GameController get game => widget.game;

  @override
  void dispose() {
    _mascot.dispose();
    super.dispose();
  }

  Future<void> _tap(ShopItem item) async {
    if (game.inventory.owned.contains(item.id)) {
      await game.toggleWear(item.id);
      setState(() => _trying = null);
      _mascot.jump();
    } else if (_trying == item.id) {
      await buyFlow(context, game, item, mascot: _mascot);
      if (mounted) setState(() => _trying = null);
    } else {
      setState(() => _trying = item.id);
      _mascot.jump();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final i in game.content.wantItems)
        if (i.slot == ItemSlot.hero) i,
    ];
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final base = MascotLook.fromGame(game);
        final trying = _trying == null ? null : game.content.item(_trying!);
        final look = MascotLook(
          color: base.color,
          hair: base.hair,
          skin: base.skin,
          mood: base.mood,
          stage: base.stage,
          accessories: {...base.accessories, ?trying?.accessory},
        );
        return Scaffold(
          appBar: widget.embedded ? null : AppBar(title: const Text('Одежда')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // Рамка героя — по ширине экрана (F-045 BR-02).
                Container(
                  key: const Key('clothes.frame'),
                  height: 250,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFFFF), Color(0xFFE9E9F2)]),
                    boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 8))],
                  ),
                  child: MascotView(look: look, controller: _mascot, size: 220, semanticsLabel: game.profile.petName),
                ),
                const SizedBox(height: 12),
                DuoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Гардероб', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                      const SizedBox(height: 12),
                      // Колонки по ширине, плитки тянутся — без пустоты справа (F-045 BR-03).
                      LayoutBuilder(
                        builder: (context, c) => GridView.count(
                          key: const Key('clothes.grid'),
                          crossAxisCount: (c.maxWidth / 72).floor().clamp(4, 8),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.8,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [for (final i in items) _tile(i)],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        trying == null
                            ? 'Своё — надень или сними. Чужое — примерь, а второй тап откроет покупку.'
                            : 'Примеряем: ${trying.title}. Нравится? Тапни ещё раз — купить за ${trying.price} 🪙',
                        style: const TextStyle(color: FinniColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tile(ShopItem item) {
    final owned = game.inventory.owned.contains(item.id);
    final worn = game.inventory.worn.contains(item.id);
    final trying = _trying == item.id;
    return GestureDetector(
      key: Key('clothes.${item.id}'),
      onTap: () => _tap(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: worn || trying ? FinniColors.primary.withValues(alpha: 0.1) : FinniColors.fill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: worn || trying ? FinniColors.primary : Colors.transparent, width: 2),
        ),
        // Содержимое ужимается под плитку на узких экранах (F-045 BR-04).
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 2),
              Text(
                owned ? (worn ? 'надето' : 'снято') : '${item.price} мон.',
                maxLines: 1,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: owned ? FinniColors.primary : FinniColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
