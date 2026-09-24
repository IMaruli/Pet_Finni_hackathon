import 'dart:convert';
import 'dart:io';

import 'package:finni/content/content_loader.dart';
import 'package:finni/content/game_content.dart';
import 'package:finni/store/profile_store.dart';
import 'package:finni/ui/app.dart';
import 'package:finni/ui/widgets/duo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lesson_helpers.dart';

/// Анимации героя бесконечны, поэтому вместо pumpAndSettle — фиксированные кадры.
Future<void> settle(WidgetTester t, [int frames = 12]) async {
  for (var i = 0; i < frames; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tapKey(WidgetTester t, String key) async {
  final f = find.byKey(Key(key));
  if (f.evaluate().isEmpty) await settle(t, 8); // реплика героя «печатает…»
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

Future<void> onboard(WidgetTester t, String name) async {
  await tapKey(t, 'role.child');
  for (var i = 0; i < 3; i++) {
    await tapKey(t, 'intro.next');
  }
  await tapKey(t, 'hero.hair.buns');
  await tapKey(t, 'hero.color.mint');
  await t.enterText(find.byKey(const Key('hero.player')), name);
  await tapKey(t, 'hero.go');
  await settle(t, 20);
  // F-038: герой знакомится — 4 реплики, потом обычный день.
  for (var i = 0; i < 4; i++) {
    await tapKey(t, 'home.greet');
  }
  expect(find.byKey(const Key('home.greet')), findsNothing);
}

Future<void> phone(WidgetTester t) async {
  t.view.physicalSize = const Size(1080, 2340);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

void main() {
  testWidgets('Appendix A on a 360dp phone through the Figma navigation', (t) async {
    await phone(t);
    final store = MemoryProfileStore();
    await t.pumpWidget(FinniApp(store: store, loadContent: () async => content));
    await settle(t, 20);

    // А.1–3: роль, знакомство, герой.
    expect(find.text('Кто заходит?'), findsOneWidget);
    await onboard(t, 'Аня');
    expect(find.text('60'), findsOneWidget);

    // А.5 план.
    await tapKey(t, 'home.next');
    await tapKey(t, 'plan.need.plus');
    expect(t.widget<DuoButton>(find.byKey(const Key('plan.done'))).onPressed, isNull);
    await tapKey(t, 'plan.suggest');
    await tapKey(t, 'plan.done');
    await settle(t, 10);

    // F-021: игры и хотелки ждут нужное.
    await tapKey(t, 'nav.games');
    await tapKey(t, 'games.sort');
    expect(find.byKey(const Key('needsFirst.sheet')), findsOneWidget);
    await t.tapAt(const Offset(20, 40)); // закрыть шторку
    await settle(t, 20);

    // А.7 покупки по разделам Дома (F-022): хотелка ждёт нужное (F-021).
    await tapKey(t, 'nav.home');
    await tapKey(t, 'home.treats');
    await tapKey(t, 'shopRow.icecream');
    expect(find.byKey(const Key('needsFirst.sheet')), findsOneWidget);
    await tapKey(t, 'needsFirst.go'); // «Купить: Завтрак»
    await tapKey(t, 'shop.buy');
    await settle(t, 30);
    await t.pageBack();
    await settle(t, 20);
    // F-039: нужное — пузырями над героем, в два тапа.
    expect(find.byKey(const Key('home.need.breakfast')), findsNothing); // уже куплен
    for (final id in ['water', 'care']) {
      await tapKey(t, 'home.need.$id');
      await tapKey(t, 'shop.buy');
      await settle(t, 30);
      expect(find.byKey(Key('home.need.$id')), findsNothing);
    }
    await tapKey(t, 'home.clothes');
    await tapKey(t, 'clothes.glasses'); // примерка
    await tapKey(t, 'clothes.glasses'); // покупка
    await tapKey(t, 'shop.buy');
    await settle(t, 30);
    await t.pageBack();
    await settle(t, 20);

    // А.6 урок дня из облачка героя (F-025): «Хочу узнать новое!» → урок.
    await tapKey(t, 'home.next');
    await playLesson(t, content.lesson('needs_1'));
    expect(find.text('+12 за урок'), findsOneWidget);
    await tapKey(t, 'lesson.done');
    await settle(t, 20);

    // Игра дня во вкладке «Игры».
    await tapKey(t, 'nav.games');
    await tapKey(t, 'games.budget');
    for (var i = 0; i < 3; i++) {
      await tapKey(t, 'budget.item.$i');
    }
    await tapKey(t, 'budget.check');
    expect(find.text('+6 🪙 в кошелёк'), findsOneWidget);
    await tapKey(t, 'game.exit');
    await settle(t, 30);

    // А.8 копилка с Дома.
    await tapKey(t, 'nav.home');
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
    await settle(t, 30);

    // Одежда: очки надеты после покупки, тап — снять.
    await tapKey(t, 'home.clothes');
    expect(find.text('надето'), findsOneWidget);
    await tapKey(t, 'clothes.glasses');
    expect(find.text('снято'), findsOneWidget);

    // F-023: облик из Одежды — Мартышка закрыта, Зайка выбирается бесплатно.
    await tapKey(t, 'clothes.style');
    await tapKey(t, 'hero.skin.monkey');
    expect(find.byKey(const Key('hero.skin.lockHint')), findsOneWidget);
    await tapKey(t, 'hero.skin.bunny');
    expect(find.byKey(const Key('hero.hair.tuft')), findsNothing); // у Зайки ушки
    await tapKey(t, 'hero.go');
    await settle(t, 20);
    await t.pageBack();
    await settle(t);

    // Комната с лентой вещей.
    await tapKey(t, 'home.room');
    expect(find.byKey(const Key('roomItem.lamp')), findsOneWidget);
    await t.pageBack();
    await settle(t);

    // А.9–10 ночь из «Заданий».
    await tapKey(t, 'nav.tasks');
    await tapKey(t, 'tasks.sleep');
    await settle(t, 25);
    expect(find.text('Итог дня 1'), findsOneWidget);
    expect(find.text('✅ Хороший день!'), findsOneWidget);
    await tapKey(t, 'night.morning');
    await settle(t, 30);
    await scrollTo(t, find.textContaining('День 2'));
    expect(find.textContaining('День 2'), findsOneWidget);

    // Уроки: путь — следующий урок открыт, за первый урок дня 2 снова награда.
    await tapKey(t, 'nav.lessons');
    await tapKey(t, 'lessons.needs_2');
    await playLesson(t, content.lesson('needs_2'));
    expect(find.text('+12 за урок'), findsOneWidget);
    expect(find.byKey(const Key('lesson.nextBlockAfterSleep')), findsOneWidget); // F-035: блок в день
    await tapKey(t, 'lesson.done');
    await settle(t, 20);

    // F-026 / F-036: задания дня и недели, награда — по кнопке «Забрать».
    await tapKey(t, 'nav.tasks');
    expect(find.text('ЗАДАНИЯ ДНЯ'), findsOneWidget);
    final claim = find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.endsWith('.claim'));
    if (claim.evaluate().isNotEmpty) {
      await t.tap(claim.first);
      await settle(t, 10);
      expect(find.textContaining('за задание'), findsWidgets);
      await settle(t, 30);
    }
    await t.scrollUntilVisible(
      find.byKey(const Key('tasks.w.lessons8')),
      200,
      scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down && w.physics is! NeverScrollableScrollPhysics).first,
    );
    expect(find.textContaining('2 / 8'), findsOneWidget);

    // А.11 перезапуск.
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(FinniApp(store: store, loadContent: () async => content));
    await settle(t, 20);
    await tapKey(t, 'nav.tasks');
    expect(find.textContaining('День 2'), findsOneWidget);

    // А.12 взрослый и сброс.
    await tapKey(t, 'nav.home');
    await tapKey(t, 'home.help');
    await tapKey(t, 'home.adult');
    final gesture = await t.startGesture(t.getCenter(find.byKey(const Key('adult.hold'))));
    await settle(t, 34);
    await gesture.up();
    await settle(t);
    await tapKey(t, 'adult.reset');
    await tapKey(t, 'adult.reset.confirm');
    await settle(t, 20);
    expect(find.byKey(const Key('role.child')), findsOneWidget);
    expect(store.raw, isNull);
  });

  testWidgets('adult without a profile sees a friendly note', (t) async {
    await phone(t);
    await t.pumpWidget(FinniApp(store: MemoryProfileStore(), loadContent: () async => content));
    await settle(t, 20);
    await tapKey(t, 'role.adult');
    expect(find.textContaining('Профиля ещё нет'), findsOneWidget);
  });

  testWidgets('sort game and catcher run on a phone', (t) async {
    await phone(t);
    await t.pumpWidget(FinniApp(store: MemoryProfileStore(), loadContent: () async => content));
    await settle(t, 20);
    await onboard(t, 'Тим');
    await tapKey(t, 'home.next');
    await tapKey(t, 'plan.suggest');
    await tapKey(t, 'plan.done');
    await settle(t, 40); // тост плана уезжает с кнопок
    await tapKey(t, 'home.needs');
    for (final id in ['breakfast', 'water', 'care']) {
      await tapKey(t, 'shopRow.$id');
      await tapKey(t, 'shop.buy');
      await settle(t, 30);
    }
    await t.pageBack();
    await settle(t, 20);

    await tapKey(t, 'nav.games');
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
    for (var i = 0; i < 320; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('game.exit')), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
