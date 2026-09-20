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
