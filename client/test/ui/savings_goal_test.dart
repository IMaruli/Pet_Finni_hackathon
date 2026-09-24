import 'package:finni/game/game_controller.dart';
import 'package:finni/store/profile_store.dart';
import 'package:finni/ui/screens/savings_screen.dart';
import 'package:finni/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lesson_test.dart' show content;

void main() {
  testWidgets('reaching a skin goal leads straight to the Look section (F-041)', (t) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    var ids = 0;
    final game = GameController(content: content, store: MemoryProfileStore(), newId: () => 'g${ids++}');
    await game.init();
    await game.createProfile(playerName: 'Аня', petName: 'Финя', lookId: 'sun_tuft');
    await game.finishGreeting();
    await game.chooseGoal('skin_giraffe');
    await game.confirmPlan(need: game.todaysNeedSum, want: 0, save: game.economy.available.value - game.todaysNeedSum);
    for (final i in game.todaysNeeds) {
      await game.buy(i.id, commandId: game.newCommandId());
    }
    await game.toSavings(game.economy.available.value);
    await game.finishLesson('needs_1');
    await game.finishLesson('needs_2');
    await game.toSavings(game.economy.available.value);
    expect(game.canRedeem, isTrue);

    await t.pumpWidget(MaterialApp(theme: finniTheme(), home: SavingsScreen(game: game)));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.scrollUntilVisible(find.byKey(const Key('goal.redeem')), 200, scrollable: find.byType(Scrollable).first);
    await t.tap(find.byKey(const Key('goal.redeem')));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Цель достигнута!'), findsOneWidget);
    expect(find.text('Примерить облик'), findsOneWidget);
    await t.tap(find.byKey(const Key('goal.go')));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Образ'), findsOneWidget);
    expect(find.byKey(const Key('hero.skin.giraffe')), findsOneWidget);
    expect(game.isSkinUnlocked('giraffe'), isTrue);
    expect(t.takeException(), isNull);
  });
}
