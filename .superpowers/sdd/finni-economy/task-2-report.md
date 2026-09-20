# Task 2 Report: Errors, plan type, catalog item

**Branch:** `Ivan_DevStand`  
**Commit:** `92a68a4` — `feat(economy): add BudgetPlan, CatalogItem, error codes`  
**Author:** Ivan \<IMaruli@users.noreply.github.com\>  
**Date:** 2026-09-20  
**Push:** No (per instructions)

## Scope

Added economy domain types consumed by later tasks:

| File | Export |
|------|--------|
| `client/lib/economy/economy_error.dart` | `enum EconomyError { insufficientFunds, planExceedsAvailable, noPlan, withdrawNotPending }` |
| `client/lib/economy/catalog_item.dart` | `enum ItemKind { need, want }`, `final class CatalogItem { id, kind, price }` |
| `client/lib/economy/budget_plan.dart` | `final class BudgetPlan { need, want, save }` with `GameCoins get total` |
| `client/test/economy/budget_plan_test.dart` | TDD test for `BudgetPlan.total` |

## TDD Evidence

### RED — failing test before implementation

Command:

```text
cd client
flutter test test/economy/budget_plan_test.dart
```

Result (exit code 1):

```text
test/economy/budget_plan_test.dart:1:8: Error: Error when reading 'lib/economy/budget_plan.dart': Не удается найти указанный файл
import 'package:finni/economy/budget_plan.dart';
       ^
test/economy/budget_plan_test.dart:7:18: Error: Method not found: 'BudgetPlan'.
    final plan = BudgetPlan(
                 ^^^^^^^^^^
00:00 +0 -1: Some tests failed.
```

Test existed; `budget_plan.dart`, `economy_error.dart`, and `catalog_item.dart` were absent.

### GREEN — implementation added

Created all three lib files per brief (verbatim). `const` kept on `BudgetPlan` and `CatalogItem` constructors — analyzer accepts them because `GameCoins.zero` is const; call sites using `GameCoins(n)` correctly use non-const construction.

Command:

```text
flutter test test/economy/budget_plan_test.dart
```

Result (exit code 0):

```text
00:00 +0: total is need plus want plus save
00:00 +1: All tests passed!
```

### Full suite

Command:

```text
flutter test
```

Result (exit code 0, 4 tests):

```text
00:00 +1: budget_plan_test.dart: total is need plus want plus save
00:00 +2: game_coins_test.dart: adds coins
00:00 +3: game_coins_test.dart: subtract rejects negative result
00:00 +4: game_coins_test.dart: constructor rejects negative value
00:00 +4: All tests passed!
```

## Design notes

- **GameCoins factory:** Tests use `GameCoins(10)` (non-const) and `BudgetPlan(...)` without `const`, per brief ruling.
- **`BudgetPlan.total`:** Implemented as `need + want + save` using existing `GameCoins` `+` operator from Task 1.
- **`EconomyError`:** Enum only; no behavior yet — reserved for Task 3+ wallet/plan validation.
- **`CatalogItem`:** Data holder for catalog entries; no catalog list in this task.

## Files committed

```
client/lib/economy/economy_error.dart
client/lib/economy/budget_plan.dart
client/lib/economy/catalog_item.dart
client/test/economy/budget_plan_test.dart
```

## Concerns / follow-ups

- None blocking. `const CatalogItem` / `const BudgetPlan` compile; if future tasks need `const` instances with non-zero prices, callers must use `GameCoins.zero` or drop `const` at call site.
- `EconomyError` and `CatalogItem` have no dedicated tests in this task (brief specified only `budget_plan_test.dart`).

## Status

**Complete.** Task 2 deliverables implemented, TDD cycle verified, full test suite green, committed locally on `Ivan_DevStand`.
