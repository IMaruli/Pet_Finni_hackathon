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
    // Проще и с вопросом-подсказкой: ребёнок в тесте не понял, что такое банки (F-062).
    _Card(
      Basket.need,
      'Без этого никак: поесть, попить, умыться. Покупаем первым. Спроси себя: без этого сегодня будет плохо?',
      '🥣 завтрак   💧 вода   🪥 умыться',
      PetMood.steady,
      {},
    ),
    _Card(
      Basket.want,
      'Просто хочется: вкусняшка, игрушка, одежда. Можно, если остались монеты. А можно и не брать!',
      '🍦 мороженое   🕶️ очки   🎧 наушники',
      PetMood.glad,
      {'glasses'},
    ),
    _Card(
      Basket.save,
      'Не тратим сейчас, а кладём в копилку на мечту. Копилка — отдельно от кошелька, в магазине её не тратят.',
      '🔭 телескоп   🚲 велосипед   🏠 комната',
      PetMood.glad,
      {'headphones'},
    ),
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
            const SizedBox(height: 16),
            Text(
              widget.replay ? 'Как играть' : 'Привет! Это игра про финансовую грамотность',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.6),
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
                        color: FinniColors.surface,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 20, offset: Offset(0, 8))],
                      ),
                      padding: const EdgeInsets.all(20),
                      // Прокрутка, если текст длинный или системный шрифт крупный (F-062).
                      child: LayoutBuilder(
                        builder: (context, box) => SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: box.maxHeight),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${i + 1} из 3', style: const TextStyle(color: FinniColors.muted, fontSize: 13)),
                                const SizedBox(height: 8),
                                IconTile(c.basket.icon, color: c.basket.color, size: 52),
                                const SizedBox(height: 12),
                                Text(c.basket.title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.7)),
                                const SizedBox(height: 8),
                                MascotView(
                                  look: MascotLook(color: const Color(0xFFFFCC33), hair: 'tuft', mood: c.mood, stage: 2, accessories: c.accessories),
                                  size: box.maxHeight < 520 ? 130 : 180,
                                ),
                                Text(c.text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, height: 1.3)),
                                const SizedBox(height: 12),
                                Text(c.examples, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
                              ],
                            ),
                          ),
                        ),
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
                    decoration: BoxDecoration(color: i == _index ? FinniColors.primary : FinniColors.line, borderRadius: BorderRadius.circular(5)),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: DuoButton(key: const Key('intro.next'), label: last ? (widget.replay ? 'Понятно!' : 'Создать героя') : 'Дальше', onPressed: _next),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
