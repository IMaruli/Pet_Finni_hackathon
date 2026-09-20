# Task 7 brief

Implement only `### Task 7` in `docs/superpowers/plans/2026-09-20-finni-economy.md` until `## Spec coverage`.

Ensure `client/lib/economy/economy.dart` exports all economy public types.
Add `client/test/economy/barrel_test.dart` as in the plan but **no const GameCoins(1)**:

```dart
import 'package:finni/economy/economy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('barrel exports engine', () {
    expect(
      EconomyEngine().apply(EconomyState.empty(), Credit(GameCoins(1), 't')).state.available,
      GameCoins(1),
    );
  });
}
```

TDD: test first if barrel incomplete.
Do not rewrite docs/superpowers/plans except if you must tick a note — prefer skip doc edit to keep commit scoped.

PATH git+flutter. Ivan_DevStand. No push. No git config.
Commit env Ivan / IMaruli@users.noreply.github.com
Message: test(economy): cover barrel export
Work: D:\Работа\Pet_Finni_hackathon
Full flutter test green before commit.
