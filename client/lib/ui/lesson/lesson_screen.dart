import 'package:flutter/material.dart';

import '../../content/lesson_models.dart';
import '../../game/game_controller.dart';
import '../../game/game_feedback.dart';
import '../../game/pet_wish.dart';
import '../mascot/mascot_look.dart';
import '../mascot/mascot_view.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/confetti.dart';
import '../widgets/duo.dart';
import 'lesson_frame.dart';
import 'lesson_steps.dart';

/// Урок: крестик и полоска шагов сверху, шаг-игра, итог (SA F-025).
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.game, required this.lesson});
  final GameController game;
  final Lesson lesson;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final _clock = Stopwatch()..start();
  final _confetti = ConfettiController();
  int _step = 0;
  bool _ready = false;
  GameFeedback? _result;

  GameController get game => widget.game;
  Lesson get lesson => widget.lesson;

  @override
  void initState() {
    super.initState();
    // Состояние игры меняем после кадра: не во время сборки дерева.
    WidgetsBinding.instance.addPostFrameCallback((_) => game.startLesson(lesson.id).then((step) {
      if (!mounted) return;
      setState(() {
        _step = step.clamp(0, lesson.steps.length - 1);
        _ready = true;
      });
    }));
  }

  @override
  void dispose() {
    final seconds = _clock.elapsed.inSeconds;
    if (seconds > 0) Future.microtask(() => game.addLearnTime(seconds)); // не во время демонтажа
    _confetti.dispose();
    super.dispose();
  }

  /// Время на экране урока — для заданий «поучись N минут» (F-026).
  void _flushTime() {
    final seconds = _clock.elapsed.inSeconds;
    if (seconds > 0) {
      _clock.reset();
      game.addLearnTime(seconds);
    }
  }

  Future<void> _passed() async {
    _flushTime();
    if (_step + 1 < lesson.steps.length) {
      setState(() => _step++);
      await game.saveLessonStep(lesson.id, _step);
      return;
    }
    final f = await game.finishLesson(lesson.id);
    if (!mounted) return;
    setState(() => _result = f);
    if (f.reward > 0) {
      buzz(Buzz.medium);
      WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.fire());
    }
  }

  Future<void> _close() async {
    _flushTime();
    await game.saveLessonStep(lesson.id, _step); // доиграть позже (BR-11)
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final look = MascotLook.fromGame(game);
    final result = _result;
    return PopScope(
      canPop: result != null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: result != null
              ? _finish(look.withEmotion(PetEmotion.excited), result)
              : !_ready
              ? const SizedBox.shrink()
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 20, 8),
                      child: Row(
                        children: [
                          IconButton(
                            key: const Key('lesson.close'),
                            icon: const Icon(Icons.close_rounded, color: FinniColors.muted),
                            onPressed: _close,
                          ),
                          Expanded(
                            child: StepBar(count: lesson.steps.length, done: _step),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: stepView(
                        lesson.steps[_step],
                        key: ValueKey('${lesson.id}.$_step'),
                        pet: game.profile.petName,
                        look: look,
                        onPassed: _passed,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _finish(MascotLook look, GameFeedback f) {
    final minutes = (game.snapshot.learnSeconds[game.day] ?? 0) ~/ 60;
    return ConfettiBurst(
      controller: _confetti,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          children: [
            const Spacer(),
            MascotView(look: look, size: 200, semanticsLabel: game.profile.petName),
            const SizedBox(height: 12),
            const Text('Урок пройден!', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
            const SizedBox(height: 6),
            Text('${lesson.emoji} ${lesson.title}', style: const TextStyle(fontSize: 17, color: FinniColors.muted)),
            const SizedBox(height: 20),
            DuoCard(
              child: Column(
                children: [
                  if (f.reward > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CoinIcon(size: 26),
                        const SizedBox(width: 8),
                        Text('+${f.reward} за урок', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  if (f.reward > 0) const SizedBox(height: 8),
                  Text(
                    f.messages.join(' '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: FinniColors.muted, fontSize: 15),
                  ),
                  if (game.nextBlockWaitsForSleep) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Блок пройден! Следующий блок появится после сна 🌙',
                      key: Key('lesson.nextBlockAfterSleep'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: FinniColors.primary),
                    ),
                  ],
                  if (minutes > 0) ...[
                    const SizedBox(height: 8),
                    Text('Сегодня учились $minutes мин', style: const TextStyle(fontSize: 14, color: FinniColors.muted)),
                  ],
                ],
              ),
            ),
            const Spacer(),
            DuoButton(key: const Key('lesson.done'), label: 'Готово', onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}
