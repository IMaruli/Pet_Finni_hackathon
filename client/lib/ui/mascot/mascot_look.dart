import 'package:flutter/painting.dart';

import '../../content/models.dart';
import '../../economy/economy_state.dart';
import '../../game/game_controller.dart';

/// Всё, что определяет внешний вид героя в кадре.
final class MascotLook {
  const MascotLook({
    required this.color,
    required this.hair,
    required this.mood,
    required this.stage,
    this.skin,
    this.accessories = const {},
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
    return MascotLook.fromLook(
      content.look(game.profile.lookId),
      mood: game.mood,
      stage: game.stage,
      skin: game.inventory.skin,
      accessories: {
        for (final id in game.inventory.worn) ?content.item(id).accessory,
      },
    );
  }

  final Color color;

  /// tuft|bangs|buns
  final String hair;

  /// 'monkey' или null.
  final String? skin;

  /// bandana|glasses|bow|headphones
  final Set<String> accessories;
  final PetMood mood;
  final int stage;

  bool get isMonkey => skin == 'monkey';
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
