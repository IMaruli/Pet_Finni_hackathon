import 'package:finni/economy/budget_plan.dart';
import 'package:finni/economy/commands.dart';
import 'package:finni/economy/economy_engine.dart';
import 'package:finni/economy/economy_error.dart';
import 'package:finni/economy/economy_state.dart';
import 'package:finni/economy/game_coins.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = EconomyEngine();

  EconomyState withSavings(int saved) {
    var state = engine
        .apply(EconomyState.empty(), Credit(GameCoins(saved + 10), 'starter'))
        .state;
    state = engine
        .apply(
          state,
          ConfirmPlan(
            BudgetPlan(
              need: GameCoins.zero,
              want: GameCoins.zero,
              save: GameCoins(saved),
            ),
          ),
        )
        .state;
    return engine.apply(state, TransferToSavings(GameCoins(saved))).state;
  }

  test('redeem spends savings only', () {
    final before = withSavings(55);
    final result = engine.apply(
      before,
      RedeemGoal(goalId: 'room2', cost: GameCoins(50)),
    );
    expect(result.error, isNull);
    expect(result.state.savings, GameCoins(5));
    expect(result.state.available, before.available);
    expect(result.explanationIds, ['exp.goal_done']);
  });

  test('redeem exactly all savings is allowed', () {
    final result = engine.apply(
      withSavings(50),
      RedeemGoal(goalId: 'room2', cost: GameCoins(50)),
    );
    expect(result.error, isNull);
    expect(result.state.savings, GameCoins.zero);
  });

  test('redeem with too little savings is refused without changes', () {
    final before = withSavings(49);
    final result = engine.apply(
      before,
      RedeemGoal(goalId: 'room2', cost: GameCoins(50)),
    );
    expect(result.error, EconomyError.insufficientFunds);
    expect(result.state.savings, GameCoins(49));
    expect(result.explanationIds, ['exp.goal_not_yet']);
  });

  test('redeem does not touch period facts, mood or stage', () {
    final before = withSavings(50);
    final after = engine
        .apply(before, RedeemGoal(goalId: 'room2', cost: GameCoins(50)))
        .state;
    expect(after.savedThisPeriod, before.savedThisPeriod);
    expect(after.petMood, before.petMood);
    expect(after.petStage, before.petStage);
  });
}
