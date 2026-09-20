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

Commit only `client/` on branch `Ivan_DevStand`. Do not `git add` docs, `.cursor`, or `.superpowers`. Do not push.
