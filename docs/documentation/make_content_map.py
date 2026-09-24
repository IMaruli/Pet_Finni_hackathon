# -*- coding: utf-8 -*-
"""Карта образовательного контента (ТЗ раздел 5, п. 7) из client/assets/content/lessons.json.
Запуск: python3 docs/documentation/make_content_map.py > docs/documentation/CONTENT_MAP.md"""
import json, os
root = os.path.join(os.path.dirname(__file__), '..', '..', 'client', 'assets', 'content')
d = json.load(open(os.path.join(root, 'lessons.json'), encoding='utf-8'))
topics = {t['id']: t for t in d['topics']}
skill = {
    'needs': 'Различать обязательные и необязательные расходы (компетенция 2)',
    'plan': 'Планировать бюджет: расходы не больше доходов, все монеты по банкам (компетенции 1, 3)',
    'save': 'Ставить цель и регулярно откладывать (компетенция 4)',
    'smart': 'Планировать покупки в ограниченном бюджете, сравнивать цены (компетенция 3)',
    'income': 'Понимать, откуда берутся деньги (компетенция 1)',
    'share': 'Планировать подарки и оценивать свои решения (компетенции 3, 5)',
    'ads': 'Распознавать рекламные уловки, беречь пароли и платежи (компетенции 3, 5)',
}
kind = {'card': 'карточка', 'sort': 'разложи', 'next': 'что дальше', 'order': 'собери правило', 'pairs': 'пары', 'pick': 'выбор'}
def cell(s): return s.replace('|', '/').replace('\n', ' ').replace('{pet}', 'Финни')
def logic(st):
    t = st['type']
    if t == 'sort':
        bins = {b['id']: b['title'] for b in st['bins']}
        groups = {}
        for c in st['cards']: groups.setdefault(bins[c['bin']], []).append(c['text'])
        return '; '.join(f"{k}: {', '.join(v)}" for k, v in groups.items())
    if t == 'next':
        good = [o['text'] for o in st['outcomes'] if o.get('good')]
        return f"{cell(st['situation'])} → {', '.join(good)}"
    if t == 'pick': return f"{cell(st['question'])} → {st['options'][st['answer']]}"
    if t == 'order': return ' '.join(st['tiles'])
    if t == 'pairs': return '; '.join(f"{a} — {b}" for a, b in st['pairs'])
    return None
print('# Карта образовательного контента\n')
print('Сгенерировано из `client/assets/content/lessons.json` скриптом `docs/documentation/make_content_map.py`. '
      'Каждый урок: мысль (карточка) → практика → ситуация с последствием («что дальше») → правило. '
      'После каждого ответа — объяснение, при ошибке — подсказка и «Выбрать снова» / повтор.\n')
print('| № | Тема | Урок | Ожидаемый навык | Шаги | Правильная логика | Объяснение ребёнку |')
print('|---|------|------|-----------------|------|-------------------|--------------------|')
for i, l in enumerate(d['lessons'], 1):
    tp = topics[l['topic']]
    steps = ' → '.join(kind.get(s['type'], s['type']) for s in l['steps'])
    logic_l = [cell(x) for s in l['steps'] if (x := logic(s))]
    why = [cell(s['why']) for s in l['steps'] if s.get('why')]
    print(f"| {i} | {tp['emoji']} {tp['title']} | {l['title']} | {skill.get(l['topic'], '')} | {steps} | {'<br>'.join(logic_l)} | {'<br>'.join(why[:3])} |")
g = json.load(open(os.path.join(root, 'minigames.json'), encoding='utf-8'))
print('\n## Мини-игры\n')
print('| Игра | Навык | Логика | Объём | Объяснение |')
print('|------|-------|--------|-------|------------|')
print(f"| Нужно или хочу? | Различать обязательные и необязательные расходы | Смахнуть карточку в «Нужно» или «Хочу» | {len(g['sortCards'])} карточек | Ошибка объясняется сразу под карточкой, в конце — разбор всех ошибок |")
print(f"| Уложись в бюджет | Покупки в пределах бюджета, сначала нужное | Собрать корзину: всё нужное и не больше бюджета | {len(g['puzzles'])} ситуаций | Итог: сколько потратил, что забыл из нужного |")
print("| Копилка-ловец | Копить и не отвлекаться на соблазны | Ловить монеты, уворачиваться от соблазнов | 1 уровень, товары и соблазны из контента | Итог: сколько накоплено и сколько «съели» соблазны |")
