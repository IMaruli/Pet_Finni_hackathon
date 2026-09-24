import 'package:flutter/material.dart';

import '../../content/models.dart';
import '../../economy/economy_state.dart';
import '../../game/game_controller.dart';
import '../mascot/mascot_look.dart';
import '../mascot/mascot_view.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/duo.dart';

/// Настрой Финика: скин, цвет, причёска и имена (SA F-023, F-008).
/// [create] — первый вход ребёнка; иначе правка облика из Одежды.
class FinikStyleScreen extends StatefulWidget {
  const FinikStyleScreen({super.key, required this.game, this.create = true});
  final GameController game;
  final bool create;

  @override
  State<FinikStyleScreen> createState() => _FinikStyleScreenState();
}

class _FinikStyleScreenState extends State<FinikStyleScreen> {
  static const _hairs = {'tuft': 'Хохолок', 'bangs': 'Чёлка', 'buns': 'Пучки'};

  final _pet = TextEditingController(text: 'Финя');
  final _player = TextEditingController();
  final _mascot = MascotController();
  late String _skin;
  late int _color;
  late String _hair;
  bool _busy = false;
  bool _showLockHint = false;

  GameController get game => widget.game;

  @override
  void initState() {
    super.initState();
    if (widget.create) {
      _skin = 'finik';
      _color = game.content.palette.first.color;
      _hair = 'tuft';
    } else {
      final look = MascotLook.fromGame(game);
      _skin = game.profile.skin;
      _color = look.color.toARGB32();
      _hair = look.hair;
    }
  }

  @override
  void dispose() {
    _pet.dispose();
    _player.dispose();
    _mascot.dispose();
    super.dispose();
  }

  bool _unlocked(SkinDef s) => widget.create ? s.unlockStage <= 1 : game.isSkinUnlocked(s.id);
  bool get _valid => !widget.create || (_player.text.trim().isNotEmpty && _pet.text.trim().isNotEmpty);
  String get _petName => widget.create ? (_pet.text.trim().isEmpty ? 'Финик' : _pet.text.trim()) : game.profile.petName;

  MascotLook _look(String skin, {PetMood mood = PetMood.glad}) => MascotLook(
    color: Color(_color),
    hair: _hair,
    skin: skin,
    mood: mood,
    stage: widget.create ? 1 : game.stage,
    accessories: widget.create ? const {} : MascotLook.fromGame(game).accessories,
  );

  void _pickSkin(SkinDef s) {
    if (!_unlocked(s)) {
      buzz(Buzz.heavy);
      _mascot.shake();
      setState(() => _showLockHint = true);
      return;
    }
    setState(() {
      _skin = s.id;
      _showLockHint = false;
    });
    _mascot.jump();
  }

  Future<void> _done() async {
    setState(() => _busy = true);
    if (widget.create) {
      await game.createProfile(
        playerName: _player.text.trim(),
        petName: _pet.text.trim(),
        lookId: 'sun_tuft',
        skin: _skin,
        color: _color,
        hair: _hair,
      );
    } else {
      await game.restyle(skin: _skin, color: _color, hair: _hair);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = game.content;
    final monkey = content.skin('monkey');
    final body = ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (widget.create) ...[
          const Text('Настрой Финика', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.6)),
          const SizedBox(height: 4),
          const Text('Выбери, каким будет твой друг', textAlign: TextAlign.center, style: TextStyle(color: FinniColors.muted, fontSize: 16)),
        ],
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [Color(_color).withValues(alpha: 0.28), FinniColors.bg.withValues(alpha: 0)]),
            ),
            child: MascotView(look: _look(_skin), controller: _mascot, size: 220, semanticsLabel: _petName),
          ),
        ),
        _label('Облик'),
        Row(
          children: [
            for (final s in content.skins)
              Expanded(child: _skinTile(s)),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _showLockHint && monkey != null
              ? Padding(
                  key: const Key('hero.skin.lockHint'),
                  padding: const EdgeInsets.only(top: 10),
                  child: DuoCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_rounded, color: FinniColors.muted, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            content.text('skin.monkey.locked', {'pet': _petName}),
                            style: const TextStyle(fontSize: 14, color: FinniColors.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        _label(_skin == 'monkey' ? 'Цвет · у Мартышки свой' : 'Цвет'),
        Wrap(
          spacing: 7,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [for (final c in content.palette) _swatch(c)],
        ),
        if (_skin == 'finik') ...[
          _label('Причёска'),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              for (final MapEntry(key: id, value: title) in _hairs.entries)
                ChoiceChip(
                  key: Key('hero.hair.$id'),
                  label: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  selected: _hair == id,
                  onSelected: (_) {
                    setState(() => _hair = id);
                    _mascot.jump();
                  },
                ),
            ],
          ),
        ],
        if (widget.create) ...[
          const SizedBox(height: 20),
          _field(const Key('hero.pet'), _pet, 'Имя героя'),
          const SizedBox(height: 10),
          _field(const Key('hero.player'), _player, 'А тебя? Игровое имя'),
          const SizedBox(height: 8),
          const Text('Фамилию и телефон писать не нужно.', textAlign: TextAlign.center, style: TextStyle(color: FinniColors.muted)),
        ],
        const SizedBox(height: 18),
        DuoButton(
          key: const Key('hero.go'),
          label: widget.create ? 'В комнату!' : 'Готово',
          onPressed: _valid && !_busy ? _done : null,
        ),
      ],
    );
    return Scaffold(
      appBar: widget.create ? null : AppBar(title: const Text('Облик')),
      body: SafeArea(top: widget.create, child: body),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
    child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: FinniColors.muted)),
  );

  Widget _skinTile(SkinDef s) {
    final open = _unlocked(s);
    final selected = _skin == s.id;
    return Semantics(
      button: true,
      selected: selected,
      label: open ? s.title : '${s.title}, закрыто',
      child: GestureDetector(
        key: Key('hero.skin.${s.id}'),
        onTap: () => _pickSkin(s),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: FinniColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? FinniColors.primary : Colors.transparent, width: 2),
            boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 3))],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 74,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: open ? 1 : 0.35,
                      child: MascotView(look: _look(s.id, mood: PetMood.steady), size: 74, animated: false, interactive: false),
                    ),
                    if (!open)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: FinniColors.ink, shape: BoxShape.circle),
                        child: const Icon(Icons.lock_rounded, size: 16, color: Colors.white),
                      ),
                  ],
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(s.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: open ? FinniColors.ink : FinniColors.muted)),
              ),
              if (!open)
                const Text('за успехи', style: TextStyle(fontSize: 11, color: FinniColors.muted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _swatch(PaletteColor c) {
    final selected = _color == c.color;
    final disabled = _skin == 'monkey';
    return Semantics(
      button: true,
      selected: selected,
      label: c.title,
      child: GestureDetector(
        key: Key('hero.color.${c.id}'),
        onTap: disabled
            ? null
            : () {
                setState(() => _color = c.color);
                _mascot.jump();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Color(c.color).withValues(alpha: disabled ? 0.35 : 1),
            shape: BoxShape.circle,
            border: Border.all(color: selected ? FinniColors.ink : FinniColors.surface, width: 3),
            boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: selected ? const Icon(Icons.check_rounded, size: 18, color: FinniColors.ink) : null,
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
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: FinniColors.primary, width: 2)),
    ),
  );
}
