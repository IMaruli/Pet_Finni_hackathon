import 'package:flutter/material.dart';

import '../../content/models.dart';
import '../../game/game_controller.dart';
import '../room/room_scene.dart';
import '../theme.dart';
import '../widgets/buy_sheet.dart';

/// Дом (Figma 08): комната во весь экран + лента вещей в комнату; цели — только в Копилке (SA F-017 BR-12, F-022 BR-06).
class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key, required this.game});
  final GameController game;

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  int _room = 1;

  GameController get game => widget.game;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final roomItems = [for (final i in game.content.wantItems) if (i.slot == ItemSlot.room) i];
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('Дом'),
            backgroundColor: Colors.transparent,
            actions: [
              if (game.inventory.rooms > 1)
                TextButton(
                  onPressed: () => setState(() => _room = _room == 1 ? 2 : 1),
                  child: Text(_room == 1 ? 'Игровая' : 'Спальня'),
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(child: RoomScene(inventory: game.inventory, room: _room, bowls: game.bowls)),
              Container(
                color: FinniColors.surface,
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 124,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(12),
                      children: [
                        for (final i in roomItems)
                          _tile(
                            key: 'roomItem.${i.id}',
                            emoji: i.emoji,
                            title: i.title,
                            status: game.inventory.owned.contains(i.id) ? '✓ есть' : '${i.price} мон.',
                            owned: game.inventory.owned.contains(i.id),
                            onTap: () => buyFlow(context, game, i),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tile({
    required String key,
    required String emoji,
    required String title,
    required String status,
    required bool owned,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        key: Key(key),
        onTap: owned ? null : onTap,
        child: Container(
          width: 92,
          decoration: BoxDecoration(
            color: owned ? FinniColors.primary.withValues(alpha: 0.08) : FinniColors.fill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: owned ? FinniColors.primary : Colors.transparent, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 34)),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: owned ? FinniColors.primary : FinniColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}
