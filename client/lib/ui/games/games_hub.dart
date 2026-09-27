import 'package:flutter/material.dart';

import '../../game/game_controller.dart';
import '../theme.dart';
import '../widgets/duo.dart';

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
              Text(headline, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                f.reward > 0 ? '+${f.reward} 🪙 в кошелёк' : 'Награда за игру сегодня уже была',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: f.reward > 0 ? FinniColors.need : FinniColors.muted,
                ),
              ),
              if (details != null) ...[const SizedBox(height: 12), details],
              const SizedBox(height: 16),
              // Главная — «Готово»: яркое «ещё раз» ребёнок жал машинально (F-064).
              DuoButton(key: const Key('game.exit'), label: 'Готово', onPressed: () => Navigator.of(sheet).pop(false)),
              const SizedBox(height: 8),
              DuoButton(key: const Key('game.again'), label: 'Играть ещё раз', color: FinniColors.surface, onPressed: () => Navigator.of(sheet).pop(true)),
            ],
          ),
        ),
      ),
    ),
  );
  return again ?? false;
}
