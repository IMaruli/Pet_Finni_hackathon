/// Уроки в стиле Duolingo: темы, уроки, шаги-игры (SA F-025).
library;

enum StepKind { card, pick, sort, pairs, order, next }

final class Topic {
  const Topic({required this.id, required this.title, required this.emoji});
  factory Topic.fromJson(Map<String, dynamic> j) => Topic(id: j['id'] as String, title: j['title'] as String, emoji: j['emoji'] as String);
  final String id;
  final String title;
  final String emoji;
}

sealed class LessonStep {
  const LessonStep();
  StepKind get kind;

  factory LessonStep.fromJson(Map<String, dynamic> j) {
    List<String> strings(String key) => [for (final s in (j[key] as List? ?? const [])) s as String];
    String text(String key) => j[key] as String? ?? '';
    return switch (j['type']) {
      'card' => CardStep(title: text('title'), lines: strings('lines'), emoji: j['emoji'] as String?),
      'pick' => PickStep(
        question: text('question'),
        options: strings('options'),
        answer: j['answer'] as int,
        why: text('why'),
        hint: text('hint'),
      ),
      'sort' => SortStep(
        prompt: text('prompt'),
        bins: [for (final b in j['bins'] as List) (id: (b as Map)['id'] as String, title: b['title'] as String)],
        cards: [for (final c in j['cards'] as List) (text: (c as Map)['text'] as String, bin: c['bin'] as String)],
        why: text('why'),
        hint: text('hint'),
        demo: j['demo'] as bool? ?? false,
      ),
      'pairs' => PairsStep(
        prompt: text('prompt'),
        pairs: [for (final p in j['pairs'] as List) (left: (p as List)[0] as String, right: p[1] as String)],
        why: text('why'),
      ),
      'order' => OrderStep(prompt: text('prompt'), tiles: strings('tiles'), extra: strings('extra'), why: text('why'), hint: text('hint')),
      'next' => NextStep(
        situation: text('situation'),
        emoji: j['emoji'] as String? ?? '💭',
        outcomes: [
          for (final o in j['outcomes'] as List)
            (text: (o as Map)['text'] as String, good: o['good'] as bool, result: o['result'] as String),
        ],
        why: text('why'),
      ),
      final t => throw FormatException('unknown lesson step type $t'),
    };
  }
}

/// Карточка: 1–3 фразы, без проверки.
final class CardStep extends LessonStep {
  const CardStep({required this.title, required this.lines, this.emoji});
  final String title;
  final List<String> lines;
  final String? emoji;
  @override
  StepKind get kind => StepKind.card;
}

/// Нажми верное: одна плитка из 2–4.
final class PickStep extends LessonStep {
  const PickStep({required this.question, required this.options, required this.answer, required this.why, required this.hint});
  final String question;
  final List<String> options;
  final int answer;
  final String why;
  final String hint;
  @override
  StepKind get kind => StepKind.pick;
}

/// Разложи: карточки по 2–3 корзинам.
final class SortStep extends LessonStep {
  const SortStep({required this.prompt, required this.bins, required this.cards, required this.why, required this.hint, this.demo = false});
  final String prompt;
  final List<({String id, String title})> bins;
  final List<({String text, String bin})> cards;
  final String why;
  final String hint;

  /// Первая встреча темы: сначала показать решённым, потом «Теперь я».
  final bool demo;
  @override
  StepKind get kind => StepKind.sort;
}

/// Пары: слева пример, справа слово.
final class PairsStep extends LessonStep {
  const PairsStep({required this.prompt, required this.pairs, required this.why});
  final String prompt;
  final List<({String left, String right})> pairs;
  final String why;
  @override
  StepKind get kind => StepKind.pairs;
}

/// Собери фразу: [tiles] в верном порядке + отвлекающие [extra].
final class OrderStep extends LessonStep {
  const OrderStep({required this.prompt, required this.tiles, required this.extra, required this.why, required this.hint});
  final String prompt;
  final List<String> tiles;
  final List<String> extra;
  final String why;
  final String hint;
  @override
  StepKind get kind => StepKind.order;
}

/// Что дальше: ситуация и 2–3 исхода с последствием.
final class NextStep extends LessonStep {
  const NextStep({required this.situation, required this.emoji, required this.outcomes, required this.why});
  final String situation;
  final String emoji;
  final List<({String text, bool good, String result})> outcomes;
  final String why;
  @override
  StepKind get kind => StepKind.next;
}

final class Lesson {
  const Lesson({required this.id, required this.topic, required this.title, required this.emoji, required this.steps});
  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
    id: j['id'] as String,
    topic: j['topic'] as String,
    title: j['title'] as String,
    emoji: j['emoji'] as String,
    steps: [for (final s in j['steps'] as List) LessonStep.fromJson(s as Map<String, dynamic>)],
  );
  final String id;
  final String topic;
  final String title;
  final String emoji;
  final List<LessonStep> steps;

  Set<StepKind> get kinds => {for (final s in steps) s.kind};

  /// Короткий урок — без шага 4 (Нажми верное / Собери фразу).
  bool get isShort => !kinds.contains(StepKind.pick) && !kinds.contains(StepKind.order);

  /// Проблемы рецепта (SA F-025 BR-01) для `GameContent.validate()`.
  List<String> problems() {
    final p = <String>[];
    if (steps.length < 4) p.add('lessons: $id needs at least 4 steps');
    if (steps.isNotEmpty && steps.first is! CardStep) p.add('lessons: $id must start with a card');
    if (steps.isNotEmpty && steps.last is! CardStep) p.add('lessons: $id must end with a card');
    for (final s in steps) {
      switch (s) {
        case CardStep(:final lines):
          if (lines.isEmpty || lines.length > 3) p.add('lessons: $id card needs 1–3 lines');
        case PickStep(:final options, :final answer, :final why):
          if (options.length < 2 || options.length > 4) p.add('lessons: $id pick needs 2–4 options');
          if (answer < 0 || answer >= options.length) p.add('lessons: $id pick answer out of range');
          if (why.isEmpty) p.add('lessons: $id pick without why');
        case SortStep(:final bins, :final cards):
          if (bins.length < 2 || bins.length > 3) p.add('lessons: $id sort needs 2–3 bins');
          final ids = {for (final b in bins) b.id};
          if (cards.any((c) => !ids.contains(c.bin))) p.add('lessons: $id sort card with unknown bin');
        case PairsStep(:final pairs):
          if (pairs.length < 3 || pairs.length > 4) p.add('lessons: $id pairs needs 3–4 pairs');
        case OrderStep(:final tiles):
          if (tiles.length < 3 || tiles.length > 4) p.add('lessons: $id order needs 3–4 tiles');
        case NextStep(:final outcomes):
          if (outcomes.length < 2 || outcomes.length > 3) p.add('lessons: $id next needs 2–3 outcomes');
          if (!outcomes.any((o) => o.good)) p.add('lessons: $id next needs a good outcome');
      }
    }
    return p;
  }
}
