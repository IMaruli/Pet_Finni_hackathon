import 'package:flutter/material.dart';

import '../../content/models.dart';
import '../../game/game_controller.dart';
import '../screens/glossary_screen.dart';
import '../screens/quest_screen.dart';
import '../theme.dart';
import '../widgets/duo.dart';

const _themeTitle = {QuestTheme.budget: 'Бюджет', QuestTheme.save: 'Копилка', QuestTheme.buy: 'Покупки'};
const _themeIcon = {
  QuestTheme.budget: Icons.pie_chart_rounded,
  QuestTheme.save: Icons.savings_rounded,
  QuestTheme.buy: Icons.shopping_cart_rounded,
};
const _themeColor = {QuestTheme.budget: FinniColors.primary, QuestTheme.save: FinniColors.teal, QuestTheme.buy: FinniColors.orange};

/// Уроки (Figma 05): пройденные сцены можно пересмотреть (SA F-017 BR-09, F-018 BR-06).
class LessonsTab extends StatelessWidget {
  const LessonsTab({super.key, required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    final done = game.snapshot.questsDone.toSet();
    final today = game.todaysQuest;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          DuoHeader(title: 'Уроки', subtitle: 'Пройдено ${done.length} из ${game.content.quests.length}'),
          for (final theme in QuestTheme.values)
            GroupedSection(
              header: _themeTitle[theme],
              children: [
                for (final q in game.content.quests.where((q) => q.theme == theme))
                  _lesson(context, q, done: done.contains(q.id), today: q.id == today.id && !game.questDoneToday),
              ],
            ),
          GroupedSection(
            header: 'Справка',
            children: [
              GroupedRow(
                key: const Key('lessons.glossary'),
                icon: Icons.menu_book_rounded,
                iconColor: FinniColors.muted,
                title: 'Словарик',
                subtitle: '${game.content.glossary.length} слов простыми словами',
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GlossaryScreen(content: game.content))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lesson(BuildContext context, Quest q, {required bool done, required bool today}) {
    final open = done || today;
    return GroupedRow(
      key: Key('lessons.${q.id}'),
      icon: open ? _themeIcon[q.theme] : Icons.lock_rounded,
      iconColor: open ? _themeColor[q.theme]! : const Color(0xFFC7C7CC),
      title: q.title,
      subtitle: done ? 'Пройден · можно повторить' : today ? 'Доступен сегодня' : 'Откроется позже',
      trailing: today ? const DuoChip(text: 'Новый', color: FinniColors.orange) : null,
      onTap: open
          ? () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => QuestScreen(game: game, review: done ? q : null)))
          : null,
    );
  }
}
