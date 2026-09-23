import 'dart:convert';
import 'dart:io';

import 'package:finni/content/content_loader.dart';
import 'package:finni/content/game_content.dart';
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
    expect(content.goals.length, greaterThanOrEqualTo(3));
    expect(content.quests.length, greaterThanOrEqualTo(6));
    expect(content.quests.map((q) => q.theme).toSet(), QuestTheme.values.toSet());
    expect(content.looks.length, greaterThanOrEqualTo(9));
    expect(content.glossary.length, greaterThanOrEqualTo(10));
    expect(content.config.demoPeriods, greaterThanOrEqualTo(5));
  });

  test('daily needs are always affordable from pocket money alone', () {
    for (var day = 1; day <= 10; day++) {
      final sum = content.needsForDay(day).fold(0, (s, i) => s + i.price);
      expect(sum, lessThanOrEqualTo(content.config.pocketMoney), reason: 'day $day');
      expect(content.needsForDay(day).every((i) => i.kind == ItemKind.need), isTrue);
    }
  });

  test('quests and puzzles rotate by day', () {
    expect(content.questForDay(1).id, content.quests.first.id);
    expect(content.questForDay(content.quests.length + 1).id, content.quests.first.id);
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

  test('seventh quest is added by data only', () {
    final files = readFiles();
    (files['quests']['quests'] as List).add({
      'id': 'q_new', 'theme': 'save', 'title': 'Новое', 'emoji': '⭐',
      'lines': [{'speaker': 'pet', 'text': 'Привет'}],
      'choices': [
        {'text': 'А', 'reward': 12, 'wise': true, 'explanation': 'Потому что'},
        {'text': 'Б', 'reward': 6, 'wise': false, 'explanation': 'Потому что'},
      ],
    });
    final extended = GameContent.fromJson(files);
    expect(extended.validate(), isEmpty);
    expect(extended.quests.length, content.quests.length + 1);
  });

  test('validation catches duplicates, bad prices, weak quests, bad rotation', () {
    final files = readFiles();
    final items = files['items']['items'] as List;
    items.add(Map<String, dynamic>.from(items.first));
    items.add({...items[3] as Map<String, dynamic>, 'id': 'free', 'price': 0});
    final quest = (files['quests']['quests'] as List).first as Map<String, dynamic>;
    quest['choices'] = [(quest['choices'] as List).first];
    files['config']['needRotation'] = [['chocolate']];
    final problems = GameContent.fromJson(files).validate();
    expect(problems.any((p) => p.contains('duplicate id breakfast')), isTrue);
    expect(problems.any((p) => p.contains('free')), isTrue);
    expect(problems.any((p) => p.contains('q_budget_breakfast')), isTrue);
    expect(problems.any((p) => p.contains('needRotation')), isTrue);
  });

  test('unknown enum value is a format error', () {
    final files = readFiles();
    ((files['items']['items'] as List).first as Map)['kind'] = 'luxury';
    expect(() => GameContent.fromJson(files), throwsFormatException);
  });
}
