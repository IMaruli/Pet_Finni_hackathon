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
