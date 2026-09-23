import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../game/game_controller.dart';
import '../../game/minigames.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'games_hub.dart';

/// «Копилка-ловец» (SA F-013).
class CatcherGame extends StatefulWidget {
  const CatcherGame({super.key, required this.game});
  final GameController game;

  @override
  State<CatcherGame> createState() => _CatcherGameState();
}

class _Popup {
  _Popup(this.text, this.at, this.good, this.born);
  final String text;
  final Offset at;
  final bool good;
  final double born;
}

class _CatcherGameState extends State<CatcherGame> with SingleTickerProviderStateMixin {
  late CatcherModel _model = CatcherModel(widget.game.content.catcher);
  late final Ticker _ticker = createTicker(_tick);
  final _popups = <_Popup>[];
  Size _field = Size.zero;
  Duration _last = Duration.zero;
  double _clock = 0;
  bool _started = false;
  bool _reported = false;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _model = CatcherModel(widget.game.content.catcher)..jarX = _field.width / 2;
      _popups.clear();
      _started = true;
      _reported = false;
      _last = Duration.zero;
    });
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.1);
    _last = elapsed;
    _clock += dt;
    setState(() {
      _model.tick(dt, _field);
      for (final e in _model.takeEvents()) {
        _popups.add(_Popup(e.value > 0 ? '+${e.value}' : 'Хотелка съела ${-e.value}!', e.at, e.value > 0, _clock));
        buzz(e.value > 0 ? Buzz.light : Buzz.heavy);
      }
      _popups.removeWhere((p) => _clock - p.born > 0.9);
    });
    if (_model.finished && !_reported) {
      _reported = true;
      _ticker.stop();
      _finish();
    }
  }

  Future<void> _finish() async {
    final m = _model;
    final again = await showGameResult(
      context,
      widget.game,
      gameId: 'catcher',
      win: m.win,
      score: m.score,
      headline: 'В банке ${m.score} 🪙${m.win ? ' — цель!' : ''}',
      details: Text(
        m.win
            ? 'Ты набрал ${m.config.target}+ и не дал хотелкам всё съесть. Вот так и копят!'
            : 'Цель была ${m.config.target}. Хотелки отнимают накопленное — обходи их!',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16),
      ),
    );
    if (!mounted) return;
    if (again) {
      _start();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _model;
    return Scaffold(
      backgroundColor: const Color(0xFFE6F4FF),
      appBar: AppBar(title: const Text('🫙 Копилка-ловец')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CoinChip(value: m.score, emoji: '🫙', label: 'из ${m.config.target}'),
                  const SizedBox(width: 12),
                  Expanded(child: ProgressBar(value: m.score / m.config.target, color: FinniColors.need)),
                  const SizedBox(width: 12),
                  Text('⏱️ ${m.timeLeft.ceil()}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  _field = Size(box.maxWidth, box.maxHeight);
                  if (!_started) _model.jarX = box.maxWidth / 2;
                  final jarTop = box.maxHeight - CatcherModel.jarHeight - 10;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (d) => setState(() => _model.jarX = (m.jarX + d.delta.dx).clamp(40, box.maxWidth - 40)),
                    onTapDown: (d) => setState(() => _model.jarX = d.localPosition.dx.clamp(40, box.maxWidth - 40)),
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        for (final item in m.items)
                          Positioned(
                            left: item.x - 20,
                            top: item.y - 20,
                            child: Text(item.emoji, style: TextStyle(fontSize: item.isTemptation ? 38 : (item.value > 1 ? 38 : 30))),
                          ),
                        for (final p in _popups)
                          Positioned(
                            left: p.at.dx - 60,
                            top: p.at.dy - 70 - (_clock - p.born) * 50,
                            width: 120,
                            child: Opacity(
                              opacity: (1 - (_clock - p.born) / 0.9).clamp(0, 1),
                              child: Text(
                                p.text,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: p.good ? FinniColors.need : FinniColors.want,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          left: m.jarX - CatcherModel.jarWidth / 2,
                          top: jarTop,
                          width: CatcherModel.jarWidth,
                          height: CatcherModel.jarHeight,
                          child: Container(
                            decoration: BoxDecoration(
                              color: FinniColors.save.withValues(alpha: 0.18),
                              border: Border.all(color: FinniColors.save, width: 4),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12), bottom: Radius.circular(28)),
                            ),
                            alignment: Alignment.center,
                            child: const Text('🐷', style: TextStyle(fontSize: 34)),
                          ),
                        ),
                        if (!_started)
                          Positioned.fill(
                            child: Container(
                              color: Colors.white.withValues(alpha: 0.85),
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('🪙 💰 — лови!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${m.config.temptations.join(' ')} — хотелки. Поймаешь — они съедят ${m.config.temptationPenalty} монеты из банки.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Набери ${m.config.target} за ${m.config.seconds} секунд. Води банку пальцем.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 18, color: FinniColors.muted),
                                  ),
                                  const SizedBox(height: 20),
                                  FilledButton(key: const Key('catcher.start'), onPressed: _start, child: const Text('Старт!')),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
