# Finni economy domain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Чистый Dart-домен игровых монет: план трёх корзин, покупки need/want, копилка с двойным снятием, период план/факт, настроение и стадии питомца без UI.

**Architecture:** Неизменяемый `EconomyState` и функция `EconomyEngine.apply(state, command) → EconomyResult`. Нет `material.dart`. Каталог товаров в команде покупки (id, тип, цена) — JSON-контент в следующем плане.

**Tech Stack:** Flutter/Dart в каталоге `client/` (пакет `finni`). Тесты: `flutter test`.

**Spec:** `docs/superpowers/specs/2026-09-20-finni-core-design.md`, SA `docs/work/product/FINNI_CORE_SA_SPEC.md`

## Global Constraints

- Только `GameCoins` (целые ≥ 0); ничего вне игровых монет.
- Ветка исполнения: `Ivan_DevStand` (создать от актуального `main` в setup, не `main`).
- Коммиты по шагам — да, если Иван выбрал исполнение этого плана. Push — нет, пока отдельно не сказал.
- Нет продакшн-кода без красного теста.
- Package Android: `ru.petfinni.finni` (уникальное имя, не финансовый бренд).
- Пороги стадии: 1 с старта; 2 после 2 закрытых периодов с fully met need **и** save>0; 3 после 4 таких периодов.
- Настроение: `glad` если need покрыт и факт need+want+save в пределах ±20% суммы плана (если план есть); `uneasy` если план need > 0 и spentNeed < plan.need; иначе `steady`. Нет порчи от «прошедших часов».
- Покупка без подтверждённого плана → `EconomyError.noPlan`, состояние то же.
- Повтор `BuyItem.commandId` → успех, состояние не меняется (анти двойной тап).

## Review Focus

- Покупка price == available → успех, available == 0 (Task 4).
- Повтор того же commandId → одно списание (Task 4).
- Снятие копилки без ConfirmWithdraw → savings не меняются (Task 5).
- Неуспешная покупка не обнуляет petStage и savings (Task 4 + 6).
- ClosePeriod без покупок need при plan.need > 0 → uneasy, стадия не прыгает вверх незаслуженно (Task 6).

## File map

- Create: `client/` — Flutter project
- Create: `client/lib/economy/game_coins.dart` — целочисленные монеты
- Create: `client/lib/economy/catalog_item.dart` — need | want + price
- Create: `client/lib/economy/budget_plan.dart` — три корзины
- Create: `client/lib/economy/economy_error.dart` — коды отказа
- Create: `client/lib/economy/commands.dart` — команды
- Create: `client/lib/economy/economy_state.dart` — снимок
- Create: `client/lib/economy/economy_result.dart`
- Create: `client/lib/economy/economy_engine.dart` — apply
- Create: `client/lib/economy/economy.dart` — barrel
- Test: `client/test/economy/*.dart`
- Не трогать UI за пределы дефолтного `main.dart` из `flutter create`

---

### Task 1: Flutter package + GameCoins

**Files:**
- Create: `client/pubspec.yaml` (через `flutter create`)
- Create: `client/lib/economy/game_coins.dart`
- Test: `client/test/economy/game_coins_test.dart`

**Interfaces:**
- Consumes: none
- Produces: `class GameCoins` with `int value`, `+`, `-` (throw `ArgumentError` if result < 0), `<=`, `>=`, `==`, `zero`

- [ ] **Step 1: Write the failing test**

Create `client/test/economy/game_coins_test.dart` (после create в step 3, если каталога нет — сначала step 3 scaffolding, затем вернись: TDD требует теста до `game_coins.dart`. Порядок: scaffolding без economy-кода → тест → красный → реализация).

```dart
import 'package:finni/economy/game_coins.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adds coins', () {
    expect(GameCoins(2) + GameCoins(3), GameCoins(5));
  });

  test('subtract rejects negative result', () {
    expect(() => GameCoins(1) - GameCoins(2), throwsArgumentError);
  });

  test('constructor rejects negative value', () {
    expect(() => GameCoins(-1), throwsA(isA<AssertionError>()));
  });
}
```

- [ ] **Step 2: Scaffold Flutter app without economy implementation**

```bash
cd "D:\Работа\Pet_Finni_hackathon"
flutter create --org ru.petfinni --project-name finni --platforms android client
```

Expected: `client/pubspec.yaml` exists, `name: finni`.

Add to `client/pubspec.yaml` under flutter (if missing, default is fine). Do not write `lib/economy/game_coins.dart` yet.

Put the test file in place. Fix import path: `package:finni/economy/game_coins.dart`.

- [ ] **Step 3: Run test to verify it fails**

```bash
cd client
flutter test test/economy/game_coins_test.dart
```

Expected: FAIL compiling or loading — `game_coins.dart` not found.

- [ ] **Step 4: Write minimal GameCoins**

`client/lib/economy/game_coins.dart`:

```dart
final class GameCoins {
  const GameCoins(this.value) : assert(value >= 0);

  static const zero = GameCoins(0);

  final int value;

  GameCoins operator +(GameCoins other) => GameCoins(value + other.value);

  GameCoins operator -(GameCoins other) {
    final next = value - other.value;
    if (next < 0) {
      throw ArgumentError.value(other.value, 'other', 'result would be negative');
    }
    return GameCoins(next);
  }

  bool operator <=(GameCoins other) => value <= other.value;
  bool operator >=(GameCoins other) => value >= other.value;

  @override
  bool operator ==(Object other) => other is GameCoins && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'GameCoins($value)';
}
```

- [ ] **Step 5: Run tests and commit**

```bash
cd client
flutter test test/economy/game_coins_test.dart
```

Expected: PASS all 3.

```bash
git add client
git commit -m "feat(economy): add GameCoins with non-negative arithmetic"
```

(Коммит только при выбранном исполнении плана.)

---

### Task 2: Errors, plan type, catalog item

**Files:**
- Create: `client/lib/economy/economy_error.dart`
- Create: `client/lib/economy/budget_plan.dart`
- Create: `client/lib/economy/catalog_item.dart`
- Test: `client/test/economy/budget_plan_test.dart`

**Interfaces:**
- Consumes: `GameCoins`
- Produces: `enum EconomyError { insufficientFunds, planExceedsAvailable, noPlan, withdrawNotPending }`; `enum ItemKind { need, want }`; `class CatalogItem { id, kind, price }`; `class BudgetPlan { need, want, save }` with `GameCoins get total`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:finni/economy/budget_plan.dart';
import 'package:finni/economy/game_coins.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('total is need plus want plus save', () {
    const plan = BudgetPlan(
      need: GameCoins(10),
      want: GameCoins(5),
      save: GameCoins(3),
    );
    expect(plan.total, const GameCoins(18));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd client
flutter test test/economy/budget_plan_test.dart
```

Expected: FAIL — `budget_plan.dart` missing.

- [ ] **Step 3: Minimal types**

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

- [ ] **Step 4: Run test to verify it passes**

```bash
cd client
flutter test test/economy/budget_plan_test.dart
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add client/lib/economy client/test/economy/budget_plan_test.dart
git commit -m "feat(economy): add BudgetPlan, CatalogItem, error codes"
```

---

### Task 3: State, commands, Credit

**Files:**
- Create: `client/lib/economy/commands.dart`
- Create: `client/lib/economy/economy_state.dart`
- Create: `client/lib/economy/economy_result.dart`
- Create: `client/lib/economy/economy_engine.dart`
- Create: `client/lib/economy/economy.dart`
- Test: `client/test/economy/credit_test.dart`

**Interfaces:**
- Consumes: types from Tasks 1–2
- Produces: `EconomyState.empty()`, `Credit(amount, sourceId)`, `EconomyEngine.apply`, `EconomyResult(state, explanationIds, error)`; credit with empty sourceId still allowed but explanation `exp.credit`; available increases; sourceId stored on lastCreditSourceId for tests

- [ ] **Step 1: Write the failing test**

```dart
import 'package:finni/economy/commands.dart';
import 'package:finni/economy/economy_engine.dart';
import 'package:finni/economy/economy_state.dart';
import 'package:finni/economy/game_coins.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('credit increases available and records source', () {
    const engine = EconomyEngine();
    final result = engine.apply(EconomyState.empty(), const Credit(GameCoins(50), 'starter'));
    expect(result.error, isNull);
    expect(result.state.available, const GameCoins(50));
    expect(result.state.lastCreditSourceId, 'starter');
    expect(result.explanationIds, ['exp.credit']);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd client
flutter test test/economy/credit_test.dart
```

Expected: FAIL missing libraries.

- [ ] **Step 3: Minimal apply for Credit only**

`commands.dart` — sealed commands; for this task only `Credit` needed, but add empty stubs of others as sealed subclasses so later tasks don't rename (YAGNI vs type consistency: define all command classes now with fields, engine can `throw UnimplementedError` except Credit).

```dart
import 'budget_plan.dart';
import 'catalog_item.dart';
import 'game_coins.dart';

sealed class EconomyCommand {
  const EconomyCommand();
}

final class Credit extends EconomyCommand {
  const Credit(this.amount, this.sourceId);
  final GameCoins amount;
  final String sourceId;
}

final class ConfirmPlan extends EconomyCommand {
  const ConfirmPlan(this.plan);
  final BudgetPlan plan;
}

final class BuyItem extends EconomyCommand {
  const BuyItem({required this.commandId, required this.item});
  final String commandId;
  final CatalogItem item;
}

final class TransferToSavings extends EconomyCommand {
  const TransferToSavings(this.amount);
  final GameCoins amount;
}

final class RequestWithdraw extends EconomyCommand {
  const RequestWithdraw(this.amount);
  final GameCoins amount;
}

final class ConfirmWithdraw extends EconomyCommand {
  const ConfirmWithdraw();
}

final class ClosePeriod extends EconomyCommand {
  const ClosePeriod();
}
```

`economy_state.dart` — include fields later tasks need now so we don't rename:

```dart
import 'budget_plan.dart';
import 'game_coins.dart';

enum PetMood { steady, glad, uneasy }

final class EconomyState {
  const EconomyState({
    required this.available,
    required this.savings,
    required this.plan,
    required this.spentNeed,
    required this.spentWant,
    required this.savedThisPeriod,
    required this.petMood,
    required this.petStage,
    required this.goodPeriods,
    required this.processedBuyIds,
    required this.pendingWithdraw,
    required this.lastCreditSourceId,
  });

  factory EconomyState.empty() => const EconomyState(
        available: GameCoins.zero,
        savings: GameCoins.zero,
        plan: null,
        spentNeed: GameCoins.zero,
        spentWant: GameCoins.zero,
        savedThisPeriod: GameCoins.zero,
        petMood: PetMood.steady,
        petStage: 1,
        goodPeriods: 0,
        processedBuyIds: [],
        pendingWithdraw: null,
        lastCreditSourceId: null,
      );

  final GameCoins available;
  final GameCoins savings;
  final BudgetPlan? plan;
  final GameCoins spentNeed;
  final GameCoins spentWant;
  final GameCoins savedThisPeriod;
  final PetMood petMood;
  final int petStage;
  final int goodPeriods;
  final List<String> processedBuyIds;
  final GameCoins? pendingWithdraw;
  final String? lastCreditSourceId;

  EconomyState copyWith({
    GameCoins? available,
    GameCoins? savings,
    BudgetPlan? plan,
    bool clearPlan = false,
    GameCoins? spentNeed,
    GameCoins? spentWant,
    GameCoins? savedThisPeriod,
    PetMood? petMood,
    int? petStage,
    int? goodPeriods,
    List<String>? processedBuyIds,
    GameCoins? pendingWithdraw,
    bool clearPendingWithdraw = false,
    String? lastCreditSourceId,
  }) {
    return EconomyState(
      available: available ?? this.available,
      savings: savings ?? this.savings,
      plan: clearPlan ? null : (plan ?? this.plan),
      spentNeed: spentNeed ?? this.spentNeed,
      spentWant: spentWant ?? this.spentWant,
      savedThisPeriod: savedThisPeriod ?? this.savedThisPeriod,
      petMood: petMood ?? this.petMood,
      petStage: petStage ?? this.petStage,
      goodPeriods: goodPeriods ?? this.goodPeriods,
      processedBuyIds: processedBuyIds ?? this.processedBuyIds,
      pendingWithdraw: clearPendingWithdraw ? null : (pendingWithdraw ?? this.pendingWithdraw),
      lastCreditSourceId: lastCreditSourceId ?? this.lastCreditSourceId,
    );
  }
}
```

`economy_result.dart`:

```dart
import 'economy_error.dart';
import 'economy_state.dart';

final class EconomyResult {
  const EconomyResult({required this.state, required this.explanationIds, this.error});
  final EconomyState state;
  final List<String> explanationIds;
  final EconomyError? error;
}
```

`economy_engine.dart` — Credit only; other commands return `UnimplementedError` until later tasks (tests don't call them yet).

```dart
import 'commands.dart';
import 'economy_result.dart';
import 'economy_state.dart';

final class EconomyEngine {
  const EconomyEngine();

  EconomyResult apply(EconomyState state, EconomyCommand command) {
    switch (command) {
      case Credit(:final amount, :final sourceId):
        return EconomyResult(
          state: state.copyWith(
            available: state.available + amount,
            lastCreditSourceId: sourceId,
          ),
          explanationIds: const ['exp.credit'],
        );
      default:
        throw UnimplementedError(command.runtimeType.toString());
    }
  }
}
```

`economy.dart` barrel exports all economy files.

- [ ] **Step 4: Run test**

```bash
cd client
flutter test test/economy/credit_test.dart
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add client/lib/economy client/test/economy/credit_test.dart
git commit -m "feat(economy): credit command increases available with source"
```

---

### Task 4: ConfirmPlan + BuyItem (need/want, noPlan, insufficient, exact, duplicate id)

**Files:**
- Modify: `client/lib/economy/economy_engine.dart`
- Test: `client/test/economy/plan_and_buy_test.dart`

**Interfaces:**
- Consumes: `ConfirmPlan`, `BuyItem`, `EconomyEngine.apply`
- Produces: same `apply`; on failure `error` set, **same state instance fields equal to input** (available/savings/stage unchanged)

- [ ] **Step 1: Write the failing test**

```dart
import 'package:finni/economy/budget_plan.dart';
import 'package:finni/economy/catalog_item.dart';
import 'package:finni/economy/commands.dart';
import 'package:finni/economy/economy_engine.dart';
import 'package:finni/economy/economy_error.dart';
import 'package:finni/economy/economy_state.dart';
import 'package:finni/economy/game_coins.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = EconomyEngine();

  EconomyState credited() => engine
      .apply(EconomyState.empty(), const Credit(GameCoins(50), 'starter'))
      .state;

  test('plan exceeding available is rejected', () {
    final start = credited();
    final result = engine.apply(
      start,
      const ConfirmPlan(BudgetPlan(need: GameCoins(40), want: GameCoins(10), save: GameCoins(1))),
    );
    expect(result.error, EconomyError.planExceedsAvailable);
    expect(result.state.available, start.available);
    expect(result.state.plan, isNull);
  });

  test('buy without plan is rejected', () {
    final start = credited();
    final result = engine.apply(
      start,
      const BuyItem(
        commandId: 'b1',
        item: CatalogItem(id: 'food', kind: ItemKind.need, price: GameCoins(10)),
      ),
    );
    expect(result.error, EconomyError.noPlan);
    expect(result.state.available, const GameCoins(50));
  });

  test('need and want purchases debit and record actuals', () {
    var state = credited();
    state = engine
        .apply(state, const ConfirmPlan(BudgetPlan(need: GameCoins(20), want: GameCoins(10), save: GameCoins(5))))
        .state;
    state = engine
        .apply(
          state,
          const BuyItem(
            commandId: 'n1',
            item: CatalogItem(id: 'food', kind: ItemKind.need, price: GameCoins(20)),
          ),
        )
        .state;
    final want = engine.apply(
      state,
      const BuyItem(
        commandId: 'w1',
        item: CatalogItem(id: 'toy', kind: ItemKind.want, price: GameCoins(10)),
      ),
    );
    expect(want.error, isNull);
    expect(want.state.available, const GameCoins(20));
    expect(want.state.spentNeed, const GameCoins(20));
    expect(want.state.spentWant, const GameCoins(10));
    expect(want.explanationIds, ['exp.buy']);
  });

  test('buy equal to entire available leaves zero', () {
    var state = credited();
    state = engine
        .apply(state, const ConfirmPlan(BudgetPlan(need: GameCoins(50), want: GameCoins.zero, save: GameCoins.zero)))
        .state;
    final result = engine.apply(
      state,
      const BuyItem(
        commandId: 'all',
        item: CatalogItem(id: 'food', kind: ItemKind.need, price: GameCoins(50)),
      ),
    );
    expect(result.error, isNull);
    expect(result.state.available, GameCoins.zero);
  });

  test('insufficient funds does not debit or reset stage', () {
    var state = credited();
    state = engine
        .apply(state, const ConfirmPlan(BudgetPlan(need: GameCoins(10), want: GameCoins.zero, save: GameCoins.zero)))
        .state;
    final result = engine.apply(
      state,
      const BuyItem(
        commandId: 'big',
        item: CatalogItem(id: 'castle', kind: ItemKind.want, price: GameCoins(51)),
      ),
    );
    expect(result.error, EconomyError.insufficientFunds);
    expect(result.state.available, const GameCoins(50));
    expect(result.state.petStage, 1);
    expect(result.explanationIds, ['exp.insufficient', 'exp.recover']);
  });

  test('duplicate buy commandId does not debit twice', () {
    var state = credited();
    state = engine
        .apply(state, const ConfirmPlan(BudgetPlan(need: GameCoins(10), want: GameCoins.zero, save: GameCoins.zero)))
        .state;
    const buy = BuyItem(
      commandId: 'dup',
      item: CatalogItem(id: 'food', kind: ItemKind.need, price: GameCoins(10)),
    );
    state = engine.apply(state, buy).state;
    final again = engine.apply(state, buy);
    expect(again.error, isNull);
    expect(again.state.available, const GameCoins(40));
    expect(again.state.spentNeed, const GameCoins(10));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd client
flutter test test/economy/plan_and_buy_test.dart
```

Expected: FAIL — `UnimplementedError` on ConfirmPlan/BuyItem.

- [ ] **Step 3: Implement ConfirmPlan and BuyItem in apply**

Replace `default: throw` with cases:

- `ConfirmPlan`: if `plan.total > state.available` → error `planExceedsAvailable`, explanations `['exp.plan_too_big']`, state unchanged. Else copyWith plan, explanations `['exp.plan_ok']`.
- `BuyItem`: if `commandId` in `processedBuyIds` → success, same numbers, explanations `['exp.buy_repeat']`. If `state.plan == null` → `noPlan`, `['exp.need_plan']`. If `item.price > available` → `insufficientFunds`, `['exp.insufficient', 'exp.recover']`. Else debit available, add price to spentNeed or spentWant, append commandId, `['exp.buy']`.

Do not implement savings/close yet.

- [ ] **Step 4: Run test**

```bash
cd client
flutter test test/economy/plan_and_buy_test.dart
```

Expected: PASS all tests in file. Then:

```bash
cd client
flutter test
```

Expected: whole suite green.

- [ ] **Step 5: Commit**

```bash
git add client/lib/economy/economy_engine.dart client/test/economy/plan_and_buy_test.dart
git commit -m "feat(economy): confirm budget plan and idempotent purchases"
```

---

### Task 5: Savings transfer and two-step withdraw

**Files:**
- Modify: `client/lib/economy/economy_engine.dart`
- Test: `client/test/economy/savings_test.dart`

**Interfaces:**
- Consumes: `TransferToSavings`, `RequestWithdraw`, `ConfirmWithdraw`
- Produces: savings vs available; `withdrawNotPending` if confirm without request

- [ ] **Step 1: Write the failing test**

```dart
import 'package:finni/economy/budget_plan.dart';
import 'package:finni/economy/commands.dart';
import 'package:finni/economy/economy_engine.dart';
import 'package:finni/economy/economy_error.dart';
import 'package:finni/economy/economy_state.dart';
import 'package:finni/economy/game_coins.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = EconomyEngine();

  EconomyState ready() {
    var s = engine.apply(EconomyState.empty(), const Credit(GameCoins(50), 'starter')).state;
    s = engine
        .apply(s, const ConfirmPlan(BudgetPlan(need: GameCoins(10), want: GameCoins.zero, save: GameCoins(20))))
        .state;
    return s;
  }

  test('transfer moves coins to savings', () {
    final result = engine.apply(ready(), const TransferToSavings(GameCoins(20)));
    expect(result.error, isNull);
    expect(result.state.available, const GameCoins(30));
    expect(result.state.savings, const GameCoins(20));
    expect(result.state.savedThisPeriod, const GameCoins(20));
    expect(result.explanationIds, ['exp.save']);
  });

  test('request withdraw does not debit until confirm', () {
    var s = engine.apply(ready(), const TransferToSavings(GameCoins(20))).state;
    final requested = engine.apply(s, const RequestWithdraw(GameCoins(5)));
    expect(requested.state.savings, const GameCoins(20));
    expect(requested.state.pendingWithdraw, const GameCoins(5));
    expect(requested.explanationIds, ['exp.withdraw_preview']);
    final confirmed = engine.apply(requested.state, const ConfirmWithdraw());
    expect(confirmed.state.savings, const GameCoins(15));
    expect(confirmed.state.available, const GameCoins(35));
    expect(confirmed.state.pendingWithdraw, isNull);
    expect(confirmed.explanationIds, ['exp.withdraw_done']);
  });

  test('confirm withdraw without request is rejected', () {
    final start = ready();
    final result = engine.apply(start, const ConfirmWithdraw());
    expect(result.error, EconomyError.withdrawNotPending);
    expect(result.state.savings, start.savings);
  });

  test('withdraw more than savings is insufficient and not pending', () {
    var s = engine.apply(ready(), const TransferToSavings(GameCoins(20))).state;
    final result = engine.apply(s, const RequestWithdraw(GameCoins(21)));
    expect(result.error, EconomyError.insufficientFunds);
    expect(result.state.pendingWithdraw, isNull);
    expect(result.state.savings, const GameCoins(20));
  });
}
```

- [ ] **Step 2: Run — expect FAIL UnimplementedError**

```bash
cd client
flutter test test/economy/savings_test.dart
```

- [ ] **Step 3: Implement transfer/withdraw**

- Transfer: if amount > available → insufficientFunds; else move to savings, add to savedThisPeriod, `exp.save`.
- RequestWithdraw: if amount > savings → insufficientFunds; else set pendingWithdraw, do not change savings yet, `exp.withdraw_preview`.
- ConfirmWithdraw: if pendingWithdraw == null → withdrawNotPending, `exp.withdraw_need_confirm`; else savings -= pending, available += pending, clear pending, `exp.withdraw_done`.

- [ ] **Step 4: flutter test file then full suite — PASS**

- [ ] **Step 5: Commit** `feat(economy): savings transfer and confirmed withdraw`

---

### Task 6: ClosePeriod, mood, stages, failed buy keeps progress

**Files:**
- Modify: `client/lib/economy/economy_engine.dart` (add `_mood` / `_stageAfterClose`)
- Test: `client/test/economy/period_pet_test.dart`

**Interfaces:**
- Consumes: `ClosePeriod`
- Produces: increments `goodPeriods` when `spentNeed >= plan.need` (plan non-null; if plan.need is 0, treat need as met) **and** `savedThisPeriod > 0`; `petStage` 2 if goodPeriods >= 2, 3 if >= 4, else 1 (never decrease); resets spentNeed/spentWant/savedThisPeriod/plan/processedBuyIds/pendingWithdraw for next period; keeps available, savings, goodPeriods, petStage; mood as Global Constraints; explanations `['exp.period_closed']` plus `['exp.mood']`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:finni/economy/budget_plan.dart';
import 'package:finni/economy/catalog_item.dart';
import 'package:finni/economy/commands.dart';
import 'package:finni/economy/economy_engine.dart';
import 'package:finni/economy/economy_state.dart';
import 'package:finni/economy/game_coins.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = EconomyEngine();

  test('uneasy when need unmet after close; stage stays 1; savings kept', () {
    var s = engine.apply(EconomyState.empty(), const Credit(GameCoins(50), 'starter')).state;
    s = engine
        .apply(s, const ConfirmPlan(BudgetPlan(need: GameCoins(10), want: GameCoins.zero, save: GameCoins.zero)))
        .state;
    s = engine.apply(s, const TransferToSavings(GameCoins(5))).state;
    final closed = engine.apply(s, const ClosePeriod());
    expect(closed.state.petMood, PetMood.uneasy);
    expect(closed.state.petStage, 1);
    expect(closed.state.savings, const GameCoins(5));
    expect(closed.state.plan, isNull);
    expect(closed.state.spentNeed, GameCoins.zero);
  });

  test('two good periods raise stage to 2', () {
    var s = EconomyState.empty();
    for (var i = 0; i < 2; i++) {
      s = engine.apply(s, const Credit(GameCoins(30), 'job')).state;
      s = engine
          .apply(s, const ConfirmPlan(BudgetPlan(need: GameCoins(10), want: GameCoins.zero, save: GameCoins(5))))
          .state;
      s = engine
          .apply(
            s,
            BuyItem(
              commandId: 'n$i',
              item: const CatalogItem(id: 'food', kind: ItemKind.need, price: GameCoins(10)),
            ),
          )
          .state;
      s = engine.apply(s, const TransferToSavings(GameCoins(5))).state;
      s = engine.apply(s, const ClosePeriod()).state;
    }
    expect(s.petStage, 2);
    expect(s.goodPeriods, 2);
    expect(s.petMood, PetMood.glad);
  });

  test('failed buy does not reset stage or savings', () {
    var s = EconomyState.empty();
    for (var i = 0; i < 2; i++) {
      s = engine.apply(s, const Credit(GameCoins(30), 'job')).state;
      s = engine
          .apply(s, const ConfirmPlan(BudgetPlan(need: GameCoins(10), want: GameCoins.zero, save: GameCoins(5))))
          .state;
      s = engine
          .apply(
            s,
            BuyItem(
              commandId: 'keep$i',
              item: const CatalogItem(id: 'food', kind: ItemKind.need, price: GameCoins(10)),
            ),
          )
          .state;
      s = engine.apply(s, const TransferToSavings(GameCoins(5))).state;
      s = engine.apply(s, const ClosePeriod()).state;
    }
    expect(s.petStage, 2);
    final savingsBefore = s.savings;
    s = engine.apply(s, const Credit(GameCoins(10), 'job')).state;
    s = engine
        .apply(s, const ConfirmPlan(BudgetPlan(need: GameCoins(1), want: GameCoins.zero, save: GameCoins.zero)))
        .state;
    final failed = engine.apply(
      s,
      const BuyItem(
        commandId: 'x',
        item: CatalogItem(id: 'yacht', kind: ItemKind.want, price: GameCoins(999)),
      ),
    );
    expect(failed.state.petStage, 2);
    expect(failed.state.savings, savingsBefore);
  });
}
```

Note: третий тест поднимает стадию только через ClosePeriod, без copyWith.

- [ ] **Step 2: FAIL UnimplementedError ClosePeriod**

- [ ] **Step 3: Implement ClosePeriod + mood helper used after buy/transfer/close**

`_needMet(state)`: plan == null → false for close goodness; for mood after close use spent vs **old** plan before clear.

Algorithm ClosePeriod:
1. If plan == null, still close: mood steady, reset period fields, exp.period_closed (no goodPeriods++).
2. needMet = spentNeed >= plan.need
3. saved = savedThisPeriod.value > 0
4. good = needMet && saved; newGood = goodPeriods + (good ? 1 : 0)
5. stage = newGood >= 4 ? 3 : newGood >= 2 ? 2 : max(current petStage, 1) — actually never decrease: `stage = max(state.petStage, computed)`
6. mood from **pre-reset** spent/plan as Global Constraints
7. Reset plan, spent*, savedThisPeriod, processedBuyIds, pendingWithdraw; keep available/savings

After successful buy/transfer, update petMood the same way (plan still present).

- [ ] **Step 4: `flutter test` full suite PASS**

- [ ] **Step 5: Commit** `feat(economy): close period with mood and stages`

---

### Task 7: Barrel + README pointer for testers

**Files:**
- Modify: `client/lib/economy/economy.dart` (ensure exports)
- Modify: `docs/superpowers/plans/2026-09-20-finni-program-roadmap.md` — P2 note: plan №1 exists
- Test: none new; run full suite

**Interfaces:**
- Produces: `export` of engine, commands, state, coins

- [ ] **Step 1: Write failing test that imports barrel only**

`client/test/economy/barrel_test.dart`:

```dart
import 'package:finni/economy/economy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('barrel exports engine', () {
    expect(EconomyEngine().apply(EconomyState.empty(), const Credit(GameCoins(1), 't')).state.available, const GameCoins(1));
  });
}
```

- [ ] **Step 2: FAIL if barrel incomplete**

- [ ] **Step 3: Fix exports**

- [ ] **Step 4: `cd client && flutter test` PASS**

- [ ] **Step 5: Commit** `test(economy): cover barrel export`

---

## Spec coverage

| Requirement | Task |
|-------------|------|
| Баланс ≥ 0 | 1, 4 |
| План ≤ available | 4 |
| Покупка need/want, факт | 4 |
| noPlan / insufficient + recover ids | 4 |
| Копилка, двушаговое снятие | 5 |
| Close, mood, stage 1–3, прогресс не обнуляется | 6 |
| Объяснения id | 3–6 |
| Duplicate buy / exact zero | 4 |
| Нет UI | all |

## Execution Handoff

План сохранён: `docs/superpowers/plans/2026-09-20-finni-economy.md`.

Перед кодом: `git fetch`, обновить `main`, создать **`Ivan_DevStand`**, работать только в ней. P0 разведку можно вести параллельно документами.

Какой способ исполнения?

1. **Subagent-driven** (рекомендую) — свежий субагент на задачу и ревью между задачами.  
2. **Native** — эта сессия, `executing-plans`, одно ревью ветки в конце.

Напиши «1» / «2» / «исполняй native» / «исполняй субагентами». Пока нет выбора — **код не пишем**.
