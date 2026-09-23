import 'package:flutter/material.dart';

import '../../game/game_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'budget_game.dart';
import 'catcher_game.dart';
import 'sort_game.dart';

final class _GameInfo {
  const _GameInfo(this.id, this.emoji, this.title, this.teaches, this.rules);
  final String id;
  final String emoji;
  final String title;
  final String teaches;
  final String rules;
}

const _games = [
  _GameInfo('sort', '🧺', 'Нужно или хочу?', 'Отличать нужное от желаемого', 'Раскидай 10 вещей по корзинам за 40 секунд'),
  _GameInfo('budget', '🧾', 'Уложись в бюджет', 'Покупать, когда монет ограничено', 'Собери корзину: всё нужное и не дороже бюджета'),
  _GameInfo('catcher', '🫙', 'Копилка-ловец', 'Копить и не поддаваться хотелкам', 'Лови монеты банкой, обходи соблазны'),
];

/// Игротека (SA F-013).
class GamesHub extends StatelessWidget {
  const GamesHub({super.key, required this.game});
  final GameController game;

  Widget _screen(String id) => switch (id) {
    'sort' => SortGame(game: game),
    'budget' => BudgetGame(game: game),
    _ => CatcherGame(game: game),
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('🎮 Игротека')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Panel(
                color: game.gameRewardToday ? const Color(0xFFE9F8F0) : const Color(0xFFFFF0DE),
                child: Text(
                  game.gameRewardToday
                      ? '✅ Награда за игру сегодня получена. Играй сколько хочешь — для тренировки!'
                      : '🎁 Первая игра сегодня принесёт до +${game.content.config.rewardWise} 🪙',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              for (final g in _games)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Panel(
                    key: Key('games.${g.id}'),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _screen(g.id))),
                    child: Row(
                      children: [
                        Text(g.emoji, style: const TextStyle(fontSize: 48)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                              Text('Учит: ${g.teaches}', style: const TextStyle(color: FinniColors.primary, fontWeight: FontWeight.w700)),
                              Text(g.rules, style: const TextStyle(color: FinniColors.muted)),
                              if (game.snapshot.gameBest[g.id] case final best?)
                                Text('Лучший результат: $best', style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        const Icon(Icons.play_circle_fill, size: 40, color: FinniColors.primary),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Итог мини-игры: начисление и разбор. Возвращает true, если нажали «Ещё раз».
Future<bool> showGameResult(
  BuildContext context,
  GameController game, {
  required String gameId,
  required bool win,
  required int score,
  required String headline,
  Widget? details,
}) async {
  final f = await game.finishMiniGame(gameId, win: win, score: score);
  if (!context.mounted) return false;
  final again = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    builder: (sheet) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(sheet).size.height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(win ? '🏆' : '💪', textAlign: TextAlign.center, style: const TextStyle(fontSize: 56)),
              Text(headline, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                f.reward > 0 ? '+${f.reward} 🪙 в кошелёк' : 'Награда за игру сегодня уже была',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: f.reward > 0 ? FinniColors.need : FinniColors.muted,
                ),
              ),
              if (details != null) ...[const SizedBox(height: 12), details],
              const SizedBox(height: 16),
              FilledButton(key: const Key('game.again'), onPressed: () => Navigator.of(sheet).pop(true), child: const Text('Ещё раз')),
              const SizedBox(height: 8),
              OutlinedButton(key: const Key('game.exit'), onPressed: () => Navigator.of(sheet).pop(false), child: const Text('В игротеку')),
            ],
          ),
        ),
      ),
    ),
  );
  return again ?? false;
}
