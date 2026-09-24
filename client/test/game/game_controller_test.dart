import 'dart:convert';
import 'dart:io';

import 'package:finni/content/content_loader.dart';
import 'package:finni/content/game_content.dart';
import 'package:finni/economy/economy.dart';
import 'package:finni/game/game_controller.dart';
import 'package:finni/game/game_feedback.dart';
import 'package:finni/game/quests.dart';
import 'package:finni/content/lesson_models.dart';
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
  late MemoryProfileStore store;
  late GameController game;
  var ids = 0;

  Future<GameController> fresh() async {
    final g = GameController(content: loadContent(), store: store, newId: () => 'cmd${ids++}');
    await g.init();
    return g;
  }

  setUp(() async {
    store = MemoryProfileStore();
    game = await fresh();
    await game.createProfile(playerName: 'Аня', petName: 'Финни', lookId: 'sun_tuft');
  });

  Future<void> buyNeeds() async {
    for (final item in game.todaysNeeds) {
      await game.buy(item.id, commandId: game.newCommandId());
    }
  }

  /// Хороший день: план, всё нужное, немного отложить.
  Future<void> goodDay({int save = 2}) async {
    final need = game.todaysNeedSum;
    expect((await planAll(game, need: need, want: 0)).ok, isTrue);
    for (final item in game.todaysNeeds) {
      expect((await game.buy(item.id, commandId: game.newCommandId())).ok, isTrue);
    }
    expect((await game.toSavings(save)).ok, isTrue);
  }

  test('new player has no profile', () async {
    final g = GameController(content: loadContent(), store: MemoryProfileStore());
    await g.init();
    expect(g.loaded, isTrue);
    expect(g.hasProfile, isFalse);
  });

  test('create profile credits start and pocket money', () {
    expect(game.hasProfile, isTrue);
    expect(game.day, 1);
    expect(game.economy.available, GameCoins(60));
    expect(game.economy.lastCreditSourceId, 'pocket:1');
    expect(game.stage, 1);
    expect(game.stageTitle, 'ещё маленький');
  });

  test('plan must cover today needs', () async {
    final f = await game.confirmPlan(need: game.todaysNeedSum - 1, want: 0, save: 0);
    expect(f.ok, isFalse);
    expect(f.reason, FeedbackReason.planNeedLow);
    expect(game.planConfirmed, isFalse);
  });

  test('food and care are needed every period (TZ: обязательные расходы)', () async {
    for (var d = 1; d <= 5; d++) {
      final ids = game.todaysNeeds.map((i) => i.id);
      expect(game.todaysNeeds.where((i) => i.need == 'food'), hasLength(1), reason: 'day $d');
      expect(ids, contains('care'), reason: 'day $d');
      expect(game.todaysNeedSum, lessThanOrEqualTo(game.content.config.pocketMoney));
      await goodDay();
      await game.endDay();
    }
  });

  test('confirmed plan is fixed until the period ends (TZ: план → факт)', () async {
    await planAll(game, need: game.todaysNeedSum, want: 10);
    final f = await game.confirmPlan(need: game.todaysNeedSum, want: 0, save: 30);
    expect(f.ok, isFalse);
    expect(f.reason, FeedbackReason.planLocked);
    expect(game.economy.plan!.want.value, 10);
    await game.endDay();
    expect((await planAll(game, need: game.todaysNeedSum, want: 0)).ok, isTrue);
  });

  test('plan must place every coin (F-024)', () async {
    final all = game.economy.available.value;
    final f = await game.confirmPlan(need: game.todaysNeedSum, want: 10, save: 5);
    expect(f.reason, FeedbackReason.planNotAll);
    expect(f.messages.single, contains('${all - game.todaysNeedSum - 15}'));
    expect(game.planConfirmed, isFalse);
    expect((await game.confirmPlan(need: game.todaysNeedSum, want: 10, save: all - game.todaysNeedSum - 10)).ok, isTrue);
  });

  test('plan bigger than wallet is refused', () async {
    final f = await game.confirmPlan(need: 20, want: 40, save: 10);
    expect(f.reason, FeedbackReason.planTooBig);
    expect(f.messages, isNotEmpty);
  });

  test('buy before plan asks for plan', () async {
    final f = await game.buy('breakfast', commandId: game.newCommandId());
    expect(f.reason, FeedbackReason.noPlan);
  });

  test('needs: only today list, once a day', () async {
    await game.endDay(); // день 2: без воды
    await planAll(game, need: game.todaysNeedSum, want: 20);
    final notToday = game.content.needItems.firstWhere((i) => !game.todaysNeeds.contains(i));
    expect((await game.buy(notToday.id, commandId: game.newCommandId())).reason, FeedbackReason.notToday);
    final first = game.todaysNeeds.first;
    expect((await game.buy(first.id, commandId: game.newCommandId())).ok, isTrue);
    expect(game.isBoughtToday(first.id), isTrue);
    expect((await game.buy(first.id, commandId: game.newCommandId())).reason, FeedbackReason.alreadyBought);
  });

  test('double tap with same command id debits once', () async {
    await planAll(game, need: game.todaysNeedSum, want: 0);
    final id = game.newCommandId();
    await game.buy('breakfast', commandId: id);
    final before = game.economy.available;
    final f = await game.buy('breakfast', commandId: id);
    expect(f.repeat, isTrue);
    expect(game.economy.available, before);
  });

  test('hero sticker is owned, worn, and not sold twice', () async {
    await planAll(game, need: game.todaysNeedSum, want: 20);
    await buyNeeds();
    expect((await game.buy('glasses', commandId: game.newCommandId())).ok, isTrue);
    expect(game.inventory.owned, contains('glasses'));
    expect(game.inventory.worn, contains('glasses'));
    expect((await game.buy('glasses', commandId: game.newCommandId())).reason, FeedbackReason.alreadyOwned);
    await game.toggleWear('glasses');
    expect(game.inventory.worn, isNot(contains('glasses')));
    await game.toggleWear('glasses');
    expect(game.inventory.worn, contains('glasses'));
  });

  test('insufficient funds reports how much is missing', () async {
    await planAll(game, need: game.todaysNeedSum, want: 0);
    await buyNeeds();
    await game.toSavings(game.economy.available.value - 5);
    final f = await game.buy('headphones', commandId: game.newCommandId());
    expect(f.reason, FeedbackReason.insufficient);
    expect(f.missing, 18 - game.economy.available.value);
    expect(f.messages.length, 2);
  });

  test('partial needs mid-day keep the pet calm, not sad', () async {
    await planAll(game, need: game.todaysNeedSum, want: 0);
    await game.buy(game.todaysNeeds.first.id, commandId: game.newCommandId());
    expect(game.economy.petMood, PetMood.uneasy); // домен
    expect(game.mood, PetMood.steady); // экран: ждёт нужное
  });

  test('sad face from a skipped day shows next morning until the plan', () async {
    await planAll(game, need: game.todaysNeedSum, want: 0);
    await game.buy(game.todaysNeeds.first.id, commandId: game.newCommandId());
    await game.endDay();
    expect(game.mood, PetMood.uneasy);
  });

  test('chocolate makes the day glad only when needs are covered', () async {
    await planAll(game, need: game.todaysNeedSum, want: 12);
    await buyNeeds();
    expect(game.mood, PetMood.steady);
    await game.buy('chocolate', commandId: game.newCommandId());
    expect(game.mood, PetMood.glad);
    expect(game.inventory.owned, isNot(contains('chocolate')));
  });

  group('lessons (F-025)', () {
    test('first lesson of the day pays, labelled; repeat is practice', () async {
      final before = game.economy.available.value;
      final f = await game.finishLesson('needs_1');
      expect(f.reward, 12);
      expect(game.economy.available.value, before + 12);
      expect(game.economy.lastCreditSourceId, 'lesson:needs_1');
      expect(f.messages.single, contains('за урок'));
      final again = await game.finishLesson('needs_1');
      expect(again.reward, 0);
      expect(again.repeat, isTrue);
      expect(game.snapshot.lessonLog.length, 2);
    });

    test('path opens lesson by lesson; first run of a topic is new, next ones are review', () async {
      expect(game.isLessonOpen('needs_1'), isTrue);
      expect(game.isLessonOpen('needs_2'), isFalse);
      expect(game.recommendedLesson.id, 'needs_1');
      await game.finishLesson('needs_1');
      expect(game.snapshot.lessonLog.last.newTopic, isTrue);
      expect(game.isLessonOpen('needs_2'), isTrue);
      expect(game.recommendedLesson.id, 'needs_2');
      await game.finishLesson('needs_2');
      expect(game.snapshot.lessonLog.last.review, isTrue);
      expect(game.snapshot.lessonLog.last.kinds, containsAll(['card', 'pairs', 'next']));
    });

    test('closing mid-lesson keeps the step; finishing later counts as resumed', () async {
      expect(await game.startLesson('needs_1'), 0);
      await game.saveLessonStep('needs_1', 2);
      await game.addLearnTime(90);
      final restarted = await fresh();
      expect(restarted.lessonProgress!.step, 2);
      expect(restarted.recommendedLesson.id, 'needs_1');
      expect(await game.startLesson('needs_1'), 2);
      await game.finishLesson('needs_1');
      expect(game.lessonProgress, isNull);
      expect(game.snapshot.lessonLog.single.resumed, isTrue);
      expect(game.snapshot.learnSeconds[1], 90);
    });
  });

  group('quests (F-026)', () {
    test('three daily quests are fixed in the morning and pay nothing', () async {
      final ids = game.dailyQuests.map((q) => q.$1).toList();
      expect(ids.length, 3);
      expect(game.snapshot.dailyQuests, [for (final q in ids) q.name]);
      final coins = game.economy.available.value;
      await game.finishLesson('needs_1');
      expect(game.economy.available.value, coins + 12); // только награда урока
      await game.endDay();
      expect(game.snapshot.dailyQuests.length, 3);
    });

    test('needs day is recorded for quests', () async {
      await planAll(game, need: game.todaysNeedSum);
      await buyNeeds();
      expect(game.snapshot.needsDays, [1]);
      final weekly = {for (final w in game.weeklyQuests) w.$1: w.$2};
      expect(weekly[WeeklyId.needs3]!.value, 1);
    });

    test('quests lead to a fitting lesson', () async {
      expect(game.lessonFor(QuestId.newTopic).id, 'needs_1');
      await game.finishLesson('needs_1');
      await game.finishLesson('needs_2');
      expect(game.lessonFor(QuestId.newTopic).topic, isNot('needs'));
      expect(game.lessonFor(QuestId.review).topic, 'needs');
      expect(game.lessonFor(QuestId.sortStep).kinds, contains(StepKind.sort));
    });
  });

  test('mini game pays once a day and keeps best score', () async {
    final f = await game.finishMiniGame('sort', win: true, score: 9);
    expect(f.reward, 12);
    final g = await game.finishMiniGame('sort', win: false, score: 4);
    expect(g.reward, 0);
    expect(game.snapshot.gameBest['sort'], 9);
    expect(game.economy.lastCreditSourceId, 'game:sort');
  });

  test('goal: choose, save, redeem, reward lands in inventory', () async {
    expect((await game.chooseGoal('furniture')).reason, FeedbackReason.needOption);
    expect((await game.chooseGoal('furniture', option: 'tv')).ok, isTrue);
    await planAll(game, need: game.todaysNeedSum, want: 0);
    expect((await game.redeemGoal()).reason, FeedbackReason.insufficient);
    await buyNeeds();
    await game.toSavings(40);
    expect(game.goalRemaining, 10);
    expect(game.canRedeem, isFalse);
    await game.finishLesson('needs_1');
    await game.toSavings(10);
    expect(game.canRedeem, isTrue);
    final f = await game.redeemGoal();
    expect(f.ok, isTrue);
    expect(game.inventory.furniture, 'tv');
    expect(game.inventory.goalsDone, contains('furniture'));
    expect(game.goal, isNull);
    expect((await game.chooseGoal('furniture', option: 'sofa')).reason, FeedbackReason.alreadyOwned);
  });

  test('item goal puts its reward into the room (F-029)', () async {
    expect((await game.chooseGoal('telescope')).ok, isTrue);
    await planAll(game, need: game.todaysNeedSum);
    await buyNeeds();
    await game.toSavings(game.economy.available.value);
    await game.finishLesson('needs_1');
    await game.finishMiniGame('sort', win: true, score: 9);
    await game.toSavings(game.economy.available.value);
    expect(game.canRedeem, isTrue);
    expect((await game.redeemGoal()).ok, isTrue);
    expect(game.inventory.owned, contains('telescope'));
    expect(game.inventory.goalsDone, contains('telescope'));
  });

  test('room and skin goals', () async {
    await game.chooseGoal('room2');
    await planAll(game, need: game.todaysNeedSum, want: 0);
    await game.toSavings(40);
    await game.finishLesson('needs_1');
    await game.toSavings(10);
    await game.redeemGoal();
    expect(game.inventory.rooms, 2);
    expect((await game.redeemGoal()).reason, FeedbackReason.noGoal);
  });

  test('withdraw needs confirm; cancel keeps savings', () async {
    await planAll(game, need: game.todaysNeedSum, want: 0);
    await game.toSavings(20);
    expect((await game.confirmWithdraw()).reason, FeedbackReason.withdrawNotPending);
    await game.requestWithdraw(5);
    await game.cancelWithdraw();
    expect(game.economy.savings, GameCoins(20));
    expect(game.economy.pendingWithdraw, isNull);
    await game.requestWithdraw(5);
    expect((await game.confirmWithdraw()).ok, isTrue);
    expect(game.economy.savings, GameCoins(15));
  });

  test('end day: summary, new day, pocket money, flags reset', () async {
    await goodDay(save: 10);
    await game.finishLesson('needs_1');
    await game.finishMiniGame('sort', win: true, score: 10);
    final availableBefore = game.economy.available.value;
    final s = await game.endDay();
    expect(s.day, 1);
    expect(s.good, isTrue);
    expect(s.saved, 10);
    expect(s.spentNeed, 16);
    expect(game.day, 2);
    expect(game.economy.available.value, availableBefore + 20);
    expect(game.economy.lastCreditSourceId, 'pocket:2');
    expect(game.planConfirmed, isFalse);
    expect(game.lessonPaidToday, isFalse);
    expect(game.gameRewardToday, isFalse);
    expect(game.snapshot.boughtToday, isEmpty);
    expect(game.snapshot.lastSummary!.day, 1);
  });

  test('skipped needs make an uneasy, not-good day without losing stage', () async {
    await planAll(game, need: game.todaysNeedSum, want: 0);
    await game.toSavings(5);
    final s = await game.endDay();
    expect(s.good, isFalse);
    expect(s.mood, PetMood.uneasy);
    expect(game.stage, 1);
  });

  test('Appendix A: five demo days grow the pet to stage 3 and survive restart', () async {
    for (var d = 1; d <= 4; d++) {
      await goodDay();
      final s = await game.endDay();
      if (d == 2) expect(s.grew, isTrue);
    }
    expect(game.stage, 3);
    expect(game.stageTitle, 'настоящий взрослый');
    await goodDay();
    await game.endDay();
    expect(game.demoComplete, isTrue);

    final restarted = await fresh();
    expect(restarted.day, 6);
    expect(restarted.stage, 3);
    expect(restarted.economy.savings, game.economy.savings);
  });

  test('every change is persisted', () async {
    await planAll(game, need: game.todaysNeedSum, want: 0);
    await game.buy('breakfast', commandId: game.newCommandId());
    final restarted = await fresh();
    expect(restarted.isBoughtToday('breakfast'), isTrue);
    expect(restarted.planConfirmed, isTrue);
  });

  test('reset wipes the profile', () async {
    await game.reset();
    expect(game.hasProfile, isFalse);
    expect(store.raw, isNull);
    expect((await fresh()).hasProfile, isFalse);
  });

  test('any treat makes the day glad once needs are covered (F-022)', () async {
    expect(game.content.treatItems.length, greaterThanOrEqualTo(9));
    expect(game.content.treatItems.every((i) => i.joy != null), isTrue);
    await planAll(game, need: game.todaysNeedSum, want: 10);
    await buyNeeds();
    await game.buy('icecream', commandId: game.newCommandId());
    expect(game.mood, PetMood.glad);
  });

  test('a treat shows its joy on the hero until the day ends (F-031)', () async {
    expect(game.todaysJoy, isNull);
    await planAll(game, need: game.todaysNeedSum, want: 20);
    await buyNeeds();
    await game.buy('balloon', commandId: game.newCommandId());
    expect(game.todaysJoy, 'balloon');
    await game.buy('cupcake', commandId: game.newCommandId());
    expect(game.todaysJoy, 'hearts'); // видна последняя
    expect(game.mood, PetMood.glad);
    await game.endDay();
    expect(game.todaysJoy, isNull);
  });

  test('needs show in the room: bowls and grooming (F-027)', () async {
    // день 1: завтрак, вода, уход
    expect(game.foodServed, isFalse);
    expect(game.waterServed, isFalse);
    expect(game.isGrubby, isTrue);
    await planAll(game, need: game.todaysNeedSum);
    await game.buy('breakfast', commandId: game.newCommandId());
    expect(game.foodServed, isTrue);
    await game.buy('water', commandId: game.newCommandId());
    expect(game.waterServed, isTrue);
    await game.buy('care', commandId: game.newCommandId());
    expect(game.isGrubby, isFalse);
    expect(game.bowls.food && game.bowls.water, isTrue);
    await game.endDay(); // новый день: миски снова пустые, умывание снова нужно
    expect(game.foodServed, isFalse);
    expect(game.waterServed, !game.todaysNeeds.any((i) => i.id == 'water'));
    expect(game.isGrubby, isTrue);
  });

  group('Finik style (F-023)', () {
    test('profile keeps the chosen skin, color and hair', () async {
      final g = await fresh();
      await g.createProfile(playerName: 'Аня', petName: 'Банни', lookId: 'sun_tuft', skin: 'bunny', color: 0xFF6EDDB0, hair: 'buns');
      expect(g.profile.skin, 'bunny');
      expect(g.profile.color, 0xFF6EDDB0);
      expect((await fresh()).profile.hair, 'buns');
    });

    test('restyle is free and saved', () async {
      final coins = game.economy.available;
      expect((await game.restyle(skin: 'cat', color: 0xFFB79CFF)).ok, isTrue);
      expect(game.profile.skin, 'cat');
      expect(game.profile.color, 0xFFB79CFF);
      expect(game.economy.available, coins);
      expect((await fresh()).profile.skin, 'cat');
    });

    test('monkey waits for the grown-up stage', () async {
      expect(game.isSkinUnlocked('bunny'), isTrue);
      expect(game.isSkinUnlocked('monkey'), isFalse);
      final f = await game.restyle(skin: 'monkey');
      expect(f.reason, FeedbackReason.locked);
      expect(f.messages.single, contains('взрослым'));
      expect(game.profile.skin, 'finik');
      expect((await game.restyle(skin: 'dragon')).reason, FeedbackReason.locked);
      for (var d = 0; d < 4; d++) {
        await goodDay();
        await game.endDay();
      }
      expect(game.stage, 3);
      expect(game.isSkinUnlocked('monkey'), isTrue);
      expect((await game.restyle(skin: 'monkey')).ok, isTrue);
    });
  });

  group('needs first (F-021)', () {
    test('a want before needs is refused and costs nothing', () async {
      await planAll(game, need: game.todaysNeedSum, want: 20);
      final before = game.economy.available;
      final f = await game.buy('glasses', commandId: game.newCommandId());
      expect(f.ok, isFalse);
      expect(f.reason, FeedbackReason.needsFirst);
      expect(f.messages.single, contains('Завтрак'));
      expect(game.economy.available, before);
      expect(game.inventory.owned, isNot(contains('glasses')));
    });

    test('needs themselves are never blocked, wants open after them', () async {
      await planAll(game, need: game.todaysNeedSum, want: 20);
      expect(game.needsLeft.map((i) => i.id), ['breakfast', 'water', 'care']);
      expect(game.needsLeftCost, 16);
      expect((await game.buy('breakfast', commandId: game.newCommandId())).ok, isTrue);
      expect(game.needsLeftTitles, 'Вода, Зубы и умывание');
      expect((await game.buy('water', commandId: game.newCommandId())).ok, isTrue);
      expect((await game.buy('care', commandId: game.newCommandId())).ok, isTrue);
      expect(game.needsLeft, isEmpty);
      expect((await game.buy('glasses', commandId: game.newCommandId())).ok, isTrue);
    });

    test('savings may not eat the money for needs', () async {
      await planAll(game, need: game.todaysNeedSum, want: 0);
      final spare = game.economy.available.value - game.needsLeftCost;
      final f = await game.toSavings(spare + 1);
      expect(f.reason, FeedbackReason.needsFirst);
      expect(game.economy.savings.value, 0);
      expect((await game.toSavings(spare)).ok, isTrue);
      await buyNeeds();
      expect(game.economy.available.value, 0);
    });

    test('games wait for the plan and the needs', () async {
      expect(game.gamesLocked, isTrue); // нет плана
      await planAll(game, need: game.todaysNeedSum, want: 0);
      expect(game.gamesLocked, isTrue); // голоден, монет хватает
      await buyNeeds();
      expect(game.gamesLocked, isFalse);
    });

    test('games open when coins do not cover the needs: a way to earn', () async {
      final raw = {
        for (final name in ContentLoader.files)
          name: jsonDecode(File('assets/content/$name.json').readAsStringSync()),
      };
      (raw['config'] as Map<String, dynamic>)
        ..['startCoins'] = 5
        ..['pocketMoney'] = 5;
      final poor = GameController(content: GameContent.fromJson(raw), store: MemoryProfileStore(), newId: () => 'p${ids++}');
      await poor.init();
      await poor.createProfile(playerName: 'Аня', petName: 'Финни', lookId: 'sun_tuft');
      expect(poor.canAffordNeeds, isFalse);
      expect(poor.gamesLocked, isFalse);
    });
  });
}
