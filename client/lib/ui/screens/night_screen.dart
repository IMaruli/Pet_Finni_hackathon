import 'dart:math';

import 'package:flutter/material.dart';

import '../../economy/economy_state.dart';
import '../../game/game_controller.dart';
import '../../store/snapshot.dart';
import '../mascot/mascot_look.dart';
import '../mascot/mascot_painter.dart';
import '../mascot/mascot_view.dart';
import '../mascot/sphere.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/confetti.dart';
import '../widgets/plan_fact_bars.dart';

/// «Лечь спать»: подтверждение, закрытие дня, ночь (SA F-015).
Future<void> goToSleep(BuildContext context, GameController game) async {
  if (!game.needsDone) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Нужное не куплено'),
        content: Text('${game.profile.petName} ляжет спать без нужного и будет грустить. Всё равно спать?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(d).pop(false), child: const Text('Сначала куплю')),
          FilledButton(key: const Key('night.confirm'), onPressed: () => Navigator.of(d).pop(true), child: const Text('Спать')),
        ],
      ),
    );
    if (ok != true) return;
  }
  final summary = await game.endDay();
  if (!context.mounted) return;
  await Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (_, _, _) => NightScreen(game: game, summary: summary),
      transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
    ),
  );
  if (context.mounted) {
    showToast(
      context,
      ['Доброе утро! +${game.content.config.pocketMoney} 🪙 карманных', 'День ${game.day}: начни с плана.'],
      emoji: '☀️',
      color: FinniColors.primary,
    );
  }
}

class NightScreen extends StatefulWidget {
  const NightScreen({super.key, required this.game, required this.summary});
  final GameController game;
  final DaySummary summary;

  @override
  State<NightScreen> createState() => _NightScreenState();
}

class _NightScreenState extends State<NightScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _stars = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  final _confetti = ConfettiController();
  final _mascot = MascotController();
  bool _showSummary = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() => _showSummary = true);
      if (widget.summary.grew) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          _confetti.fire();
          _mascot.dance();
          buzz(Buzz.heavy);
        });
      }
    });
  }

  @override
  void dispose() {
    _stars.dispose();
    _confetti.dispose();
    _mascot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final s = widget.summary;
    final base = MascotLook.fromGame(game);
    final look = MascotLook(
      color: base.color,
      hair: base.hair,
      skin: base.skin,
      accessories: base.accessories,
      mood: s.mood,
      stage: s.stageAfter,
    );
    return Scaffold(
      backgroundColor: FinniColors.night,
      body: ConfettiBurst(
        controller: _confetti,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(animation: _stars, builder: (_, _) => CustomPaint(painter: _StarsPainter(_stars.value))),
            ),
            SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: _showSummary ? _summary(look) : _sleeping(look),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sleeping(MascotLook look) {
    return Center(
      key: const ValueKey('sleep'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💤', style: TextStyle(fontSize: 40)),
          CustomPaint(size: const Size.square(200), painter: MascotPainter(look: look, pose: const SpherePose(0, 0.15), blink: 1)),
          Text('Спокойной ночи, ${widget.game.profile.petName}!', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _summary(MascotLook look) {
    final game = widget.game;
    final s = widget.summary;
    final name = game.profile.petName;
    const white = TextStyle(color: Colors.white);
    return ListView(
      key: const ValueKey('summary'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('Итог дня ${s.day}', textAlign: TextAlign.center, style: white.copyWith(fontSize: 26, fontWeight: FontWeight.w900)),
        Center(child: MascotView(look: look, controller: _mascot, size: 170, semanticsLabel: name)),
        if (s.grew)
          Text(
            game.content.text('stage.up', {'pet': name, 'n': game.content.text('stage.${s.stageAfter}')}),
            textAlign: TextAlign.center,
            style: const TextStyle(color: FinniColors.coin, fontSize: 22, fontWeight: FontWeight.w900),
          ),
        const SizedBox(height: 12),
        _card(
          child: Column(
            children: [
              const Text('План и факт', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              PlanFactBars(summary: s),
            ],
          ),
        ),
        _card(
          child: Row(
            children: [
              Text(switch (s.mood) {
                PetMood.glad => '😄',
                PetMood.steady => '🙂',
                PetMood.uneasy => '😕',
              }, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Настроение: ${game.content.text('mood.${s.mood.name}')}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    Text(game.content.text('mood.${s.mood.name}.why', {'pet': name})),
                  ],
                ),
              ),
            ],
          ),
        ),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.good ? '✅ Хороший день!' : '🌱 Завтра будет лучше',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              _ladder(s),
              const SizedBox(height: 6),
              Text(game.content.text('stage.why', {'n': '${s.goodPeriods}'})),
            ],
          ),
        ),
        _card(
          color: const Color(0xFFFFF3C4),
          child: Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 10),
              Expanded(child: Text(game.adviceFor(s), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('night.morning'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Доброе утро ☀️'),
        ),
      ],
    );
  }

  Widget _ladder(DaySummary s) {
    const need = {1: 0, 2: 2, 3: 4};
    return Row(
      children: [
        for (var st = 1; st <= 3; st++)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: st <= s.stageAfter ? FinniColors.primary : FinniColors.line,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    widget.game.content.text('stage.$st'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: st <= s.stageAfter ? Colors.white : FinniColors.ink),
                  ),
                  Text(
                    st == 1 ? 'старт' : '${need[st]} хор. дня',
                    style: TextStyle(fontSize: 11, color: st <= s.stageAfter ? Colors.white70 : FinniColors.muted),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _card({required Widget child, Color? color}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color ?? FinniColors.surface, borderRadius: BorderRadius.circular(24)),
      child: child,
    ),
  );
}

class _StarsPainter extends CustomPainter {
  _StarsPainter(this.t);
  final double t;
  static final _stars = List.generate(60, (i) {
    final r = Random(i * 7919);
    return (r.nextDouble(), r.nextDouble() * 0.7, r.nextDouble() * 2 * pi, 1 + r.nextDouble() * 2.2);
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final (x, y, phase, radius) in _stars) {
      final a = 0.35 + 0.65 * (0.5 + 0.5 * sin(t * 2 * pi + phase));
      canvas.drawCircle(Offset(x * size.width, y * size.height), radius, Paint()..color = Colors.white.withValues(alpha: a));
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => old.t != t;
}
