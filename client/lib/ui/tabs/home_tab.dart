import 'package:flutter/material.dart';

import '../../game/game_controller.dart';
import '../../game/pet_wish.dart';
import '../mascot/mascot_look.dart';
import '../mascot/mascot_view.dart';
import '../room/room_scene.dart';
import '../screens/adult_screen.dart';
import '../screens/category_screen.dart';
import '../screens/look_screen.dart';
import '../screens/glossary_screen.dart';
import '../screens/intro_screen.dart';
import '../screens/night_screen.dart';
import '../screens/plan_screen.dart';
import '../lesson/lesson_screen.dart';
import '../screens/room_screen.dart';
import '../screens/savings_screen.dart';
import '../shell/main_shell.dart';
import '../theme.dart';
import '../../economy/economy_state.dart';
import '../widgets/common.dart';
import '../widgets/first_tip.dart';
import '../widgets/buy_sheet.dart';
import '../widgets/duo.dart';
import '../widgets/need_bubble.dart';
import '../widgets/pet_speech.dart';
import '../widgets/piggy.dart';

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

  /// Шаг знакомства героя с игроком (F-038).
  int _greet = 1;
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
                bowls: game.bowls,
                time: game.greeting
                    ? DayTime.morning
                    : game.isIntroDay && (wish.kind == WishKind.eat || wish.kind == WishKind.drink)
                    ? DayTime
                          .day // в день знакомства еда — днём, после урока (F-043)
                    : wish.dayTime, // утро → день → вечер → ночь по шагам дня (F-028)
                room: room,
                feetY: feetY,
                heroScale: 0.78,
                fullBleed: true, // комната во весь экран (F-048)
                hero: MascotView(
                  look: MascotLook.fromGame(game).withEmotion(game.greeting ? PetEmotion.excited : (_moodLine == null ? wish.emotion : null)),
                  controller: _mascot,
                  size: heroSize,
                  semanticsLabel: name,
                  onTap: _sayMood,
                ),
                orbit: game.greeting
                    ? const []
                    : [
                        for (final (i, item) in game.needsShown.indexed)
                          NeedBubble(
                            key: Key('home.need.${item.id}'),
                            item: item,
                            phase: i * 0.27,
                            urgent: i == 0,
                            onTap: () => buyFlow(context, game, item, mascot: _mascot),
                          ),
                      ],
                heroBadge: game.greeting
                    ? PetSpeech(
                        text: game.content.text('greet.$_greet', {'pet': name, 'player': game.profile.playerName}),
                        action: game.content.text('greet.$_greet.action'),
                        actionKey: const Key('home.greet'),
                        onAction: _nextGreet,
                      )
                    : _moodLine != null
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Flexible(child: _nameRow(name)),
                        if (game.inventory.rooms > 1) ...[const Spacer(), _roomToggle()],
                      ],
                    ),
                    if (!game.greeting) ...[const SizedBox(height: 6), Align(alignment: Alignment.centerLeft, child: _statePanel(name))],
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              // Светлая панель-«док»: кнопки одинаково читаются утром, вечером и ночью (F-042).
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
                decoration: BoxDecoration(
                  color: const Color(0xF5FFFFFF),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 18, offset: Offset(0, 6))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Четыре раздела; нужное — пузырями над героем (SA F-022, F-039, F-041).
                        Expanded(
                          child: DuoIconButton(
                            key: const Key('home.treats'),
                            icon: Icons.icecream_rounded,
                            label: 'Хотелки',
                            color: FinniColors.want,
                            onTap: () => _open(FirstTipGate(id: 'treats', game: game, child: CategoryScreen(game: game, category: ShopCategory.treats))),
                          ),
                        ),
                        Expanded(
                          child: DuoIconButton(
                            key: const Key('home.clothes'),
                            icon: Icons.checkroom_rounded,
                            label: 'Образ',
                            color: FinniColors.primary,
                            onTap: () => _open(FirstTipGate(id: 'look', game: game, child: LookScreen(game: game))),
                          ),
                        ),
                        Expanded(
                          child: DuoIconButton(
                            key: const Key('home.room'),
                            icon: Icons.weekend_rounded,
                            label: 'Дом',
                            color: FinniColors.orange,
                            onTap: () => _open(FirstTipGate(id: 'room', game: game, child: RoomScreen(game: game))),
                          ),
                        ),
                        Expanded(
                          child: DuoIconButton(
                            key: const Key('home.savings'),
                            icon: Icons.savings_rounded,
                            label: 'Копилка',
                            color: FinniColors.save,
                            onTap: () => _open(SavingsScreen(game: game)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _topBar(String name) {
    final goal = game.goal;
    final saved = game.economy.savings.value;
    return Row(
      children: [
        // Кошелёк: тап объясняет разницу с копилкой (F-062).
        Pressable(
          key: const Key('home.wallet'),
          onTap: () => showToast(context, const ['Кошелёк — монеты на покупки сегодня.', 'Копилка — отдельно, на мечту. В магазине её не тратят.'], emoji: '👛'),
          child: Glass(
          radius: 24,
          padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CoinIcon(size: 20),
              const SizedBox(width: 6),
              Text('${game.economy.available.value}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
            ],
          ),
        ),
        ),
        const SizedBox(width: 8),
        // Копилка на виду: сколько отложено и сколько до цели (SA F-040).
        Flexible(
          child: Semantics(
            button: true,
            label: goal == null ? 'Копилка: $saved' : 'Копилка: $saved из ${goal.cost}',
            child: Pressable(
              key: const Key('home.piggy'),
              onTap: () => _open(SavingsScreen(game: game)),
              child: Glass(
                radius: 24,
                tint: const Color(0xCCE3F0FF),
                padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 30, height: 26, child: CustomPaint(painter: PiggyBankPainter())),
                    const SizedBox(width: 6),
                    // Текущая цель на виду (ТЗ 2.5.3, F-057).
                    if (goal != null) ...[Text(goal.emoji, key: const Key('home.piggy.goal'), style: const TextStyle(fontSize: 18)), const SizedBox(width: 4)],
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              goal == null ? '$saved' : '$saved / ${goal.cost}',
                              key: const Key('home.piggy.amount'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: Color(0xFF0A5BC4)),
                            ),
                          ),
                          if (goal != null)
                            SizedBox(
                              width: 56,
                              height: 4,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: (saved / goal.cost).clamp(0.0, 1.0),
                                  backgroundColor: const Color(0x330A84FF),
                                  color: FinniColors.save,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        Semantics(
          button: true,
          label: 'Меню',
          child: Pressable(
            key: const Key('home.help'),
            onTap: _help,
            child: const Glass(
              radius: 22,
              padding: EdgeInsets.all(10),
              child: Icon(Icons.more_horiz_rounded, size: 24, color: FinniColors.ink),
            ),
          ),
        ),
      ],
    );
  }

  /// Имя героя и стадия — второй строкой.
  Widget _nameRow(String name) => Glass(
    radius: 18,
    padding: const EdgeInsets.fromLTRB(12, 5, 6, 5),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Имя видно всегда, ужимается стадия (F-051 BR-10).
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 110),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.3),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: DuoChip(text: game.stageTitle, color: FinniColors.primary),
          ),
        ),
      ],
    ),
  );

  /// Показатели состояния героя (ТЗ 2.5.3, F-057): эмодзи + слово, не только цвет.
  List<(String, String, String, String)> _state(String name) {
    final (moodEmoji, moodWord) = switch (game.mood) {
      PetMood.glad => ('😄', 'радуется'),
      PetMood.steady => ('🙂', 'спокоен'),
      PetMood.uneasy => ('😕', 'грустит'),
    };
    final hungry = game.needsShown.any((i) => i.need == 'food');
    final dirty = game.isGrubby;
    return [
      ('mood', moodEmoji, moodWord, 'Настроение: $moodWord. Растёт, когда нужное куплено и ты держишься плана.'),
      ('food', hungry ? '🍽️' : '😋', hungry ? 'голоден' : 'сыт', hungry ? '$name голоден: купи еду дня в пузыре над ним.' : '$name сыт: еда дня куплена.'),
      (
        'clean',
        dirty ? '🫧' : '✨',
        dirty ? 'испачкался' : 'чистый',
        dirty ? '$name испачкался: купи умывание в пузыре над ним.' : '$name чистый: уход сегодня не нужен или куплен.',
      ),
    ];
  }

  Widget _statePanel(String name) {
    final items = _state(name);
    return Semantics(
      button: true,
      label: 'Состояние: ${items.map((e) => e.$3).join(', ')}',
      child: Pressable(
        key: const Key('home.state'),
        onTap: () => showToast(context, [for (final e in items) e.$4], emoji: items.first.$2),
        child: Glass(
          radius: 16,
          padding: const EdgeInsets.fromLTRB(10, 4, 12, 4),
          // На узком экране и при крупном шрифте плашка ужимается, а не вылезает.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, e) in items.indexed) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('·', style: TextStyle(color: FinniColors.muted)),
                    ),
                  Text(e.$2, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 3),
                  Text(
                    e.$3,
                    key: Key('home.state.${e.$1}'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _room == id ? FinniColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                boxShadow: _room == id ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 1))] : null,
              ),
              child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
      ],
    ),
  );

  void _nextGreet() {
    _mascot.jump();
    if (_greet < 6) {
      setState(() => _greet++);
    } else {
      game.finishGreeting();
    }
  }

  Color _accent(WishKind kind) => switch (kind) {
    WishKind.eat || WishKind.drink || WishKind.wash => FinniColors.need,
    WishKind.quest => FinniColors.orange,
    WishKind.play => FinniColors.blue,
    WishKind.save => FinniColors.save,
    WishKind.plan || WishKind.sleep => FinniColors.primary,
  };

  void _fulfil(WishKind kind) => switch (kind) {
    WishKind.plan => _open(PlanScreen(game: game)),
    // Сразу подтверждение покупки того, что просит герой (F-039).
    WishKind.eat || WishKind.drink || WishKind.wash =>
      game.planConfirmed && game.needsLeft.isNotEmpty
          ? buyFlow(context, game, game.needsLeft.first, mascot: _mascot)
          : _open(CategoryScreen(game: game, category: ShopCategory.needs)),
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
