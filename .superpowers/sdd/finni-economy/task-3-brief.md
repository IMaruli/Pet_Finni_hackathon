# Task 3 brief

Implement **only** Task 3 from `docs/superpowers/plans/2026-09-20-finni-economy.md` (heading `### Task 3` until `### Task 4`). Copy the Dart file bodies from that section.

**Ruling:** `GameCoins(n)` is a factory, not const. In `credit_test.dart` do **not** write `const Credit(GameCoins(50), 'starter')` or `const GameCoins(50)`. Use:

```dart
void main() {
  test('credit increases available and records source', () {
    const engine = EconomyEngine();
    final result = engine.apply(EconomyState.empty(), Credit(GameCoins(50), 'starter'));
    expect(result.error, isNull);
    expect(result.state.available, GameCoins(50));
    expect(result.state.lastCreditSourceId, 'starter');
    expect(result.explanationIds, ['exp.credit']);
  });
}
```

`EconomyState.empty()` may keep `const EconomyState(... GameCoins.zero ...)` because `zero` is a const private constructor.

TDD: test first (missing files), then create commands/state/result/engine/barrel as in the plan. Engine handles Credit only; other commands UnimplementedError.

PATH: Git cmd + %USERPROFILE%\sdk\flutter\bin
Branch: Ivan_DevStand. No push. No git config.
Commit env: Ivan / IMaruli@users.noreply.github.com
Message: feat(economy): credit command increases available with source
Add: client/lib/economy (new files) + client/test/economy/credit_test.dart
Full `flutter test` green before commit.

Work dir: D:\Работа\Pet_Finni_hackathon
