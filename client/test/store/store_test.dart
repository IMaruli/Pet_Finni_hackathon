import 'dart:convert';

import 'package:finni/economy/economy.dart';
import 'package:finni/store/profile_store.dart';
import 'package:finni/store/snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

GameSnapshot sample() {
  const engine = EconomyEngine();
  var e = engine.apply(EconomyState.empty(), Credit(GameCoins(60), 'start')).state;
  e = engine
      .apply(e, ConfirmPlan(BudgetPlan(need: GameCoins(16), want: GameCoins(4), save: GameCoins(10))))
      .state;
  e = engine
      .apply(e, BuyItem(commandId: 'b1', item: CatalogItem(id: 'breakfast', kind: ItemKind.need, price: GameCoins(8))))
      .state;
  e = engine.apply(e, TransferToSavings(GameCoins(10))).state;
  e = engine.apply(e, RequestWithdraw(GameCoins(3))).state;
  return GameSnapshot(
    profile: const Profile(playerName: 'Аня', petName: 'Финни', lookId: 'sun_tuft'),
    economy: e,
    inventory: Inventory.empty.copyWith(owned: {'glasses'}, worn: {'glasses'}, rooms: 2, furniture: 'tv', skin: 'monkey', goalsDone: {'room2'}),
    goalId: 'furniture',
    goalOption: 'tv',
    day: 3,
    boughtToday: const ['breakfast'],
    questDoneToday: true,
    gameRewardToday: false,
    questsDone: const ['q1', 'q2'],
    gameBest: const {'sort': 9},
    lastSummary: const DaySummary(
      day: 2, planNeed: 16, planWant: 4, planSave: 10, spentNeed: 16, spentWant: 0, saved: 10,
      mood: PetMood.glad, stageBefore: 1, stageAfter: 2, good: true, goodPeriods: 2,
    ),
    soundOn: false,
  );
}

void main() {
  test('snapshot survives JSON round-trip', () {
    final s = sample();
    final back = GameSnapshot.fromJson(jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
    expect(jsonEncode(back.toJson()), jsonEncode(s.toJson()));
    expect(back.economy.pendingWithdraw, GameCoins(3));
    expect(back.economy.plan!.save, GameCoins(10));
    expect(back.economy.petMood, s.economy.petMood);
    expect(back.inventory.worn, {'glasses'});
    expect(back.lastSummary!.grew, isTrue);
  });

  test('empty economy (no plan, no pending) round-trips', () {
    final s = sample().copyWith(economy: EconomyState.empty(), clearSummary: true);
    final back = GameSnapshot.fromJson(jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
    expect(back.economy.plan, isNull);
    expect(back.economy.pendingWithdraw, isNull);
    expect(back.lastSummary, isNull);
  });

  test('wrong version is a format error', () {
    final json = sample().toJson()..['version'] = 99;
    expect(() => GameSnapshot.fromJson(json), throwsFormatException);
  });

  group('SharedPrefsProfileStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('first launch loads null', () async {
      expect(await SharedPrefsProfileStore().load(), isNull);
    });

    test('save then load returns same snapshot', () async {
      final store = SharedPrefsProfileStore();
      await store.save(sample());
      final loaded = await SharedPrefsProfileStore().load();
      expect(jsonEncode(loaded!.toJson()), jsonEncode(sample().toJson()));
    });

    test('clear wipes everything', () async {
      final store = SharedPrefsProfileStore();
      await store.save(sample());
      await store.clear();
      expect(await store.load(), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
    });

    test('corrupted snapshot starts clean and is removed', () async {
      SharedPreferences.setMockInitialValues({SharedPrefsProfileStore.key: '{not json'});
      final store = SharedPrefsProfileStore();
      expect(await store.load(), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(SharedPrefsProfileStore.key), isFalse);
    });

    test('snapshot missing a field starts clean', () async {
      final json = sample().toJson()..remove('profile');
      SharedPreferences.setMockInitialValues({SharedPrefsProfileStore.key: jsonEncode(json)});
      expect(await SharedPrefsProfileStore().load(), isNull);
    });
  });

  test('memory store round-trips and clears', () async {
    final store = MemoryProfileStore();
    await store.save(sample());
    expect((await store.load())!.day, 3);
    await store.clear();
    expect(await store.load(), isNull);
  });
}
