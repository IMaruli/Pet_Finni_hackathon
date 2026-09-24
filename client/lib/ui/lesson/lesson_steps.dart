import 'dart:async';

import 'package:flutter/material.dart';

import '../../content/lesson_models.dart';
import '../../game/lesson_logic.dart';
import '../mascot/mascot_look.dart';
import '../mascot/mascot_view.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'lesson_frame.dart';

/// Шаг урока по типу (SA F-025). [onPassed] — шаг пройден, дальше.
Widget stepView(LessonStep step, {required Key key, required String pet, required MascotLook look, required VoidCallback onPassed}) {
  String t(String s) => s.replaceAll('{pet}', pet);
  return switch (step) {
    CardStep() => CardView(key: key, step: step, look: look, text: t, onPassed: onPassed),
    PickStep() => PickView(key: key, step: step, text: t, onPassed: onPassed),
    SortStep() => SortView(key: key, step: step, text: t, onPassed: onPassed),
    PairsStep() => PairsView(key: key, step: step, text: t, onPassed: onPassed),
    OrderStep() => OrderView(key: key, step: step, text: t, onPassed: onPassed),
    NextStep() => NextView(key: key, step: step, look: look, text: t, onPassed: onPassed),
  };
}

/// Подстановка {pet} в тексты шага.
typedef StepText = String Function(String);

// ---------- Карточка ----------

class CardView extends StatefulWidget {
  const CardView({super.key, required this.step, required this.look, required this.text, required this.onPassed});
  final CardStep step;
  final MascotLook look;
  final StepText text;
  final VoidCallback onPassed;

  @override
  State<CardView> createState() => _CardViewState();
}

class _CardViewState extends State<CardView> {
  bool _ready = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Кнопка ждёт короткую паузу, чтобы фразу успели увидеть (BR-04).
    _timer = Timer(const Duration(milliseconds: 800), () => mounted ? setState(() => _ready = true) : null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.step;
    return StepScaffold(
      prompt: '',
      buttonLabel: 'Дальше',
      onButton: _ready ? widget.onPassed : null,
      body: ListView(
        children: [
          Row(
            children: [
              SizedBox(width: 64, height: 64, child: MascotView(look: widget.look, size: 64, interactive: false)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.text(s.title), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (final (i, line) in s.lines.indexed)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + i * 180),
              curve: Curves.easeOut,
              builder: (_, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: FinniColors.surface, borderRadius: BorderRadius.circular(18)),
                child: Text(widget.text(line), style: const TextStyle(fontSize: 17, height: 1.3, fontWeight: FontWeight.w500)),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------- Нажми верное ----------

class PickView extends StatefulWidget {
  const PickView({super.key, required this.step, required this.text, required this.onPassed});
  final PickStep step;
  final StepText text;
  final VoidCallback onPassed;

  @override
  State<PickView> createState() => _PickViewState();
}

class _PickViewState extends State<PickView> {
  int? _selected;
  StepFeedback? _feedback;

  void _check() {
    final ok = pickOk(widget.step, _selected!);
    buzz(ok ? Buzz.medium : Buzz.heavy);
    setState(() => _feedback = ok ? StepFeedback.good(widget.text(widget.step.why)) : StepFeedback.retry(widget.text(widget.step.hint)));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.step;
    return StepScaffold(
      prompt: widget.text(s.question),
      onButton: _selected == null ? null : _check,
      feedback: _feedback,
      onFeedback: () {
        if (_feedback!.good) return widget.onPassed();
        setState(() {
          _feedback = null;
          _selected = null; // плитка отпускается, шаг не сгорает
        });
      },
      body: ListView(
        children: [
          for (final (i, o) in s.options.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LessonTile(
                key: Key('pick.$i'),
                text: widget.text(o),
                selected: _selected == i,
                onTap: _feedback != null ? null : () => setState(() => _selected = i),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------- Разложи ----------

class SortView extends StatefulWidget {
  const SortView({super.key, required this.step, required this.text, required this.onPassed});
  final SortStep step;
  final StepText text;
  final VoidCallback onPassed;

  @override
  State<SortView> createState() => _SortViewState();
}

class _SortViewState extends State<SortView> {
  /// Карточка → корзина; нет ключа — карточка в ряду.
  final _placed = <int, String>{};
  late bool _demo = widget.step.demo;
  int? _selected;
  StepFeedback? _feedback;

  SortStep get s => widget.step;

  @override
  void initState() {
    super.initState();
    if (_demo) {
      for (final (i, c) in s.cards.indexed) {
        _placed[i] = c.bin;
      }
    }
  }

  void _tapCard(int i) {
    if (_demo || _feedback != null) return;
    setState(() {
      if (_placed.containsKey(i)) {
        _placed.remove(i); // повторное нажатие возвращает карточку в ряд
        _selected = null;
      } else {
        _selected = _selected == i ? null : i;
      }
    });
    buzz(Buzz.select);
  }

  void _tapBin(String bin) {
    final i = _selected;
    if (_demo || i == null || _feedback != null) return;
    setState(() {
      _placed[i] = bin;
      _selected = null;
    });
    buzz(Buzz.select);
  }

  void _check() {
    final wrong = [
      for (final e in _placed.entries)
        if (!sortOk(s, e.key, e.value)) e.key,
    ];
    buzz(wrong.isEmpty ? Buzz.medium : Buzz.heavy);
    setState(() {
      for (final i in wrong) {
        _placed.remove(i); // неверные выпадают обратно
      }
      _feedback = wrong.isEmpty ? StepFeedback.good(widget.text(s.why)) : StepFeedback.retry(widget.text(s.hint));
    });
  }

  @override
  Widget build(BuildContext context) {
    final row = [
      for (var i = 0; i < s.cards.length; i++)
        if (!_placed.containsKey(i)) i,
    ];
    return StepScaffold(
      prompt: _demo ? 'Смотри, как раскладывают' : widget.text(s.prompt),
      buttonLabel: _demo ? 'Теперь я' : 'Готово',
      onButton: _demo
          ? () => setState(() {
              _demo = false;
              _placed.clear();
            })
          : row.isEmpty
          ? _check
          : null,
      feedback: _feedback,
      onFeedback: () => _feedback!.good ? widget.onPassed() : setState(() => _feedback = null),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final i in row)
                  LessonTile(
                    key: Key('sort.card.$i'),
                    text: widget.text(s.cards[i].text),
                    selected: _selected == i,
                    onTap: () => _tapCard(i),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final b in s.bins)
                  Expanded(
                    child: GestureDetector(
                      key: Key('sort.bin.${b.id}'),
                      onTap: () => _tapBin(b.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _selected != null ? FinniColors.primary.withValues(alpha: 0.06) : FinniColors.fill,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _selected != null ? FinniColors.primary : FinniColors.line, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
                              child: Text(
                                b.title,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: FinniColors.muted),
                              ),
                            ),
                            for (final e in _placed.entries.where((e) => e.value == b.id))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: LessonTile(
                                  key: Key('sort.placed.${e.key}'),
                                  text: widget.text(s.cards[e.key].text),
                                  center: true,
                                  onTap: () => _selected != null ? _tapBin(e.value) : _tapCard(e.key), // с выбранной карточкой тап по корзине кладёт её
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!_demo)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Нажми карточку, потом корзину. Повторное нажатие возвращает карточку в ряд.',
                style: TextStyle(fontSize: 13, color: FinniColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------- Пары ----------

class PairsView extends StatefulWidget {
  const PairsView({super.key, required this.step, required this.text, required this.onPassed});
  final PairsStep step;
  final StepText text;
  final VoidCallback onPassed;

  @override
  State<PairsView> createState() => _PairsViewState();
}

class _PairsViewState extends State<PairsView> {
  late final _left = shuffled(widget.step.pairs.length, widget.step.prompt.length);
  late final _right = shuffled(widget.step.pairs.length, widget.step.prompt.length * 31 + 7);
  final _matched = <int>{};
  int? _l;
  int? _r;
  StepFeedback? _feedback;

  PairsStep get s => widget.step;

  void _tap({int? left, int? right}) {
    if (_feedback != null) return;
    setState(() {
      if (left != null) _l = _l == left ? null : left;
      if (right != null) _r = _r == right ? null : right;
    });
    buzz(Buzz.select);
    final l = _l, r = _r;
    if (l == null || r == null) return;
    if (pairOk(s, l, r)) {
      buzz(Buzz.medium);
      setState(() {
        _matched.add(l); // верная пара остаётся связанной
        _l = _r = null;
        if (_matched.length == s.pairs.length) _feedback = StepFeedback.good(widget.text(s.why));
      });
    } else {
      buzz(Buzz.heavy);
      setState(() => _feedback = StepFeedback.retry(widget.text(pairMiss(s, l, r)), title: 'Эта пара не сошлась'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      prompt: widget.text(s.prompt),
      showButton: false,
      feedback: _feedback,
      onFeedback: () => _feedback!.good
          ? widget.onPassed()
          : setState(() {
              _feedback = null;
              _l = _r = null;
            }),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                for (final i in _left)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: LessonTile(
                        key: Key('pairs.left.$i'),
                        text: widget.text(s.pairs[i].left),
                        selected: _l == i,
                        locked: _matched.contains(i),
                        onTap: _matched.contains(i) ? null : () => _tap(left: i),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                for (final i in _right)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: LessonTile(
                        key: Key('pairs.right.$i'),
                        text: widget.text(s.pairs[i].right),
                        selected: _r == i,
                        locked: _matched.contains(i),
                        onTap: _matched.contains(i) ? null : () => _tap(right: i),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Собери фразу ----------

class OrderView extends StatefulWidget {
  const OrderView({super.key, required this.step, required this.text, required this.onPassed});
  final OrderStep step;
  final StepText text;
  final VoidCallback onPassed;

  @override
  State<OrderView> createState() => _OrderViewState();
}

class _OrderViewState extends State<OrderView> {
  late final List<String> _bank = [
    for (final i in shuffled(widget.step.tiles.length + widget.step.extra.length, widget.step.prompt.length + 3))
      [...widget.step.tiles, ...widget.step.extra][i],
  ];

  /// Индексы плиток банка в слотах.
  final _slots = <int>[];
  StepFeedback? _feedback;

  OrderStep get s => widget.step;

  void _check() {
    final ok = orderOk(s, [for (final i in _slots) _bank[i]]);
    buzz(ok ? Buzz.medium : Buzz.heavy);
    setState(() => _feedback = ok ? StepFeedback.good(widget.text(s.why)) : StepFeedback.retry(widget.text(s.hint)));
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      prompt: widget.text(s.prompt),
      onButton: _slots.length == s.tiles.length ? _check : null,
      feedback: _feedback,
      onFeedback: () => _feedback!.good
          ? widget.onPassed()
          : setState(() {
              _feedback = null;
              _slots.clear();
            }),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var k = 0; k < s.tiles.length; k++)
                k < _slots.length
                    ? LessonTile(
                        key: Key('order.slot.$k'),
                        text: _bank[_slots[k]],
                        onTap: _feedback != null ? null : () => setState(() => _slots.removeAt(k)),
                      )
                    : Container(
                        width: 86,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: FinniColors.line, width: 2),
                          color: FinniColors.fill,
                        ),
                      ),
            ],
          ),
          const Spacer(),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final (i, word) in _bank.indexed)
                LessonTile(
                  key: Key('order.tile.$i'),
                  text: word,
                  dim: _slots.contains(i),
                  onTap: _slots.contains(i) || _feedback != null || _slots.length == s.tiles.length
                      ? null
                      : () {
                          buzz(Buzz.select);
                          setState(() => _slots.add(i));
                        },
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------- Что дальше ----------

class NextView extends StatefulWidget {
  const NextView({super.key, required this.step, required this.look, required this.text, required this.onPassed});
  final NextStep step;
  final MascotLook look;
  final StepText text;
  final VoidCallback onPassed;

  @override
  State<NextView> createState() => _NextViewState();
}

class _NextViewState extends State<NextView> {
  int? _selected;
  int? _chosen;

  NextStep get s => widget.step;

  @override
  Widget build(BuildContext context) {
    final chosen = _chosen == null ? null : s.outcomes[_chosen!];
    return StepScaffold(
      // После выбора экран меняется на последствие (BR-10).
      prompt: widget.text(chosen?.result ?? s.situation),
      onButton: _selected == null
          ? null
          : () {
              buzz(s.outcomes[_selected!].good ? Buzz.medium : Buzz.heavy);
              setState(() => _chosen = _selected);
            },
      feedback: chosen == null
          ? null
          : chosen.good
          ? StepFeedback.good(widget.text(s.why), title: 'Хороший ход')
          : StepFeedback.retry(widget.text(s.why), title: 'Выбрать снова', action: 'Выбрать снова'),
      onFeedback: () => chosen!.good
          ? widget.onPassed()
          : setState(() {
              _chosen = null;
              _selected = null;
            }),
      body: ListView(
        children: [
          Container(
            height: 150,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: FinniColors.surface, borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MascotView(look: widget.look, size: 120, interactive: false),
                AnimatedScale(
                  duration: const Duration(milliseconds: 250),
                  scale: chosen == null ? 1 : 1.15,
                  child: Text(s.emoji, style: const TextStyle(fontSize: 54)),
                ),
              ],
            ),
          ),
          if (chosen == null)
            for (final (i, o) in s.outcomes.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LessonTile(
                  key: Key('next.outcome.$i'),
                  text: widget.text(o.text),
                  selected: _selected == i,
                  onTap: () => setState(() => _selected = i),
                ),
              ),
        ],
      ),
    );
  }
}
