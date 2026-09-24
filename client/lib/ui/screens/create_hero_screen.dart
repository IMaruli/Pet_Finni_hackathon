import 'package:flutter/material.dart';

import '../../economy/economy_state.dart';
import '../../game/game_controller.dart';
import '../mascot/mascot_look.dart';
import '../mascot/mascot_view.dart';
import '../theme.dart';
import '../widgets/duo.dart';

/// Создание героя (Figma 01): имя, облик, «В комнату!» (SA F-008, F-017 BR-02).
class CreateHeroScreen extends StatefulWidget {
  const CreateHeroScreen({super.key, required this.game});
  final GameController game;

  @override
  State<CreateHeroScreen> createState() => _CreateHeroScreenState();
}

class _CreateHeroScreenState extends State<CreateHeroScreen> {
  final _pet = TextEditingController(text: 'Финя');
  final _player = TextEditingController();
  final _mascot = MascotController();
  String _tone = 'sun';
  String _hair = 'tuft';
  bool _busy = false;

  static const _tones = ['sun', 'lemon', 'orange'];
  static const _hairs = {'tuft': 'Хохолок', 'bangs': 'Чёлка', 'buns': 'Пучки'};

  String get _lookId => '${_tone}_$_hair';
  bool get _valid => _player.text.trim().isNotEmpty && _pet.text.trim().isNotEmpty;

  @override
  void dispose() {
    _pet.dispose();
    _player.dispose();
    _mascot.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    setState(() => _busy = true);
    await widget.game.createProfile(playerName: _player.text.trim(), petName: _pet.text.trim(), lookId: _lookId);
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.game.content;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            const Text('Питомец Финни', textAlign: TextAlign.center, style: TextStyle(color: FinniColors.teal, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Как зовут героя?', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
            Center(
              child: MascotView(
                look: MascotLook.fromLook(content.look(_lookId), mood: PetMood.glad, stage: 1),
                controller: _mascot,
                size: 190,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final t in _tones)
                  GestureDetector(
                    key: Key('hero.tone.$t'),
                    onTap: () {
                      setState(() => _tone = t);
                      _mascot.jump();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color(content.look('${t}_tuft').color),
                        shape: BoxShape.circle,
                        border: Border.all(color: _tone == t ? FinniColors.ink : Colors.white, width: 3),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              runSpacing: 6,
              children: [
                for (final MapEntry(key: id, value: title) in _hairs.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      key: Key('hero.hair.$id'),
                      label: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      selected: _hair == id,
                      onSelected: (_) {
                        setState(() => _hair = id);
                        _mascot.jump();
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _field(const Key('hero.pet'), _pet, 'Имя героя'),
            const SizedBox(height: 10),
            _field(const Key('hero.player'), _player, 'А тебя? Игровое имя'),
            const SizedBox(height: 8),
            const Text(
              'Жёлтый кружок — твой герой. Комнату обставим вместе.\nФамилию и телефон писать не нужно.',
              textAlign: TextAlign.center,
              style: TextStyle(color: FinniColors.muted),
            ),
            const SizedBox(height: 18),
            DuoButton(key: const Key('hero.go'), label: 'В комнату!', onPressed: _valid && !_busy ? _go : null),
          ],
        ),
      ),
    );
  }

  Widget _field(Key key, TextEditingController c, String hint) => TextField(
    key: key,
    controller: c,
    maxLength: 16,
    textCapitalization: TextCapitalization.words,
    onChanged: (_) => setState(() {}),
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    decoration: InputDecoration(
      hintText: hint,
      counterText: '',
      filled: true,
      fillColor: FinniColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: FinniColors.line, width: 2)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: FinniColors.teal, width: 2)),
    ),
  );
}
