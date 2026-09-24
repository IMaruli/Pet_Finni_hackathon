import 'package:flutter/material.dart';

import '../economy/catalog_item.dart';

/// Токены дизайн-системы v2 (SA F-018): нейтральная основа в духе Apple HIG, один акцент.
abstract final class FinniColors {
  static const bg = Color(0xFFF2F2F7);
  static const surface = Color(0xFFFFFFFF);
  static const fill = Color(0xFFEFEFF4);
  static const ink = Color(0xFF1C1C1E);
  static const muted = Color(0xFF8E8E93);
  static const line = Color(0xFFE5E5EA);
  static const primary = Color(0xFF5E5CE6);
  static const teal = Color(0xFF30B0C7);
  static const orange = Color(0xFFFF9500);
  static const blue = Color(0xFF007AFF);
  static const need = Color(0xFF34C759);
  static const want = Color(0xFFFF2D55);
  static const save = Color(0xFF0A84FF);
  static const coin = Color(0xFFFFB800);
  static const night = Color(0xFF1C1F3A);
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

  IconData get icon => switch (this) {
    Basket.need => Icons.shopping_basket_rounded,
    Basket.want => Icons.favorite_rounded,
    Basket.save => Icons.savings_rounded,
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
      onPrimary: Colors.white,
      secondary: FinniColors.teal,
      surface: FinniColors.surface,
    ),
    scaffoldBackgroundColor: FinniColors.bg,
    splashFactory: NoSplash.splashFactory,
  );
  final text = base.textTheme.apply(bodyColor: FinniColors.ink, displayColor: FinniColors.ink);
  return base.copyWith(
    textTheme: text.copyWith(
      bodyMedium: text.bodyMedium?.copyWith(fontSize: 16, height: 1.35, letterSpacing: -0.2),
      bodyLarge: text.bodyLarge?.copyWith(fontSize: 17, height: 1.35, letterSpacing: -0.3),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: FinniColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      foregroundColor: FinniColors.primary,
      titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: FinniColors.ink, letterSpacing: -0.4),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: FinniColors.primary, textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
    ),
    chipTheme: base.chipTheme.copyWith(
      side: BorderSide.none,
      backgroundColor: FinniColors.fill,
      selectedColor: FinniColors.primary.withValues(alpha: 0.14),
      labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: FinniColors.ink),
      shape: const StadiumBorder(),
      showCheckmark: false,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: FinniColors.bg,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: FinniColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
    ),
  );
}
