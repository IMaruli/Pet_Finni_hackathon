import 'dart:math';

import 'package:flutter/material.dart';

import '../../content/lesson_models.dart';
import '../../game/game_controller.dart';
import '../lesson/lesson_screen.dart';
import '../screens/glossary_screen.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/duo.dart';

const _topicColor = [FinniColors.need, FinniColors.primary, FinniColors.save, FinniColors.orange];

/// Уроки: путь по темам, как в Duolingo (SA F-025 BR-13).
class LessonsTab extends StatelessWidget {
  const LessonsTab({super.key, required this.game});
  final GameController game;

  void _open(BuildContext context, Lesson l) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LessonScreen(game: game, lesson: l)));

  @override
  Widget build(BuildContext context) {
    final content = game.content;
    final done = content.lessons.where((l) => game.isLessonDone(l.id)).length;
    final current = game.recommendedLesson;
    var n = 0;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          DuoHeader(
            title: 'Уроки',
            subtitle: game.lessonPaidToday
                ? 'Пройдено $done из ${content.lessons.length} · награда за сегодня получена'
                : 'Пройдено $done из ${content.lessons.length} · первый урок дня +${content.config.rewardWise} 🪙',
          ),
          for (final (ti, topic) in content.topics.indexed) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: DuoCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Text(topic.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(topic.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                          Text(
                            game.isTopicStarted(topic.id) ? 'Знакомая тема' : 'Новая тема',
                            style: const TextStyle(fontSize: 13, color: FinniColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${content.lessonsOf(topic.id).where((l) => game.isLessonDone(l.id)).length}/${content.lessonsOf(topic.id).length}',
                      style: const TextStyle(fontSize: 15, color: FinniColors.muted, fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                  ],
                ),
              ),
            ),
            for (final l in content.lessonsOf(topic.id))
              _node(context, l, color: _topicColor[ti % _topicColor.length], offset: sin(n++ * 1.1) * 70, current: l.id == current.id),
          ],
          GroupedSection(
            header: 'Справка',
            children: [
              GroupedRow(
                key: const Key('lessons.glossary'),
                icon: Icons.menu_book_rounded,
                iconColor: FinniColors.muted,
                title: 'Словарик',
                subtitle: '${content.glossary.length} слов простыми словами',
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => GlossaryScreen(content: content))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _node(BuildContext context, Lesson l, {required Color color, required double offset, required bool current}) {
    final open = game.isLessonOpen(l.id);
    final done = game.isLessonDone(l.id);
    final resume = game.lessonProgress?.lessonId == l.id;
    final fill = !open ? const Color(0xFFD1D1D6) : color;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Transform.translate(
        offset: Offset(offset, 0),
        child: Column(
          children: [
            if (current)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: FinniColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Text(resume ? 'Доиграть' : 'Начать', style: TextStyle(fontWeight: FontWeight.w700, color: color)),
              ),
            Semantics(
              button: true,
              label: '${l.title}, ${done ? 'пройден' : open ? 'открыт' : 'закрыт'}',
              child: GestureDetector(
                key: Key('lessons.${l.id}'),
                onTap: open
                    ? () {
                        buzz(Buzz.light);
                        _open(context, l);
                      }
                    : () {
                        buzz(Buzz.heavy);
                        showToast(context, ['Сначала пройди урок перед этим.'], emoji: '🔒');
                      },
                child: Container(
                  width: current ? 82 : 72,
                  height: current ? 82 : 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fill,
                    boxShadow: [BoxShadow(color: Color.lerp(fill, Colors.black, 0.25)!, offset: const Offset(0, 5))],
                  ),
                  alignment: Alignment.center,
                  child: !open
                      ? const Icon(Icons.lock_rounded, color: Colors.white, size: 30)
                      : done && !current
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 36)
                      : Text(l.emoji, style: const TextStyle(fontSize: 32)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(l.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: open ? FinniColors.ink : FinniColors.muted)),
          ],
        ),
      ),
    );
  }
}
