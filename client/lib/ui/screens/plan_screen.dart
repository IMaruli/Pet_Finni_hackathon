import 'package:flutter/material.dart';

import '../../economy/catalog_item.dart';
import '../../game/game_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/duo.dart';
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Center(
          child: Column(
            key: const Key('plan.left'),
            children: [
              Text(
                '$_left',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -2,
                  height: 1,
                  color: _left == 0 ? FinniColors.need : FinniColors.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _left == 0 ? 'Все $_available монет разложены' : 'из $_available монет осталось разложить',
                style: const TextStyle(fontSize: 15, color: FinniColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        DuoCard(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final b in Basket.values) Expanded(child: _jarColumn(b))],
          ),
        ),
        GroupedSection(
          header: 'Нужное сегодня',
          footer: _needOk ? null : 'Положи в «Нужное» хотя бы ${game.todaysNeedSum} монет.',
          children: [
            for (final i in game.todaysNeeds)
              GroupedRow(
                leading: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: FinniColors.fill, borderRadius: BorderRadius.circular(8)),
                  child: Text(i.emoji, style: const TextStyle(fontSize: 18)),
                ),
                title: i.title,
                value: '${i.price}',
                chevron: false,
              ),
            GroupedRow(
              icon: _needOk ? Icons.check_rounded : Icons.shopping_basket_rounded,
              iconColor: _needOk ? FinniColors.need : FinniColors.muted,
              title: 'Итого',
              value: '${game.todaysNeedSum}',
              chevron: false,
            ),
          ],
        ),
        if (_hint != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(_hint!, textAlign: TextAlign.center, style: const TextStyle(color: FinniColors.primary, fontSize: 15)),
          ),
        const SizedBox(height: 20),
        DuoButton(key: const Key('plan.done'), label: 'Готово', onPressed: _needOk && _left == 0 ? _done : null), // все монеты в банках (F-024)
        const SizedBox(height: 10),
        DuoButton(key: const Key('plan.suggest'), label: 'Подсказать', icon: Icons.auto_awesome_rounded, color: FinniColors.surface, onPressed: _suggest),
      ],
    );
  }

  Widget _jarColumn(Basket b) {
    return Column(
      children: [
        JarView(title: b.title, emoji: b.emoji, color: b.color, coins: _values[b]!, capacity: _available, height: 124),
        const SizedBox(height: 10),
        _stepper(b),
      ],
    );
  }

  /// Степпер в стиле iOS: « − | + » в серой капсуле; долгое нажатие — ±5.
  Widget _stepper(Basket b) {
    Widget half(String label, Key key, int delta) => Semantics(
      button: true,
      label: delta > 0 ? 'Добавить монету в «${b.title}»' : 'Убрать монету из «${b.title}»',
      child: GestureDetector(
        key: key,
        behavior: HitTestBehavior.opaque,
        onTap: () => _change(b, delta),
        onLongPress: () => _change(b, delta * 5),
        child: SizedBox(
          width: 44,
          height: 36,
          child: Center(child: Icon(delta > 0 ? Icons.add_rounded : Icons.remove_rounded, size: 22, color: FinniColors.ink)),
        ),
      ),
    );
    return Container(
      decoration: BoxDecoration(color: FinniColors.fill, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          half('−', Key('plan.${b.name}.minus'), -1),
          Container(width: 0.8, height: 18, color: const Color(0x33000000)),
          half('+', Key('plan.${b.name}.plus'), 1),
        ],
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
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ProgressBar(value: facts[b]!.$1 == 0 ? 0 : facts[b]!.$2 / facts[b]!.$1, color: b.color),
                ],
              ),
            ),
          ),
        // История покупок текущего периода (ТЗ 2.5.6, F-056).
        GroupedSection(
          key: const Key('plan.history'),
          header: 'Покупки сегодня',
          footer: game.purchasesToday.isEmpty ? 'Пока ничего не куплено.' : null,
          children: [
            for (final (i, item) in game.purchasesToday.indexed)
              GroupedRow(
                key: Key('plan.history.$i'),
                leading: Text(item.emoji, style: const TextStyle(fontSize: 24)),
                title: item.title,
                subtitle: item.kind == ItemKind.need ? 'Нужное' : 'Хочу',
                trailing: Text('−${item.price}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                chevron: false,
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Новый план — завтра утром. Так проще держать слово.',
          textAlign: TextAlign.center,
          style: TextStyle(color: FinniColors.muted),
        ),
      ],
    );
  }
}
