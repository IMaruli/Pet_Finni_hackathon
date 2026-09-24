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

**Пайплайн:** brainstorming → design spec + SA → writing-plans (одна подсистема) → TDD → проверка.  
См. `.cursor/rules/delivery-workflow.mdc` и `superpowers-workflow.mdc`.
