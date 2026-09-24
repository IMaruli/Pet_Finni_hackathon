import 'package:flutter/material.dart';

import '../../game/game_controller.dart';
import 'clothes_screen.dart';
import 'create_hero_screen.dart';

enum LookTab { look, clothes }

/// «Образ»: облик (скин, цвет, причёска) и одежда в одном разделе (SA F-041).
class LookScreen extends StatelessWidget {
  const LookScreen({super.key, required this.game, this.initialTab = LookTab.look});
  final GameController game;
  final LookTab initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab.index,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Образ'),
          bottom: const TabBar(
            tabs: [
              Tab(key: Key('look.tab.look'), text: 'Облик'),
              Tab(key: Key('look.tab.clothes'), text: 'Одежда'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FinikStyleScreen(game: game, create: false, embedded: true),
            ClothesScreen(game: game, embedded: true),
          ],
        ),
      ),
    );
  }
}
