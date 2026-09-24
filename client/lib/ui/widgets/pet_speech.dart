import 'dart:math';

import 'package:flutter/material.dart';

import '../motion.dart';
import '../theme.dart';
import 'common.dart';
import 'duo.dart';

/// Полупрозрачное стекло облачка (SA F-021 BR-09).
const _tint = Color(0xC4FFFFFF);

/// Реплика героя: облачко-сообщение с хвостиком вниз, «печатает…», кнопка-капсула (SA F-020 BR-02…BR-04).
class PetSpeech extends StatefulWidget {
  const PetSpeech({super.key, required this.text, this.action, this.onAction, this.actionKey, this.accent = FinniColors.primary});
  final String text;
  final String? action;
  final VoidCallback? onAction;
  final Key? actionKey;
  final Color accent;

  @override
  State<PetSpeech> createState() => _PetSpeechState();
}

class _PetSpeechState extends State<PetSpeech> with TickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final AnimationController _dots = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  bool _typing = true;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(PetSpeech old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _start();
  }

  void _start() {
    final gen = ++_generation;
    if (Motion.reduced) {
      // F-058: без «печатания» и прыжка облачка.
      _pop.value = 1;
      setState(() => _typing = false);
      return;
    }
    setState(() => _typing = true);
    _pop.forward(from: 0);
    _dots.repeat();
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted || gen != _generation) return;
      _dots.stop();
      setState(() => _typing = false);
    });
  }

  @override
  void dispose() {
    _pop.dispose();
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bubble = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 6))],
            ),
            child: Glass(
              radius: 20,
              tint: _tint,
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              child: AnimatedSize(duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic, child: _typing ? _typingDots() : _content()),
            ),
          ),
          CustomPaint(size: const Size(18, 9), painter: _Tail()),
        ],
      ),
    );
    return Semantics(
      liveRegion: true,
      label: widget.text,
      child: AnimatedBuilder(
        animation: _pop,
        builder: (_, child) {
          final t = Curves.easeOutBack.transform(_pop.value);
          return Opacity(
            opacity: _pop.value.clamp(0.0, 1.0),
            child: Transform.scale(scale: 0.6 + 0.4 * t, alignment: Alignment.bottomCenter, child: child),
          );
        },
        child: bubble,
      ),
    );
  }

  Widget _typingDots() => SizedBox(
    width: 46,
    height: 22,
    child: AnimatedBuilder(
      animation: _dots,
      builder: (_, _) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < 3; i++)
            Opacity(
              opacity: 0.3 + 0.7 * (0.5 + 0.5 * sin((_dots.value - i * 0.18) * 2 * pi)),
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(color: FinniColors.muted, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _content() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(
        child: Padding(
          padding: EdgeInsets.only(right: widget.action == null ? 6 : 10),
          child: Text(
            widget.text,
            style: const TextStyle(
              fontSize: 16, // основной текст ≥ 16 sp (ТЗ 3.6)
              height: 1.3,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
              color: FinniColors.ink,
            ),
          ),
        ),
      ),
      if (widget.action != null)
        Semantics(
          button: true,
          label: widget.action,
          child: GestureDetector(
            key: widget.actionKey,
            onTap: () {
              buzz(Buzz.light);
              widget.onAction?.call();
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                height: 40, // с отступами зона нажатия 48 dp (ТЗ 3.6)
                padding: const EdgeInsets.only(left: 12, right: 6),
                decoration: BoxDecoration(color: widget.accent, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.action!,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class _Tail extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.2, size.width / 2, size.height)
      ..quadraticBezierTo(size.width * 0.55, size.height * 0.2, size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = _tint);
  }

  @override
  bool shouldRepaint(_Tail old) => false;
}
