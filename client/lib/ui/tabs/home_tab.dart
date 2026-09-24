import 'package:flutter/material.dart';

import '../../game/game_controller.dart';
import '../../game/pet_wish.dart';
import '../mascot/mascot_look.dart';
import '../mascot/mascot_view.dart';
import '../room/room_scene.dart';
import '../screens/adult_screen.dart';
import '../screens/category_screen.dart';
import '../screens/clothes_screen.dart';
import '../screens/glossary_screen.dart';
import '../screens/intro_screen.dart';
import '../screens/night_screen.dart';
import '../screens/plan_screen.dart';
import '../lesson/lesson_screen.dart';
import '../screens/room_screen.dart';
import '../screens/savings_screen.dart';
import '../shell/main_shell.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/duo.dart';
import '../widgets/pet_speech.dart';

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

  /// Реплика о самочувствии после тапа по герою (F-020 BR-07).
  String? _moodLine;
  int _moodGen = 0;

  void _sayMood() {
    final gen = ++_moodGen;
    final mood = game.mood.name;
    setState(() => _moodLine = game.content.text('mood.$mood.why', {'pet': game.profile.petName}));
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && gen == _moodGen) setState(() => _moodLine = null);
    });
  }

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
        final wish = wishFor(game);
        const feetY = 0.74;
        final heroSize = size.width * 0.5;
        return Stack(
          children: [
            Positioned.fill(
              child: RoomScene(
                inventory: game.inventory,
                room: room,
                feetY: feetY,
                heroScale: 0.78,
                hero: MascotView(
                  look: MascotLook.fromGame(game).withEmotion(_moodLine == null ? wish.emotion : null),
                  controller: _mascot,
                  size: heroSize,
                  semanticsLabel: name,
                  onTap: _sayMood,
                ),
                heroBadge: _moodLine != null
                    ? PetSpeech(text: _moodLine!)
                    : PetSpeech(
                        text: wish.text,
                        action: wish.action,
                        actionKey: const Key('home.next'),
                        accent: _accent(wish.kind),
                        onAction: () => _fulfil(wish.kind),
                      ),
              ),
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
                      // Пять разделов: одно действие — одно место (SA F-022 BR-02).
                      Expanded(child: DuoIconButton(key: const Key('home.needs'), icon: Icons.shopping_basket_rounded, label: 'Нужное', color: FinniColors.need, onTap: () => _open(CategoryScreen(game: game, category: ShopCategory.needs)))),
                      Expanded(child: DuoIconButton(key: const Key('home.treats'), icon: Icons.icecream_rounded, label: 'Хотелки', color: FinniColors.want, onTap: () => _open(CategoryScreen(game: game, category: ShopCategory.treats)))),
                      Expanded(child: DuoIconButton(key: const Key('home.clothes'), icon: Icons.checkroom_rounded, label: 'Одежда', onTap: () => _open(ClothesScreen(game: game)))),
                      Expanded(child: DuoIconButton(key: const Key('home.room'), icon: Icons.weekend_rounded, label: 'Дом', color: FinniColors.orange, onTap: () => _open(RoomScreen(game: game)))),
                      Expanded(child: DuoIconButton(key: const Key('home.savings'), icon: Icons.savings_rounded, label: 'Копилка', color: FinniColors.save, onTap: () => _open(SavingsScreen(game: game)))),
                    ],
                  ),
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

  Color _accent(WishKind kind) => switch (kind) {
    WishKind.eat || WishKind.drink || WishKind.wash => FinniColors.need,
    WishKind.quest => FinniColors.orange,
    WishKind.play => FinniColors.blue,
    WishKind.save => FinniColors.save,
    WishKind.plan || WishKind.sleep => FinniColors.primary,
  };

  void _fulfil(WishKind kind) => switch (kind) {
    WishKind.plan => _open(PlanScreen(game: game)),
    WishKind.eat || WishKind.drink || WishKind.wash => _open(CategoryScreen(game: game, category: ShopCategory.needs)),
    WishKind.quest => _open(LessonScreen(game: game, lesson: game.recommendedLesson)),
    WishKind.play => ShellScope.go(context, ShellTab.games),
    WishKind.save => _open(SavingsScreen(game: game)),
    WishKind.sleep => goToSleep(context, game),
  };

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
