import 'package:flutter/material.dart';

import '../../economy/economy_state.dart';
import '../../game/game_controller.dart';
import '../mascot/mascot_look.dart';
import '../mascot/mascot_view.dart';
import '../theme.dart';

/// Создание героя: имена и облик с живым 3D-превью (SA F-008).
class CreateHeroScreen extends StatefulWidget {
  const CreateHeroScreen({super.key, required this.game});
  final GameController game;

  @override
  State<CreateHeroScreen> createState() => _CreateHeroScreenState();
}

class _CreateHeroScreenState extends State<CreateHeroScreen> {
  final _player = TextEditingController();
  final _pet = TextEditingController(text: 'Финни');
  final _mascot = MascotController();
  String _tone = 'sun';
  String _hair = 'tuft';
  bool _busy = false;

  static const _tones = {'sun': 'Солнышко', 'lemon': 'Лимон', 'orange': 'Апельсин'};
  static const _hairs = {'tuft': 'Хохолок', 'bangs': 'Чёлка', 'buns': 'Пучки'};

  String get _lookId => '${_tone}_$_hair';
  bool get _valid => _player.text.trim().isNotEmpty && _pet.text.trim().isNotEmpty;

  @override
  void dispose() {
    _player.dispose();
    _pet.dispose();
    _mascot.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    setState(() => _busy = true);
    await widget.game.createProfile(
      playerName: _player.text.trim(),
      petName: _pet.text.trim(),
      lookId: _lookId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final look = widget.game.content.look(_lookId);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const Text('Твой герой', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            const Text('Покрути его пальцем!', textAlign: TextAlign.center, style: TextStyle(color: FinniColors.muted)),
            Center(
              child: MascotView(
                look: MascotLook.fromLook(look, mood: PetMood.glad, stage: 1),
                controller: _mascot,
                size: 220,
                semanticsLabel: _pet.text,
              ),
            ),
            _label('Оттенок'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final MapEntry(key: id, value: title) in _tones.entries)
                  ChoiceChip(
                    key: Key('hero.tone.$id'),
                    avatar: CircleAvatar(backgroundColor: Color(widget.game.content.look('${id}_tuft').color)),
                    label: Text(title),
                    selected: _tone == id,
                    onSelected: (_) {
                      setState(() => _tone = id);
                      _mascot.jump();
                    },
                  ),
              ],
            ),
            _label('Причёска'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final MapEntry(key: id, value: title) in _hairs.entries)
                  ChoiceChip(
                    key: Key('hero.hair.$id'),
                    label: Text(title),
                    selected: _hair == id,
                    onSelected: (_) {
                      setState(() => _hair = id);
                      _mascot.jump();
                    },
                  ),
              ],
            ),
            _label('Как тебя зовут в игре?'),
            TextField(
              key: const Key('hero.player'),
              controller: _player,
              maxLength: 16,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: _input('Например, Капитан'),
            ),
            const Text(
              'Только игровое имя. Фамилию и телефон писать не нужно.',
              style: TextStyle(fontSize: 13, color: FinniColors.muted),
            ),
            _label('Как зовут героя?'),
            TextField(
              key: const Key('hero.pet'),
              controller: _pet,
              maxLength: 16,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: _input('Финни'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('hero.go'),
              onPressed: _valid && !_busy ? _go : null,
              child: const Text('Поехали! 🚀'),
            ),
            if (!_valid)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Впиши оба имени', textAlign: TextAlign.center, style: TextStyle(color: FinniColors.muted)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
  );

  InputDecoration _input(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: FinniColors.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
  );
}
