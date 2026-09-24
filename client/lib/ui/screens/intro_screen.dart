import 'package:flutter/material.dart';

import '../../economy/economy_state.dart';
import '../mascot/mascot_look.dart';
import '../mascot/mascot_view.dart';
import '../theme.dart';
import '../widgets/duo.dart';

/// Знакомство с тремя типами решений (SA F-008).
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, required this.onDone, this.replay = false});
  final VoidCallback onDone;
  final bool replay;

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _Card {
  const _Card(this.basket, this.text, this.examples, this.mood, this.accessories);
  final Basket basket;
  final String text;
  final String examples;
  final PetMood mood;
  final Set<String> accessories;
}

class _IntroScreenState extends State<IntroScreen> {
  final _page = PageController();
  int _index = 0;

  static const _cards = [
    _Card(Basket.need, 'То, без чего никак. Покупаем в первую очередь.', '🥣 завтрак   💧 вода   🪥 уход', PetMood.steady, {}),
    _Card(Basket.want, 'То, что радует. Можно, если монеты остались.', '🍫 шоколадка   🕶️ очки   🎧 наушники', PetMood.glad, {'glasses'}),
    _Card(Basket.save, 'Монеты в копилку на большую мечту. Копим по чуть-чуть.', '🏠 комната   🐵 облик   🛋️ мебель', PetMood.glad, {'headphones'}),
  ];

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _cards.length - 1) {
      _page.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _cards.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              widget.replay ? 'Подсказка' : 'Привет! Это игра про монеты',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Каждую монету можно отправить в одну из трёх банок',
                textAlign: TextAlign.center,
                style: TextStyle(color: FinniColors.muted),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _page,
                itemCount: _cards.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final c = _cards[i];
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.basket.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: c.basket.color.withValues(alpha: 0.4), width: 3),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${i + 1} из 3', style: const TextStyle(color: FinniColors.muted, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(
                            '${c.basket.emoji} ${c.basket.title}',
                            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: c.basket.color),
                          ),
                          const SizedBox(height: 8),
                          Flexible(
                            child: MascotView(
                              look: MascotLook(
                                color: const Color(0xFFFFCC33),
                                hair: 'tuft',
                                mood: c.mood,
                                stage: 2,
                                accessories: c.accessories,
                              ),
                              size: 200,
                            ),
                          ),
                          Text(c.text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, height: 1.3)),
                          const SizedBox(height: 12),
                          Text(c.examples, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _cards.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.all(4),
                    width: i == _index ? 26 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: i == _index ? FinniColors.primary : FinniColors.line,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: DuoButton(
                  key: const Key('intro.next'),
                  label: last ? (widget.replay ? 'Понятно!' : 'Создать героя') : 'Дальше',
                  onPressed: _next,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
