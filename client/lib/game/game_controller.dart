import 'dart:math';

import 'package:flutter/foundation.dart';

import '../content/game_content.dart';
import '../content/lesson_models.dart';
import '../content/models.dart';
import '../economy/economy.dart';
import '../store/profile_store.dart';
import '../store/snapshot.dart';
import 'game_feedback.dart';
import 'quests.dart';
import 'bowls.dart';

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
  static String _randomId() => '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1000000000)}';

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

  /// День знакомства: нужды начинаются со следующего дня (F-042).
  bool get isIntroDay => day < snapshot.firstNeedsDay;

  /// В первый день с нуждами — «первый набор» (завтрак, вода, умывание), дальше — по расписанию.
  List<ShopItem> get todaysNeeds =>
      isIntroDay ? [for (final id in content.config.introDayNeeds) content.item(id)] : content.needsForDay(day == snapshot.firstNeedsDay ? 1 : day);

  /// Нужды «проснулись»: в день знакомства — после урока и игры (F-043), в остальные дни — сразу.
  bool get needsAwake => !isIntroDay || (lessonPaidToday && gameRewardToday);

  /// Пузыри над героем и замок игр — только для проснувшихся нужд (F-043).
  List<ShopItem> get needsShown => needsAwake ? needsLeft : const [];
  int get todaysNeedSum => todaysNeeds.fold(0, (s, i) => s + i.price);
  bool isBoughtToday(String itemId) => snapshot.boughtToday.contains(itemId);
  bool get needsDone => todaysNeeds.every((i) => isBoughtToday(i.id));

  // Потребности видны в комнате (SA F-027).
  bool _needToday(String id) => todaysNeeds.any((i) => i.id == id);
  bool get foodServed => !todaysNeeds.any((i) => i.need == 'food') || todaysNeeds.any((i) => i.need == 'food' && isBoughtToday(i.id));
  bool get waterServed => !_needToday('water') || isBoughtToday('water');

  /// Неухоженный, пока не куплен любой уход дня: умывание, купание, стирка, стрижка (F-032).
  bool get isGrubby => todaysNeeds.any((i) => i.need == 'hygiene' && !isBoughtToday(i.id));
  Bowls get bowls => Bowls(food: foodServed, water: waterServed);

  /// Радость последней хотелки, купленной сегодня (F-031).
  String? get todaysJoy {
    for (final id in snapshot.boughtToday.reversed) {
      final joy = content.item(id).joy;
      if (joy != null) return joy;
    }
    return null;
  }

  // Сначала нужное (SA F-021).
  List<ShopItem> get needsLeft => [
    for (final i in todaysNeeds)
      if (!isBoughtToday(i.id)) i,
  ];
  int get needsLeftCost => needsLeft.fold(0, (s, i) => s + i.price);
  String get needsLeftTitles => needsLeft.map((i) => i.title).join(', ');
  bool get canAffordNeeds => economy.available.value >= needsLeftCost;

  /// Игры с наградой ждут нужное; открыты, если на нужное не хватает — чтобы заработать.
  bool get gamesLocked => needsShown.isNotEmpty && canAffordNeeds;
  String get gamesLockedText =>
      planConfirmed ? content.text('rule.games_locked', {'pet': profile.petName, 'needs': needsLeftTitles}) : content.text('rule.games_no_plan');

  bool get planConfirmed => economy.plan != null;

  /// Награда урока за сегодня уже получена (F-025).
  bool get lessonPaidToday => snapshot.questDoneToday;
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

  PetMood _withTreat(PetMood base) => base == PetMood.steady && content.treatItems.any((i) => isBoughtToday(i.id)) ? PetMood.glad : base;

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
    bool introDay = true,
    String skin = 'finik',
    int? color,
    String? hair,
  }) async {
    var e = EconomyState.empty();
    e = _engine.apply(e, Credit(GameCoins(content.config.startCoins), 'start')).state;
    e = _engine.apply(e, Credit(GameCoins(content.config.pocketMoney), 'pocket:1')).state;
    await _commit(
      GameSnapshot(
        profile: Profile(playerName: playerName, petName: petName, lookId: lookId, skin: skin, color: color, hair: hair),
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
        dailyQuests: [for (final q in pickDailyQuests(day: 1, hasNewTopic: true, hasStarted: false)) q.name],
        introDone: false,
        firstNeedsDay: introDay ? 2 : 1,
      ),
    );
  }

  Future<void> reset() async {
    await _store.clear();
    _snapshot = null;
    notifyListeners();
  }

  Future<void> setSound(bool on) => _commit(snapshot.copyWith(soundOn: on));
  Future<void> setReduceMotion(bool on) => _commit(snapshot.copyWith(reduceMotion: on));

  /// Герой ещё не познакомился с игроком (F-038).
  bool get greeting => !snapshot.introDone;
  Future<void> finishGreeting() => _commit(snapshot.copyWith(introDone: true));

  // ---------- Облик (SA F-023) ----------

  /// Мартышка — награда за рост; старые сохранения с целью-обезьянкой тоже открывают её.
  bool isSkinUnlocked(String skin) {
    final def = content.skin(skin);
    if (def == null) return false;
    final byStage = stage >= def.unlockStage || (skin == 'monkey' && inventory.skin == 'monkey');
    final byGoal = def.unlockGoal == null || inventory.goalsDone.contains(def.unlockGoal);
    return byStage && byGoal && topicsDone >= def.unlockTopics;
  }

  /// Законченных блоков уроков (F-037).
  int get topicsDone => content.topics.where((t) => blockDoneDay(t.id) != null).length;

  /// Как открыть закрытый облик — своя подсказка (F-037).
  String skinLockedText(String skin) => content.text('skin.$skin.locked', {'pet': profile.petName});

  /// Смена облика бесплатна.
  Future<GameFeedback> restyle({String? skin, int? color, String? hair}) async {
    if (skin != null && !isSkinUnlocked(skin)) {
      return _fail(FeedbackReason.locked, [skinLockedText(skin)]);
    }
    await _commit(
      snapshot.copyWith(
        profile: profile.restyled(skin: skin, color: color, hair: hair),
      ),
    );
    return const GameFeedback(ok: true);
  }

  // ---------- Бюджет и покупки ----------

  Future<GameFeedback> confirmPlan({required int need, required int want, required int save}) async {
    // Подтверждённый план не переписывают: с ним сравнивают факт до конца периода (ТЗ: план → факт).
    if (planConfirmed) return _fail(FeedbackReason.planLocked, [content.text('exp.plan_locked')]);
    if (need < todaysNeedSum) {
      return _fail(FeedbackReason.planNeedLow, ['В банку «Нужное» положи хотя бы $todaysNeedSum: столько стоит нужное на сегодня.']);
    }
    final plan = BudgetPlan(need: GameCoins(need), want: GameCoins(want), save: GameCoins(save));
    final r = _engine.apply(economy, ConfirmPlan(plan));
    if (r.error != null) return _fail(FeedbackReason.planTooBig, _texts(r));
    // Все монеты по банкам: запас не отменяет выбор (SA F-024).
    final left = economy.available.value - plan.total.value;
    if (left > 0) {
      return _fail(FeedbackReason.planNotAll, [
        content.text('exp.plan_not_all', {'n': '$left'}),
      ]);
    }
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
      } else if (needsLeft.isNotEmpty) {
        return _fail(FeedbackReason.needsFirst, [
          content.text('rule.want_blocked', {'pet': profile.petName, 'needs': needsLeftTitles}),
        ]);
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
        worn: item.slot == ItemSlot.hero
            ? {
                ...inv.worn.difference({for (final r in _sameWear(inv.worn, itemId)) r.id}),
                itemId,
              } // купленное надевается вместо вещи того же места (F-051)
            : inv.worn,
      );
    }
    final bought = [...snapshot.boughtToday, itemId];
    final allNeeds = todaysNeeds.every((i) => bought.contains(i.id));
    await _commit(
      snapshot.copyWith(
        economy: r.state,
        inventory: inv,
        boughtToday: bought,
        needsDays: allNeeds && !snapshot.needsDays.contains(day) ? [...snapshot.needsDays, day] : null,
      ),
    );
    return GameFeedback(ok: true, messages: [..._texts(r), item.effect]);
  }

  /// Надеть или снять. Надетая вещь снимает другую с того же места (F-051); вернёт снятую, если была.
  Future<ShopItem?> toggleWear(String itemId) async {
    if (!inventory.owned.contains(itemId)) return null;
    final worn = {...inventory.worn};
    if (worn.remove(itemId)) {
      await _commit(snapshot.copyWith(inventory: inventory.copyWith(worn: worn)));
      return null;
    }
    final replaced = _sameWear(worn, itemId);
    worn
      ..removeAll([for (final r in replaced) r.id])
      ..add(itemId);
    await _commit(snapshot.copyWith(inventory: inventory.copyWith(worn: worn)));
    return replaced.firstOrNull;
  }

  /// Надетые вещи с того же места, что и [itemId].
  List<ShopItem> _sameWear(Set<String> worn, String itemId) {
    final place = content.item(itemId).wear;
    if (place == null) return const [];
    return [
      for (final id in worn)
        if (id != itemId && content.item(id).wear == place) content.item(id),
    ];
  }

  // ---------- Копилка и цель ----------

  Future<GameFeedback> toSavings(int amount) async {
    if (needsLeft.isNotEmpty && economy.available.value - amount < needsLeftCost) {
      return _fail(FeedbackReason.needsFirst, [
        content.text('rule.save_blocked', {'n': '$amount', 'needs': needsLeftTitles}),
      ]);
    }
    final r = _engine.apply(economy, TransferToSavings(GameCoins(amount)));
    if (r.error != null) {
      final missing = amount - economy.available.value;
      return _fail(FeedbackReason.insufficient, _texts(r, n: '$missing'), missing: missing);
    }
    await _commit(snapshot.copyWith(economy: r.state));
    return GameFeedback(ok: true, messages: _texts(r));
  }

  /// Покупки текущего периода по порядку (ТЗ 2.5.6, F-056).
  List<ShopItem> get purchasesToday => [for (final id in snapshot.boughtToday) content.item(id)];

  /// Средняя сумма регулярного пополнения копилки (ТЗ 2.5.7, F-055): по прошлым периодам;
  /// нет истории — отложенное сегодня, затем план «Отложить». 0 — посчитать нельзя.
  int get averageSaving {
    final h = snapshot.savedHistory;
    if (h.isNotEmpty) {
      final avg = h.reduce((a, b) => a + b) ~/ h.length;
      return avg == 0 && h.any((v) => v > 0) ? 1 : avg;
    }
    final today = economy.savedThisPeriod.value;
    if (today > 0) return today;
    return economy.plan?.save.value ?? 0;
  }

  /// Сколько дней до цели при средней сумме пополнения; null — посчитать нельзя.
  int? daysToGoal(int remaining) {
    if (remaining <= 0) return 0;
    final avg = averageSaving;
    return avg <= 0 ? null : (remaining / avg).ceil();
  }

  /// Прибавка копилки-вклада за сумму: 1 монета за каждые 10 (F-044).
  int interestFor(int savings) => savings * content.config.interestPercent ~/ 100;

  /// Сколько копилка прибавит этой ночью; после снятия — ничего.
  int get interestTonight => snapshot.withdrewToday ? 0 : interestFor(economy.savings.value);

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
    await _commit(snapshot.copyWith(economy: r.state, withdrewToday: true));
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
      GoalReward.skin => inv, // облик открывается целью в goalsDone (F-037)
      GoalReward.furniture => inv.copyWith(furniture: snapshot.goalOption),
      GoalReward.gift => inv, // радость дарить: цель отмечена в goalsDone
      GoalReward.item => inv.copyWith(owned: {...inv.owned, ?g.item}), // вещь-награда в комнату (F-029)
    };
    await _commit(snapshot.copyWith(economy: r.state, inventory: inv, clearGoal: true));
    return GameFeedback(ok: true, messages: _texts(r));
  }

  // ---------- Задания и мини-игры ----------

  // ---------- Уроки (SA F-025) ----------

  bool isLessonDone(String id) => snapshot.lessonLog.any((r) => r.lessonId == id);
  bool isLessonDoneLesson(Lesson l) => isLessonDone(l.id);
  bool isTopicStarted(String topicId) => snapshot.lessonLog.any((r) => content.lesson(r.lessonId).topic == topicId);
  LessonProgress? get lessonProgress => snapshot.lessonProgress;

  /// День, когда блок (тема) закончен впервые; `null` — ещё нет (F-035).
  int? blockDoneDay(String topicId) {
    var last = 0;
    for (final l in content.lessonsOf(topicId)) {
      final run = snapshot.lessonLog.where((r) => r.lessonId == l.id).firstOrNull;
      if (run == null) return null;
      last = max(last, run.day);
    }
    return last;
  }

  /// Путь: первый урок открыт, следующий — после предыдущего; новый блок — только после сна
  /// после окончания предыдущего блока (F-035). Пройденные можно повторять.
  bool isLessonOpen(String id) {
    final i = content.lessons.indexWhere((l) => l.id == id);
    if (i == 0 || isLessonDone(id)) return true;
    if (i < 0 || !isLessonDone(content.lessons[i - 1].id)) return false;
    final prev = content.lessons[i - 1];
    if (prev.topic == content.lessons[i].topic) return true;
    final done = blockDoneDay(prev.topic);
    return done != null && done < day;
  }

  /// Следующий урок пути — первый в новом блоке, а предыдущий блок закончен сегодня.
  bool get nextBlockWaitsForSleep {
    final next = content.lessons.where((l) => !isLessonDone(l.id)).firstOrNull;
    return next != null && !isLessonOpen(next.id) && isLessonDone(content.lessons[content.lessons.indexOf(next) - 1].id);
  }

  /// Новый блок можно открыть сегодня (для задания «Открой новую тему»).
  bool get hasNewTopicToday {
    final next = content.lessons.where((l) => !isTopicStarted(l.topic)).firstOrNull;
    return next != null && isLessonOpen(next.id);
  }

  /// Что пройти сейчас: начатый, иначе следующий по пути, иначе повтор первого.
  Lesson get recommendedLesson {
    final p = lessonProgress;
    if (p != null) return content.lesson(p.lessonId);
    // Новый блок ждёт сна — предлагаем повторить пройденное (F-035).
    return content.lessons.where((l) => !isLessonDone(l.id) && isLessonOpen(l.id)).firstOrNull ??
        content.lessons.where(isLessonDoneLesson).lastOrNull ??
        content.lessons.first;
  }

  bool get hasNewTopic => content.topics.any((t) => !isTopicStarted(t.id));

  /// Откроется ли новый блок в день [d] (утро после сна).
  bool _newTopicOn(int d) {
    final i = content.lessons.indexWhere((l) => !isTopicStarted(l.topic));
    if (i < 0) return false;
    if (i == 0) return true;
    final done = blockDoneDay(content.lessons[i - 1].topic);
    return done != null && done < d;
  }

  /// Открывает урок; возвращает шаг, с которого продолжить.
  Future<int> startLesson(String id) async {
    final p = lessonProgress;
    if (p != null && p.lessonId == id) {
      if (p.step > 0 && !p.resumed) {
        await _commit(
          snapshot.copyWith(
            lessonProgress: LessonProgress(lessonId: id, step: p.step, resumed: true),
          ),
        );
      }
      return p.step;
    }
    await _commit(snapshot.copyWith(lessonProgress: LessonProgress(lessonId: id, step: 0)));
    return 0;
  }

  Future<void> saveLessonStep(String id, int step) async {
    final resumed = lessonProgress?.lessonId == id && lessonProgress!.resumed;
    await _commit(
      snapshot.copyWith(
        lessonProgress: LessonProgress(lessonId: id, step: step, resumed: resumed),
      ),
    );
  }

  Future<void> addLearnTime(int seconds) async {
    if (seconds <= 0) return;
    final learn = {...snapshot.learnSeconds};
    learn[day] = (learn[day] ?? 0) + seconds;
    await _commit(snapshot.copyWith(learnSeconds: learn));
  }

  /// Урок закончен: журнал, награда урока за первый урок дня (ТЗ: награда урока).
  Future<GameFeedback> finishLesson(String id) async {
    final lesson = content.lesson(id);
    final topicKnown = isTopicStarted(lesson.topic);
    final p = lessonProgress;
    final run = LessonRun(
      lessonId: id,
      day: day,
      newTopic: !topicKnown,
      review: topicKnown,
      kinds: [for (final k in lesson.kinds) k.name],
      resumed: p != null && p.lessonId == id && p.resumed,
    );
    var next = snapshot.copyWith(lessonLog: [...snapshot.lessonLog, run], clearLessonProgress: true);
    if (lessonPaidToday) {
      await _commit(next);
      return GameFeedback(ok: true, repeat: true, messages: [content.text('lesson.repeat')]);
    }
    final reward = content.config.rewardWise;
    final r = _engine.apply(economy, Credit(GameCoins(reward), 'lesson:$id'));
    next = next.copyWith(economy: r.state, questDoneToday: true);
    await _commit(next);
    return GameFeedback(
      ok: true,
      reward: reward,
      messages: [
        content.text('lesson.reward', {'n': '$reward'}),
      ],
    );
  }

  // ---------- Задания дня и недели (SA F-026) ----------

  LearnFacts get _facts => LearnFacts(day: day, runs: snapshot.lessonLog, learnSeconds: snapshot.learnSeconds, needsDays: snapshot.needsDays);

  List<(QuestId, QuestProgress)> get dailyQuests {
    final ids = snapshot.dailyQuests.isEmpty
        ? pickDailyQuests(day: day, hasNewTopic: hasNewTopicToday, hasStarted: lessonProgress != null)
        : [for (final n in snapshot.dailyQuests) QuestId.values.byName(n)];
    return [for (final q in ids) (q, dailyProgress(q, _facts))];
  }

  List<(WeeklyId, QuestProgress)> get weeklyQuests => [for (final w in WeeklyId.values) (w, weeklyProgress(w, _facts))];

  bool isQuestClaimed(QuestId q) => snapshot.claimed.contains('d$day:${q.name}');
  bool isWeeklyClaimed(WeeklyId w) => snapshot.claimed.contains('w${weekOf(day)}:${w.name}');

  /// Забрать награду выполненного задания дня (F-036).
  Future<GameFeedback> claimQuest(QuestId q) async {
    final entry = dailyQuests.where((e) => e.$1 == q).firstOrNull;
    if (entry == null || !entry.$2.done || isQuestClaimed(q)) {
      return _fail(FeedbackReason.none, [content.text('quest.claim.no')]);
    }
    return _claim('d$day:${q.name}', 'quest:${q.name}', content.config.questReward);
  }

  /// Забрать награду выполненного задания недели (F-036).
  Future<GameFeedback> claimWeekly(WeeklyId w) async {
    final entry = weeklyQuests.where((e) => e.$1 == w).first;
    if (!entry.$2.done || isWeeklyClaimed(w)) return _fail(FeedbackReason.none, [content.text('quest.claim.no')]);
    return _claim('w${weekOf(day)}:${w.name}', 'weekly:${weekOf(day)}:${w.name}', content.config.weeklyReward);
  }

  Future<GameFeedback> _claim(String key, String source, int reward) async {
    final r = _engine.apply(economy, Credit(GameCoins(reward), source));
    await _commit(snapshot.copyWith(economy: r.state, claimed: [...snapshot.claimed, key]));
    return GameFeedback(
      ok: true,
      reward: reward,
      messages: [
        content.text('quest.claim.ok', {'n': '$reward'}),
      ],
    );
  }

  /// Урок, в который ведёт задание.
  Lesson lessonFor(QuestId q) {
    final open = [
      for (final l in content.lessons)
        if (isLessonOpen(l.id)) l,
    ];
    Lesson pick(bool Function(Lesson l) test) =>
        open.where((l) => test(l) && !isLessonDone(l.id)).firstOrNull ?? open.where(test).firstOrNull ?? recommendedLesson;
    return switch (q) {
      QuestId.review => open.where((l) => isTopicStarted(l.topic)).firstOrNull ?? recommendedLesson,
      QuestId.newTopic => pick((l) => !isTopicStarted(l.topic)),
      QuestId.nextStep => pick((l) => l.kinds.contains(StepKind.next)),
      QuestId.sortStep => pick((l) => l.kinds.contains(StepKind.sort)),
      _ => recommendedLesson,
    };
  }

  Future<GameFeedback> finishMiniGame(String gameId, {required bool win, required int score}) async {
    final best = {...snapshot.gameBest};
    best[gameId] = max(best[gameId] ?? 0, score);
    if (gameRewardToday) {
      await _commit(snapshot.copyWith(gameBest: best));
      return const GameFeedback(ok: true, repeat: true, messages: ['Награда за игру сегодня уже получена. Играй для тренировки!']);
    }
    final reward = win ? content.config.gameWin : content.config.gameTry;
    final r = _engine.apply(economy, Credit(GameCoins(reward), 'game:$gameId'));
    await _commit(snapshot.copyWith(economy: r.state, gameRewardToday: true, gameBest: best));
    return GameFeedback(ok: true, reward: reward, messages: ['+$reward монет за игру!']);
  }

  // ---------- Конец дня ----------

  Future<DaySummary> endDay() async {
    final before = economy;
    final plan = before.plan;
    final interest = interestTonight;
    var closed = _engine.apply(before, const ClosePeriod()).state;
    if (interest > 0) closed = _engine.apply(closed, AccrueInterest(GameCoins(interest), 'interest:$day')).state;
    final dayMood = _withTreat(closed.petMood);
    final nextDay = day + 1;
    final morning = _engine.apply(closed, Credit(GameCoins(content.config.pocketMoney), 'pocket:$nextDay')).state;
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
      interest: interest,
    );
    await _commit(
      snapshot.copyWith(
        economy: morning,
        day: nextDay,
        boughtToday: const [],
        questDoneToday: false,
        gameRewardToday: false,
        withdrewToday: false,
        savedHistory: [...snapshot.savedHistory, before.savedThisPeriod.value].reversed.take(10).toList().reversed.toList(),
        lastSummary: summary,
        dailyQuests: [for (final q in pickDailyQuests(day: nextDay, hasNewTopic: _newTopicOn(nextDay), hasStarted: lessonProgress != null)) q.name],
      ),
    );
    return summary;
  }

  /// Совет на завтра по итогу дня.
  String adviceFor(DaySummary s) {
    if (s.spentNeed < s.planNeed || s.planNeed == 0) return content.text('advice.need');
    if (s.spentWant > s.planWant) return content.text('advice.plan'); // перерасход хотелок мешает росту (F-054)
    if (s.saved == 0) return content.text('advice.save');
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
