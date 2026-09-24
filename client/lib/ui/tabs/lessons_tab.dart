import 'package:flutter/material.dart';

import '../../content/models.dart';
import '../../game/game_controller.dart';
import '../screens/glossary_screen.dart';
import '../screens/quest_screen.dart';
import '../theme.dart';
import '../widgets/duo.dart';

const _themeTitle = {QuestTheme.budget: 'бюджет', QuestTheme.save: 'копилка', QuestTheme.buy: 'покупки'};

/// Уроки (Figma 05): пройденные сцены можно пересмотреть (SA F-017 BR-09).
class LessonsTab extends StatelessWidget {
  const LessonsTab({super.key, required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    final done = game.snapshot.questsDone.toSet();
    final today = game.todaysQuest;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          DuoHeader(title: 'Уроки', subtitle: 'Пройденные — можно пересмотреть · ${done.length} из ${game.content.quests.length}'),
          for (final q in game.content.quests)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: _lesson(context, q, done: done.contains(q.id), today: q.id == today.id && !game.questDoneToday),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: DuoButton(
              key: const Key('lessons.glossary'),
              label: 'Словарик',
              emoji: '📖',
              color: FinniColors.teal,
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GlossaryScreen(content: game.content))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lesson(BuildContext context, Quest q, {required bool done, required bool today}) {
    final open = done || today;
    final (chip, color) = done ? ('смотреть', FinniColors.teal) : today ? ('сегодня', FinniColors.orange) : ('закрыто', FinniColors.muted);
    return Opacity(
      opacity: open ? 1 : 0.6,
      child: DuoCard(
        key: Key('lessons.${q.id}'),
        padding: const EdgeInsets.all(12),
        onTap: open
            ? () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => QuestScreen(game: game, review: done ? q : null)),
              )
            : null,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: FinniColors.primary.withValues(alpha: 0.6), shape: BoxShape.circle),
              child: Text(open ? q.emoji : '🔒', style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  Text(
                    '${done ? 'Пройден' : 'Ещё не пройден'} · тема: ${_themeTitle[q.theme]}',
                    style: const TextStyle(fontSize: 13, color: FinniColors.muted),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [DuoChip(text: chip, color: color), if (done) const Text('  ✓', style: TextStyle(color: FinniColors.coin, fontWeight: FontWeight.w900))]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
