import 'package:flutter/material.dart';

import '../content/content_loader.dart';
import '../content/game_content.dart';
import '../economy/economy_state.dart';
import '../game/game_controller.dart';
import '../store/profile_store.dart';
import 'mascot/mascot_look.dart';
import 'mascot/mascot_view.dart';
import 'screens/create_hero_screen.dart';
import 'screens/adult_screen.dart';
import 'screens/role_screen.dart';
import 'shell/main_shell.dart';
import 'screens/intro_screen.dart';
import 'theme.dart';

/// Оболочка приложения: загрузка, выбор первого экрана (SA F-016).
class FinniApp extends StatefulWidget {
  const FinniApp({super.key, this.store, this.loadContent});
  final ProfileStore? store;
  final Future<GameContent> Function()? loadContent;

  @override
  State<FinniApp> createState() => _FinniAppState();
}

enum _Stage { role, intro, hero }

class _FinniAppState extends State<FinniApp> {
  GameController? _game;
  Object? _error;
  _Stage _stage = _Stage.role;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final content = await (widget.loadContent ?? ContentLoader.load)();
      final game = GameController(content: content, store: widget.store ?? SharedPrefsProfileStore());
      await game.init();
      if (mounted) setState(() => _game = game);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _game?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Финни',
      debugShowCheckedModeBanner: false,
      theme: finniTheme(),
      home: _home(),
    );
  }

  Widget _home() {
    if (_error != null) return _ErrorScreen(error: _error!);
    final game = _game;
    if (game == null) return const _Splash();
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        if (game.hasProfile) {
          _stage = _Stage.role;
          return MainShell(game: game);
        }
        return switch (_stage) {
          _Stage.role => RoleScreen(
            onChild: () => setState(() => _stage = _Stage.intro),
            onAdult: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AdultScreen(game: game))),
          ),
          _Stage.intro => IntroScreen(onDone: () => setState(() => _stage = _Stage.hero)),
          _Stage.hero => FinikStyleScreen(game: game),
        };
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MascotView(
              look: MascotLook(color: Color(0xFFFFCC33), hair: 'tuft', mood: PetMood.glad, stage: 2),
              size: 180,
              interactive: false,
            ),
            SizedBox(height: 12),
            Text('Финни', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700)),
            Text('учимся обращаться с монетами', style: TextStyle(color: FinniColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Что-то сломалось 🛠️', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Позови взрослого. Для разработчика:'),
              const SizedBox(height: 12),
              Expanded(child: SingleChildScrollView(child: SelectableText('$error'))),
            ],
          ),
        ),
      ),
    );
  }
}
