import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

/// Компоненты дизайн-системы v2 (SA F-018). Имена `Duo*` сохранены с F-017, чтобы не трогать экраны.

/// Основная кнопка: плоская, радиус 14, при нажатии сжимается.
/// `color: FinniColors.surface` — вторичная (серая заливка, тёмный текст).
class DuoButton extends StatefulWidget {
  const DuoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = FinniColors.primary,
    this.textColor,
    this.icon,
    this.expand = true,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color? textColor;
  final IconData? icon;
  final bool expand;
  final double height;

  @override
  State<DuoButton> createState() => _DuoButtonState();
}

class _DuoButtonState extends State<DuoButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final secondary = widget.color == FinniColors.surface;
    final face = !enabled || secondary ? FinniColors.fill : widget.color;
    final ink = !enabled
        ? FinniColors.muted
        : widget.textColor ?? (secondary ? FinniColors.ink : (face.computeLuminance() > 0.6 ? FinniColors.ink : Colors.white));
    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[Icon(widget.icon, size: 20, color: ink), const SizedBox(width: 8)],
        Flexible(
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: ink, letterSpacing: -0.3, height: 1.2),
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
          child: AnimatedScale(
            scale: _down && enabled ? 0.97 : 1,
            duration: const Duration(milliseconds: 90),
            child: AnimatedOpacity(
              opacity: _down && enabled ? 0.85 : 1,
              duration: const Duration(milliseconds: 90),
              child: Container(
                width: widget.expand ? double.infinity : null,
                height: widget.height,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: widget.expand ? Alignment.center : null,
                decoration: BoxDecoration(color: face, borderRadius: BorderRadius.circular(14)),
                child: widget.expand ? content : Center(widthFactor: 1, child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Белая карточка с мягкой тенью, без рамки.
class DuoCard extends StatelessWidget {
  const DuoCard({
    super.key,
    required this.child,
    this.color = FinniColors.surface,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
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
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4)),
          BoxShadow(color: Color(0x08000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return card;
    return Pressable(onTap: onTap!, child: card);
  }
}

/// Сжатие при нажатии для любых карточек и плиток.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        buzz(Buzz.select);
        widget.onTap();
      },
      child: AnimatedScale(scale: _down ? 0.97 : 1, duration: const Duration(milliseconds: 90), child: widget.child),
    );
  }
}

/// Капсула-бейдж: «сделано», «+12».
class DuoChip extends StatelessWidget {
  const DuoChip({super.key, required this.text, this.color = FinniColors.primary, this.icon});
  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ink = Color.lerp(color, const Color(0xFF000000), 0.15)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: ink), const SizedBox(width: 4)],
          Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink, letterSpacing: -0.1)),
        ],
      ),
    );
  }
}

/// Цветная плитка с иконкой, как в «Настройках».
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.color = FinniColors.primary, this.size = 32});
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.white, 0.15)!, color],
        ),
      ),
      child: Icon(icon, size: size * 0.58, color: Colors.white),
    );
  }
}

/// Матовое стекло поверх сцены.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = 22,
    this.padding = const EdgeInsets.all(12),
    this.tint = const Color(0xB8FFFFFF),
  });
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: const Color(0x66FFFFFF), width: 0.8),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Круглая стеклянная кнопка с подписью (Дом: Одежда, Копилка, Спать, Комната).
class DuoIconButton extends StatelessWidget {
  const DuoIconButton({super.key, required this.icon, required this.label, required this.onTap, this.color = FinniColors.ink});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: Pressable(
          onTap: onTap,
          child: SizedBox(
            width: 72,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Glass(radius: 26, padding: const EdgeInsets.all(13), child: Icon(icon, size: 26, color: color)),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: FinniColors.ink,
                    shadows: [Shadow(color: Color(0xCCFFFFFF), blurRadius: 6)],
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

/// Крупный заголовок экрана, как в iOS.
class DuoHeader extends StatelessWidget {
  const DuoHeader({super.key, required this.title, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, height: 1.1, letterSpacing: -0.8)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: const TextStyle(fontSize: 15, color: FinniColors.muted, letterSpacing: -0.2)),
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

/// Заголовок секции капсом.
class DuoSection extends StatelessWidget {
  const DuoSection(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(36, 22, 20, 8),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: FinniColors.muted, letterSpacing: 0.2),
    ),
  );
}

/// Группа строк «inset grouped».
class GroupedSection extends StatelessWidget {
  const GroupedSection({super.key, this.header, this.footer, required this.children});
  final String? header;
  final String? footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(const Padding(padding: EdgeInsets.only(left: 60), child: Divider(height: 0.5, thickness: 0.5, color: FinniColors.line)));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null) DuoSection(header!),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(color: FinniColors.surface, child: Column(children: rows)),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 6, 20, 0),
            child: Text(footer!, style: const TextStyle(fontSize: 13, color: FinniColors.muted)),
          ),
      ],
    );
  }
}

/// Строка списка: плитка, заголовок, подзаголовок, значение, шеврон.
class GroupedRow extends StatelessWidget {
  const GroupedRow({
    super.key,
    this.icon,
    this.iconColor = FinniColors.primary,
    this.leading,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.chevron = true,
    this.done = false,
    this.onTap,
  });

  final IconData? icon;
  final Color iconColor;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final bool chevron;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          if (leading != null)
            leading!
          else if (icon != null)
            IconTile(done ? Icons.check_rounded : icon!, color: done ? FinniColors.need : iconColor),
          if (leading != null || icon != null) const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    letterSpacing: -0.4,
                    color: done ? FinniColors.muted : FinniColors.ink,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: FinniColors.muted,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!, style: const TextStyle(fontSize: 13, color: FinniColors.muted, letterSpacing: -0.1)),
                  ),
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 8),
            Text(value!, style: const TextStyle(fontSize: 17, color: FinniColors.muted, letterSpacing: -0.4)),
          ],
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          if (chevron && onTap != null) ...[
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFC4C4C7), size: 22),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          buzz(Buzz.select);
          onTap!();
        },
        highlightColor: const Color(0x0F000000),
        child: row,
      ),
    );
  }
}

enum ShellTab { games, tasks, home, lessons, shop }

extension ShellTabLook on ShellTab {
  IconData get icon => switch (this) {
    ShellTab.games => Icons.sports_esports_outlined,
    ShellTab.tasks => Icons.check_circle_outline_rounded,
    ShellTab.home => Icons.home_outlined,
    ShellTab.lessons => Icons.menu_book_outlined,
    ShellTab.shop => Icons.shopping_bag_outlined,
  };

  IconData get activeIcon => switch (this) {
    ShellTab.games => Icons.sports_esports_rounded,
    ShellTab.tasks => Icons.check_circle_rounded,
    ShellTab.home => Icons.home_rounded,
    ShellTab.lessons => Icons.menu_book_rounded,
    ShellTab.shop => Icons.shopping_bag_rounded,
  };

  String get title => switch (this) {
    ShellTab.games => 'Игры',
    ShellTab.tasks => 'Задания',
    ShellTab.home => 'Дом',
    ShellTab.lessons => 'Уроки',
    ShellTab.shop => 'Магазин',
  };
}

/// Таб-бар из матового стекла.
class DuoTabBar extends StatelessWidget {
  const DuoTabBar({super.key, required this.current, required this.onTap, this.badges = const {}});
  final ShellTab current;
  final ValueChanged<ShellTab> onTap;
  final Map<ShellTab, String> badges;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xE6F9F9F9),
            border: Border(top: BorderSide(color: Color(0x33000000), width: 0.3)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 58,
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
                                Badge(
                                  isLabelVisible: badges.containsKey(tab),
                                  smallSize: 8,
                                  backgroundColor: FinniColors.want,
                                  child: Icon(
                                    tab == current ? tab.activeIcon : tab.icon,
                                    size: 26,
                                    color: tab == current ? FinniColors.primary : FinniColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tab.title,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: tab == current ? FinniColors.primary : FinniColors.muted,
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
        ),
      ),
    );
  }
}
