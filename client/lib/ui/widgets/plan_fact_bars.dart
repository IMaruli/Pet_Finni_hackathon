import 'dart:math';

import 'package:flutter/material.dart';

import '../../store/snapshot.dart';
import '../theme.dart';

/// Три пары столбиков «план / факт» с числами (SA F-015).
class PlanFactBars extends StatelessWidget {
  const PlanFactBars({super.key, required this.summary, this.dark = false});
  final DaySummary summary;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final pairs = [
      (Basket.need, summary.planNeed, summary.spentNeed),
      (Basket.want, summary.planWant, summary.spentWant),
      (Basket.save, summary.planSave, summary.saved),
    ];
    final top = pairs.fold(1, (m, p) => max(m, max(p.$2, p.$3)));
    final ink = dark ? Colors.white : FinniColors.ink;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legend('План', ink.withValues(alpha: 0.35), ink),
            const SizedBox(width: 16),
            _legend('Факт', ink, ink),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (basket, plan, fact) in pairs)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _bar(plan, top, basket.color.withValues(alpha: 0.35), ink),
                            const SizedBox(width: 6),
                            _bar(fact, top, basket.color, ink),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${basket.emoji} ${basket.title}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ink),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legend(String text, Color swatch, Color ink) => Row(
    children: [
      Container(width: 14, height: 14, decoration: BoxDecoration(color: swatch, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 6),
      Text(text, style: TextStyle(fontSize: 13, color: ink, fontWeight: FontWeight.w700)),
    ],
  );

  Widget _bar(int value, int top, Color color, Color ink) => LayoutBuilder(
    builder: (context, box) {
      final maxBar = max(8.0, (box.maxHeight.isFinite ? box.maxHeight : 120) - 26);
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('$value', style: TextStyle(fontSize: 14, height: 1.2, fontWeight: FontWeight.w900, color: ink)),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value / top),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutBack,
            builder: (_, v, _) => Container(
              width: 22,
              height: (maxBar * v).clamp(4.0, maxBar).toDouble(),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      );
    },
  );
}
