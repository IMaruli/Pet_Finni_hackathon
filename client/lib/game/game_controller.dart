import 'dart:math';

import 'package:flutter/foundation.dart';

import '../content/game_content.dart';
import '../content/models.dart';
import '../economy/economy.dart';
import '../store/profile_store.dart';
import '../store/snapshot.dart';
import 'game_feedback.dart';

/// Единая точка изменения состояния игры (SA F-006).
final class GameController extends ChangeNotifier {
  GameController({
    required this.content,
    required ProfileStore store,
    String Function()? newId,
    // ignore: prefer_initializing_formals
  }) : _store = store,
       _newId = newId ?? _randomId;

  static final _random = Random();
  static String _randomId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1000000000)}';

  final GameContent content;
  final ProfileStore _store;
  final String Function() _newId;
  static const _engine = EconomyEngine();

  bool _loaded = false;
  GameSnapshot? _snapshot;

  // ---------- Состояние ----------

  bool get loaded => _loaded;
  bool get hasProfile => _snapshot != null;
  GameSnapshot get snapshot => _snapshot!;
  EconomyState get economy => snapshot.economy;
  Profile get profile => snapshot.profile;
  Inventory get inventory => snapshot.inventory;
  int get day => snapshot.day;

  List<ShopItem> get todaysNeeds => content.needsForDay(day);
  int get todaysNeedSum => todaysNeeds.fold(0, (s, i) => s + i.price);
  bool isBoughtToday(String itemId) => snapshot.boughtToday.contains(itemId);
  bool get needsDone => todaysNeeds.every((i) => isBoughtToday(i.id));

  bool get planConfirmed => economy.plan != null;
  Quest get todaysQuest => content.questForDay(day);
  bool get questDoneToday => snapshot.questDoneToday;
  bool get gameRewardToday => snapshot.gameRewardToday;

  GoalDef? get goal => snapshot.goalId == null ? null : content.goal(snapshot.goalId!);
  int get goalRemaining => goal == null ? 0 : max(0, goal!.cost - economy.savings.value);
  bool get canRedeem => goal != null && goalRemaining == 0;

  /// Настроение на экране (SA F-006 BR-05, BR-14).
  /// Днём, пока нужное можно докупить, герой не грустит, а ждёт: грусть — итог дня.
  /// Утром до плана видно вчерашнее настроение. Шоколадка — короткая радость, но не вместо нужного.
  PetMood get mood {
    var base = economy.petMood;
    if (base == PetMood.uneasy && planConfirmed && !needsDone) base = PetMood.steady;
    return _withTreat(base);
  }

  PetMood _withTreat(PetMood base) =>
      base == PetMood.steady && isBoughtToday('chocolate') ? PetMood.glad : base;

  int get stage => economy.petStage;
  String get stageTitle => content.text('stage.$stage');
  bool get demoComplete => day > content.config.demoPeriods;

  String newCommandId() => _newId();

  // ---------- Жизненный цикл ----------

  Future<void> init() async {
    _snapshot = await _store.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> createProfile({
    required String playerName,
    required String petName,
    required String lookId,
  }) async {
    var e = EconomyState.empty();
    e = _engine.apply(e, Credit(GameCoins(content.config.startCoins), 'start')).state;
    e = _engine.apply(e, Credit(GameCoins(content.config.pocketMoney), 'pocket:1')).state;
    await _commit(
      GameSnapshot(
        profile: Profile(playerName: playerName, petName: petName, lookId: lookId),
        economy: e,
        inventory: Inventory.empty,
        goalId: null,
        goalOption: null,
        day: 1,
        boughtToday: const [],
        questDoneToday: false,
        gameRewardToday: false,
        questsDone: const [],
        gameBest: const {},
        lastSummary: null,
        soundOn: true,
      ),
    );
  }

  Future<void> reset() async {
    await _store.clear();
    _snapshot = null;
    notifyListeners();
  }

  Future<void> setSound(bool on) => _commit(snapshot.copyWith(soundOn: on));

  // ---------- Бюджет и покупки ----------

  Future<GameFeedback> confirmPlan({required int need, required int want, required int save}) async {
    if (need < todaysNeedSum) {
      return _fail(FeedbackReason.planNeedLow, [
        'В банку «Нужное» положи хотя бы $todaysNeedSum: столько стоит нужное на сегодня.',
      ]);
    }
    final plan = BudgetPlan(need: GameCoins(need), want: GameCoins(want), save: GameCoins(save));
    final r = _engine.apply(economy, ConfirmPlan(plan));
    if (r.error != null) return _fail(FeedbackReason.planTooBig, _texts(r));
    await _commit(snapshot.copyWith(economy: r.state));
    return GameFeedback(ok: true, messages: _texts(r));
  }

  Future<GameFeedback> buy(String itemId, {required String commandId}) async {
    final item = content.item(itemId);
    final repeat = economy.processedBuyIds.contains(commandId);
    if (!repeat) {
      if (!planConfirmed) return _fail(FeedbackReason.noPlan, [content.text('exp.need_plan')]);
      if (item.kind == ItemKind.need) {
        if (!todaysNeeds.any((i) => i.id == itemId)) {
          return _fail(FeedbackReason.notToday, ['Сегодня это не нужно. Посмотри список нужного дня.']);
        }
        if (isBoughtToday(itemId)) {
          return _fail(FeedbackReason.alreadyBought, ['Уже куплено сегодня. Завтра понадобится снова.']);
        }
      } else if (item.slot != ItemSlot.consumable && inventory.owned.contains(itemId)) {
        return _fail(FeedbackReason.alreadyOwned, ['Это у тебя уже есть!']);
      }
    }

    final r = _engine.apply(economy, BuyItem(commandId: commandId, item: item.catalogItem));
    if (repeat) return GameFeedback(ok: true, repeat: true, messages: _texts(r));
    if (r.error == EconomyError.noPlan) return _fail(FeedbackReason.noPlan, _texts(r));
    if (r.error != null) {
      final missing = item.price - economy.available.value;
      return _fail(FeedbackReason.insufficient, _texts(r, n: '$missing'), missing: missing);
    }

    var inv = inventory;
    if (item.slot != ItemSlot.consumable) {
      inv = inv.copyWith(
        owned: {...inv.owned, itemId},
        worn: item.slot == ItemSlot.hero ? {...inv.worn, itemId} : inv.worn,
      );
    }
    await _commit(
      snapshot.copyWith(
        economy: r.state,
        inventory: inv,
        boughtToday: [...snapshot.boughtToday, itemId],
      ),
    );
    return GameFeedback(ok: true, messages: [..._texts(r), item.effect]);
  }

  Future<void> toggleWear(String itemId) async {
    if (!inventory.owned.contains(itemId)) return;
    final worn = {...inventory.worn};
    if (!worn.remove(itemId)) worn.add(itemId);
    await _commit(snapshot.copyWith(inventory: inventory.copyWith(worn: worn)));
  }

  // ---------- Копилка и цель ----------

  Future<GameFeedback> toSavings(int amount) async {
    final r = _engine.apply(economy, TransferToSavings(GameCoins(amount)));
    if (r.error != null) {
      final missing = amount - economy.available.value;
      return _fail(FeedbackReason.insufficient, _texts(r, n: '$missing'), missing: missing);
    }
    await _commit(snapshot.copyWith(economy: r.state));
    return GameFeedback(ok: true, messages: _texts(r));
  }

  Future<GameFeedback> requestWithdraw(int amount) async {
    final r = _engine.apply(economy, RequestWithdraw(GameCoins(amount)));
    if (r.error != null) {
      final missing = amount - economy.savings.value;
      return _fail(FeedbackReason.insufficient, _texts(r, n: '$missing'), missing: missing);
    }
    await _commit(snapshot.copyWith(economy: r.state));
    return GameFeedback(ok: true, messages: _texts(r));
  }

  Future<GameFeedback> confirmWithdraw() async {
    final r = _engine.apply(economy, const ConfirmWithdraw());
    if (r.error != null) return _fail(FeedbackReason.withdrawNotPending, _texts(r));
    await _commit(snapshot.copyWith(economy: r.state));
    return GameFeedback(ok: true, messages: _texts(r));
  }

  /// Отмена первого шага снятия: копилка не меняется.
  Future<void> cancelWithdraw() async {
    if (economy.pendingWithdraw == null) return;
    await _commit(snapshot.copyWith(economy: economy.copyWith(clearPendingWithdraw: true)));
  }

  Future<GameFeedback> chooseGoal(String goalId, {String? option}) async {
    final g = content.goal(goalId);
    if (inventory.goalsDone.contains(goalId)) {
      return _fail(FeedbackReason.alreadyOwned, ['Эта цель уже достигнута! Выбери другую.']);
    }
    if (g.reward == GoalReward.furniture && !g.options.any((o) => o.id == option)) {
      return _fail(FeedbackReason.needOption, ['Выбери, какую вещь хочешь.']);
    }
    await _commit(snapshot.copyWith(goalId: goalId, goalOption: option));
    return GameFeedback(ok: true, messages: ['Цель выбрана: ${g.title}. Копим!']);
  }

  Future<GameFeedback> redeemGoal() async {
    final g = goal;
    if (g == null) return _fail(FeedbackReason.noGoal, ['Сначала выбери цель.']);
    final r = _engine.apply(economy, RedeemGoal(goalId: g.id, cost: g.coins));
    if (r.error != null) {
      return _fail(FeedbackReason.insufficient, _texts(r, n: '$goalRemaining'), missing: goalRemaining);
    }
    var inv = inventory.copyWith(goalsDone: {...inventory.goalsDone, g.id});
    inv = switch (g.reward) {
      GoalReward.room => inv.copyWith(rooms: 2),
      GoalReward.skin => inv.copyWith(skin: 'monkey'),
      GoalReward.furniture => inv.copyWith(furniture: snapshot.goalOption),
    };
    await _commit(snapshot.copyWith(economy: r.state, inventory: inv, clearGoal: true));
    return GameFeedback(ok: true, messages: _texts(r));
  }

  // ---------- Задания и мини-игры ----------

  Future<GameFeedback> answerQuest(int choiceIndex) async {
    final q = todaysQuest;
    final choice = q.choices[choiceIndex];
    if (questDoneToday) {
      return GameFeedback(ok: true, repeat: true, messages: [choice.explanation]);
    }
    final r = _engine.apply(economy, Credit(GameCoins(choice.reward), 'quest:${q.id}'));
    await _commit(
      snapshot.copyWith(
        economy: r.state,
        questDoneToday: true,
        questsDone: [...snapshot.questsDone, q.id],
      ),
    );
    return GameFeedback(ok: true, reward: choice.reward, messages: [choice.explanation]);
  }

  Future<GameFeedback> finishMiniGame(String gameId, {required bool win, required int score}) async {
    final best = {...snapshot.gameBest};
    best[gameId] = max(best[gameId] ?? 0, score);
    if (gameRewardToday) {
      await _commit(snapshot.copyWith(gameBest: best));
      return const GameFeedback(
        ok: true,
        repeat: true,
        messages: ['Награда за игру сегодня уже получена. Играй для тренировки!'],
      );
    }
    final reward = win ? content.config.rewardWise : content.config.rewardTry;
    final r = _engine.apply(economy, Credit(GameCoins(reward), 'game:$gameId'));
    await _commit(snapshot.copyWith(economy: r.state, gameRewardToday: true, gameBest: best));
    return GameFeedback(ok: true, reward: reward, messages: ['+$reward монет за игру!']);
  }

  // ---------- Конец дня ----------

  Future<DaySummary> endDay() async {
    final before = economy;
    final plan = before.plan;
    final closed = _engine.apply(before, const ClosePeriod()).state;
    final dayMood = _withTreat(closed.petMood);
    final nextDay = day + 1;
    final morning = _engine
        .apply(closed, Credit(GameCoins(content.config.pocketMoney), 'pocket:$nextDay'))
        .state;
    final summary = DaySummary(
      day: day,
      planNeed: plan?.need.value ?? 0,
      planWant: plan?.want.value ?? 0,
      planSave: plan?.save.value ?? 0,
      spentNeed: before.spentNeed.value,
      spentWant: before.spentWant.value,
      saved: before.savedThisPeriod.value,
      mood: dayMood,
      stageBefore: before.petStage,
      stageAfter: closed.petStage,
      good: closed.goodPeriods > before.goodPeriods,
      goodPeriods: closed.goodPeriods,
    );
    await _commit(
      snapshot.copyWith(
        economy: morning,
        day: nextDay,
        boughtToday: const [],
        questDoneToday: false,
        gameRewardToday: false,
        lastSummary: summary,
      ),
    );
    return summary;
  }

  /// Совет на завтра по итогу дня.
  String adviceFor(DaySummary s) {
    if (s.spentNeed < s.planNeed || s.planNeed == 0) return content.text('advice.need');
    if (s.saved == 0) return content.text('advice.save');
    if (s.spentWant > s.planWant) return content.text('advice.plan');
    return content.text('advice.great');
  }

  // ---------- Внутреннее ----------

  List<String> _texts(EconomyResult r, {String n = ''}) => [
    for (final id in r.explanationIds) content.text(id, {'n': n, 'pet': profile.petName}),
  ];

  GameFeedback _fail(FeedbackReason reason, List<String> messages, {int missing = 0}) =>
      GameFeedback(ok: false, reason: reason, messages: messages, missing: missing);

  Future<void> _commit(GameSnapshot next) async {
    _snapshot = next;
    notifyListeners();
    await _store.save(next);
  }
}
