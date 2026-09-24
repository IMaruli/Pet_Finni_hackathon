import 'dart:math';

import '../content/lesson_models.dart';

/// Проверки ходов в шагах урока (SA F-025). Чистые функции — UI только рисует.

bool pickOk(PickStep s, int option) => option == s.answer;

bool sortOk(SortStep s, int card, String bin) => s.cards[card].bin == bin;

/// Слева пример [left], справа слово пары [right] (индексы исходного списка).
bool pairOk(PairsStep s, int left, int right) => left == right;

/// «Наклейка — хотелка, не еда.» — смысл ошибки, без всей раскладки.
String pairMiss(PairsStep s, int left, int right) =>
    '${s.pairs[left].left} — ${s.pairs[left].right.toLowerCase()}, не ${s.pairs[right].right.toLowerCase()}.';

bool orderOk(OrderStep s, List<String> placed) {
  if (placed.length != s.tiles.length) return false;
  for (var i = 0; i < placed.length; i++) {
    if (placed[i] != s.tiles[i]) return false;
  }
  return true;
}

/// Стабильная перестановка 0..n-1, не совпадающая с исходным порядком (при n > 1).
List<int> shuffled(int n, int seed) {
  final list = List<int>.generate(n, (i) => i)..shuffle(Random(seed));
  if (n > 1 && Iterable<int>.generate(n).every((i) => list[i] == i)) {
    final first = list.removeAt(0);
    list.add(first);
  }
  return list;
}
