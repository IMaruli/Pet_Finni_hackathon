# Редизайн интерфейса по макету Figma (Duolingo-стиль) — системная спецификация (SA)

| Поле | Значение |
|------|----------|
| **ID** | F-017 |
| **Назначение** | Новый визуальный язык и навигация: полноэкранная 3D-комната, таб-бар, простые экраны |
| **Репозиторий** | `Pet_Finni_hackathon` |
| **Источник** | Figma «Pet Finni — UI MVP» (страницы Screens, CJM Flow); отзыв Егора 2026-09-24: «как у Duolingo, просто и понятно; комната сзади не 3D и выглядит обрубком» |
| **Статус** | Согласовано Егором 2026-09-24 |
| **Участники** | Егор |
| **Связанные артефакты** | F-007 (маскот не меняется), F-008…F-016 (экраны переезжают в новую навигацию) |

---

## 1. Контекст

Первая версия UI: дом — длинная прокручиваемая страница, комната — карточка в ленте. Отзыв: сложно, не 3D, «обрубок». Макет Figma задаёт другую модель: комната на весь экран за героем, всё остальное — плавающие элементы и вкладки.

## 2. Цель

Ребёнок видит героя в живой объёмной комнате и одну главную кнопку «что делать дальше». Все разделы — в один тап из нижнего таб-бара. Минимум текста, крупные «толстые» кнопки.

## 3. Бизнес-требования

| ID | Требование | Приоритет |
|----|------------|-----------|
| BR-01 | Старт: «Кто заходит?» — Ребёнок / Взрослый (Figma 00) | Must |
| BR-02 | Создание героя в одном экране: имя, облик, «В комнату!» (Figma 01) | Must |
| BR-03 | Дом (Figma 02): комната на весь экран, герой на коврике, верхняя плашка (монеты, имя, стадия), облачко «нужно» над героем, кнопки «Одежда», «Комната», «Спать», карточка следующего шага | Must |
| BR-04 | Таб-бар: Игры · Задания · Дом · Уроки · Магазин (Дом по центру, по умолчанию) | Must |
| BR-05 | Комната рисуется в перспективе (1-точечная): стены, пол с досками к точке схода, окно со светом, коврик-эллипс, тени | Must |
| BR-06 | Вещи в комнате объёмные: ночник, коврик, постер, диван, полка, ТВ, приставка; появляются по мере покупок и целей (Figma RoomState 0–5) | Must |
| BR-07 | Игры (Figma 03): сетка цветных карточек с наградой | Must |
| BR-08 | Задания (Figma 04): «Сегодня» (план, нужное, задание, игра) и «На неделю» (цель, хорошие дни) со статусами | Must |
| BR-09 | Уроки (Figma 05): пройденные сцены можно пересмотреть без монет; словарик | Must |
| BR-10 | Магазин (Figma 06): строки с иконкой, типом и ценой; разделы Нужное / Хочу / Копим | Must |
| BR-11 | Одежда (Figma 07): рамка с героем, шкаф налепок, тап = примерка; не купленные — с ценой | Must |
| BR-12 | Комната (Figma 08): комната во весь экран + лента вещей снизу | Must |
| BR-13 | Кнопки в стиле Duolingo: объём (нижний бортик 4 dp), нажатие «проваливает» кнопку | Must |
| BR-14 | Экраны плана, копилки, задания, ночи, взрослого — на новых компонентах | Must |
| BR-15 | Шрифт — системный, жирные начертания | Should |
| BR-16 | Комната «уютная» (запрос Егора 2026-09-24): лучи света из окна, пылинки в луче (анимация), мягкие тени в углах и под мебелью, стеновые панели, обои, карниз, доски пола разных оттенков, отблеск окна на полу | Must |
| BR-17 | Декор всегда: подвесной светильник, часы на боковой стене, большое растение в углу, растение на подоконнике | Must |
| BR-18 | Ночь: лунный луч, звёзды в окне, тёплое свечение ночника и светильника | Must |
| BR-19 | Анимация — только слой пылинок (`RoomAmbience`), статичная комната не перерисовывается каждый кадр | Must |

## 4. Описание

### 4.1 AS-IS

`HomeScreen` = ListView (комната-карточка, плашки, сетка 6 плиток). Навигация push-экранами.

### 4.2 TO-BE

```
FinniApp
 ├─ RoleScreen ──► IntroScreen ──► CreateHeroScreen   (нет профиля)
 │        └─────► AdultScreen                         (взрослый)
 └─ MainShell (IndexedStack + DuoTabBar)             (есть профиль)
      ├─ GamesTab     ─► SortGame / BudgetGame / CatcherGame / PlanScreen
      ├─ TasksTab     ─► PlanScreen / QuestScreen / ShopScreen / GamesHub / SavingsScreen
      ├─ HomeTab      ─► ClothesScreen / RoomScreen / NightScreen / SavingsScreen
      ├─ LessonsTab   ─► QuestScreen(review) / GlossaryScreen
      └─ ShopTab      ─► BuySheet / SavingsScreen
```

### 4.3 Перспектива комнаты

Точка схода `V = (0.5w, 0.42h)`. Задняя стена — прямоугольник `[0.16w..0.84w] × [0.10h..0.56h]`. Левая/правая стены — трапеции от краёв экрана к краям задней стены; пол — трапеция от низа задней стены к низу экрана; доски — линии из `V` к нижнему краю. Окно — четырёхугольник на левой стене с перспективным сжатием. Свет из окна — полупрозрачный многоугольник на полу. Вещи позиционируются в долях экрана и рисуются с градиентом и мягкой тенью.

### 4.4 Затронутые компоненты

| Слой | Путь |
|------|------|
| Компоненты | `client/lib/ui/widgets/duo.dart` (DuoButton, DuoCard, DuoChip, DuoTabBar, DuoIconButton) |
| Комната | `client/lib/ui/room/room_painter.dart`, `room_scene.dart` |
| Оболочка | `client/lib/ui/shell/main_shell.dart`, `ui/screens/role_screen.dart` |
| Вкладки | `client/lib/ui/tabs/{games,tasks,home,lessons,shop}_tab.dart` |
| Экраны | `ui/screens/clothes_screen.dart`, `room_screen.dart`; рестайл остальных |
| Тесты | `client/test/ui/app_flow_test.dart`, `client/test/ui/room_test.dart` |

## 5. Сценарии

| UC | Актор | Цель | Предусловия |
|----|-------|------|-------------|
| UC-01 | Ребёнок | Войти, создать героя, попасть в комнату | Нет профиля |
| UC-02 | Ребёнок | Понять следующий шаг с одного взгляда | Дом |
| UC-03 | Ребёнок | Переключать разделы таб-баром | Профиль есть |
| UC-04 | Ребёнок | Примерить налепку | Одежда |
| UC-05 | Ребёнок | Увидеть купленную вещь в комнате | Покупка room-товара или цель |
| UC-06 | Ребёнок | Пересмотреть пройденную сцену | Уроки |
| UC-07 | Взрослый | Войти со стартового экрана | — |

## 6. Матрица исходов

### Success (S)

| ID | Условие | Результат |
|----|---------|-----------|
| S-01 | Куплен ночник | Ночник светится в комнате; на Доме и в «Комнате» |
| S-02 | Цель «мебель: ТВ» | ТВ на тумбе в комнате |
| S-03 | rooms = 2 | На Доме переключатель «Спальня / Игровая», у игровой другая стена и декор |
| S-04 | Тап по «толстой» кнопке | Кнопка опускается на 4 dp, вибрация |
| S-05 | Урок пересмотрен | Объяснения видны, монеты не начисляются |

### Exception (E)

| ID | Условие | Поведение |
|----|---------|-----------|
| E-01 | Экран 360×640 | Комната и плашки помещаются, без переполнений |
| E-02 | Взрослый без профиля | «Профиля ещё нет», кнопка «Назад» |

## 7. NFR

| ID | Категория | Требование |
|----|-----------|------------|
| NFR-01 | UX | Одна главная кнопка на экран, тач ≥ 48 dp, текст ≥ 16 sp |
| NFR-02 | Perf | Комната — `RepaintBoundary`, перерисовка только при смене инвентаря/ночи |
| NFR-03 | Legal | Всё рисуется кодом; ассеты Figma — только референс |

## 8. API и контракты

```dart
// duo.dart
class DuoButton extends StatefulWidget {
  const DuoButton({required String label, required VoidCallback? onPressed, Color color, Color? textColor,
    String? emoji, bool expand = true, double height = 56, Key? key});
}
class DuoCard extends StatelessWidget { const DuoCard({required Widget child, Color? color, VoidCallback? onTap, EdgeInsets padding}); }
class DuoChip extends StatelessWidget { const DuoChip({required String text, Color color, String? emoji}); }
class DuoIconButton extends StatelessWidget { const DuoIconButton({required String emoji, required String label, required VoidCallback onTap}); }
class DuoTabBar extends StatelessWidget { const DuoTabBar({required int index, required ValueChanged<int> onTap}); }

// room
class RoomScene extends StatelessWidget {
  const RoomScene({required Inventory inventory, required int room, bool night = false, Widget? hero, double heroSize});
}
final class RoomPainter extends CustomPainter { RoomPainter({required Set<String> owned, String? furniture, required int room, bool night, double feetY}); }
class RoomAmbience extends StatefulWidget { const RoomAmbience({required double feetY, bool night, bool animated = true}); } // пылинки в луче
Offset heroAnchor(Size size); // точка «ног» героя на коврике

// shell
class MainShell extends StatefulWidget { const MainShell({required GameController game}); }
class RoleScreen extends StatelessWidget { const RoleScreen({required VoidCallback onChild, required VoidCallback onAdult}); }
class ClothesScreen extends StatelessWidget { const ClothesScreen({required GameController game}); }
class RoomScreen extends StatelessWidget { const RoomScreen({required GameController game}); }
class QuestScreen { const QuestScreen({required GameController game, Quest? review}); } // review: без монет
```

Ключи тестов: `role.child`, `role.adult`, `nav.{games,tasks,home,lessons,shop}`, `home.next`, `home.clothes`, `home.room`, `home.sleep`, `home.help`, `home.savings`, `tasks.{plan,quest,needs,game,goal}`, `lessons.<questId>`, `shopRow.<itemId>`, `clothes.<itemId>`.

## 9. Зависимости

F-006, F-007.

## 10. Открытые вопросы

| # | Вопрос | Владелец | Статус |
|---|--------|----------|--------|
| 1 | Шрифт Nunito (OFL) вместо системного? | Егор | Нужно скачать файл шрифта — по запросу |
| 2 | Использовать рендеры комнат из Figma вместо кода? | Егор | Нет: референс (2026-09-24) |
