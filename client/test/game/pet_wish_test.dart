import 'dart:convert';
import 'dart:io';

import 'package:finni/content/content_loader.dart';
import 'package:finni/content/game_content.dart';
import 'package:finni/game/game_controller.dart';
import 'package:finni/game/game_feedback.dart';
import 'package:finni/game/pet_wish.dart';
import 'package:finni/store/profile_store.dart';
import 'package:flutter_test/flutter_test.dart';

GameContent loadContent() => GameContent.fromJson({
  for (final name in ContentLoader.files)
    name: jsonDecode(File('assets/content/$name.json').readAsStringSync()),
});

/// План на весь кошелёк: остаток — в «Отложить» (SA F-024).
Future<GameFeedback> planAll(GameController g, {required int need, int want = 0}) =>
    g.confirmPlan(need: need, want: want, save: g.economy.available.value - need - want);

void main() {
  late GameController game;
  var ids = 0;

  setUp(() async {
    game = GameController(content: loadContent(), store: MemoryProfileStore(), newId: () => 'w${ids++}');
    await game.init();
    await game.createProfile(playerName: 'Аня', petName: 'Финя', lookId: 'sun_tuft');
  });

  test('morning without a plan: curious, asks for a plan', () {
    final w = wishFor(game);
    expect(w.kind, WishKind.plan);
    expect(w.emotion, PetEmotion.curious);
    expect(w.action, 'План');
    expect(w.text, isNot(startsWith('wish.')));
    expect(w.text, contains('40 на старт и 20 карманных')); // ТЗ: доход подписан
  });

  test('needs come in list order with matching emotions', () async {
    await planAll(game, need: game.todaysNeedSum, want: 0);
    expect(wishFor(game).kind, WishKind.eat); // day 1: breakfast, water
    expect(wishFor(game).emotion, PetEmotion.hungry);
    await game.buy('breakfast', commandId: game.newCommandId());
    expect(wishFor(game).kind, WishKind.drink);
    expect(wishFor(game).emotion, PetEmotion.thirsty);
  });

  test('care need makes the pet want to wash, each need has its own words (F-032)', () async {
    await planAll(game, need: game.todaysNeedSum, want: 0);
    for (final i in game.todaysNeeds.where((i) => i.need != 'hygiene')) {
      await game.buy(i.id, commandId: game.newCommandId());
    }
    final w = wishFor(game);
    expect(w.kind, WishKind.wash);
    expect(w.emotion, PetEmotion.grubby);
    expect(w.text, game.content.item('care').ask);
    for (var d = 0; d < 8 && !game.todaysNeeds.any((i) => i.id == 'soup'); d++) {
      await game.endDay();
    }
    await planAll(game, need: game.todaysNeedSum, want: 0);
    expect(wishFor(game).text, contains('суп'));
  });

  test('day time follows the day: morning, day, evening, night (F-028)', () {
    expect(WishKind.plan.dayTime, DayTime.morning);
    expect(WishKind.eat.dayTime, DayTime.morning);
    expect(WishKind.wash.dayTime, DayTime.morning);
    expect(WishKind.quest.dayTime, DayTime.day);
    expect(WishKind.play.dayTime, DayTime.day);
    expect(WishKind.save.dayTime, DayTime.evening);
    expect(WishKind.sleep.dayTime, DayTime.night);
    expect(wishFor(game).dayTime, DayTime.morning);
  });

  test('after needs: lesson, then save, then sleep — playing is optional (F-036)', () async {
    await planAll(game, need: game.todaysNeedSum, want: 0);
    for (final i in game.todaysNeeds) {
      await game.buy(i.id, commandId: game.newCommandId());
    }
    expect(wishFor(game).kind, WishKind.quest);
    expect(wishFor(game).emotion, PetEmotion.excited);
    await game.finishLesson('needs_1');
    expect(wishFor(game).kind, WishKind.save); // без «Хочу поиграть»
    expect(wishFor(game).emotion, PetEmotion.calm);
    await game.toSavings(4);
    final w = wishFor(game);
    expect(w.kind, WishKind.sleep);
    expect(w.emotion, PetEmotion.sleepy);
    expect(w.action, 'Спать');
  });
}
