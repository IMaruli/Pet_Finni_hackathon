import 'dart:convert';
import 'dart:io';

import 'package:finni/content/content_loader.dart';
import 'package:finni/content/game_content.dart';
import 'package:finni/game/game_controller.dart';
import 'package:finni/game/pet_wish.dart';
import 'package:finni/store/profile_store.dart';
import 'package:flutter_test/flutter_test.dart';

GameContent loadContent() => GameContent.fromJson({
  for (final name in ContentLoader.files)
    name: jsonDecode(File('assets/content/$name.json').readAsStringSync()),
});

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
  });

  test('needs come in list order with matching emotions', () async {
    await game.confirmPlan(need: game.todaysNeedSum, want: 0, save: 4);
    expect(wishFor(game).kind, WishKind.eat); // day 1: breakfast, water
    expect(wishFor(game).emotion, PetEmotion.hungry);
    await game.buy('breakfast', commandId: game.newCommandId());
    expect(wishFor(game).kind, WishKind.drink);
    expect(wishFor(game).emotion, PetEmotion.thirsty);
  });

  test('care need makes the pet want to wash', () async {
    await game.confirmPlan(need: game.todaysNeedSum, want: 0, save: 0);
    for (final i in game.todaysNeeds) {
      await game.buy(i.id, commandId: game.newCommandId());
    }
    await game.endDay(); // day 2: breakfast, care
    await game.confirmPlan(need: game.todaysNeedSum, want: 0, save: 0);
    await game.buy('breakfast', commandId: game.newCommandId());
    expect(wishFor(game).kind, WishKind.wash);
    expect(wishFor(game).emotion, PetEmotion.grubby);
  });

  test('after needs: quest, then play, then save, then sleep', () async {
    await game.confirmPlan(need: game.todaysNeedSum, want: 0, save: 4);
    for (final i in game.todaysNeeds) {
      await game.buy(i.id, commandId: game.newCommandId());
    }
    expect(wishFor(game).kind, WishKind.quest);
    expect(wishFor(game).emotion, PetEmotion.excited);
    await game.answerQuest(0);
    expect(wishFor(game).kind, WishKind.play);
    await game.finishMiniGame('sort', win: true, score: 9);
    expect(wishFor(game).kind, WishKind.save);
    expect(wishFor(game).emotion, PetEmotion.calm);
    await game.toSavings(4);
    final w = wishFor(game);
    expect(w.kind, WishKind.sleep);
    expect(w.emotion, PetEmotion.sleepy);
    expect(w.action, 'Спать');
  });
}
