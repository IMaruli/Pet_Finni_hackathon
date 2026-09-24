import 'dart:convert';
import 'dart:io';

import 'package:finni/content/content_loader.dart';
import 'package:finni/content/game_content.dart';
import 'package:finni/content/lesson_models.dart';
import 'package:finni/content/models.dart';
import 'package:finni/economy/catalog_item.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> readFiles() => {
  for (final name in ContentLoader.files)
    name: jsonDecode(File('assets/content/$name.json').readAsStringSync()),
};

void main() {
  late GameContent content;

  setUp(() => content = GameContent.fromJson(readFiles()));

  test('real content pack is valid', () {
    expect(content.validate(), isEmpty);
  });

  test('volumes of TZ 2.6 are met', () {
    expect(content.needItems.length + content.wantItems.length, greaterThanOrEqualTo(8));
    expect(content.needItems, isNotEmpty);
    expect(content.wantItems, isNotEmpty);
    expect(content.goals.length, greaterThanOrEqualTo(6));
    expect(content.wantItems.where((i) => i.slot == ItemSlot.room).length, greaterThanOrEqualTo(8));
    expect(content.lessons.length, greaterThanOrEqualTo(14));
    expect(content.topics.length, greaterThanOrEqualTo(7));
    expect(content.looks.length, greaterThanOrEqualTo(9));
    expect(content.glossary.length, greaterThanOrEqualTo(10));
    expect(content.config.demoPeriods, greaterThanOrEqualTo(5));
  });

  test('needs vary: food and daily care every day, extras by schedule (F-032)', () {
    expect(content.needsForDay(1).map((i) => i.id), ['breakfast', 'water', 'care']);
    final seen = <String>{};
    for (var day = 1; day <= 60; day++) {
      final ids = content.needsForDay(day).map((i) => i.id).toList();
      seen.addAll(ids);
      expect(content.needsForDay(day).where((i) => i.need == 'food').length, 1, reason: 'day $day');
      expect(ids, contains('care'), reason: 'day $day');
      expect(content.needsForDay(day).map((i) => i.id), ids, reason: 'stable $day');
    }
    expect(seen, containsAll(['breakfast', 'soup', 'fruits', 'water', 'care', 'bath', 'laundry', 'haircut']));
    expect({for (var d = 2; d <= 11; d++) content.needsForDay(d).map((i) => i.id).join(',')}.length, greaterThan(3));
  });

  test('daily needs are always affordable from pocket money alone', () {
    for (var day = 1; day <= 60; day++) {
      final sum = content.needsForDay(day).fold(0, (s, i) => s + i.price);
      expect(sum, lessThanOrEqualTo(content.config.pocketMoney), reason: 'day $day');
      expect(content.needsForDay(day).every((i) => i.kind == ItemKind.need), isTrue);
    }
  });

  test('puzzles rotate by day', () {
    expect(content.puzzleForDay(2).id, content.puzzles[1].id);
  });

  test('every puzzle is solvable: all needs fit the budget', () {
    for (final p in content.puzzles) {
      final needs = p.items.where((i) => i.kind == ItemKind.need).fold(0, (s, i) => s + i.price);
      expect(needs, lessThanOrEqualTo(p.budget), reason: p.id);
    }
  });

  test('items bridge to domain catalog items', () {
    final item = content.item('breakfast');
    expect(item.catalogItem.id, 'breakfast');
    expect(item.catalogItem.kind, ItemKind.need);
    expect(item.catalogItem.price.value, 8);
  });

  test('text substitutes placeholders and falls back to id', () {
    expect(content.text('stage.up', {'pet': 'Финни', 'n': 'большой'}), 'Финни вырос! Теперь он большой.');
    expect(content.text('no.such.key'), 'no.such.key');
  });

  test('a new lesson is added by data only (TZ: контент)', () {
    final files = readFiles();
    (files['lessons']['lessons'] as List).add({
      'id': 'new_1', 'topic': 'save', 'title': 'Новое', 'emoji': '⭐',
      'steps': [
        {'type': 'card', 'title': 'Мысль', 'lines': ['Одна фраза.']},
        {'type': 'pick', 'question': 'Верно?', 'options': ['Да', 'Нет'], 'answer': 0, 'why': 'Потому что', 'hint': 'Подумай'},
        {'type': 'next', 'situation': 'Ситуация', 'outcomes': [
          {'text': 'А', 'good': true, 'result': 'Хорошо'},
          {'text': 'Б', 'good': false, 'result': 'Не очень'},
        ], 'why': 'Потому что'},
        {'type': 'card', 'title': 'Запомни', 'lines': ['Итог.']},
      ],
    });
    final extended = GameContent.fromJson(files);
    expect(extended.validate(), isEmpty);
    expect(extended.lessons.length, content.lessons.length + 1);
  });

  test('lessons follow the recipe and use all six games (F-025)', () {
    for (final l in content.lessons) {
      expect(l.steps.first, isA<CardStep>(), reason: l.id);
      expect(l.steps.last, isA<CardStep>(), reason: l.id);
      expect(l.problems(), isEmpty, reason: l.id);
    }
    expect({for (final l in content.lessons) ...l.kinds}, StepKind.values.toSet());
    expect(content.lessons.where((l) => l.isShort), isNotEmpty);
    expect(content.lessons.where((l) => !l.isShort), isNotEmpty);
    final sort = content.lesson('needs_1').steps[1] as SortStep;
    expect(sort.demo, isTrue);
    expect(sort.bins.map((b) => b.id), ['need', 'want']);
  });

  test('validation catches duplicates, bad prices, weak quests, bad rotation', () {
    final files = readFiles();
    final items = files['items']['items'] as List;
    items.add(Map<String, dynamic>.from(items.first));
    items.add({...items[3] as Map<String, dynamic>, 'id': 'free', 'price': 0});
    final lesson = (files['lessons']['lessons'] as List).first as Map<String, dynamic>;
    ((lesson['steps'] as List)[2] as Map)['outcomes'] = [{'text': 'А', 'good': false, 'result': 'Хм'}];
    files['config']['needSchedule'] = [{'item': 'chocolate'}];
    final problems = GameContent.fromJson(files).validate();
    expect(problems.any((p) => p.contains('duplicate id breakfast')), isTrue);
    expect(problems.any((p) => p.contains('free')), isTrue);
    expect(problems.any((p) => p.contains('needs_1')), isTrue);
    expect(problems.any((p) => p.contains('needSchedule')), isTrue);
  });

  test('unknown enum value is a format error', () {
    final files = readFiles();
    ((files['items']['items'] as List).first as Map)['kind'] = 'luxury';
    expect(() => GameContent.fromJson(files), throwsFormatException);
  });

  test('skins and palette for Finik style (F-023)', () {
    final c = content;
    expect(c.skins.map((s) => s.id), ['finik', 'cat', 'bunny', 'monkey']);
    expect(c.skins.last.unlockStage, 3);
    expect(c.skins.first.unlockStage, 1);
    expect(c.palette.length, greaterThanOrEqualTo(8));
    expect(c.goals.map((g) => g.id), isNot(contains('skin_monkey')));
  });
}
