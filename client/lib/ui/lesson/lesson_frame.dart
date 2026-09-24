import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/duo.dart';

/// Плашка после хода: «Верно» + почему + «Дальше» или «Ещё раз» + подсказка (SA F-025 BR-03).
final class StepFeedback {
  const StepFeedback.good(this.text, {this.title = 'Верно', this.action = 'Дальше'}) : good = true;
  const StepFeedback.retry(this.text, {this.title = 'Ещё раз', this.action = 'Ещё раз'}) : good = false;
  final bool good;
  final String title;
  final String text;
  final String action;
}

/// Рамка шага: фраза-задание сверху, тело, внизу кнопка или плашка.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    required this.prompt,
    required this.body,
    this.buttonLabel = 'Проверить',
    this.onButton,
    this.feedback,
    this.onFeedback,
    this.showButton = true,
  });

  final String prompt;
  final Widget body;
  final String buttonLabel;
  final VoidCallback? onButton;
  final StepFeedback? feedback;
  final VoidCallback? onFeedback;
  final bool showButton;

  @override
  Widget build(BuildContext context) {
    final f = feedback;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (prompt.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text(prompt, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.25)),
          ),
        Expanded(
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: body),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, a) => SlideTransition(
            position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: FadeTransition(opacity: a, child: child),
          ),
          child: f != null
              ? _Panel(key: ValueKey(f), feedback: f, onPressed: onFeedback)
              : !showButton
              ? const SizedBox(height: 24)
              : SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: DuoButton(key: const Key('lesson.check'), label: buttonLabel, onPressed: onButton),
                  ),
                ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({super.key, required this.feedback, required this.onPressed});
  final StepFeedback feedback;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final good = feedback.good;
    final ink = good ? const Color(0xFF1E7A34) : FinniColors.ink;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: good ? const Color(0xFFDDF5E3) : const Color(0xFFEDEDF2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(good ? Icons.check_circle_rounded : Icons.refresh_rounded, color: ink, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(feedback.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ink)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(feedback.text, style: TextStyle(fontSize: 16, color: ink, height: 1.3)),
              const SizedBox(height: 14),
              DuoButton(
                key: Key(good ? 'lesson.next' : 'lesson.retry'),
                label: feedback.action,
                color: good ? FinniColors.need : FinniColors.ink,
                onPressed: onPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Крупная плитка ответа.
class LessonTile extends StatelessWidget {
  const LessonTile({
    super.key,
    required this.text,
    required this.onTap,
    this.selected = false,
    this.locked = false,
    this.dim = false,
    this.center = false,
  });
  final String text;
  final VoidCallback? onTap;
  final bool selected;

  /// Верная пара / разложенная карточка — зафиксирована.
  final bool locked;
  final bool dim;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final border = locked
        ? FinniColors.need
        : selected
        ? FinniColors.primary
        : FinniColors.line;
    return Opacity(
      opacity: dim ? 0.35 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: locked
                ? const Color(0xFFEAF8EE)
                : selected
                ? FinniColors.primary.withValues(alpha: 0.08)
                : FinniColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 2),
            boxShadow: [BoxShadow(color: border.withValues(alpha: 0.5), offset: const Offset(0, 2))],
          ),
          child: Text(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: locked ? const Color(0xFF1E7A34) : FinniColors.ink),
          ),
        ),
      ),
    );
  }
}

/// Полоска шагов под крестиком.
class StepBar extends StatelessWidget {
  const StepBar({super.key, required this.count, required this.done});
  final int count;
  final int done;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < count; i++)
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(color: i < done ? FinniColors.need : FinniColors.line, borderRadius: BorderRadius.circular(4)),
          ),
        ),
    ],
  );
}
