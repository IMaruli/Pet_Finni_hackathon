import 'package:flutter/material.dart';

import '../../game/game_controller.dart';
import '../mascot/mascot_look.dart';
import '../mascot/mascot_view.dart';
import '../room/room_painter.dart';
import '../room/room_scene.dart';
import '../screens/adult_screen.dart';
import '../screens/clothes_screen.dart';
import '../screens/glossary_screen.dart';
import '../screens/intro_screen.dart';
import '../screens/night_screen.dart';
import '../screens/plan_screen.dart';
import '../screens/quest_screen.dart';
import '../screens/room_screen.dart';
import '../screens/savings_screen.dart';
import '../shell/main_shell.dart';
import '../theme.dart';
import '../widgets/duo.dart';

enum DayStep { plan, needs, quest, game, save }

DayStep nextStep(GameController g) {
  if (!g.planConfirmed) return DayStep.plan;
  if (!g.needsDone) return DayStep.needs;
  if (!g.questDoneToday) return DayStep.quest;
  if (!g.gameRewardToday) return DayStep.game;
  return DayStep.save;
}

/// Дом (Figma 02): комната на весь экран, герой, плавающие элементы (SA F-017 BR-03).
class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.game});
  final GameController game;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _mascot = MascotController();
  int _room = 1;

  GameController get game => widget.game;

  @override
  void dispose() {
    _mascot.dispose();
    super.dispose();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) _mascot.jump();
  }

  @override
  Widget build(BuildContext context) {
    final name = game.profile.petName;
    final room = game.inventory.rooms > 1 ? _room : 1;
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        const feetY = 0.66;
        final feet = heroAnchor(size, feetY: feetY);
        final heroSize = size.width * 0.5;
        return Stack(
          children: [
            Positioned.fill(
              child: RoomScene(
                inventory: game.inventory,
                room: room,
                feetY: feetY,
                heroScale: 0.5,
                hero: MascotView(look: MascotLook.fromGame(game), controller: _mascot, size: heroSize, semanticsLabel: name),
              ),
            ),
            // Облачко «что нужно» над героем.
            Positioned(
              left: 16,
              right: 16,
              top: feet.dy - heroSize * 0.92 - 36,
              child: Center(child: _needBubble()),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Column(
                  children: [
                    _topBar(name),
                    if (game.inventory.rooms > 1) ...[const SizedBox(height: 8), _roomToggle()],
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DuoIconButton(key: const Key('home.clothes'), emoji: '👕', label: 'Одежда', onTap: () => _open(ClothesScreen(game: game))),
                      DuoIconButton(key: const Key('home.savings'), emoji: '🐷', label: '${game.economy.savings.value}', onTap: () => _open(SavingsScreen(game: game))),
                      DuoIconButton(key: const Key('home.sleep'), emoji: '🌙', label: 'Спать', color: const Color(0xFFE8EAFB), onTap: () => goToSleep(context, game)),
                      DuoIconButton(key: const Key('home.room'), emoji: '🛋️', label: 'Комната', onTap: () => _open(RoomScreen(game: game))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _nextCard(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _topBar(String name) {
    return Row(
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
            decoration: BoxDecoration(
              color: FinniColors.surface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 3))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: FinniColors.primary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20)),
                  child: Text('🪙 ${game.economy.available.value}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 2,
                  child: FittedBox(fit: BoxFit.scaleDown, child: DuoChip(text: game.stageTitle, color: FinniColors.teal)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _roundButton(const Key('home.help'), '?', 'Помощь', _help),
      ],
    );
  }

  Widget _roundButton(Key key, String text, String label, VoidCallback onTap) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        height: 44,
        constraints: const BoxConstraints(minWidth: 44),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: FinniColors.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: FinniColors.teal, width: 2),
        ),
        child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: FinniColors.ink)),
      ),
    ),
  );

  Widget _roomToggle() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: FinniColors.surface.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(20)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (id, label) in [(1, '🛏️ Спальня'), (2, '🧸 Игровая')])
          GestureDetector(
            onTap: () => setState(() => _room = id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _room == id ? FinniColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
      ],
    ),
  );

  Widget _needBubble() {
    final missing = [for (final i in game.todaysNeeds) if (!game.isBoughtToday(i.id)) i];
    final (dot, text, onTap) = !game.planConfirmed
        ? (FinniColors.primary, 'Сначала план: разложи монеты', () => _open(PlanScreen(game: game)))
        : missing.isNotEmpty
        ? (FinniColors.orange, 'Нужно: ${missing.first.title.toLowerCase()} ${missing.first.price}', () => ShellScope.go(context, ShellTab.shop))
        : (FinniColors.teal, '${game.content.text('mood.${game.mood.name}')} · всё нужное есть', null);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: FinniColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Flexible(child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
          ],
        ),
      ),
    );
  }

  Widget _nextCard() {
    final step = nextStep(game);
    final (emoji, title, text, action, color, VoidCallback onTap) = switch (step) {
      DayStep.plan => ('🫙', 'План дня', 'Разложи монеты по трём банкам', 'К плану', FinniColors.primary, () => _open(PlanScreen(game: game))),
      DayStep.needs => ('🥣', 'Купи нужное', 'Иначе ${game.profile.petName} загрустит', 'В магазин', FinniColors.orange, () => ShellScope.go(context, ShellTab.shop)),
      DayStep.quest => ('📜', 'Квест дня', 'Сцена с выбором · +${game.content.config.rewardWise}', 'Играть', FinniColors.teal, () => _open(QuestScreen(game: game))),
      DayStep.game => ('🎮', 'Игра дня', 'До +${game.content.config.rewardWise} монет', 'Играть', FinniColors.blue, () => ShellScope.go(context, ShellTab.games)),
      DayStep.save => ('🐷', 'Отложи в копилку', 'Потом можно спать 🌙', 'Копилка', FinniColors.save, () => _open(SavingsScreen(game: game))),
    };
    return DuoCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                Text(text, style: const TextStyle(fontSize: 14, color: FinniColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DuoButton(key: const Key('home.next'), label: action, color: color, expand: false, height: 46, onPressed: onTap),
        ],
      ),
    );
  }

  void _help() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DuoButton(
                key: const Key('help.intro'),
                label: 'Как играть',
                emoji: '💡',
                onPressed: () {
                  Navigator.of(sheet).pop();
                  _open(IntroScreen(replay: true, onDone: () => Navigator.of(context).pop()));
                },
              ),
              const SizedBox(height: 10),
              DuoButton(
                key: const Key('help.glossary'),
                label: 'Словарик',
                emoji: '📖',
                color: FinniColors.teal,
                onPressed: () {
                  Navigator.of(sheet).pop();
                  _open(GlossaryScreen(content: game.content));
                },
              ),
              const SizedBox(height: 10),
              DuoButton(
                key: const Key('home.adult'),
                label: 'Для взрослых',
                emoji: '👪',
                color: FinniColors.surface,
                onPressed: () {
                  Navigator.of(sheet).pop();
                  _open(AdultScreen(game: game));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
