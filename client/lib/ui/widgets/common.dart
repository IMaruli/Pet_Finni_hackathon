import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

enum Buzz { select, light, medium, heavy }

/// Вибрация с выключателем из раздела взрослого (BR-15 F-002).
abstract final class Haptics {
  static bool enabled = true;
}

void buzz(Buzz kind) {
  if (!Haptics.enabled) return;
  switch (kind) {
    case Buzz.select:
      HapticFeedback.selectionClick();
    case Buzz.light:
      HapticFeedback.lightImpact();
    case Buzz.medium:
      HapticFeedback.mediumImpact();
    case Buzz.heavy:
      HapticFeedback.heavyImpact();
  }
}

/// Монеты с анимированным счётчиком.
class CoinChip extends StatelessWidget {
  const CoinChip({
    super.key,
    required this.value,
    this.label,
    this.emoji = '🪙',
    this.color = FinniColors.coin,
  });
  final int value;
  final String? label;
  final String emoji;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${label ?? 'Монеты'}: $value',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: FinniColors.surface,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: value.toDouble()),
                  duration: const Duration(milliseconds: 500),
                  builder: (_, v, _) => Text(
                    '${v.round()}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: FinniColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Бейдж корзины: иконка + слово + цвет.
class BasketBadge extends StatelessWidget {
  const BasketBadge(this.basket, {super.key, this.small = false});
  final Basket basket;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: basket.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${basket.emoji} ${basket.title}',
        style: TextStyle(
          fontSize: small ? 12 : 14,
          fontWeight: FontWeight.w800,
          color: basket.color,
        ),
      ),
    );
  }
}

/// Белая карточка-панель.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.onTap,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? FinniColors.surface,
      borderRadius: BorderRadius.circular(24),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: FinniColors.line, width: 2),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Большая плитка меню.
class MenuTile extends StatelessWidget {
  const MenuTile({
    super.key,
    required this.emoji,
    required this.title,
    required this.onTap,
    this.badge,
    this.color,
  });
  final String emoji;
  final String title;
  final VoidCallback onTap;
  final String? badge;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: color ?? FinniColors.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            buzz(Buzz.select);
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: FinniColors.line, width: 2),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (badge != null)
                  Positioned(
                    right: 0,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: FinniColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Пузырь реплики.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.text,
    this.color = FinniColors.surface,
    this.tailLeft = true,
  });
  final String text;
  final Color color;
  final bool tailLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(22),
          topRight: const Radius.circular(22),
          bottomLeft: Radius.circular(tailLeft ? 4 : 22),
          bottomRight: Radius.circular(tailLeft ? 22 : 4),
        ),
        border: Border.all(color: FinniColors.line, width: 2),
      ),
      child: Text(text, style: const TextStyle(fontSize: 17, height: 1.35)),
    );
  }
}

/// Короткое сообщение ребёнку.
void showToast(
  BuildContext context,
  List<String> messages, {
  String emoji = '💬',
  Color? color,
}) {
  if (messages.isEmpty) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(milliseconds: 2800),
      backgroundColor: color ?? FinniColors.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      content: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              messages.join('\n'),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Шкала прогресса с подписью.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 14,
  });
  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: color.withValues(alpha: 0.15),
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0, 1)),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => FractionallySizedBox(
            widthFactor: v,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
