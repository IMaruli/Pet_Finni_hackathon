import 'package:flutter/material.dart';

import '../../content/models.dart';
import '../../game/game_controller.dart';
import '../games/games_hub.dart';
import '../mascot/mascot_look.dart';
import '../mascot/mascot_view.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/room_view.dart';
import 'adult_screen.dart';
import 'glossary_screen.dart';
import 'intro_screen.dart';
import 'night_screen.dart';
import 'plan_screen.dart';
import 'quest_screen.dart';
import 'savings_screen.dart';
import 'shop_screen.dart';

enum DayStep { plan, needs, quest, game, save }

DayStep nextStep(GameController g) {
  if (!g.planConfirmed) return DayStep.plan;
  if (!g.needsDone) return DayStep.needs;
  if (!g.questDoneToday) return DayStep.quest;
  if (!g.gameRewardToday) return DayStep.game;
  return DayStep.save;
}

/// Главный экран (SA F-009).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.game});
  final GameController game;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        if (!game.hasProfile) return const SizedBox.shrink();
        Haptics.enabled = game.snapshot.soundOn;
        final look = MascotLook.fromGame(game);
        final name = game.profile.petName;
        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _topBar(),
                const SizedBox(height: 12),
                if (game.inventory.rooms > 1) ...[
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 1, label: Text('🛏️ Спальня')),
                      ButtonSegment(value: 2, label: Text('🧸 Игровая')),
                    ],
                    selected: {_room},
                    onSelectionChanged: (s) => setState(() => _room = s.first),
                  ),
                  const SizedBox(height: 8),
                ],
                LayoutBuilder(
                  builder: (context, box) => RoomView(
                    inventory: game.inventory,
                    room: _room,
                    tableItems: [for (final i in game.todaysNeeds) if (game.isBoughtToday(i.id)) i.emoji],
                    poster: MascotView(look: look, size: 120, animated: false, interactive: false),
                    hero: MascotView(
                      look: look,
                      controller: _mascot,
                      size: box.maxWidth * 0.52,
                      semanticsLabel: name,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _heroCaption(name),
                const SizedBox(height: 12),
                _nextCard(),
                const SizedBox(height: 12),
                _needsRow(),
                const SizedBox(height: 12),
                _goalCard(),
                const SizedBox(height: 12),
                _menu(),
                if (game.demoComplete) ...[
                  const SizedBox(height: 12),
                  Panel(
                    color: const Color(0xFFE9F8F0),
                    child: Text(
                      '🏁 Демо пройдено: ${game.content.config.demoPeriods} дней позади! Можно играть дальше.',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _topBar() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: FinniColors.ink, borderRadius: BorderRadius.circular(20)),
              child: Text('День ${game.day}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
            const Spacer(),
            _iconButton('?', 'Подсказка', const Key('home.help'), () => _open(IntroScreen(replay: true, onDone: () => Navigator.of(context).pop()))),
            _iconButton('📖', 'Словарик', const Key('home.glossary'), () => _open(GlossaryScreen(content: game.content))),
            _iconButton('👪', 'Взрослым', const Key('home.adult'), () => _open(AdultScreen(game: game))),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: Center(child: CoinChip(value: game.economy.available.value, label: 'кошелёк'))),
            const SizedBox(width: 8),
            Expanded(
              child: Center(
                child: CoinChip(value: game.economy.savings.value, emoji: '🐷', label: 'копилка', color: FinniColors.save),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _iconButton(String emoji, String tip, Key key, VoidCallback onTap) => IconButton(
    key: key,
    tooltip: tip,
    onPressed: onTap,
    visualDensity: VisualDensity.compact,
    style: IconButton.styleFrom(minimumSize: const Size(40, 48), padding: EdgeInsets.zero),
    icon: Text(emoji, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
  );

  Widget _heroCaption(String name) {
    final mood = game.mood.name;
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$name ${game.stageTitle}',
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                ),
              ),
              _stageDots(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${game.content.text('mood.$mood')}: ${game.content.text('mood.$mood.why', {'pet': name})}',
            style: const TextStyle(color: FinniColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _stageDots() => Semantics(
    label: 'Стадия ${game.stage} из 3',
    child: Row(
      children: [
        for (var s = 1; s <= 3; s++)
          Container(
            margin: const EdgeInsets.only(left: 4),
            width: 12 + s * 3.0,
            height: 12 + s * 3.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: s <= game.stage ? FinniColors.primary : FinniColors.line,
            ),
          ),
      ],
    ),
  );

  Widget _nextCard() {
    final step = nextStep(game);
    final (emoji, title, text, action, onTap) = switch (step) {
      DayStep.plan => ('🫙', 'Разложи монеты по банкам', 'Сначала план: сколько на нужное, сколько на хотелки, сколько отложить.', 'К плану', () => _open(PlanScreen(game: game))),
      DayStep.needs => ('🥣', 'Купи нужное на сегодня', 'Без него ${game.profile.petName} будет грустить.', 'В магазин', () => _open(ShopScreen(game: game))),
      DayStep.quest => ('📜', 'Задание дня: ${game.todaysQuest.title}', 'За любое решение — монеты и объяснение.', 'Играть сцену', () => _open(QuestScreen(game: game))),
      DayStep.game => ('🎮', 'Игра дня', 'Сыграй и получи до +${game.content.config.rewardWise} монет.', 'В игротеку', () => _open(GamesHub(game: game))),
      DayStep.save => ('🐷', 'Отложи в копилку и ложись спать', 'Каждая монета в копилке приближает цель.', 'К копилке', () => _open(SavingsScreen(game: game))),
    };
    return Panel(
      color: const Color(0xFFFFF0DE),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ДАЛЬШЕ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: FinniColors.primary, letterSpacing: 1)),
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                Text(text, style: const TextStyle(color: FinniColors.muted)),
                const SizedBox(height: 8),
                FilledButton(key: const Key('home.next'), onPressed: onTap, child: Text(action)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _needsRow() {
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const BasketBadge(Basket.need, small: true),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 10,
              children: [
                for (final ShopItem i in game.todaysNeeds)
                  Text(
                    '${i.emoji} ${game.isBoughtToday(i.id) ? '✅' : '⬜'}',
                    style: const TextStyle(fontSize: 18),
                    semanticsLabel: '${i.title}: ${game.isBoughtToday(i.id) ? 'куплено' : 'не куплено'}',
                  ),
              ],
            ),
          ),
          Text('${game.todaysNeedSum} 🪙', style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _goalCard() {
    final goal = game.goal;
    if (goal == null) {
      return Panel(
        onTap: () => _open(SavingsScreen(game: game)),
        child: const Row(
          children: [
            Text('🎯', style: TextStyle(fontSize: 32)),
            SizedBox(width: 12),
            Expanded(child: Text('Выбери цель для копилки', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
            Icon(Icons.chevron_right),
          ],
        ),
      );
    }
    final saved = game.economy.savings.value;
    return Panel(
      onTap: () => _open(SavingsScreen(game: game)),
      child: Row(
        children: [
          Text(goal.emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Цель: ${goal.title}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                ProgressBar(value: saved / goal.cost, color: FinniColors.save),
                const SizedBox(height: 4),
                Text(
                  game.canRedeem ? 'Хватает! Забери цель 🎉' : '${saved.clamp(0, goal.cost)} из ${goal.cost} · осталось ${game.goalRemaining}',
                  style: const TextStyle(color: FinniColors.muted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menu() {
    final tiles = [
      MenuTile(key: const Key('home.plan'), emoji: '🫙', title: 'План', onTap: () => _open(PlanScreen(game: game)), badge: game.planConfirmed ? null : '!'),
      MenuTile(key: const Key('home.shop'), emoji: '🛒', title: 'Магазин', onTap: () => _open(ShopScreen(game: game))),
      MenuTile(key: const Key('home.quest'), emoji: '📜', title: 'Задание', onTap: () => _open(QuestScreen(game: game)), badge: game.questDoneToday ? null : '+${game.content.config.rewardWise}'),
      MenuTile(key: const Key('home.games'), emoji: '🎮', title: 'Игры', onTap: () => _open(GamesHub(game: game)), badge: game.gameRewardToday ? null : '+${game.content.config.rewardWise}'),
      MenuTile(key: const Key('home.savings'), emoji: '🐷', title: 'Копилка', onTap: () => _open(SavingsScreen(game: game))),
      MenuTile(key: const Key('home.sleep'), emoji: '🌙', title: 'Спать', onTap: () => goToSleep(context, game), color: const Color(0xFFE8EAFB)),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.92,
      children: tiles,
    );
  }
}
