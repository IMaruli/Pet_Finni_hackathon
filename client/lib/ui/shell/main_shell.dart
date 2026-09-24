import 'package:flutter/material.dart';

import '../../game/game_controller.dart';
import '../tabs/games_tab.dart';
import '../tabs/home_tab.dart';
import '../tabs/lessons_tab.dart';
import '../tabs/tasks_tab.dart';
import '../widgets/common.dart';
import '../widgets/duo.dart';

/// Переключение вкладок из любого экрана, в том числе открытого поверх оболочки.
abstract final class ShellScope {
  static _MainShellState? _active;

  static void go(BuildContext context, ShellTab tab) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    _active?._go(tab);
  }
}

/// Оболочка с таб-баром: Игры · Задания · Дом · Уроки (SA F-017, F-022 BR-01).
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.game, this.initialTab = ShellTab.home});
  final GameController game;
  final ShellTab initialTab;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late ShellTab _tab = widget.initialTab;

  @override
  void initState() {
    super.initState();
    ShellScope._active = this;
  }

  @override
  void dispose() {
    if (ShellScope._active == this) ShellScope._active = null;
    super.dispose();
  }

  void _go(ShellTab tab) {
    if (mounted) setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        if (!game.hasProfile) return const SizedBox.shrink();
        Haptics.enabled = game.snapshot.soundOn;
        final reward = '+${game.content.config.rewardWise}';
        return Scaffold(
          body: IndexedStack(
            index: _tab.index,
            children: [
              GamesTab(game: game),
              TasksTab(game: game),
              HomeTab(game: game),
              LessonsTab(game: game),
            ],
          ),
          bottomNavigationBar: DuoTabBar(
            current: _tab,
            onTap: _go,
            badges: {
              if (!game.gameRewardToday) ShellTab.games: reward,
              if (!game.planConfirmed || game.dailyQuests.any((q) => !q.$2.done))
                ShellTab.tasks: '!',
            },
          ),
        );
      },
    );
  }
}
