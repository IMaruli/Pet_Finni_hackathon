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
  const _Card(this.id, this.icon, this.title, this.teaches, this.colors, {this.rewarded = true});
  final String id;
  final IconData icon;
  final String title;
  final String teaches;
  final List<Color> colors;
  final bool rewarded;
}

const _cards = [
  _Card('sort', Icons.swipe_rounded, 'Нужно или хочу?', 'Отличать нужное', [Color(0xFF34C759), Color(0xFF30B0C7)]),
  _Card('budget', Icons.receipt_long_rounded, 'Уложись в бюджет', 'Покупки по средствам', [Color(0xFF5E5CE6), Color(0xFF007AFF)]),
  _Card('catcher', Icons.savings_rounded, 'Копилка-ловец', 'Копить без соблазнов', [Color(0xFFFF9500), Color(0xFFFF2D55)]),
  _Card('plan', Icons.pie_chart_rounded, 'План дня', 'Три банки', [Color(0xFF8E8E93), Color(0xFF636366)], rewarded: false),
];

/// Игры (Figma 03): карточки с градиентной обложкой (SA F-017 BR-07, F-018).
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
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          DuoHeader(
            title: 'Игры',
            subtitle: game.gameRewardToday ? 'Награда за сегодня получена — играй для тренировки' : 'Первая игра сегодня — до +$reward монет',
            trailing: CoinChip(value: game.economy.available.value),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.8,
              children: [for (final c in _cards) _card(context, c, reward)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, _Card c, int reward) {
    final best = game.snapshot.gameBest[c.id];
    return DuoCard(
      key: Key('games.${c.id}'),
      padding: EdgeInsets.zero,
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _screen(c.id))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: c.colors),
              ),
              child: Stack(
                children: [
                  Positioned(right: -18, bottom: -18, child: Icon(c.icon, size: 110, color: const Color(0x26FFFFFF))),
                  Center(child: Icon(c.icon, size: 44, color: Colors.white)),
                  if (c.rewarded && !game.gameRewardToday)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(12)),
                        child: Text('+$reward', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Text(
                  best == null ? c.teaches : 'Рекорд: $best',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: FinniColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
