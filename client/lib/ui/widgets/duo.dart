import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

/// «Толстая» кнопка в стиле Duolingo: нижний бортик, при нажатии проваливается (SA F-017).
class DuoButton extends StatefulWidget {
  const DuoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = FinniColors.primary,
    this.textColor,
    this.emoji,
    this.expand = true,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color? textColor;
  final String? emoji;
  final bool expand;
  final double height;

  @override
  State<DuoButton> createState() => _DuoButtonState();
}

class _DuoButtonState extends State<DuoButton> {
  static const _ledge = 4.0;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final face = enabled ? widget.color : const Color(0xFFE3DDD2);
    final edge = enabled ? ledgeOf(widget.color) : const Color(0xFFCFC7BA);
    final ink = enabled
        ? (widget.textColor ?? (face.computeLuminance() > 0.5 ? FinniColors.ink : Colors.white))
        : FinniColors.muted;
    final pressed = _down && enabled;
    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.emoji != null) ...[
          Text(widget.emoji!, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ink, letterSpacing: 0.3),
          ),
        ),
      ],
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapCancel: () => setState(() => _down = false),
          onTapUp: enabled ? (_) => setState(() => _down = false) : null,
          onTap: enabled
              ? () {
                  buzz(Buzz.light);
                  widget.onPressed!();
                }
              : null,
          child: SizedBox(
            width: widget.expand ? double.infinity : null,
            height: widget.height + _ledge,
            child: Stack(
              children: [
                Positioned.fill(
                  top: _ledge,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: edge, borderRadius: BorderRadius.circular(18)),
                  ),
                ),
                AnimatedPadding(
                  duration: const Duration(milliseconds: 70),
                  padding: EdgeInsets.only(top: pressed ? _ledge : 0, bottom: pressed ? 0 : _ledge),
                  child: Container(
                    height: widget.height,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(color: face, borderRadius: BorderRadius.circular(18)),
                    alignment: widget.expand ? Alignment.center : null,
                    child: widget.expand ? content : Center(widthFactor: 1, child: content),
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

/// Белая карточка с «бортиком» снизу.
class DuoCard extends StatelessWidget {
  const DuoCard({
    super.key,
    required this.child,
    this.color = FinniColors.surface,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
  });

  final Widget child;
  final Color color;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: FinniColors.line, width: 2),
        boxShadow: const [BoxShadow(color: FinniColors.line, offset: Offset(0, 3))],
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        buzz(Buzz.select);
        onTap!();
      },
      child: card,
    );
  }
}

/// Маленький бейдж: «доступно», «+12», «сделано».
class DuoChip extends StatelessWidget {
  const DuoChip({super.key, required this.text, this.color = FinniColors.teal, this.emoji});
  final String text;
  final Color color;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)),
      child: Text(
        emoji == null ? text : '$emoji $text',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ledgeOf(color)),
      ),
    );
  }
}

/// Круглая плавающая кнопка с подписью (Одежда, Комната, Спать).
class DuoIconButton extends StatelessWidget {
  const DuoIconButton({super.key, required this.emoji, required this.label, required this.onTap, this.color = FinniColors.surface});
  final String emoji;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: () {
            buzz(Buzz.select);
            onTap();
          },
          child: Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Заголовок раздела: крупно + подзаголовок + справа монеты.
class DuoHeader extends StatelessWidget {
  const DuoHeader({super.key, required this.title, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, height: 1.1)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: const TextStyle(fontSize: 15, color: FinniColors.muted)),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Подпись секции («Сегодня», «На неделю»).
class DuoSection extends StatelessWidget {
  const DuoSection(this.text, {super.key, this.color = FinniColors.teal});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
    child: Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
  );
}

enum ShellTab { games, tasks, home, lessons, shop }

extension ShellTabLook on ShellTab {
  String get emoji => switch (this) {
    ShellTab.games => '🎮',
    ShellTab.tasks => '📋',
    ShellTab.home => '🏠',
    ShellTab.lessons => '📖',
    ShellTab.shop => '🛍️',
  };

  String get title => switch (this) {
    ShellTab.games => 'Игры',
    ShellTab.tasks => 'Задания',
    ShellTab.home => 'Дом',
    ShellTab.lessons => 'Уроки',
    ShellTab.shop => 'Магазин',
  };
}

/// Нижний таб-бар из макета: Игры · Задания · Дом · Уроки · Магазин.
class DuoTabBar extends StatelessWidget {
  const DuoTabBar({super.key, required this.current, required this.onTap, this.badges = const {}});
  final ShellTab current;
  final ValueChanged<ShellTab> onTap;
  final Map<ShellTab, String> badges;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFBF4),
        border: Border(top: BorderSide(color: FinniColors.line, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 74,
          child: Row(
            children: [
              for (final tab in ShellTab.values)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: tab == current,
                    label: tab.title,
                    child: GestureDetector(
                      key: Key('nav.${tab.name}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        buzz(Buzz.select);
                        onTap(tab);
                      },
                      child: ExcludeSemantics(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: tab == current ? FinniColors.primary.withValues(alpha: 0.35) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: AnimatedScale(
                                    scale: tab == current ? 1.15 : 1,
                                    duration: const Duration(milliseconds: 180),
                                    child: Text(tab.emoji, style: const TextStyle(fontSize: 22)),
                                  ),
                                ),
                                if (badges[tab] case final b?)
                                  Positioned(
                                    right: -4,
                                    top: -4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(color: FinniColors.orange, borderRadius: BorderRadius.circular(10)),
                                      child: Text(b, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w900)),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tab.title,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: tab == current ? FontWeight.w900 : FontWeight.w600,
                                color: tab == current ? FinniColors.ink : FinniColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
