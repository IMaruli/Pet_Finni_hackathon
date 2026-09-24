import 'dart:math';

import 'package:flutter/material.dart';

import '../../content/models.dart';
import '../theme.dart';
import 'common.dart';

/// Пузырь нужного над героем: эмодзи и цена, покачивается; первый — пульсирует (SA F-039).
class NeedBubble extends StatefulWidget {
  const NeedBubble({super.key, required this.item, required this.onTap, this.phase = 0, this.urgent = false});
  final ShopItem item;
  final VoidCallback onTap;

  /// Сдвиг фазы покачивания, чтобы пузыри не двигались в такт.
  final double phase;

  /// То, что герой просит прямо сейчас.
  final bool urgent;

  @override
  State<NeedBubble> createState() => _NeedBubbleState();
}

class _NeedBubbleState extends State<NeedBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Semantics(
      button: true,
      label: '${item.title}, ${item.price} монет',
      child: AnimatedBuilder(
        animation: _t,
        builder: (_, child) {
          final a = (_t.value + widget.phase) * 2 * pi;
          final pulse = widget.urgent ? 1 + 0.06 * (0.5 + 0.5 * sin(a * 2)) : 1.0;
          return Transform.translate(offset: Offset(0, sin(a) * 4), child: Transform.scale(scale: pulse, child: child));
        },
        child: GestureDetector(
          onTap: () {
            buzz(Buzz.light);
            widget.onTap();
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
            decoration: BoxDecoration(
              color: const Color(0xEEFFFFFF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: widget.urgent ? FinniColors.want : FinniColors.line, width: widget.urgent ? 2 : 1),
              boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 4),
                const CoinIcon(size: 14),
                const SizedBox(width: 3),
                Text('${item.price}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: FinniColors.ink)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
