import 'package:flutter/material.dart';

import '../../content/models.dart';
import '../../economy/catalog_item.dart';
import '../../game/game_controller.dart';
import '../../game/minigames.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/duo.dart';
import 'games_hub.dart';

/// «Уложись в бюджет» (SA F-013).
class BudgetGame extends StatefulWidget {
  const BudgetGame({super.key, required this.game});
  final GameController game;

  @override
  State<BudgetGame> createState() => _BudgetGameState();
}

class _BudgetGameState extends State<BudgetGame> {
  /// Первая игра — ситуация дня (их 10), «Ещё раз» — случайная другая из пула (F-033).
  late BudgetPuzzle _puzzle = widget.game.content.puzzleForDay(widget.game.day);
  final _picked = <int>{};
  int _attempts = 0;
  String? _message;

  BudgetCheck get _check => checkBasket(_puzzle, _picked);

  void _toggle(int i) {
    setState(() {
      if (!_picked.remove(i)) _picked.add(i);
      _message = null;
    });
    buzz(Buzz.select);
  }

  void _hint() {
    setState(() {
      for (var i = 0; i < _puzzle.items.length; i++) {
        if (_puzzle.items[i].kind == ItemKind.need) _picked.add(i);
      }
      _message = 'Подсказка: сначала всё нужное. Теперь посмотри, что ещё влезает.';
    });
  }

  Future<void> _submit() async {
    final c = _check;
    _attempts++;
    if (!c.ok) {
      buzz(Buzz.heavy);
      setState(() {
        _message = c.missingNeeds.isNotEmpty
            ? 'Не хватает нужного: ${c.missingNeeds.map((i) => '${i.emoji} ${i.title}').join(', ')}.'
            : 'Перебор на ${c.over} 🪙. Убери что-то из хотелок.';
      });
      return;
    }
    buzz(Buzz.medium);
    final win = _attempts == 1;
    final again = await showGameResult(
      context,
      widget.game,
      gameId: 'budget',
      win: win,
      score: win ? 3 : (_attempts == 2 ? 2 : 1),
      headline: win ? 'С первой попытки!' : 'Уложился!',
      details: Text(
        'Потрачено ${c.total} из ${_puzzle.budget} 🪙, осталось ${c.left}. '
        '${c.left > 0 ? 'Остаток можно отложить!' : 'Ровно в бюджет — тоже отлично.'}',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16),
      ),
    );
    if (!mounted) return;
    if (again) {
      setState(() {
        _puzzle = nextPuzzle(widget.game.content.puzzles, previous: _puzzle);
        _picked.clear();
        _attempts = 0;
        _message = null;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _check;
    return Scaffold(
      appBar: AppBar(title: const Text('🧾 Уложись в бюджет')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(_puzzle.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  if (_puzzle.story.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 2),
                      child: Text(_puzzle.story, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                    ),
                  Text(
                    'Бюджет ${_puzzle.budget} 🪙. Возьми всё нужное и не выйди за бюджет.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: FinniColors.muted, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < _puzzle.items.length; i++) _itemTile(i),
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_message!, textAlign: TextAlign.center, style: const TextStyle(color: FinniColors.primary, fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: FinniColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12)],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('🧺', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ProgressBar(
                          value: c.total / _puzzle.budget,
                          color: c.over > 0 ? FinniColors.want : FinniColors.need,
                          height: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${c.total} / ${_puzzle.budget}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.over > 0 ? FinniColors.want : FinniColors.ink),
                      ),
                    ],
                  ),
                  if (c.over > 0)
                    Text('Перебор на ${c.over} 🪙', style: const TextStyle(color: FinniColors.want, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (_attempts > 0)
                        Expanded(child: DuoButton(key: const Key('budget.hint'), label: '💡 Подсказка', color: FinniColors.surface, onPressed: _hint)),
                      if (_attempts > 0) const SizedBox(width: 10),
                      Expanded(
                        child: DuoButton(
                          key: const Key('budget.check'),
                          label: 'Проверить',
                          color: FinniColors.teal,
                          onPressed: _picked.isEmpty ? null : _submit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemTile(int i) {
    final item = _puzzle.items[i];
    final on = _picked.contains(i);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedScale(
        scale: on ? 1.02 : 1,
        duration: const Duration(milliseconds: 150),
        child: Panel(
          key: Key('budget.item.$i'),
          color: on ? const Color(0xFFFFF0DE) : null,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          onTap: () => _toggle(i),
          child: Row(
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    BasketBadge(basketOf(item.kind), small: true),
                  ],
                ),
              ),
              Text('${item.price} 🪙', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Icon(on ? Icons.check_circle : Icons.add_circle_outline, color: on ? FinniColors.need : FinniColors.muted, size: 30),
            ],
          ),
        ),
      ),
    );
  }
}
