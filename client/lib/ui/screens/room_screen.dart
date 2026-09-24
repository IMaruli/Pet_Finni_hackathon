import 'package:flutter/material.dart';

import '../../content/models.dart';
import '../../game/game_controller.dart';
import '../room/room_scene.dart';
import '../theme.dart';
import '../widgets/buy_sheet.dart';
import 'savings_screen.dart';

/// Комната (Figma 08): комната во весь экран + лента вещей снизу (SA F-017 BR-12).
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
        final furnitureGoal = game.content.goals.firstWhere((g) => g.reward == GoalReward.furniture);
        final roomGoal = game.content.goals.firstWhere((g) => g.reward == GoalReward.room);
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('Комната'),
            backgroundColor: Colors.transparent,
            actions: [
              if (game.inventory.rooms > 1)
                TextButton(
                  onPressed: () => setState(() => _room = _room == 1 ? 2 : 1),
                  child: Text(_room == 1 ? '🧸 Игровая' : '🛏️ Спальня', style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(child: RoomScene(inventory: game.inventory, room: _room)),
              Container(
                color: const Color(0xFFFFFBF4),
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
                            status: game.inventory.owned.contains(i.id) ? '✓ есть' : '🪙 ${i.price}',
                            owned: game.inventory.owned.contains(i.id),
                            onTap: () => buyFlow(context, game, i),
                          ),
                        for (final o in furnitureGoal.options)
                          _tile(
                            key: 'roomItem.${o.id}',
                            emoji: o.emoji,
                            title: o.title,
                            status: game.inventory.furniture == o.id ? '✓ есть' : 'копим 🐷',
                            owned: game.inventory.furniture == o.id,
                            onTap: () => _toSavings(),
                          ),
                        _tile(
                          key: 'roomItem.room2',
                          emoji: roomGoal.emoji,
                          title: roomGoal.title,
                          status: game.inventory.rooms > 1 ? '✓ есть' : 'копим 🐷',
                          owned: game.inventory.rooms > 1,
                          onTap: () => _toSavings(),
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

  void _toSavings() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SavingsScreen(game: game)));

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
            color: owned ? const Color(0xFFE8F5F1) : const Color(0xFFFBF1E1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: owned ? FinniColors.teal : FinniColors.line, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 34)),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: owned ? FinniColors.teal : FinniColors.ink)),
            ],
          ),
        ),
      ),
    );
  }
}
