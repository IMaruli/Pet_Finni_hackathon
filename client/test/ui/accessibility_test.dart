import 'package:finni/game/game_controller.dart';
import 'package:finni/store/profile_store.dart';
import 'package:finni/ui/motion.dart';
import 'package:finni/ui/screens/plan_screen.dart';
import 'package:finni/ui/screens/savings_screen.dart';
import 'package:finni/ui/shell/main_shell.dart';
import 'package:finni/ui/theme.dart';
import 'package:finni/ui/widgets/pet_speech.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lesson_test.dart' show content;

/// ТЗ 3.6 (F-058): меньше движения, зоны нажатия ≥ 48 dp, крупный шрифт без переполнений на 360 dp.
void main() {
  tearDown(() => Motion.setting = false);

  Future<GameController> day2() async {
    var ids = 0;
    final g = GameController(content: content, store: MemoryProfileStore(), newId: () => 'a${ids++}');
    await g.init();
    await g.createProfile(playerName: 'Аня', petName: 'Финя', lookId: 'sun_tuft', introDay: false);
    await g.finishGreeting();
    await g.chooseGoal('zoo');
    return g;
  }

  Future<void> pump(WidgetTester t, Widget home, {double scale = 1}) async {
    t.view.physicalSize = const Size(1080, 2340); // 360 dp
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: finniTheme(),
        builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
        home: home,
      ),
    );
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('reduced motion: speech shows text at once, no typing (F-058)', (t) async {
    Motion.setting = true;
    await pump(t, const Scaffold(body: Center(child: PetSpeech(text: 'Привет!'))));
    expect(find.text('Привет!'), findsOneWidget);
  });

  testWidgets('need bubbles and the speech action are at least 48 dp (F-058)', (t) async {
    final g = await day2();
    await g.confirmPlan(need: g.todaysNeedSum, want: 0, save: g.economy.available.value - g.todaysNeedSum);
    await pump(t, MainShell(game: g));
    final bubble = t.getSize(find.byKey(const Key('home.need.breakfast')));
    expect(bubble.height, greaterThanOrEqualTo(48));
    expect(t.getSize(find.byKey(const Key('home.next'))).height, greaterThanOrEqualTo(48));
  });

  for (final (name, build) in <(String, Widget Function(GameController))>[
    ('home', (g) => MainShell(game: g)),
    ('plan', (g) => PlanScreen(game: g)),
    ('savings', (g) => SavingsScreen(game: g)),
  ]) {
    testWidgets('$name has no overflow at text scale 1.3 on 360 dp (F-058)', (t) async {
      final g = await day2();
      await pump(t, build(g), scale: 1.3);
      expect(t.takeException(), isNull);
    });
  }
}
