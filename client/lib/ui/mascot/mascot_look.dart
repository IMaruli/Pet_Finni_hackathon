import 'package:flutter/painting.dart';

import '../../content/models.dart';
import '../../economy/economy_state.dart';
import '../../game/game_controller.dart';
import '../../game/pet_wish.dart';

/// Всё, что определяет внешний вид героя в кадре.
final class MascotLook {
  const MascotLook({
    required this.color,
    required this.hair,
    required this.mood,
    required this.stage,
    this.skin,
    this.accessories = const {},
    this.emotion,
    this.grubby = false,
    this.joy,
  });

  factory MascotLook.fromLook(
    Look look, {
    PetMood mood = PetMood.glad,
    int stage = 1,
    Set<String> accessories = const {},
    String? skin,
  }) => MascotLook(
    color: Color(look.color),
    hair: look.hair,
    mood: mood,
    stage: stage,
    skin: skin,
    accessories: accessories,
  );

  factory MascotLook.fromGame(GameController game) {
    final content = game.content;
    final profile = game.profile;
    final look = content.look(profile.lookId);
    return MascotLook(
      color: Color(profile.color ?? look.color),
      hair: profile.hair ?? look.hair,
      mood: game.mood,
      stage: game.stage,
      skin: profile.skin,
      accessories: _wornAccessories(game),
      grubby: game.isGrubby && !game.greeting, // на знакомстве герой чистый (F-038)
      joy: game.todaysJoy,
    );
  }

  final Color color;

  /// tuft|bangs|buns
  final String hair;

  /// finik (или null) | cat | bunny | monkey (SA F-023).
  final String? skin;

  /// bandana|glasses|bow|headphones
  final Set<String> accessories;
  final PetMood mood;
  final int stage;

  /// Эмоция желания (F-020). `null` — лицо по настроению дня.
  final PetEmotion? emotion;

  /// Уход сегодня нужен и не куплен: пятна и «запах» (F-027).
  final bool grubby;

  /// Радость хотелки дня: частицы вокруг героя или шарик (F-031).
  final String? joy;

  MascotLook withEmotion(PetEmotion? e) =>
      MascotLook(color: color, hair: hair, mood: mood, stage: stage, skin: skin, accessories: accessories, emotion: e, grubby: grubby, joy: joy);

  bool get isMonkey => skin == 'monkey';
  bool get isCat => skin == 'cat';
  bool get isBunny => skin == 'bunny';
  bool get isBear => skin == 'bear';
  bool get isGiraffe => skin == 'giraffe';
  bool get isElephant => skin == 'elephant';

  /// Причёска есть у Финика и Мартышки; у Котика и Зайки — ушки.
  bool get hasHair => !isCat && !isBunny && !isBear && !isGiraffe && !isElephant;
  Color get bodyColor => isMonkey ? const Color(0xFF9A6234) : color;

  double get scale => switch (stage) {
    1 => 0.8,
    2 => 0.9,
    _ => 1.0,
  };

  String get moodLabel => switch (mood) {
    PetMood.glad => 'радуется',
    PetMood.steady => 'спокоен',
    PetMood.uneasy => 'грустит',
  };

  /// По одной вещи на место (F-051 BR-09): у старых сохранений побеждает последняя надетая.
  static Set<String> _wornAccessories(GameController game) {
    final byPlace = <String, String>{};
    final free = <String>{};
    for (final id in game.inventory.worn) {
      final item = game.content.item(id);
      final acc = item.accessory;
      if (acc == null) continue;
      if (item.wear == null) {
        free.add(acc);
      } else {
        byPlace[item.wear!] = acc;
      }
    }
    return {...free, ...byPlace.values};
  }
}
