# Work docs

| Путь | Назначение |
|------|------------|
| [`templates/FEATURE_SA_SPEC_TEMPLATE.md`](../templates/FEATURE_SA_SPEC_TEMPLATE.md) | Шаблон SA |
| [`work/product/TZ_RESEARCH_AND_PLANS.md`](product/TZ_RESEARCH_AND_PLANS.md) | Разведка ТЗ и конкуренты |
| [`work/product/FINNI_CORE_SA_SPEC.md`](product/FINNI_CORE_SA_SPEC.md) | SA ядра MVP (F-001), согласовано |
| [`work/product/2026-09-21_PRODUCT_HANDOFF.md`](product/2026-09-21_PRODUCT_HANDOFF.md) | Сводка решений чата для коллеги (2026-09-21) |
| [`superpowers/specs/2026-09-20-finni-core-design.md`](../superpowers/specs/2026-09-20-finni-core-design.md) | Design Superpowers (architectural) |
| [`superpowers/plans/2026-09-20-finni-program-roadmap.md`](../superpowers/plans/2026-09-20-finni-program-roadmap.md) | Roadmap программы |
| [`superpowers/plans/2026-09-20-finni-economy.md`](../superpowers/plans/2026-09-20-finni-economy.md) | Implementation plan №1: домен экономики (TDD) |
| [`superpowers/specs/2026-09-24-finni-game-ui-design.md`](../superpowers/specs/2026-09-24-finni-game-ui-design.md) | Design игры поверх экономики (Егор): 3D-маскот, мини-игры, экраны |
| [`work/product/FINNI_GAME_UI_SA_SPEC.md`](product/FINNI_GAME_UI_SA_SPEC.md) | SA-эпик F-002: игра, подсистемы 2–5 roadmap |
| [`work/product/TZ_RULES_COMPLIANCE.md`](product/TZ_RULES_COMPLIANCE.md) | Аудит соответствия правилам игры из ТЗ |
| [`business/README.md`](../business/README.md) | **Бизнес-описание механик со скриншотами** |
| `work/{area}/` | Прочие SA и бизнес-доки |

### SA по историям (Егор, `Egor_DevStand`)

| ID | История | SA | Код | Тесты |
|----|---------|----|-----|-------|
| F-003 | Получение цели (`RedeemGoal`) | [economy/F-003](economy/F-003_REDEEM_GOAL_SA_SPEC.md) | `client/lib/economy/` | `test/economy/redeem_goal_test.dart` |
| F-004 | Контент-пакет JSON | [content/F-004](content/F-004_CONTENT_PACK_SA_SPEC.md) | `client/lib/content/`, `client/assets/content/` | `test/content/` |
| F-005 | Профиль и хранение | [store/F-005](store/F-005_PROFILE_STORE_SA_SPEC.md) | `client/lib/store/` | `test/store/` |
| F-006 | Игровой контроллер | [game/F-006](game/F-006_GAME_CONTROLLER_SA_SPEC.md) | `client/lib/game/game_controller.dart` | `test/game/game_controller_test.dart` |
| F-007 | 3D-маскот | [ui/F-007](ui/F-007_MASCOT_3D_SA_SPEC.md) | `client/lib/ui/mascot/` | `test/ui/mascot_test.dart` |
| F-008 | Знакомство и создание героя | [ui/F-008](ui/F-008_ONBOARDING_SA_SPEC.md) | `ui/screens/intro_screen.dart`, `create_hero_screen.dart` | `test/ui/app_flow_test.dart` |
| F-009 | Дом и комната | [ui/F-009](ui/F-009_HOME_ROOM_SA_SPEC.md) | `ui/tabs/home_tab.dart`, `ui/room/room_scene.dart` | `app_flow_test` |
| F-010 | План: три банки | [ui/F-010](ui/F-010_BUDGET_JARS_SA_SPEC.md) | `ui/screens/plan_screen.dart`, `ui/widgets/jar_view.dart` | `app_flow_test` |
| F-011 | Покупка и гардероб (разделы — F-022) | [ui/F-011](ui/F-011_SHOP_WARDROBE_SA_SPEC.md) | `ui/widgets/buy_sheet.dart`, `ui/screens/clothes_screen.dart` | `app_flow_test` |
| F-012 | Задания-сцены (заменено F-025) | [ui/F-012](ui/F-012_QUEST_SCENES_SA_SPEC.md) | — | — |
| F-013 | Мини-игры | [ui/F-013](ui/F-013_MINI_GAMES_SA_SPEC.md) | `client/lib/game/minigames.dart`, `ui/games/` | `test/game/minigames_test.dart`, `app_flow_test` |
| F-014 | Копилка и цели | [ui/F-014](ui/F-014_SAVINGS_GOALS_SA_SPEC.md) | `ui/screens/savings_screen.dart` | `app_flow_test` |
| F-015 | Ночь: итог дня | [ui/F-015](ui/F-015_NIGHT_SUMMARY_SA_SPEC.md) | `ui/screens/night_screen.dart` | `app_flow_test` |
| F-016 | Взрослым, словарик, оболочка | [ui/F-016](ui/F-016_ADULT_GLOSSARY_APP_SA_SPEC.md) | `ui/app.dart`, `ui/screens/adult_screen.dart` | `app_flow_test` |
| F-017 | Редизайн по Figma | [ui/F-017](ui/F-017_UI_REDESIGN_SA_SPEC.md) | `ui/shell/`, `ui/tabs/` | `app_flow_test` |
| F-018 | Дизайн-система v2 | [ui/F-018](ui/F-018_DESIGN_SYSTEM_SA_SPEC.md) | `ui/theme.dart`, `ui/widgets/duo.dart` | `app_flow_test` |
| F-019 | 3D-комнаты | [ui/F-019](ui/F-019_ROOM_3D_SA_SPEC.md) | `ui/room3d/`, `ui/room/room_scene.dart` | `test/ui/room3d_test.dart` |
| F-020 | Желания героя | [ui/F-020](ui/F-020_PET_WISHES_SA_SPEC.md) | `game/pet_wish.dart`, `ui/widgets/pet_speech.dart` | `test/game/pet_wish_test.dart` |
| F-021 | Сначала нужное | [game/F-021](game/F-021_NEEDS_FIRST_SA_SPEC.md) | `game/game_controller.dart`, `ui/tabs/games_tab.dart`, `ui/widgets/buy_sheet.dart` | `game_controller_test`, `app_flow_test` |
| F-022 | Разделы без общего магазина | [ui/F-022](ui/F-022_SECTIONS_SA_SPEC.md) | `ui/screens/category_screen.dart`, `ui/tabs/home_tab.dart`, `ui/shell/main_shell.dart` | `app_flow_test` |
| F-023 | Настройка Финика: скины и цвета | [ui/F-023](ui/F-023_FINIK_STYLE_SA_SPEC.md) | `ui/screens/create_hero_screen.dart`, `ui/mascot/`, `store/snapshot.dart` | `game_controller_test`, `store_test`, `content_test`, `mascot_test`, `app_flow_test` |
| F-024 | План раскладывает все монеты | [game/F-024](game/F-024_PLAN_ALL_COINS_SA_SPEC.md) | `game/game_controller.dart`, `ui/screens/plan_screen.dart` | `game_controller_test` |
| F-025 | Уроки как в Duolingo: 6 игр по рецепту | [ui/F-025](ui/F-025_LESSON_ENGINE_SA_SPEC.md) | `content/lesson_models.dart`, `game/lesson_logic.dart`, `ui/lesson/`, `assets/content/lessons.json` | `lesson_logic_test`, `lesson_test`, `content_test`, `app_flow_test` |
| F-026 | Задания дня и недели | [game/F-026](game/F-026_DAILY_WEEKLY_QUESTS_SA_SPEC.md) | `game/quests.dart`, `ui/tabs/tasks_tab.dart` | `lesson_logic_test`, `game_controller_test` |
| F-027 | Потребности в комнате: миски и неухоженный питомец | [ui/F-027](ui/F-027_NEEDS_IN_ROOM_SA_SPEC.md) | `game/bowls.dart`, `ui/room3d/room_builder.dart`, `ui/mascot/mascot_painter.dart` | `game_controller_test`, `room3d_test`, `mascot_test` |
| F-028 | Время суток в комнате | [ui/F-028](ui/F-028_DAY_TIME_SA_SPEC.md) | `game/pet_wish.dart`, `ui/room3d/room_builder.dart`, `ui/room/room_scene.dart` | `pet_wish_test`, `room3d_test` |
| F-029 | Вещи в комнату, цели-вещи, исправление отрисовки | [ui/F-029](ui/F-029_ROOM_ITEMS_SA_SPEC.md) | `ui/room3d/`, `assets/content/items.json`, `goals.json` | `room3d_test`, `game_controller_test`, `content_test` |
| F-030 | Больше одежды | [ui/F-030](ui/F-030_WARDROBE_SA_SPEC.md) | `ui/mascot/mascot_painter.dart`, `ui/screens/clothes_screen.dart` | `mascot_test` |
| F-031 | Хотелки радуют героя видимо | [ui/F-031](ui/F-031_TREATS_JOY_SA_SPEC.md) | `ui/mascot/mascot_view.dart`, `assets/content/items.json` | `game_controller_test`, `mascot_test` |
| F-032 | Разнообразное нужное по расписанию | [game/F-032](game/F-032_NEEDS_VARIETY_SA_SPEC.md) | `content/game_content.dart` (`needsForDay`), `assets/content/config.json` | `content_test`, `game_controller_test`, `pet_wish_test` |
| F-033 | Мини-игры: пулы, объяснения, копилка | [ui/F-033](ui/F-033_MINIGAMES_VARIETY_SA_SPEC.md) | `game/minigames.dart`, `ui/games/`, `assets/content/minigames.json` | `minigames_test`, `app_flow_test` |
| F-034 | Больше уроков и практики | [ui/F-034](ui/F-034_LESSONS_CONTENT_SA_SPEC.md) | `assets/content/lessons.json` | `content_test`, `lesson_test` |
| F-035 | Один блок уроков в день | [ui/F-035](ui/F-035_LESSON_BLOCK_PER_DAY_SA_SPEC.md) | `game/game_controller.dart`, `ui/tabs/lessons_tab.dart` | `game_controller_test`, `lesson_test` |
| F-036 | Игра по желанию, монеты за задания | [game/F-036](game/F-036_PLAY_OPTIONAL_QUEST_REWARDS_SA_SPEC.md) | `game/pet_wish.dart`, `game/game_controller.dart`, `ui/tabs/tasks_tab.dart` | `game_controller_test`, `pet_wish_test` |
| F-037 | Больше персонажей | [ui/F-037](ui/F-037_MORE_CHARACTERS_SA_SPEC.md) | `ui/mascot/`, `ui/screens/create_hero_screen.dart` | `game_controller_test`, `mascot_test` |
| F-038 | Знакомство с питомцем | [ui/F-038](ui/F-038_PET_GREETING_SA_SPEC.md) | `ui/tabs/home_tab.dart`, `store/snapshot.dart` | `game_controller_test`, `app_flow_test` |
| F-039 | Пузыри нужного над героем | [ui/F-039](ui/F-039_NEED_BUBBLES_SA_SPEC.md) | `ui/widgets/need_bubble.dart`, `ui/room/room_scene.dart`, `ui/tabs/home_tab.dart` | `app_flow_test` |
| F-040 | Копилка на виду на Доме | [ui/F-040](ui/F-040_PIGGY_ON_HOME_SA_SPEC.md) | `ui/tabs/home_tab.dart`, `ui/widgets/piggy.dart` | `app_flow_test` |
| F-041 | Раздел «Образ», переход после цели | [ui/F-041](ui/F-041_LOOK_SECTION_SA_SPEC.md) | `ui/screens/look_screen.dart`, `ui/screens/savings_screen.dart`, `ui/tabs/home_tab.dart` | `app_flow_test`, `savings_goal_test` |
| F-042 | Спокойный первый день, панель разделов | [game/F-042](game/F-042_INTRO_DAY_SA_SPEC.md) | `game/game_controller.dart`, `game/pet_wish.dart`, `ui/tabs/home_tab.dart` | `game_controller_test`, `app_flow_test` |
| F-043 | Мягкий первый день | [game/F-043](game/F-043_SOFT_FIRST_DAY_SA_SPEC.md) | `game/game_controller.dart`, `game/pet_wish.dart` | `game_controller_test`, `app_flow_test` |
| F-044 | Копилка как вклад | [game/F-044](game/F-044_SAVINGS_DEPOSIT_SA_SPEC.md) | `economy/`, `game/game_controller.dart`, `ui/screens/savings_screen.dart` | `economy`, `game_controller_test`, `app_flow_test` |
| F-045 | Вёрстка «Одежды» | [ui/F-045](ui/F-045_CLOTHES_LAYOUT_SA_SPEC.md) | `ui/screens/clothes_screen.dart` | `app_flow_test` |
| F-046 | Перетаскивание в уроках | [ui/F-046](ui/F-046_DRAG_SORT_SA_SPEC.md) | `ui/lesson/lesson_steps.dart` | `lesson_test` |
| F-047 | Фото из зоопарка на виду | [ui/F-047](ui/F-047_ZOO_PHOTO_PLACE_SA_SPEC.md) | `ui/room3d/room_builder.dart` | `room3d_test` |
| F-048 | Комната во весь экран | [ui/F-048](ui/F-048_FULL_SCREEN_ROOM_SA_SPEC.md) | `ui/room3d/room_builder.dart`, `ui/room/room_scene.dart`, `ui/tabs/home_tab.dart` | `room3d_test` |
| F-049 | CI: релизный APK в GitHub Actions | [ops/F-049](ops/F-049_CI_RELEASE_APK_SA_SPEC.md) | `.github/workflows/android-apk.yml`, `android/app/build.gradle.kts` | запуск Actions |
| F-051 | Качество комнаты, повороты героя, места одежды | [ui/F-051](ui/F-051_ROOM_QUALITY_WEAR_SLOTS_SA_SPEC.md) | `ui/room3d/*`, `ui/mascot/mascot_view.dart`, `game/game_controller.dart`, `ui/tabs/home_tab.dart` | `room3d_test`, `game_controller_test`, `content_test` |
| F-052 | Обои в полоску | [ui/F-052](ui/F-052_STRIPED_WALLPAPER_SA_SPEC.md) | `ui/room3d/room_builder.dart` | `room3d_test` |
| F-053 | Релиз 1.0: название, иконка, заставка | [ops/F-053](ops/F-053_RELEASE_1_0_SA_SPEC.md) | `android/app/src/main/*`, `tool/icon/`, `README.md`, `docs/release/` | эмулятор, CI |
| F-054 | Рост учитывает траты по плану | [game/F-054](game/F-054_GROWTH_BY_PLAN_SA_SPEC.md) | `economy/economy_engine.dart`, `ui/screens/night_screen.dart` | `period_pet_test`, `game_controller_test` |
| F-055 | Срок до цели по средней сумме | [game/F-055](game/F-055_GOAL_ETA_AVERAGE_SA_SPEC.md) | `game/game_controller.dart`, `ui/screens/savings_screen.dart` | `game_controller_test` |
| F-056 | Покупки сегодня и итог вчера | [ui/F-056](ui/F-056_HISTORY_TODAY_YESTERDAY_SA_SPEC.md) | `ui/screens/plan_screen.dart`, `ui/tabs/tasks_tab.dart` | `app_flow_test` |
| F-057 | Плашка состояния и цель на Доме | [ui/F-057](ui/F-057_HOME_STATE_PANEL_SA_SPEC.md) | `ui/tabs/home_tab.dart` | `app_flow_test` |
| F-058 | Доступность | [ui/F-058](ui/F-058_ACCESSIBILITY_SA_SPEC.md) | `ui/motion.dart`, `ui/mascot/*`, `ui/widgets/*` | `mascot_test`, `app_flow_test` |
| F-059 | Карточка RuStore | [ops/F-059](ops/F-059_RUSTORE_CARD_SA_SPEC.md) | `docs/release/rustore/` | — |
| F-060 | Документация PDF | [ops/F-060](ops/F-060_DOCUMENTATION_PDF_SA_SPEC.md) | `docs/documentation/` | — |

**Пайплайн:** brainstorming → design spec + SA → writing-plans (одна подсистема) → TDD → проверка.  
См. `.cursor/rules/delivery-workflow.mdc` и `superpowers-workflow.mdc`.
