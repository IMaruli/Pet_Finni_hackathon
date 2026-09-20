### Task 2: Errors, plan type, catalog item

**Files:**
- Create: `client/lib/economy/economy_error.dart`
- Create: `client/lib/economy/budget_plan.dart`
- Create: `client/lib/economy/catalog_item.dart`
- Test: `client/test/economy/budget_plan_test.dart`

**Interfaces:**
- Consumes: `GameCoins` (factory; not a const constructor — `const GameCoins(10)` is illegal. Use `GameCoins(10)` and non-const `BudgetPlan(...)`. `GameCoins.zero` is const.)
- Produces: `enum EconomyError { insufficientFunds, planExceedsAvailable, noPlan, withdrawNotPending }`; `enum ItemKind { need, want }`; `class CatalogItem { id, kind, price }`; `class BudgetPlan { need, want, save }` with `GameCoins get total`

TDD: write failing test first (budget_plan.dart missing), then add the three files with the implementations below (verbatim except: no `const` on GameCoins(...) / BudgetPlan in tests).

Test:

```dart
import 'package:finni/economy/budget_plan.dart';
import 'package:finni/economy/game_coins.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('total is need plus want plus save', () {
    final plan = BudgetPlan(
      need: GameCoins(10),
      want: GameCoins(5),
      save: GameCoins(3),
    );
    expect(plan.total, GameCoins(18));
  });
}
```

`economy_error.dart`:

```dart
enum EconomyError { insufficientFunds, planExceedsAvailable, noPlan, withdrawNotPending }
```

`catalog_item.dart`:

```dart
import 'game_coins.dart';

enum ItemKind { need, want }

final class CatalogItem {
  const CatalogItem({required this.id, required this.kind, required this.price});
  final String id;
  final ItemKind kind;
  final GameCoins price;
}
```

Note: `const CatalogItem` may be invalid if price cannot be const. If the analyzer forbids const CatalogItem, drop `const` on the constructor.

`budget_plan.dart`:

```dart
import 'game_coins.dart';

final class BudgetPlan {
  const BudgetPlan({required this.need, required this.want, required this.save});
  final GameCoins need;
  final GameCoins want;
  final GameCoins save;
  GameCoins get total => need + want + save;
}
```

If `const BudgetPlan` fails to compile because GameCoins fields aren't const-constructible from callers, drop `const` on BudgetPlan constructor.

Run: `cd client; flutter test test/economy/budget_plan_test.dart` then full `flutter test`.

Commit only new economy files + test:
git add client/lib/economy/economy_error.dart client/lib/economy/budget_plan.dart client/lib/economy/catalog_item.dart client/test/economy/budget_plan_test.dart
message: feat(economy): add BudgetPlan, CatalogItem, error codes

Branch Ivan_DevStand. No push. No git config. Use env identity Ivan / IMaruli@users.noreply.github.com
