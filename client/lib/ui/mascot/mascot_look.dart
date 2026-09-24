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
      accessories: {
        for (final id in game.inventory.worn) ?content.item(id).accessory,
      },
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

  MascotLook withEmotion(PetEmotion? e) =>
      MascotLook(color: color, hair: hair, mood: mood, stage: stage, skin: skin, accessories: accessories, emotion: e);

  bool get isMonkey => skin == 'monkey';
  bool get isCat => skin == 'cat';
  bool get isBunny => skin == 'bunny';

  /// Причёска есть у Финика и Мартышки; у Котика и Зайки — ушки.
  bool get hasHair => !isCat && !isBunny;
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
}
