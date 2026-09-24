import 'package:finni/content/lesson_models.dart';
import 'package:finni/ui/lesson/lesson_steps.dart';
import 'package:finni/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// F-046: карточки урока «Разложи» перетаскиваются в корзины и обратно.
void main() {
  const step = SortStep(
    prompt: 'Разложи',
    bins: [(id: 'need', title: 'Нужно'), (id: 'want', title: 'Хочу')],
    cards: [(text: 'Хлеб', bin: 'need'), (text: 'Игрушка', bin: 'want')],
    why: 'Верно!',
    hint: 'Подумай ещё',
  );

  Future<void> pump(WidgetTester t, {required VoidCallback onPassed}) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: finniTheme(),
        home: Scaffold(body: SortView(step: step, text: (s) => s, onPassed: onPassed)),
      ),
    );
  }

  Future<void> drag(WidgetTester t, String from, String to) async {
    final g = await t.startGesture(t.getCenter(find.byKey(Key(from))));
    await t.pump(const Duration(milliseconds: 50));
    await g.moveBy(const Offset(0, 20));
    await t.pump();
    await g.moveTo(t.getCenter(find.byKey(Key(to))));
    await t.pump();
    await g.up();
    await t.pumpAndSettle();
  }

  testWidgets('drag cards into bins, back to the row, then check (F-046)', (t) async {
    var passed = false;
    await pump(t, onPassed: () => passed = true);

    await drag(t, 'sort.card.0', 'sort.bin.need');
    expect(find.byKey(const Key('sort.placed.0')), findsOneWidget);
    expect(find.byKey(const Key('sort.card.0')), findsNothing);

    // Обратно в ряд.
    await drag(t, 'sort.placed.0', 'sort.row');
    expect(find.byKey(const Key('sort.card.0')), findsOneWidget);

    await drag(t, 'sort.card.0', 'sort.bin.need');
    await drag(t, 'sort.card.1', 'sort.bin.want');
    await t.tap(find.text('Готово'));
    await t.pumpAndSettle();
    expect(find.text('Верно!'), findsOneWidget);
    expect(passed, isFalse);
  });

  testWidgets('tap path still works (F-046 BR-05)', (t) async {
    await pump(t, onPassed: () {});
    await t.tap(find.byKey(const Key('sort.card.1')));
    await t.pump();
    await t.tap(find.byKey(const Key('sort.bin.want')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('sort.placed.1')), findsOneWidget);
  });
}
