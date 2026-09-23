import 'package:flutter/material.dart';

import '../economy/catalog_item.dart';

/// Палитра Финни: тёплая, контрастная, цвет всегда дублируется иконкой и словом.
abstract final class FinniColors {
  static const bg = Color(0xFFFFF7E8);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF3B2A20);
  static const muted = Color(0xFF8A7563);
  static const primary = Color(0xFFFF7A2F);
  static const need = Color(0xFF22A06B);
  static const want = Color(0xFFE8508F);
  static const save = Color(0xFF3F7FF0);
  static const coin = Color(0xFFFFC233);
  static const night = Color(0xFF1E2350);
  static const line = Color(0xFFF0E2CC);
}

enum Basket { need, want, save }

extension BasketLook on Basket {
  String get title => switch (this) {
    Basket.need => 'Нужное',
    Basket.want => 'Хочу',
    Basket.save => 'Отложить',
  };

  String get emoji => switch (this) {
    Basket.need => '🥣',
    Basket.want => '🎁',
    Basket.save => '🐷',
  };

  Color get color => switch (this) {
    Basket.need => FinniColors.need,
    Basket.want => FinniColors.want,
    Basket.save => FinniColors.save,
  };
}

Basket basketOf(ItemKind kind) => kind == ItemKind.need ? Basket.need : Basket.want;

ThemeData finniTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: FinniColors.primary,
      primary: FinniColors.primary,
      surface: FinniColors.surface,
    ),
    scaffoldBackgroundColor: FinniColors.bg,
  );
  final text = base.textTheme.apply(bodyColor: FinniColors.ink, displayColor: FinniColors.ink);
  return base.copyWith(
    textTheme: text.copyWith(
      bodyMedium: text.bodyMedium?.copyWith(fontSize: 16, height: 1.35),
      bodyLarge: text.bodyLarge?.copyWith(fontSize: 18, height: 1.35),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      foregroundColor: FinniColors.ink,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: FinniColors.ink),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 56),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        foregroundColor: FinniColors.ink,
        side: const BorderSide(color: FinniColors.line, width: 2),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: FinniColors.bg,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
  );
}
