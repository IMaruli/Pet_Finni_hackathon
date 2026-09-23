import 'package:flutter/material.dart';

import '../../content/game_content.dart';
import '../widgets/common.dart';

/// Словарик терминов (SA F-016).
class GlossaryScreen extends StatelessWidget {
  const GlossaryScreen({super.key, required this.content});
  final GameContent content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📖 Словарик')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: content.glossary.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final e = content.glossary[i];
            return Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.term, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(e.meaning, style: const TextStyle(fontSize: 17)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
