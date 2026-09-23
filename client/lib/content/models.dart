import '../economy/catalog_item.dart';
import '../economy/game_coins.dart';

enum ItemSlot { consumable, hero, room }

enum QuestTheme { budget, save, buy }

enum GoalReward { room, skin, furniture }

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
  });

  factory GoalDef.fromJson(Map<String, dynamic> j) => GoalDef(
    id: j['id'] as String,
    title: j['title'] as String,
    emoji: j['emoji'] as String,
    description: j['description'] as String,
    cost: j['cost'] as int,
    reward: _enum(GoalReward.values, j['reward'], 'reward'),
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

  GameCoins get coins => GameCoins(cost);
}

final class QuestLine {
  const QuestLine({required this.speaker, required this.text});
  factory QuestLine.fromJson(Map<String, dynamic> j) =>
      QuestLine(speaker: j['speaker'] as String, text: j['text'] as String);

  /// narrator|pet|friend|seller
  final String speaker;
  final String text;
}

final class QuestChoice {
  const QuestChoice({
    required this.text,
    required this.reward,
    required this.wise,
    required this.explanation,
  });
  factory QuestChoice.fromJson(Map<String, dynamic> j) => QuestChoice(
    text: j['text'] as String,
    reward: j['reward'] as int,
    wise: j['wise'] as bool,
    explanation: j['explanation'] as String,
  );
  final String text;
  final int reward;
  final bool wise;
  final String explanation;
}

final class Quest {
  const Quest({
    required this.id,
    required this.theme,
    required this.title,
    required this.emoji,
    required this.lines,
    required this.choices,
  });

  factory Quest.fromJson(Map<String, dynamic> j) => Quest(
    id: j['id'] as String,
    theme: _enum(QuestTheme.values, j['theme'], 'theme'),
    title: j['title'] as String,
    emoji: j['emoji'] as String,
    lines: [for (final l in j['lines'] as List) QuestLine.fromJson(l as Map<String, dynamic>)],
    choices: [for (final c in j['choices'] as List) QuestChoice.fromJson(c as Map<String, dynamic>)],
  );

  final String id;
  final QuestTheme theme;
  final String title;
  final String emoji;
  final List<QuestLine> lines;
  final List<QuestChoice> choices;
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
  const BudgetPuzzle({required this.id, required this.title, required this.budget, required this.items});
  factory BudgetPuzzle.fromJson(Map<String, dynamic> j) => BudgetPuzzle(
    id: j['id'] as String,
    title: j['title'] as String,
    budget: j['budget'] as int,
    items: [for (final i in j['items'] as List) PuzzleItem.fromJson(i as Map<String, dynamic>)],
  );
  final String id;
  final String title;
  final int budget;
  final List<PuzzleItem> items;
}

final class CatcherConfig {
  const CatcherConfig({
    required this.seconds,
    required this.target,
    required this.temptations,
    required this.temptationPenalty,
  });
  factory CatcherConfig.fromJson(Map<String, dynamic> j) => CatcherConfig(
    seconds: j['seconds'] as int,
    target: j['target'] as int,
    temptations: [for (final t in j['temptations'] as List) t as String],
    temptationPenalty: j['temptationPenalty'] as int,
  );
  final int seconds;
  final int target;
  final List<String> temptations;
  final int temptationPenalty;
}

final class GameConfig {
  const GameConfig({
    required this.startCoins,
    required this.pocketMoney,
    required this.rewardWise,
    required this.rewardTry,
    required this.demoPeriods,
    required this.needRotation,
  });
  factory GameConfig.fromJson(Map<String, dynamic> j) => GameConfig(
    startCoins: j['startCoins'] as int,
    pocketMoney: j['pocketMoney'] as int,
    rewardWise: j['rewardWise'] as int,
    rewardTry: j['rewardTry'] as int,
    demoPeriods: j['demoPeriods'] as int,
    needRotation: [
      for (final day in j['needRotation'] as List) [for (final id in day as List) id as String],
    ],
  );
  final int startCoins;
  final int pocketMoney;
  final int rewardWise;
  final int rewardTry;
  final int demoPeriods;
  final List<List<String>> needRotation;
}
