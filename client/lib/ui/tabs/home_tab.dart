import 'package:flutter/material.dart';

import '../../game/game_controller.dart';
import '../mascot/mascot_look.dart';
import '../mascot/mascot_view.dart';
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
import '../widgets/common.dart';
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
        final feet = Offset(size.width / 2, size.height * feetY);
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
                      DuoIconButton(key: const Key('home.clothes'), icon: Icons.checkroom_rounded, label: 'Одежда', onTap: () => _open(ClothesScreen(game: game))),
                      DuoIconButton(key: const Key('home.savings'), icon: Icons.savings_rounded, label: 'Копилка', color: FinniColors.save, onTap: () => _open(SavingsScreen(game: game))),
                      DuoIconButton(key: const Key('home.sleep'), icon: Icons.bedtime_rounded, label: 'Спать', color: FinniColors.primary, onTap: () => goToSleep(context, game)),
                      DuoIconButton(key: const Key('home.room'), icon: Icons.weekend_rounded, label: 'Комната', color: FinniColors.orange, onTap: () => _open(RoomScreen(game: game))),
                    ],
                  ),
                  const SizedBox(height: 12),
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
          child: Glass(
            radius: 24,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CoinIcon(size: 20),
                const SizedBox(width: 6),
                Text(
                  '${game.economy.available.value}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                ),
                Container(width: 0.8, height: 18, margin: const EdgeInsets.symmetric(horizontal: 10), color: const Color(0x33000000)),
                Flexible(
                  child: Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.4)),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 2,
                  child: FittedBox(fit: BoxFit.scaleDown, child: DuoChip(text: game.stageTitle, color: FinniColors.primary)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          label: 'Меню',
          child: Pressable(
            key: const Key('home.help'),
            onTap: _help,
            child: const Glass(radius: 22, padding: EdgeInsets.all(10), child: Icon(Icons.more_horiz_rounded, size: 24, color: FinniColors.ink)),
          ),
        ),
      ],
    );
  }

  Widget _roomToggle() => Glass(
    radius: 18,
    padding: const EdgeInsets.all(3),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (id, label) in [(1, 'Спальня'), (2, 'Игровая')])
          GestureDetector(
            onTap: () => setState(() => _room = id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _room == id ? FinniColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                boxShadow: _room == id ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 1))] : null,
              ),
              child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
      ],
    ),
  );

  Widget _needBubble() {
    final missing = [for (final i in game.todaysNeeds) if (!game.isBoughtToday(i.id)) i];
    final (dot, text, onTap) = !game.planConfirmed
        ? (FinniColors.primary, 'Сначала план дня', () => _open(PlanScreen(game: game)))
        : missing.isNotEmpty
        ? (FinniColors.orange, 'Нужно: ${missing.first.title.toLowerCase()} · ${missing.first.price}', () => ShellScope.go(context, ShellTab.shop))
        : (FinniColors.need, '${game.content.text('mood.${game.mood.name}')} · всё нужное есть', null);
    return GestureDetector(
      onTap: onTap,
      child: Glass(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Flexible(child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: -0.2))),
          ],
        ),
      ),
    );
  }

  Widget _nextCard() {
    final step = nextStep(game);
    final (icon, title, text, action, color, VoidCallback onTap) = switch (step) {
      DayStep.plan => (Icons.pie_chart_rounded, 'План дня', 'Разложи монеты по трём банкам', 'Начать', FinniColors.primary, () => _open(PlanScreen(game: game))),
      DayStep.needs => (Icons.shopping_basket_rounded, 'Купи нужное', 'Иначе ${game.profile.petName} загрустит', 'Магазин', FinniColors.need, () => ShellScope.go(context, ShellTab.shop)),
      DayStep.quest => (Icons.auto_stories_rounded, 'Квест дня', 'Сцена с выбором · +${game.content.config.rewardWise}', 'Играть', FinniColors.orange, () => _open(QuestScreen(game: game))),
      DayStep.game => (Icons.sports_esports_rounded, 'Игра дня', 'До +${game.content.config.rewardWise} монет', 'Играть', FinniColors.blue, () => ShellScope.go(context, ShellTab.games)),
      DayStep.save => (Icons.savings_rounded, 'Отложи в копилку', 'А потом — спать', 'Копилка', FinniColors.save, () => _open(SavingsScreen(game: game))),
    };
    return Glass(
      radius: 22,
      tint: const Color(0xD9FFFFFF),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          IconTile(icon, color: color, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.4)),
                Text(text, style: const TextStyle(fontSize: 13, color: FinniColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DuoButton(key: const Key('home.next'), label: action, color: color, expand: false, height: 40, onPressed: onTap),
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
                icon: Icons.lightbulb_outline_rounded,
                onPressed: () {
                  Navigator.of(sheet).pop();
                  _open(IntroScreen(replay: true, onDone: () => Navigator.of(context).pop()));
                },
              ),
              const SizedBox(height: 10),
              DuoButton(
                key: const Key('help.glossary'),
                label: 'Словарик',
                icon: Icons.menu_book_rounded,
                color: FinniColors.surface,
                onPressed: () {
                  Navigator.of(sheet).pop();
                  _open(GlossaryScreen(content: game.content));
                },
              ),
              const SizedBox(height: 10),
              DuoButton(
                key: const Key('home.adult'),
                label: 'Для взрослых',
                icon: Icons.family_restroom_rounded,
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
