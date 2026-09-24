import 'package:flutter/material.dart';

import '../../game/game_controller.dart';
import '../games/budget_game.dart';
import '../games/catcher_game.dart';
import '../games/sort_game.dart';
import '../screens/plan_screen.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/duo.dart';

final class _Card {
  const _Card(this.id, this.emoji, this.title, this.teaches, this.color, {this.rewarded = true});
  final String id;
  final String emoji;
  final String title;
  final String teaches;
  final Color color;
  final bool rewarded;
}

const _cards = [
  _Card('sort', '🧺', 'Нужно или хочу?', 'нужное и желаемое', FinniColors.teal),
  _Card('plan', '🫙', 'План дня', 'три банки', FinniColors.primary, rewarded: false),
  _Card('catcher', '🐷', 'Копилка-ловец', 'копить, не отвлекаясь', FinniColors.orange),
  _Card('budget', '🧾', 'Уложись в бюджет', 'покупки по бюджету', FinniColors.blue),
];

/// Игры (Figma 03): сетка цветных карточек (SA F-017 BR-07).
class GamesTab extends StatelessWidget {
  const GamesTab({super.key, required this.game});
  final GameController game;

  Widget _screen(String id) => switch (id) {
    'sort' => SortGame(game: game),
    'budget' => BudgetGame(game: game),
    'plan' => PlanScreen(game: game),
    _ => CatcherGame(game: game),
  };

  @override
  Widget build(BuildContext context) {
    final reward = game.content.config.rewardWise;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          DuoHeader(
            title: 'Игры',
            subtitle: 'Учись и зарабатывай монеты',
            trailing: CoinChip(value: game.economy.available.value),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DuoCard(
              color: game.gameRewardToday ? const Color(0xFFE8F5F1) : const Color(0xFFFFF4D6),
              padding: const EdgeInsets.all(12),
              child: Text(
                game.gameRewardToday
                    ? '✅ Награда за игру сегодня есть. Играй для тренировки!'
                    : '🎁 Первая игра сегодня — до +$reward 🪙',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.82,
              children: [
                for (final c in _cards)
                  DuoCard(
                    key: Key('games.${c.id}'),
                    padding: const EdgeInsets.all(10),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _screen(c.id))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: c.color, borderRadius: BorderRadius.circular(16)),
                            child: Text(c.emoji, style: const TextStyle(fontSize: 52)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(c.title, maxLines: 2, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, height: 1.15)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(c.teaches, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: FinniColors.muted)),
                            ),
                            if (c.rewarded)
                              Text(
                                game.gameRewardToday ? '✓' : '🪙+$reward',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: FinniColors.coin),
                              ),
                          ],
                        ),
                        if (game.snapshot.gameBest[c.id] case final best?)
                          Text('рекорд: $best', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
