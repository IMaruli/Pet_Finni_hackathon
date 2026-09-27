import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../game/game_controller.dart';
import '../theme.dart';
import 'duo.dart';

/// Подсказки при первом входе в раздел (F-062). В автотестах выключены — их проверяет отдельный тест.
abstract final class FirstTips {
  static bool enabled = kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST');
}

/// Показать подсказку [id] один раз: эмодзи, заголовок, 2–3 строки и «Понятно». Тексты — `copy.json` `tip.<id>.*`.
Future<void> showFirstTip(BuildContext context, GameController game, String id) async {
  if (!FirstTips.enabled || !game.hasProfile || game.greeting || game.tipSeen(id)) return;
  await game.markTip(id);
  if (!context.mounted) return;
  final c = game.content;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(c.text('tip.$id.emoji'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 6),
            Text(c.text('tip.$id.title'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            for (final line in c.text('tip.$id.text').split('\n'))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.check_circle_rounded, size: 20, color: FinniColors.need)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(line, style: const TextStyle(fontSize: 17, height: 1.35))),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            DuoButton(key: const Key('tip.ok'), label: 'Понятно', onPressed: () => Navigator.of(sheet).pop()),
          ],
        ),
      ),
    ),
  );
}

/// Показывает подсказку [id] при первом открытии [child] (для экранов без своего состояния).
class FirstTipGate extends StatefulWidget {
  const FirstTipGate({super.key, required this.id, required this.game, required this.child});
  final String id;
  final GameController game;
  final Widget child;

  @override
  State<FirstTipGate> createState() => _FirstTipGateState();
}

class _FirstTipGateState extends State<FirstTipGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showFirstTip(context, widget.game, widget.id);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
