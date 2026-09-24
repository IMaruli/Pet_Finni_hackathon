import '../economy/catalog_item.dart';
import '../economy/game_coins.dart';

enum ItemSlot { consumable, hero, room }

enum GoalReward { room, skin, furniture, gift, item }

T _enum<T extends Enum>(List<T> values, Object? raw, String field) {
  for (final v in values) {
    if (v.name == raw) return v;
  }
  throw FormatException('unknown $field: $raw');
}

ItemKind _kind(Object? raw) => _enum(ItemKind.values, raw, 'kind');

final class ShopItem {
  const ShopItem({
    required this.id,
    required this.kind,
    required this.price,
    required this.title,
    required this.emoji,
    required this.effect,
    required this.slot,
    this.accessory,
    this.joy,
    this.need,
    this.ask,
  });

  factory ShopItem.fromJson(Map<String, dynamic> j) => ShopItem(
    id: j['id'] as String,
    kind: _kind(j['kind']),
    price: j['price'] as int,
    title: j['title'] as String,
    emoji: j['emoji'] as String,
    effect: j['effect'] as String,
    slot: _enum(ItemSlot.values, j['slot'], 'slot'),
    accessory: j['accessory'] as String?,
    joy: j['joy'] as String?,
    need: j['need'] as String?,
    ask: j['ask'] as String?,
  );

  final String id;
  final ItemKind kind;
  final int price;
  final String title;
  final String emoji;
  final String effect;
  final ItemSlot slot;

  /// hero: bandana|glasses|bow|headphones; room: lamp|rug|poster.
  final String? accessory;

  /// Как хотелка радует героя (F-031): hearts|sparkles|bubbles|balloon|notes|stars.
  final String? joy;

  /// Группа нужного (F-032): food|water|hygiene.
  final String? need;

  /// Реплика героя, когда эта вещь нужна (F-032).
  final String? ask;

  GameCoins get coins => GameCoins(price);
  CatalogItem get catalogItem => CatalogItem(id: id, kind: kind, price: coins);
}

final class GoalOption {
  const GoalOption({required this.id, required this.title, required this.emoji});
  factory GoalOption.fromJson(Map<String, dynamic> j) =>
      GoalOption(id: j['id'] as String, title: j['title'] as String, emoji: j['emoji'] as String);
  final String id;
  final String title;
  final String emoji;
}

final class GoalDef {
  const GoalDef({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.cost,
    required this.reward,
    required this.options,
    this.item,
  });

  factory GoalDef.fromJson(Map<String, dynamic> j) => GoalDef(
    id: j['id'] as String,
    title: j['title'] as String,
    emoji: j['emoji'] as String,
    description: j['description'] as String,
    cost: j['cost'] as int,
    reward: _enum(GoalReward.values, j['reward'], 'reward'),
    item: j['item'] as String?,
    options: [
      for (final o in (j['options'] as List? ?? const []))
        GoalOption.fromJson(o as Map<String, dynamic>),
    ],
  );

  final String id;
  final String title;
  final String emoji;
  final String description;
  final int cost;
  final GoalReward reward;
  final List<GoalOption> options;

  /// Вещь в комнату для `reward: item` (F-029).
  final String? item;

  GameCoins get coins => GameCoins(cost);
}

/// Скин героя (SA F-023). [unlockStage] > 1 — открывается ростом героя.
final class SkinDef {
  const SkinDef({required this.id, required this.title, this.unlockStage = 1});
  factory SkinDef.fromJson(Map<String, dynamic> j) =>
      SkinDef(id: j['id'] as String, title: j['title'] as String, unlockStage: j['unlockStage'] as int? ?? 1);
  final String id;
  final String title;
  final int unlockStage;
}

/// Цвет палитры героя (SA F-023).
final class PaletteColor {
  const PaletteColor({required this.id, required this.title, required this.color});
  factory PaletteColor.fromJson(Map<String, dynamic> j) => PaletteColor(
    id: j['id'] as String,
    title: j['title'] as String,
    color: 0xFF000000 | int.parse((j['color'] as String).replaceFirst('#', ''), radix: 16),
  );
  final String id;
  final String title;

  /// ARGB.
  final int color;
}

final class Look {
  const Look({required this.id, required this.title, required this.color, required this.hair});
  factory Look.fromJson(Map<String, dynamic> j) {
    final hex = (j['color'] as String).replaceFirst('#', '');
    return Look(
      id: j['id'] as String,
      title: j['title'] as String,
      color: 0xFF000000 | int.parse(hex, radix: 16),
      hair: j['hair'] as String,
    );
  }
  final String id;
  final String title;

  /// ARGB.
  final int color;

  /// tuft|bangs|buns
  final String hair;
}

final class GlossaryEntry {
  const GlossaryEntry({required this.term, required this.meaning});
  factory GlossaryEntry.fromJson(Map<String, dynamic> j) =>
      GlossaryEntry(term: j['term'] as String, meaning: j['meaning'] as String);
  final String term;
  final String meaning;
}

final class SortCard {
  const SortCard({required this.emoji, required this.title, required this.kind, required this.why});
  factory SortCard.fromJson(Map<String, dynamic> j) => SortCard(
    emoji: j['emoji'] as String,
    title: j['title'] as String,
    kind: _kind(j['kind']),
    why: j['why'] as String,
  );
  final String emoji;
  final String title;
  final ItemKind kind;
  final String why;
}

final class PuzzleItem {
  const PuzzleItem({required this.emoji, required this.title, required this.price, required this.kind});
  factory PuzzleItem.fromJson(Map<String, dynamic> j) => PuzzleItem(
    emoji: j['emoji'] as String,
    title: j['title'] as String,
    price: j['price'] as int,
    kind: _kind(j['kind']),
  );
  final String emoji;
  final String title;
  final int price;
  final ItemKind kind;
}

final class BudgetPuzzle {
  const BudgetPuzzle({required this.id, required this.title, required this.budget, required this.items, this.story = ''});
  factory BudgetPuzzle.fromJson(Map<String, dynamic> j) => BudgetPuzzle(
    id: j['id'] as String,
    title: j['title'] as String,
    story: j['story'] as String? ?? '',
    budget: j['budget'] as int,
    items: [for (final i in j['items'] as List) PuzzleItem.fromJson(i as Map<String, dynamic>)],
  );
  final String id;
  final String title;

  /// Короткая ситуация: зачем покупаем (F-033).
  final String story;
  final int budget;
  final List<PuzzleItem> items;
}

/// Соблазн в «Копилке-ловце»: эмодзи и название для объяснения (F-033).
final class Temptation {
  const Temptation({required this.emoji, required this.title});
  factory Temptation.fromJson(Object j) =>
      j is String ? Temptation(emoji: j, title: 'Хотелка') : Temptation(emoji: (j as Map)['emoji'] as String, title: j['title'] as String);
  final String emoji;
  final String title;
}

/// Монеты разного достоинства; [weight] — как часто падают.
final class CatchGood {
  const CatchGood({required this.emoji, required this.value, this.weight = 1});
  factory CatchGood.fromJson(Map<String, dynamic> j) =>
      CatchGood(emoji: j['emoji'] as String, value: j['value'] as int, weight: j['weight'] as int? ?? 1);
  final String emoji;
  final int value;
  final int weight;
}

final class CatcherConfig {
  const CatcherConfig({
    required this.seconds,
    required this.target,
    required this.temptations,
    required this.temptationPenalty,
    this.goods = const [CatchGood(emoji: '🪙', value: 1, weight: 4), CatchGood(emoji: '💰', value: 5)],
  });
  factory CatcherConfig.fromJson(Map<String, dynamic> j) => CatcherConfig(
    seconds: j['seconds'] as int,
    target: j['target'] as int,
    temptations: [for (final t in j['temptations'] as List) Temptation.fromJson(t as Object)],
    temptationPenalty: j['temptationPenalty'] as int,
    goods: j['goods'] == null
        ? const [CatchGood(emoji: '🪙', value: 1, weight: 4), CatchGood(emoji: '💰', value: 5)]
        : [for (final g in j['goods'] as List) CatchGood.fromJson(g as Map<String, dynamic>)],
  );
  final int seconds;
  final int target;
  final List<Temptation> temptations;
  final int temptationPenalty;
  final List<CatchGood> goods;
}

final class GameConfig {
  const GameConfig({
    required this.startCoins,
    required this.pocketMoney,
    required this.rewardWise,
    required this.rewardTry,
    this.gameWin = 6,
    this.gameTry = 3,
    this.questReward = 3,
    this.weeklyReward = 10,
    required this.demoPeriods,
    required this.needSchedule,
    required this.firstDayNeeds,
  });
  factory GameConfig.fromJson(Map<String, dynamic> j) => GameConfig(
    startCoins: j['startCoins'] as int,
    pocketMoney: j['pocketMoney'] as int,
    rewardWise: j['rewardWise'] as int,
    rewardTry: j['rewardTry'] as int,
    gameWin: j['gameWin'] as int? ?? 6,
    gameTry: j['gameTry'] as int? ?? 3,
    questReward: j['questReward'] as int? ?? 3,
    weeklyReward: j['weeklyReward'] as int? ?? 10,
    demoPeriods: j['demoPeriods'] as int,
    needSchedule: [for (final r in j['needSchedule'] as List) NeedRule.fromJson(r as Map<String, dynamic>)],
    firstDayNeeds: [for (final id in j['firstDayNeeds'] as List? ?? const []) id as String],
  );
  final int startCoins;
  final int pocketMoney;
  final int rewardWise;
  final int rewardTry;

  /// Мини-игра по желанию — дешевле урока (F-036).
  final int gameWin;
  final int gameTry;

  /// За выполненное задание дня / недели по кнопке «Забрать» (F-036).
  final int questReward;
  final int weeklyReward;
  final int demoPeriods;
  /// Расписание нужного по приоритету (F-032).
  final List<NeedRule> needSchedule;

  /// Нужное первого дня — всегда одинаковое, для знакомства.
  final List<String> firstDayNeeds;
}

/// Правило расписания нужного: одно из [pick] каждый день, либо [item] каждый [every]-й день
/// (со сдвигом [offset]) или с вероятностью [chance].
final class NeedRule {
  const NeedRule({this.item, this.pick = const [], this.every = 1, this.offset = 0, this.chance = 1});
  factory NeedRule.fromJson(Map<String, dynamic> j) => NeedRule(
    item: j['item'] as String?,
    pick: [for (final id in j['pick'] as List? ?? const []) id as String],
    every: j['every'] as int? ?? 1,
    offset: j['offset'] as int? ?? 0,
    chance: (j['chance'] as num? ?? 1).toDouble(),
  );
  final String? item;
  final List<String> pick;
  final int every;
  final int offset;
  final double chance;

  /// Ежедневное и обязательное (еда, умывание) — не отбрасывается при переборе.
  bool get mandatory => every == 1 && chance >= 1;
  List<String> get ids => [?item, ...pick];
}
