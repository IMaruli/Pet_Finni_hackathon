import 'package:flutter/material.dart';

import '../../economy/catalog_item.dart';
import '../../game/game_controller.dart';
import '../../game/minigames.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/duo.dart';
import 'games_hub.dart';

/// «Нужно или хочу?» (SA F-013).
class SortGame extends StatefulWidget {
  const SortGame({super.key, required this.game, this.seconds = 40});
  final GameController game;
  final int seconds;

  @override
  State<SortGame> createState() => _SortGameState();
}

class _SortGameState extends State<SortGame> with SingleTickerProviderStateMixin {
  late SortRound _round;
  late final AnimationController _timer = AnimationController(vsync: this, duration: Duration(seconds: widget.seconds))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _finish();
    });
  bool? _lastRight;
  double _drag = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _round = SortRound(widget.game.content.sortCards);
    _finished = false;
    _lastRight = null;
    _timer.forward(from: 0);
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  void _answer(ItemKind kind) {
    if (_finished || _round.finished) return;
    final right = _round.answer(kind);
    buzz(right ? Buzz.light : Buzz.heavy);
    setState(() {
      _lastRight = right;
      _drag = 0;
    });
    if (_round.finished) _finish();
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    _timer.stop();
    final r = _round;
    final again = await showGameResult(
      context,
      widget.game,
      gameId: 'sort',
      win: r.win,
      score: r.score,
      headline: '${r.score} из ${r.total} верно${r.win ? '!' : ''}',
      details: r.mistakes.isEmpty && r.index == r.total
          ? const Text('Ни одной ошибки! Ты отлично отличаешь нужное от хотелок.', textAlign: TextAlign.center)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (r.index < r.total)
                  Text('Время вышло: разобрано ${r.index} из ${r.total}.', style: const TextStyle(color: FinniColors.muted)),
                for (final m in r.mistakes)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Panel(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        '${m.emoji} ${m.title} — это ${m.kind == ItemKind.need ? '«Нужно»' : '«Хочу»'}: ${m.why}',
                      ),
                    ),
                  ),
              ],
            ),
    );
    if (!mounted) return;
    if (again) {
      setState(_start);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _round;
    return Scaffold(
      appBar: AppBar(title: const Text('🧺 Нужно или хочу?')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _timer,
                builder: (_, _) => Row(
                  children: [
                    const Text('⏱️', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(child: ProgressBar(value: 1 - _timer.value, color: FinniColors.primary)),
                    const SizedBox(width: 8),
                    Text('${(widget.seconds * (1 - _timer.value)).ceil()} с', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('Карточка ${r.finished ? r.total : r.index + 1} из ${r.total} · верно ${r.score}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: FinniColors.muted)),
              const Spacer(),
              if (!r.finished)
                GestureDetector(
                  onHorizontalDragUpdate: (d) => setState(() => _drag += d.delta.dx),
                  onHorizontalDragEnd: (_) {
                    if (_drag < -80) {
                      _answer(ItemKind.need);
                    } else if (_drag > 80) {
                      _answer(ItemKind.want);
                    } else {
                      setState(() => _drag = 0);
                    }
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                    child: Transform.translate(
                      key: ValueKey(r.index),
                      offset: Offset(_drag, 0),
                      child: Transform.rotate(
                        angle: _drag / 900,
                        child: Container(
                          width: 240,
                          height: 260,
                          decoration: BoxDecoration(
                            color: FinniColors.surface,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 8))],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(r.current.emoji, style: const TextStyle(fontSize: 96)),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(r.current.title, textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                height: 28,
                child: _lastRight == null
                    ? const Text('Смахни влево — «Нужно», вправо — «Хочу»', style: TextStyle(color: FinniColors.muted))
                    : Text(
                        _lastRight! ? '✅ Верно!' : '❌ Не совсем — разберём в конце',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _lastRight! ? FinniColors.need : FinniColors.want,
                        ),
                      ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(child: _bigButton(Basket.need, ItemKind.need, const Key('sort.need'))),
                  const SizedBox(width: 12),
                  Expanded(child: _bigButton(Basket.want, ItemKind.want, const Key('sort.want'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bigButton(Basket b, ItemKind kind, Key key) => DuoButton(
    key: key,
    label: kind == ItemKind.need ? 'Нужно' : 'Хочу',
    icon: b.icon,
    color: b.color,
    height: 68,
    onPressed: () => _answer(kind),
  );
}
