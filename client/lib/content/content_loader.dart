import 'dart:convert';

import 'package:flutter/services.dart';

import 'game_content.dart';

abstract final class ContentLoader {
  static const files = ['config', 'items', 'goals', 'lessons', 'looks', 'copy', 'minigames'];

  /// Читает `assets/content/*.json`. Бросает [ContentException], если пакет невалиден.
  static Future<GameContent> load([AssetBundle? bundle]) async {
    final source = bundle ?? rootBundle;
    final raw = <String, dynamic>{
      for (final name in files)
        name: jsonDecode(await source.loadString('assets/content/$name.json')),
    };
    final content = GameContent.fromJson(raw);
    final problems = content.validate();
    if (problems.isNotEmpty) throw ContentException(problems);
    return content;
  }
}
