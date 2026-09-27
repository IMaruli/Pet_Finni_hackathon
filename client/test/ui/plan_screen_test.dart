import 'package:finni/game/game_controller.dart';
import 'package:finni/store/profile_store.dart';
import 'package:finni/ui/screens/plan_screen.dart';
import 'package:finni/ui/theme.dart';
import 'package:finni/ui/widgets/duo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lesson_test.dart' show content;

/// F-066: когда все монеты разложены, «+» не нажимается, а «Готово» остаётся на месте и работает.
void main() {
  testWidgets('extra + after all coins are placed does not break Done (F-066)', (t) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final g = GameController(content: content, store: MemoryProfileStore(), newId: () => 'x');
    await g.init();
    await g.createProfile(playerName: 'Аня', petName: 'Финя', lookId: 'sun_tuft', introDay: false);
    await g.finishGreeting();
    await t.pumpWidget(MaterialApp(theme: finniTheme(), home: PlanScreen(game: g)));
    await t.pump(const Duration(milliseconds: 300));

    bool done() => t.widget<DuoButton>(find.byKey(const Key('plan.done'))).onPressed != null;
    await t.tap(find.byKey(const Key('plan.suggest'))); // кнопки закреплены внизу — видны без прокрутки
    await t.pump();
    expect(done(), isTrue);

    // Лишний «+» в каждую банку и долгое нажатие — ничего не меняют.
    for (final b in ['need', 'want', 'save']) {
      await t.ensureVisible(find.byKey(Key('plan.$b.plus')));
      await t.tap(find.byKey(Key('plan.$b.plus')));
      await t.longPress(find.byKey(Key('plan.$b.plus')));
      await t.pump();
      expect(done(), isTrue, reason: b);
    }
    expect(find.byKey(const Key('plan.done')).hitTestable(), findsOneWidget); // кнопка на экране

    // «−», затем «+» — снова всё разложено.
    await t.tap(find.byKey(const Key('plan.save.minus')));
    await t.pump();
    expect(done(), isFalse);
    await t.tap(find.byKey(const Key('plan.save.plus')));
    await t.pump();
    expect(done(), isTrue);

    await t.tap(find.byKey(const Key('plan.done')));
    await t.pump(const Duration(milliseconds: 300));
    expect(g.planConfirmed, isTrue);
  });
}
