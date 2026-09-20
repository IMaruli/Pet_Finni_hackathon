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
    expect(() => GameCoins(-1), throwsArgumentError);
  });
}
