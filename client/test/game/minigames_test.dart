import 'dart:math';
import 'dart:ui';

import 'package:finni/content/models.dart';
import 'package:finni/economy/catalog_item.dart';
import 'package:finni/game/minigames.dart';
import 'package:flutter_test/flutter_test.dart';

const deck = [
  SortCard(emoji: 'a', title: 'A', kind: ItemKind.need, why: 'a'),
  SortCard(emoji: 'b', title: 'B', kind: ItemKind.want, why: 'b'),
  SortCard(emoji: 'c', title: 'C', kind: ItemKind.need, why: 'c'),
  SortCard(emoji: 'd', title: 'D', kind: ItemKind.want, why: 'd'),
];

void main() {
  group('SortRound', () {
    test('all correct wins and has no mistakes', () {
      final r = SortRound(deck, size: 4, random: Random(1));
      while (!r.finished) {
        expect(r.answer(r.current.kind), isTrue);
      }
      expect(r.score, 4);
      expect(r.mistakes, isEmpty);
      expect(r.win, isTrue);
    });

    test('wrong answers are collected as mistakes', () {
      final r = SortRound(deck, size: 4, random: Random(2));
      final wrong = r.current;
      expect(r.answer(wrong.kind == ItemKind.need ? ItemKind.want : ItemKind.need), isFalse);
      while (!r.finished) {
        r.answer(r.current.kind);
      }
      expect(r.score, 3);
      expect(r.mistakes, [wrong]);
    });

    test('win threshold is 80 percent', () {
      final r = SortRound(deck, size: 4, random: Random(3));
      r.answer(r.current.kind == ItemKind.need ? ItemKind.want : ItemKind.need);
      while (!r.finished) {
        r.answer(r.current.kind);
      }
      expect(r.win, isFalse);
    });

    test('round size is capped by deck', () {
      expect(SortRound(deck, size: 10).total, 4);
    });

    test('answering after finish does nothing', () {
      final r = SortRound(deck, size: 1);
      r.answer(r.current.kind);
      expect(r.answer(ItemKind.need), isFalse);
      expect(r.score, 1);
    });
  });

  group('checkBasket', () {
    const puzzle = BudgetPuzzle(id: 'p', title: 'P', budget: 20, items: [
      PuzzleItem(emoji: '1', title: 'N1', price: 8, kind: ItemKind.need),
      PuzzleItem(emoji: '2', title: 'N2', price: 6, kind: ItemKind.need),
      PuzzleItem(emoji: '3', title: 'W1', price: 5, kind: ItemKind.want),
      PuzzleItem(emoji: '4', title: 'W2', price: 7, kind: ItemKind.want),
    ]);

    test('all needs within budget is ok', () {
      final c = checkBasket(puzzle, {0, 1, 2});
      expect(c.ok, isTrue);
      expect(c.total, 19);
      expect(c.left, 1);
    });

    test('missing need is reported', () {
      final c = checkBasket(puzzle, {0, 2});
      expect(c.ok, isFalse);
      expect(c.missingNeeds.single.title, 'N2');
    });

    test('over budget is reported', () {
      final c = checkBasket(puzzle, {0, 1, 3});
      expect(c.ok, isFalse);
      expect(c.over, 1);
    });
  });

  group('CatcherModel', () {
    const config = CatcherConfig(seconds: 5, target: 10, temptations: ['🍭'], temptationPenalty: 3);
    const field = Size(300, 600);

    test('time runs out and finishes', () {
      final m = CatcherModel(config, random: Random(1));
      for (var i = 0; i < 60; i++) {
        m.tick(0.1, field);
      }
      expect(m.finished, isTrue);
      expect(m.timeLeft, 0);
    });

    test('coin falling into jar adds value; temptation takes coins, never below zero', () {
      final m = CatcherModel(config, random: Random(1));
      m.jarX = 150;
      m.items.add(Falling(x: 150, y: field.height - 60, speed: 100, value: 5, emoji: '🪙'));
      m.tick(0.1, field);
      expect(m.score, 5);
      m.items.add(Falling(x: 150, y: field.height - 60, speed: 100, value: -3, emoji: '🍭'));
      m.tick(0.1, field);
      expect(m.score, 2);
      m.items.add(Falling(x: 150, y: field.height - 60, speed: 100, value: -3, emoji: '🍭'));
      m.tick(0.1, field);
      expect(m.score, 0);
      final events = m.takeEvents();
      expect(events.where((e) => e.value < 0).length, 2);
      expect(m.takeEvents(), isEmpty);
    });

    test('items that miss fall away', () {
      final m = CatcherModel(config, random: Random(1));
      m.jarX = 20;
      m.items.add(Falling(x: 280, y: field.height - 5, speed: 300, value: 5, emoji: '🪙'));
      m.tick(0.1, field);
      expect(m.score, 0);
      expect(m.items.where((i) => i.x == 280), isEmpty);
    });

    test('win when target reached', () {
      final m = CatcherModel(config, random: Random(1))..score = 10;
      expect(m.win, isTrue);
    });

    test('spawns items over time', () {
      final m = CatcherModel(config, random: Random(4));
      for (var i = 0; i < 20; i++) {
        m.tick(0.1, field);
      }
      expect(m.spawned, greaterThan(0));
    });
  });
}
