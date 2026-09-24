import 'package:flutter/material.dart';

import '../../content/models.dart';
import '../../game/game_controller.dart';
import '../../game/game_feedback.dart';
import '../mascot/mascot_look.dart';
import '../mascot/mascot_view.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/duo.dart';

const _themeTitle = {QuestTheme.budget: 'Бюджет', QuestTheme.save: 'Копилка', QuestTheme.buy: 'Покупки'};
const _themeIcon = {
  QuestTheme.budget: Icons.pie_chart_rounded,
  QuestTheme.save: Icons.savings_rounded,
  QuestTheme.buy: Icons.shopping_cart_rounded,
};

const _speakerEmoji = {'narrator': '📖', 'friend': '👧', 'seller': '🧑‍🍳'};

/// Задание-сцена (SA F-012).
class QuestScreen extends StatefulWidget {
  const QuestScreen({super.key, required this.game, this.review});
  final GameController game;

  /// Пересмотр пройденной сцены: объяснения без монет (SA F-017 BR-09).
  final Quest? review;

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  final _mascot = MascotController();
  final _scroll = ScrollController();
  late final Quest _quest = widget.review ?? widget.game.todaysQuest;
  late int _shown = widget.review == null ? 1 : widget.review!.lines.length;
  int? _chosen;
  GameFeedback? _result;

  GameController get game => widget.game;
  bool get _allShown => _shown >= _quest.lines.length;

  @override
  void dispose() {
    _mascot.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _fill(String s) =>
      s.replaceAll('{pet}', game.profile.petName).replaceAll('{player}', game.profile.playerName);

  void _advance() {
    if (_allShown) return;
    setState(() => _shown++);
    buzz(Buzz.select);
    _scrollDown();
  }

  void _scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) {
      _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  });

  Future<void> _choose(int i) async {
    final f = widget.review == null
        ? await game.answerQuest(i)
        : GameFeedback(ok: true, repeat: true, messages: [_quest.choices[i].explanation]);
    if (!mounted) return;
    setState(() {
      _chosen = i;
      _result = f;
    });
    if (_quest.choices[i].wise) {
      _mascot.jump();
      buzz(Buzz.medium);
    } else {
      _mascot.shake();
    }
    _scrollDown();
  }

  @override
  Widget build(BuildContext context) {
    final look = MascotLook.fromGame(game);
    return Scaffold(
      appBar: AppBar(title: Text(_quest.title)),
      body: SafeArea(
        child: GestureDetector(
          key: const Key('quest.tap'),
          behavior: HitTestBehavior.translucent,
          onTap: _advance,
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Center(
                child: DuoChip(text: _themeTitle[_quest.theme]!, icon: _themeIcon[_quest.theme]),
              ),
              Center(child: MascotView(look: look, controller: _mascot, size: 150, semanticsLabel: game.profile.petName)),
              for (var i = 0; i < _shown && i < _quest.lines.length; i++) _line(_quest.lines[i], look),
              if (!_allShown)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('Нажми, чтобы продолжить ▸', textAlign: TextAlign.center, style: TextStyle(color: FinniColors.muted)),
                ),
              if (_allShown && _result == null) ...[
                const SizedBox(height: 16),
                Text('Что сделает ${game.profile.petName}?', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                for (var i = 0; i < _quest.choices.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DuoButton(
                      key: Key('quest.choice.$i'),
                      label: _fill(_quest.choices[i].text),
                      color: FinniColors.surface,
                      height: 64,
                      onPressed: () => _choose(i),
                    ),
                  ),
              ],
              if (_result != null) _resultCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(QuestLine line, MascotLook look) {
    final isPet = line.speaker == 'pet';
    final avatar = isPet
        ? SizedBox(width: 52, height: 52, child: MascotView(look: look, size: 52, animated: false, interactive: false))
        : CircleAvatar(
            radius: 26,
            backgroundColor: FinniColors.surface,
            child: Text(_speakerEmoji[line.speaker] ?? '💬', style: const TextStyle(fontSize: 26)),
          );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child)),
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          textDirection: isPet ? TextDirection.rtl : TextDirection.ltr,
          children: [
            avatar,
            const SizedBox(width: 8),
            Flexible(
              child: SpeechBubble(
                text: _fill(line.text),
                tailLeft: !isPet,
                color: isPet ? const Color(0xFFFFF0C2) : line.speaker == 'narrator' ? const Color(0xFFF2EEFF) : FinniColors.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultCard() {
    final choice = _quest.choices[_chosen!];
    final f = _result!;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Panel(
        color: choice.wise ? const Color(0xFFE9F8F0) : const Color(0xFFFFF3E0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              choice.wise ? '🌟 Мудрое решение!' : '🤔 Можно лучше. Вот почему:',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('«${_fill(choice.text)}»', style: const TextStyle(fontStyle: FontStyle.italic, color: FinniColors.muted)),
            const SizedBox(height: 8),
            Text(_fill(choice.explanation), style: const TextStyle(fontSize: 17)),
            const SizedBox(height: 12),
            if (f.reward > 0)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.4, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: Text(
                  '+${f.reward} 🪙  Задание: ${_quest.title}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: FinniColors.need),
                ),
              )
            else
              Text(
                widget.review != null ? 'Это повтор урока — монеты не начисляются.' : 'Монеты за задание сегодня уже получены. Это для тренировки!',
                textAlign: TextAlign.center,
                style: TextStyle(color: FinniColors.muted),
              ),
            const SizedBox(height: 12),
            DuoButton(
              key: const Key('quest.retry'),
              label: 'Другой вариант',
              color: FinniColors.surface,
              onPressed: () => setState(() {
                _chosen = null;
                _result = null;
              }),
            ),
            const SizedBox(height: 10),
            DuoButton(key: const Key('quest.home'), label: 'Готово', color: FinniColors.teal, onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}
