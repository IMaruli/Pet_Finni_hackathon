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
| F-009 | Дом и комната | [ui/F-009](ui/F-009_HOME_ROOM_SA_SPEC.md) | `ui/screens/home_screen.dart`, `ui/widgets/room_view.dart` | `app_flow_test` |
| F-010 | План: три банки | [ui/F-010](ui/F-010_BUDGET_JARS_SA_SPEC.md) | `ui/screens/plan_screen.dart`, `ui/widgets/jar_view.dart` | `app_flow_test` |
| F-011 | Магазин и гардероб | [ui/F-011](ui/F-011_SHOP_WARDROBE_SA_SPEC.md) | `ui/screens/shop_screen.dart` | `app_flow_test` |
| F-012 | Задания-сцены | [ui/F-012](ui/F-012_QUEST_SCENES_SA_SPEC.md) | `ui/screens/quest_screen.dart` | `app_flow_test` |
| F-013 | Мини-игры | [ui/F-013](ui/F-013_MINI_GAMES_SA_SPEC.md) | `client/lib/game/minigames.dart`, `ui/games/` | `test/game/minigames_test.dart`, `app_flow_test` |
| F-014 | Копилка и цели | [ui/F-014](ui/F-014_SAVINGS_GOALS_SA_SPEC.md) | `ui/screens/savings_screen.dart` | `app_flow_test` |
| F-015 | Ночь: итог дня | [ui/F-015](ui/F-015_NIGHT_SUMMARY_SA_SPEC.md) | `ui/screens/night_screen.dart` | `app_flow_test` |
| F-016 | Взрослым, словарик, оболочка | [ui/F-016](ui/F-016_ADULT_GLOSSARY_APP_SA_SPEC.md) | `ui/app.dart`, `ui/screens/adult_screen.dart` | `app_flow_test` |

**Пайплайн:** brainstorming → design spec + SA → writing-plans (одна подсистема) → TDD → проверка.  
См. `.cursor/rules/delivery-workflow.mdc` и `superpowers-workflow.mdc`.
