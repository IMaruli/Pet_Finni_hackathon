import 'dart:math';
import 'dart:ui';

import '../content/models.dart';
import '../economy/catalog_item.dart';

/// «Нужно или хочу?»: раунд из случайных карточек (SA F-013).
final class SortRound {
  SortRound(List<SortCard> deck, {int size = 10, Random? random})
    : _cards = ([...deck]..shuffle(random ?? Random())).take(size).toList();

  final List<SortCard> _cards;
  final List<SortCard> _mistakes = [];
  int _index = 0;
  int _score = 0;

  int get total => _cards.length;
  int get index => _index;
  bool get finished => _index >= _cards.length;
  SortCard get current => _cards[_index];
  int get score => _score;
  List<SortCard> get mistakes => List.unmodifiable(_mistakes);
  bool get win => _score * 5 >= total * 4;

  /// Возвращает, верен ли ответ.
  bool answer(ItemKind kind) {
    if (finished) return false;
    final card = _cards[_index++];
    if (card.kind == kind) {
      _score++;
      return true;
    }
    _mistakes.add(card);
    return false;
  }
}

/// «Уложись в бюджет»: проверка корзины.
final class BudgetCheck {
  const BudgetCheck({required this.total, required this.budget, required this.missingNeeds});
  final int total;
  final int budget;
  final List<PuzzleItem> missingNeeds;

  int get over => max(0, total - budget);
  int get left => max(0, budget - total);
  bool get ok => missingNeeds.isEmpty && over == 0;
}

/// Следующая ситуация для «Уложись в бюджет»: случайная, но не та же, что только что (F-033).
BudgetPuzzle nextPuzzle(List<BudgetPuzzle> all, {BudgetPuzzle? previous, Random? random}) {
  final pool = [for (final p in all) if (p.id != previous?.id) p];
  final from = pool.isEmpty ? all : pool;
  return from[(random ?? Random()).nextInt(from.length)];
}

BudgetCheck checkBasket(BudgetPuzzle puzzle, Set<int> picked) {
  var total = 0;
  final missing = <PuzzleItem>[];
  for (var i = 0; i < puzzle.items.length; i++) {
    final item = puzzle.items[i];
    if (picked.contains(i)) {
      total += item.price;
    } else if (item.kind == ItemKind.need) {
      missing.add(item);
    }
  }
  return BudgetCheck(total: total, budget: puzzle.budget, missingNeeds: missing);
}

/// Падающий предмет в «Копилке-ловце».
final class Falling {
  Falling({required this.x, required this.y, required this.speed, required this.value, required this.emoji, this.title = ''});
  double x;
  double y;
  final double speed;

  /// > 0 — монета, < 0 — соблазн.
  final int value;
  final String emoji;

  /// Название соблазна для объяснения («Леденец»).
  final String title;
  bool get isTemptation => value < 0;
}

final class CatchEvent {
  const CatchEvent(this.value, this.at, {this.title = '', this.emoji = ''});
  final int value;
  final Offset at;
  final String title;
  final String emoji;
}

/// «Копилка-ловец»: вся физика без UI.
final class CatcherModel {
  CatcherModel(this.config, {Random? random})
    : _random = random ?? Random(),
      timeLeft = config.seconds.toDouble();

  static const jarWidth = 96.0;
  static const jarHeight = 80.0;
  static const _catchHalf = jarWidth / 2 + 8;

  final CatcherConfig config;
  final Random _random;
  final List<Falling> items = [];
  final List<CatchEvent> _events = [];

  double jarX = 0;
  int score = 0;
  double timeLeft;
  int spawned = 0;
  double _untilSpawn = 0.3;

  /// Пойманные соблазны — для разбора в конце (F-033).
  final List<Falling> caught = [];

  bool get finished => timeLeft <= 0;
  bool get win => score >= config.target;

  List<CatchEvent> takeEvents() {
    final e = List<CatchEvent>.of(_events);
    _events.clear();
    return e;
  }

  void tick(double dt, Size field) {
    if (finished) return;
    timeLeft = max(0, timeLeft - dt);

    _untilSpawn -= dt;
    if (_untilSpawn <= 0 && !finished) {
      _spawn(field);
      _untilSpawn = 0.45 + _random.nextDouble() * 0.35;
    }

    final catchTop = field.height - jarHeight - 10;
    for (final item in items) {
      item.y += item.speed * dt;
    }
    items.removeWhere((item) {
      if (item.y >= catchTop && item.y <= field.height && (item.x - jarX).abs() <= _catchHalf) {
        score = max(0, score + item.value);
        _events.add(CatchEvent(item.value, Offset(item.x, item.y), title: item.title, emoji: item.emoji));
        if (item.isTemptation) caught.add(item);
        return true;
      }
      return item.y > field.height;
    });
  }

  void _spawn(Size field) {
    spawned++;
    final x = 30 + _random.nextDouble() * max(1, field.width - 60);
    final speed = 160 + _random.nextDouble() * 160;
    final roll = _random.nextDouble();
    if (roll < 0.25) {
      final t = config.temptations[_random.nextInt(config.temptations.length)];
      items.add(Falling(x: x, y: -30, speed: speed, value: -config.temptationPenalty, emoji: t.emoji, title: t.title));
    } else {
      final total = config.goods.fold(0, (s, g) => s + g.weight);
      var pick = _random.nextInt(total);
      final good = config.goods.firstWhere((g) => (pick -= g.weight) < 0);
      items.add(Falling(x: x, y: -30, speed: speed, value: good.value, emoji: good.emoji));
    }
  }
}
