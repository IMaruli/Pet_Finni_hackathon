import '../economy/catalog_item.dart';
import 'models.dart';

final class ContentException implements Exception {
  const ContentException(this.problems);
  final List<String> problems;
  @override
  String toString() => 'ContentException:\n${problems.join('\n')}';
}

/// Весь контент игры. Собирается из JSON-файлов, ключ = имя файла без `.json`.
final class GameContent {
  GameContent._({
    required this.config,
    required this.items,
    required this.goals,
    required this.quests,
    required this.looks,
    required this.skins,
    required this.palette,
    required this.texts,
    required this.glossary,
    required this.sortCards,
    required this.puzzles,
    required this.catcher,
  });

  factory GameContent.fromJson(Map<String, dynamic> files) {
    List<T> list<T>(String file, String key, T Function(Map<String, dynamic>) parse) => [
      for (final e in (files[file] as Map<String, dynamic>)[key] as List)
        parse(e as Map<String, dynamic>),
    ];
    final copy = files['copy'] as Map<String, dynamic>;
    final games = files['minigames'] as Map<String, dynamic>;
    return GameContent._(
      config: GameConfig.fromJson(files['config'] as Map<String, dynamic>),
      items: list('items', 'items', ShopItem.fromJson),
      goals: list('goals', 'goals', GoalDef.fromJson),
      quests: list('quests', 'quests', Quest.fromJson),
      looks: list('looks', 'looks', Look.fromJson),
      skins: list('looks', 'skins', SkinDef.fromJson),
      palette: list('looks', 'palette', PaletteColor.fromJson),
      texts: (copy['texts'] as Map<String, dynamic>).cast<String, String>(),
      glossary: [
        for (final g in copy['glossary'] as List) GlossaryEntry.fromJson(g as Map<String, dynamic>),
      ],
      sortCards: list('minigames', 'sortCards', SortCard.fromJson),
      puzzles: list('minigames', 'puzzles', BudgetPuzzle.fromJson),
      catcher: CatcherConfig.fromJson(games['catcher'] as Map<String, dynamic>),
    );
  }

  final GameConfig config;
  final List<ShopItem> items;
  final List<GoalDef> goals;
  final List<Quest> quests;
  final List<Look> looks;
  final List<SkinDef> skins;
  final List<PaletteColor> palette;
  final Map<String, String> texts;
  final List<GlossaryEntry> glossary;
  final List<SortCard> sortCards;
  final List<BudgetPuzzle> puzzles;
  final CatcherConfig catcher;

  List<ShopItem> get needItems => items.where((i) => i.kind == ItemKind.need).toList();
  List<ShopItem> get wantItems => items.where((i) => i.kind == ItemKind.want).toList();

  /// Хотелки-вкусности: расходуемые «хочу» (SA F-022 BR-04).
  List<ShopItem> get treatItems => [for (final i in wantItems) if (i.slot == ItemSlot.consumable) i];

  ShopItem item(String id) => items.firstWhere((i) => i.id == id);
  GoalDef goal(String id) => goals.firstWhere((g) => g.id == id);
  Look look(String id) => looks.firstWhere((l) => l.id == id, orElse: () => looks.first);
  SkinDef? skin(String id) => skins.where((s) => s.id == id).firstOrNull;

  List<ShopItem> needsForDay(int day) =>
      [for (final id in config.needRotation[(day - 1) % config.needRotation.length]) item(id)];
  Quest questForDay(int day) => quests[(day - 1) % quests.length];
  BudgetPuzzle puzzleForDay(int day) => puzzles[(day - 1) % puzzles.length];

  String text(String id, [Map<String, String> vars = const {}]) {
    var s = texts[id] ?? id;
    vars.forEach((k, v) => s = s.replaceAll('{$k}', v));
    return s;
  }

  List<String> validate() {
    final problems = <String>[];

    void unique(String what, Iterable<String> ids) {
      final seen = <String>{};
      for (final id in ids) {
        if (!seen.add(id)) problems.add('$what: duplicate id $id');
      }
    }

    unique('items', items.map((i) => i.id));
    unique('goals', goals.map((g) => g.id));
    unique('quests', quests.map((q) => q.id));
    unique('looks', looks.map((l) => l.id));
    unique('skins', skins.map((s) => s.id));
    unique('palette', palette.map((p) => p.id));
    unique('puzzles', puzzles.map((p) => p.id));

    for (final i in items) {
      if (i.price <= 0) problems.add('items: ${i.id} price must be > 0');
      if (i.slot != ItemSlot.consumable && i.accessory == null) {
        problems.add('items: ${i.id} needs accessory for slot ${i.slot.name}');
      }
    }
    for (final g in goals) {
      if (g.cost <= 0) problems.add('goals: ${g.id} cost must be > 0');
      if (g.reward == GoalReward.furniture && g.options.isEmpty) {
        problems.add('goals: ${g.id} furniture needs options');
      }
    }
    for (final q in quests) {
      if (q.choices.length < 2) problems.add('quests: ${q.id} needs at least 2 choices');
      if (q.lines.isEmpty) problems.add('quests: ${q.id} needs lines');
      for (final c in q.choices) {
        if (c.explanation.trim().isEmpty) problems.add('quests: ${q.id} choice without explanation');
        if (c.reward <= 0) problems.add('quests: ${q.id} choice reward must be > 0');
      }
    }

    final ids = {for (final i in items) i.id: i};
    for (final day in config.needRotation) {
      var sum = 0;
      for (final id in day) {
        final item = ids[id];
        if (item == null || item.kind != ItemKind.need) {
          problems.add('config: needRotation has non-need item $id');
        } else {
          sum += item.price;
        }
      }
      if (sum > config.pocketMoney) problems.add('config: needRotation $day exceeds pocketMoney');
    }
    if (config.needRotation.isEmpty) problems.add('config: needRotation is empty');

    for (final p in puzzles) {
      final needs = p.items.where((i) => i.kind == ItemKind.need).fold(0, (s, i) => s + i.price);
      if (needs > p.budget) problems.add('puzzles: ${p.id} needs exceed budget');
    }

    if (items.length < 8) problems.add('volume: at least 8 shop items');
    if (needItems.isEmpty || wantItems.isEmpty) problems.add('volume: both need and want items');
    if (goals.length < 3) problems.add('volume: at least 3 goals');
    if (quests.length < 6) problems.add('volume: at least 6 quests');
    if (quests.map((q) => q.theme).toSet().length < 3) problems.add('volume: 3 quest themes');
    if (looks.length < 9) problems.add('volume: at least 9 looks');
    if (skins.where((s) => s.unlockStage == 1).length < 3) problems.add('volume: at least 3 open skins');
    if (palette.length < 8) problems.add('volume: at least 8 colors');
    if (config.demoPeriods < 5) problems.add('volume: at least 5 demo periods');
    if (sortCards.length < 6) problems.add('volume: at least 6 sort cards');
    if (puzzles.isEmpty) problems.add('volume: at least 1 budget puzzle');
    return problems;
  }
}
