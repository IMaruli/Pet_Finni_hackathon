import 'package:flutter/material.dart';

import '../../economy/economy_state.dart';
import '../mascot/mascot_look.dart';
import '../mascot/mascot_view.dart';
import '../theme.dart';
import '../widgets/duo.dart';

/// «Кто заходит?» (Figma 00, SA F-017 BR-01).
class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key, required this.onChild, required this.onAdult});
  final VoidCallback onChild;
  final VoidCallback onAdult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Text('Питомец Финни', style: TextStyle(color: FinniColors.teal, fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Кто заходит?', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.8)),
              const SizedBox(height: 6),
              const Text('Выбери режим — можно сменить позже', style: TextStyle(color: FinniColors.muted)),
              const SizedBox(height: 24),
              _card(
                key: 'role.child',
                title: 'Ребёнок',
                subtitle: 'Игра, комната, задания',
                icon: const MascotView(
                  look: MascotLook(color: Color(0xFFFFCC33), hair: 'tuft', mood: PetMood.glad, stage: 1),
                  size: 84,
                  interactive: false,
                ),
                onTap: onChild,
              ),
              const SizedBox(height: 14),
              _card(
                key: 'role.adult',
                title: 'Взрослый',
                subtitle: 'Прогресс ребёнка · сброс демо',
                icon: const IconTile(Icons.family_restroom_rounded, color: FinniColors.teal, size: 64),
                onTap: onAdult,
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required String key, required String title, required String subtitle, required Widget icon, required VoidCallback onTap}) {
    return DuoCard(
      key: Key(key),
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      child: Column(
        children: [
          SizedBox(height: 84, child: Center(child: icon)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          Text(subtitle, style: const TextStyle(color: FinniColors.muted)),
        ],
      ),
    );
  }
}
