import 'dart:convert';
import 'dart:io';

import 'package:finni/content/content_loader.dart';
import 'package:finni/content/game_content.dart';
import 'package:finni/store/profile_store.dart';
import 'package:finni/ui/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Анимации героя бесконечны, поэтому вместо pumpAndSettle — фиксированные кадры.
Future<void> settle(WidgetTester t, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tapKey(WidgetTester t, String key) async {
  final f = find.byKey(Key(key));
  if (f.evaluate().isEmpty) {
    await t.scrollUntilVisible(f, 200, scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down && w.physics is! NeverScrollableScrollPhysics).first);
  }
  await t.ensureVisible(f);
  await t.pump();
  await t.tap(f);
  await settle(t);
}

Future<void> scrollTo(WidgetTester t, Finder f) async {
  await t.scrollUntilVisible(
    f,
    -200,
    scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down && w.physics is! NeverScrollableScrollPhysics).first,
  );
  await settle(t, 3);
}

final content = GameContent.fromJson({
  for (final name in ContentLoader.files)
    name: jsonDecode(File('assets/content/$name.json').readAsStringSync()),
});

void main() {
  testWidgets('Appendix A path on a 360dp phone: onboarding → plan → buy → quest → game → save → night → adult reset', (t) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);

    final store = MemoryProfileStore();
    await t.pumpWidget(FinniApp(store: store, loadContent: () async => content));
    await settle(t, 20);

    // А.1 знакомство
    expect(find.text('🥣 Нужное'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tapKey(t, 'intro.next');
    }

    // А.2–3 герой
    await t.enterText(find.byKey(const Key('hero.player')), 'Аня');
    await tapKey(t, 'hero.hair.buns');
    await tapKey(t, 'hero.go');
    await settle(t, 20);
    expect(find.text('День 1'), findsOneWidget);

    // А.5 план
    await tapKey(t, 'home.next');
    await tapKey(t, 'plan.need.plus'); // +1 меньше нужного — «Готово» неактивна
    expect(t.widget<FilledButton>(find.byKey(const Key('plan.done'))).onPressed, isNull);
    await tapKey(t, 'plan.suggest');
    await tapKey(t, 'plan.done');
    await settle(t, 10);
    expect(find.text('Купи нужное на сегодня'), findsOneWidget);

    // А.7 покупки: нужное
    await tapKey(t, 'home.next');
    await tapKey(t, 'shop.item.breakfast');
    await tapKey(t, 'shop.buy');
    await tapKey(t, 'shop.item.water');
    await tapKey(t, 'shop.buy');
    expect(find.text('Куплено ✓'), findsNWidgets(2));
    // хотелка
    await tapKey(t, 'shop.tab.want');
    await tapKey(t, 'shop.item.glasses');
    await tapKey(t, 'shop.buy');
    // отказ при нехватке: наушники после очков не по карману? проверяем на копилке ниже
    await t.pageBack();
    await settle(t);

    // А.6 задание
    await tapKey(t, 'home.next');
    for (var i = 0; i < 5; i++) {
      await t.tap(find.byKey(const Key('quest.tap')), warnIfMissed: false);
      await settle(t, 4);
    }
    await tapKey(t, 'quest.choice.0');
    expect(find.textContaining('+12 🪙'), findsOneWidget);
    await tapKey(t, 'quest.home');

    // Игра дня: бюджет
    await tapKey(t, 'home.next');
    await tapKey(t, 'games.budget');
    for (var i = 0; i < 3; i++) {
      await tapKey(t, 'budget.item.$i');
    }
    await tapKey(t, 'budget.check');
    expect(find.text('+12 🪙 в кошелёк'), findsOneWidget);
    await tapKey(t, 'game.exit');
    await t.pageBack();
    await settle(t);

    // А.8 цель и копилка
    await tapKey(t, 'home.savings');
    await tapKey(t, 'goal.room2');
    await tapKey(t, 'save.5');
    await scrollTo(t, find.textContaining('осталось 45'));
    expect(find.textContaining('осталось 45'), findsOneWidget);
    await tapKey(t, 'withdraw.5');
    await tapKey(t, 'withdraw.keep');
    await scrollTo(t, find.textContaining('осталось 45'));
    expect(find.textContaining('осталось 45'), findsOneWidget);
    await t.pageBack();
    await settle(t);

    // А.9–10 ночь (ждём, пока уйдёт тост снизу)
    await settle(t, 30);
    await tapKey(t, 'home.sleep');
    await settle(t, 25);
    expect(find.text('Итог дня 1'), findsOneWidget);
    expect(find.text('✅ Хороший день!'), findsOneWidget);
    await tapKey(t, 'night.morning');
    await settle(t, 10);
    await scrollTo(t, find.text('День 2'));
    expect(find.text('День 2'), findsOneWidget);

    // А.11 перезапуск
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(FinniApp(store: store, loadContent: () async => content));
    await settle(t, 20);
    expect(find.text('День 2'), findsOneWidget);

    // А.12 взрослый и сброс
    await tapKey(t, 'home.adult');
    final gesture = await t.startGesture(t.getCenter(find.byKey(const Key('adult.hold'))));
    await settle(t, 34);
    await gesture.up();
    await settle(t);
    await tapKey(t, 'adult.reset');
    await tapKey(t, 'adult.reset.confirm');
    await settle(t, 20);
    expect(find.byKey(const Key('intro.next')), findsOneWidget);
    expect(store.raw, isNull);
  });

  testWidgets('sort game and catcher start without layout errors', (t) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final store = MemoryProfileStore();
    await t.pumpWidget(FinniApp(store: store, loadContent: () async => content));
    await settle(t, 20);
    for (var i = 0; i < 3; i++) {
      await tapKey(t, 'intro.next');
    }
    await t.enterText(find.byKey(const Key('hero.player')), 'Тим');
    await tapKey(t, 'hero.go');
    await settle(t, 20);

    await tapKey(t, 'home.games');
    await tapKey(t, 'games.sort');
    for (var i = 0; i < 10; i++) {
      await t.tap(find.byKey(const Key('sort.need')));
      await settle(t, 3);
    }
    await settle(t, 5);
    expect(find.byKey(const Key('game.exit')), findsOneWidget);
    await tapKey(t, 'game.exit');

    await tapKey(t, 'games.catcher');
    await tapKey(t, 'catcher.start');
    await t.drag(find.text('🐷').last, const Offset(-80, 0));
    for (var i = 0; i < 320; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('game.exit')), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
