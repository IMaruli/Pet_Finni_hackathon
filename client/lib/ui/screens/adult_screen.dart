import 'package:flutter/material.dart';

import '../motion.dart';
import '../../game/game_controller.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/duo.dart';

/// Барьер: удерживать кнопку [hold] (SA F-016).
class AdultGate extends StatefulWidget {
  const AdultGate({super.key, required this.onPassed, this.hold = const Duration(seconds: 3)});
  final VoidCallback onPassed;
  final Duration hold;

  @override
  State<AdultGate> createState() => _AdultGateState();
}

class _AdultGateState extends State<AdultGate> with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(vsync: this, duration: widget.hold)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        buzz(Buzz.medium);
        widget.onPassed();
      }
    });

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('👪', style: TextStyle(fontSize: 56)),
        const Text('Раздел для взрослых', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Нажмите и удерживайте кнопку 3 секунды', style: TextStyle(color: FinniColors.muted)),
        const SizedBox(height: 24),
        GestureDetector(
          key: const Key('adult.hold'),
          onTapDown: (_) => _progress.forward(),
          onTapUp: (_) => _progress.reverse(),
          onTapCancel: () => _progress.reverse(),
          child: AnimatedBuilder(
            animation: _progress,
            builder: (_, _) => SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(value: _progress.value, strokeWidth: 10, backgroundColor: FinniColors.line, color: FinniColors.primary),
                  const Center(
                    child: Text('Держать', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Раздел взрослого: цели приложения, прогресс без оценок, сброс.
class AdultScreen extends StatefulWidget {
  const AdultScreen({super.key, required this.game});
  final GameController game;

  @override
  State<AdultScreen> createState() => _AdultScreenState();
}

class _AdultScreenState extends State<AdultScreen> {
  bool _passed = false;

  static const _competencies = [
    ('💰', 'Доходы и расходы', 'Монеты приходят (карманные, задания) и уходят. Ребёнок видит баланс и планирует.'),
    ('🥣', 'Нужное и желаемое', 'Каждый день есть список нужного; хотелки — после. Игра «Нужно или хочу?».'),
    ('🛒', 'Покупки при ограниченном бюджете', 'Нельзя уйти в минус; при нехватке объясняем, что делать.'),
    ('🐷', 'Цель и регулярные накопления', 'Копилка с целью, снятие — с предупреждением и двойным подтверждением.'),
    ('🔍', 'Оценка своих решений', 'Вечером — план и факт, настроение героя и совет на завтра.'),
    ('🤝', 'Вместе со взрослым', 'Этот раздел: прогресс без оценок и сброс профиля.'),
  ];

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Сбросить профиль?'),
        content: const Text('Герой, монеты, покупки и прогресс удалятся с этого телефона. Отменить нельзя.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(d).pop(false), child: const Text('Отмена')),
          FilledButton(
            key: const Key('adult.reset.confirm'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(d).pop(true),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final nav = Navigator.of(context);
    await widget.game.reset();
    nav.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Взрослым')),
      body: SafeArea(
        child: !widget.game.hasProfile
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Профиля ещё нет. Пусть ребёнок сначала создаст героя.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
                ),
              )
            : _passed
            ? _content()
            : Center(child: AdultGate(onPassed: () => setState(() => _passed = true))),
      ),
    );
  }

  Widget _content() {
    final g = widget.game;
    int doneIn(String topic) => g.content.lessonsOf(topic).where((l) => g.isLessonDone(l.id)).length;
    final minutes = g.snapshot.learnSeconds.values.fold(0, (s, v) => s + v) ~/ 60;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Чему учит приложение', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Все суммы — вымышленные игровые монеты. Они не имеют ценности вне игры и ни с чем не связаны.', style: TextStyle(color: FinniColors.muted)),
        const SizedBox(height: 8),
        for (final (emoji, title, text) in _competencies)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Text(emoji, style: const TextStyle(fontSize: 28)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(text),
          ),
        const SizedBox(height: 12),
        const Text('Прогресс', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row('Игрок', g.profile.playerName),
              _row('Герой', '${g.profile.petName}, ${g.stageTitle}'),
              _row('Игровой день', '${g.day}'),
              _row('Хороших дней всего', '${g.economy.goodPeriods}'),
              _row('В копилке', '${g.economy.savings.value} 🪙'),
              _row('Цели достигнуты', '${g.inventory.goalsDone.length} из ${g.content.goals.length}'),
              for (final t in g.content.topics) _row('Уроки: ${t.title}', '${doneIn(t.id)} из ${g.content.lessonsOf(t.id).length}'),
              _row('Время в уроках', '$minutes мин'),
              if (g.snapshot.lastSummary case final s?)
                _row('Вчера: план → факт', 'нужное ${s.planNeed}→${s.spentNeed}, хочу ${s.planWant}→${s.spentWant}, отложить ${s.planSave}→${s.saved}'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text('Подсказка: спросите, почему герой сегодня радуется или грустит, и что ребёнок сделает завтра.', style: TextStyle(color: FinniColors.muted)),
        const SizedBox(height: 16),
        SwitchListTile(
          key: const Key('adult.sound'),
          title: const Text('Звук и вибрация'),
          value: g.snapshot.soundOn,
          onChanged: (v) async {
            await g.setSound(v);
            setState(() {});
          },
        ),
        // ТЗ 3.6: анимации можно отключить (F-058). Учитывается и системная «Удалить анимацию».
        SwitchListTile(
          key: const Key('adult.motion'),
          title: const Text('Меньше движения'),
          subtitle: const Text('Герой и пузыри не качаются, без конфетти'),
          value: g.snapshot.reduceMotion,
          onChanged: (v) async {
            await g.setReduceMotion(v);
            Motion.setting = v;
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        DuoButton(key: const Key('adult.reset'), label: 'Сбросить профиль (тест)', color: const Color(0xFFE06A5A), onPressed: _reset),
      ],
    );
  }

  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(k, style: const TextStyle(color: FinniColors.muted)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
