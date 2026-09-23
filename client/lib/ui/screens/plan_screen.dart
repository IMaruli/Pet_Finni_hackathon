import 'package:flutter/material.dart';

import '../../game/game_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/jar_view.dart';

/// План дня: три банки (SA F-010).
class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key, required this.game});
  final GameController game;

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final _values = {Basket.need: 0, Basket.want: 0, Basket.save: 0};
  String? _hint;

  GameController get game => widget.game;
  int get _available => game.economy.available.value;
  int get _used => _values.values.fold(0, (s, v) => s + v);
  int get _left => _available - _used;
  bool get _needOk => _values[Basket.need]! >= game.todaysNeedSum;

  void _change(Basket b, int delta) {
    setState(() {
      if (delta > 0 && _left <= 0) {
        _hint = 'Монеты кончились! Забери из другой банки.';
        buzz(Buzz.heavy);
        return;
      }
      final d = delta > 0 ? delta.clamp(0, _left) : delta;
      _values[b] = (_values[b]! + d).clamp(0, _available);
      _hint = null;
      buzz(Buzz.select);
    });
  }

  void _suggest() {
    setState(() {
      final need = game.todaysNeedSum.clamp(0, _available);
      final rest = _available - need;
      final save = (rest / 2).ceil();
      _values[Basket.need] = need;
      _values[Basket.save] = save;
      _values[Basket.want] = rest - save;
      _hint = 'Вот так можно. Поправь, если хочешь по-другому.';
    });
  }

  Future<void> _done() async {
    final f = await game.confirmPlan(
      need: _values[Basket.need]!,
      want: _values[Basket.want]!,
      save: _values[Basket.save]!,
    );
    if (!mounted) return;
    if (f.ok) {
      showToast(context, f.messages, emoji: '🫙', color: FinniColors.need);
      Navigator.of(context).pop();
    } else {
      setState(() => _hint = f.messages.join(' '));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('План дня')),
        body: SafeArea(child: game.planConfirmed ? _review() : _editor()),
      ),
    );
  }

  Widget _editor() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const Text(
          'Разложи монеты по банкам. План — это решение заранее.',
          textAlign: TextAlign.center,
          style: TextStyle(color: FinniColors.muted),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            key: const Key('plan.left'),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: _left == 0 ? FinniColors.need.withValues(alpha: 0.15) : FinniColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: FinniColors.coin, width: 2),
            ),
            child: Text(
              _left == 0 ? 'Все $_available 🪙 разложены ✓' : 'Не разложено: $_left 🪙 из $_available',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final b in Basket.values) Expanded(child: _jarColumn(b))],
        ),
        const SizedBox(height: 12),
        Panel(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text(_needOk ? '✅' : '☝️', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Нужное сегодня: ${game.todaysNeeds.map((i) => '${i.emoji} ${i.title} ${i.price}').join(', ')}. '
                  'Итого ${game.todaysNeedSum} 🪙.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        if (_hint != null) ...[
          const SizedBox(height: 10),
          Text(_hint!, textAlign: TextAlign.center, style: const TextStyle(color: FinniColors.primary, fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(key: const Key('plan.suggest'), onPressed: _suggest, child: const Text('💡 Подсказать')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                key: const Key('plan.done'),
                onPressed: _needOk && _left >= 0 ? _done : null,
                child: const Text('Готово'),
              ),
            ),
          ],
        ),
        if (!_needOk)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Положи в «Нужное» хотя бы ${game.todaysNeedSum} 🪙',
              textAlign: TextAlign.center,
              style: const TextStyle(color: FinniColors.muted),
            ),
          ),
      ],
    );
  }

  Widget _jarColumn(Basket b) {
    return Column(
      children: [
        JarView(title: b.title, emoji: b.emoji, color: b.color, coins: _values[b]!, capacity: _available, height: 140),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _round('−', Key('plan.${b.name}.minus'), () => _change(b, -1), () => _change(b, -5), b.color),
            const SizedBox(width: 6),
            _round('+', Key('plan.${b.name}.plus'), () => _change(b, 1), () => _change(b, 5), b.color),
          ],
        ),
      ],
    );
  }

  Widget _round(String label, Key key, VoidCallback tap, VoidCallback longPress, Color color) {
    return Semantics(
      button: true,
      label: label == '+' ? 'Добавить монету' : 'Убрать монету',
      child: GestureDetector(
        key: key,
        onTap: tap,
        onLongPress: longPress,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }

  Widget _review() {
    final plan = game.economy.plan!;
    final facts = {
      Basket.need: (plan.need.value, game.economy.spentNeed.value),
      Basket.want: (plan.want.value, game.economy.spentWant.value),
      Basket.save: (plan.save.value, game.economy.savedThisPeriod.value),
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('План на сегодня готов. Вот как идут дела:', textAlign: TextAlign.center, style: TextStyle(fontSize: 17)),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final b in Basket.values)
              Expanded(
                child: JarView(title: b.title, emoji: b.emoji, color: b.color, coins: facts[b]!.$1, capacity: plan.total.value, height: 130),
              ),
          ],
        ),
        const SizedBox(height: 16),
        for (final b in Basket.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Panel(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      BasketBadge(b),
                      Text(
                        '${b == Basket.save ? 'отложено' : 'потрачено'} ${facts[b]!.$2} из ${facts[b]!.$1}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ProgressBar(value: facts[b]!.$1 == 0 ? 0 : facts[b]!.$2 / facts[b]!.$1, color: b.color),
                ],
              ),
            ),
          ),
        const Text(
          'Новый план — завтра утром. Так проще держать слово.',
          textAlign: TextAlign.center,
          style: TextStyle(color: FinniColors.muted),
        ),
      ],
    );
  }
}
