import 'package:finni/game/game_controller.dart';
import 'package:finni/store/profile_store.dart';
import 'package:finni/ui/screens/plan_screen.dart';
import 'package:finni/ui/screens/savings_screen.dart';
import 'package:finni/ui/theme.dart';
import 'package:finni/ui/widgets/first_tip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lesson_test.dart' show content;

/// F-062: подсказка при первом входе в раздел — один раз, сохраняется в профиле.
void main() {
  setUp(() => FirstTips.enabled = true);
  tearDown(() => FirstTips.enabled = false);

  Future<GameController> fresh() async {
    final g = GameController(content: content, store: MemoryProfileStore(), newId: () => 'x');
    await g.init();
    await g.createProfile(playerName: 'Аня', petName: 'Финя', lookId: 'sun_tuft', introDay: false);
    await g.finishGreeting();
    return g;
  }

  Future<void> pump(WidgetTester t, Widget home) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(theme: finniTheme(), home: home));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('savings tip shows once and explains piggy vs wallet (F-062)', (t) async {
    final g = await fresh();
    await pump(t, SavingsScreen(game: g));
    expect(find.byKey(const Key('tip.ok')), findsOneWidget);
    expect(find.textContaining('покупают из кошелька'), findsOneWidget);
    await t.tap(find.byKey(const Key('tip.ok')));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(g.tipSeen('savings'), isTrue);
    await pump(t, const SizedBox());
    await pump(t, SavingsScreen(game: g));
    expect(find.byKey(const Key('tip.ok')), findsNothing);
  });

  testWidgets('plan tip tells about holding + (F-062)', (t) async {
    final g = await fresh();
    await pump(t, PlanScreen(game: g));
    expect(find.textContaining('Удерживай «+» — сразу 5'), findsOneWidget);
    await t.tap(find.byKey(const Key('tip.ok')));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('plan.howto')), findsOneWidget);
  });
}
