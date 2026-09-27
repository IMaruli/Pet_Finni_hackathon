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
    var state = engine
        .apply(EconomyState.empty(), Credit(GameCoins(50), 'starter'))
        .state;
    state = engine
        .apply(
          state,
          ConfirmPlan(
            BudgetPlan(
              need: GameCoins(10),
              want: GameCoins.zero,
              save: GameCoins(20),
            ),
          ),
        )
        .state;
    return state;
  }

  test('transfer moves coins to savings', () {
    final result = engine.apply(ready(), TransferToSavings(GameCoins(20)));
    expect(result.error, isNull);
    expect(result.state.available, GameCoins(30));
    expect(result.state.savings, GameCoins(20));
    expect(result.state.savedThisPeriod, GameCoins(20));
    expect(result.explanationIds, ['exp.save']);
  });

  test('request withdraw does not debit until confirm', () {
    var state = engine.apply(ready(), TransferToSavings(GameCoins(20))).state;
    final requested = engine.apply(state, RequestWithdraw(GameCoins(5)));
    expect(requested.state.savings, GameCoins(20));
    expect(requested.state.pendingWithdraw, GameCoins(5));
    expect(requested.explanationIds, ['exp.withdraw_preview']);

    final confirmed = engine.apply(requested.state, const ConfirmWithdraw());
    expect(confirmed.state.savings, GameCoins(15));
    expect(confirmed.state.available, GameCoins(35));
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
    final state = engine.apply(ready(), TransferToSavings(GameCoins(20))).state;
    final result = engine.apply(state, RequestWithdraw(GameCoins(21)));
    expect(result.error, EconomyError.insufficientFunds);
    expect(result.state.pendingWithdraw, isNull);
    expect(result.state.savings, GameCoins(20));
  });

  test('accrue interest goes to savings, not the wallet (F-044)', () {
    final start = EconomyState.empty().copyWith(savings: GameCoins(30), available: GameCoins(4));
    final r = const EconomyEngine().apply(start, AccrueInterest(GameCoins(3), 'interest:1'));
    expect(r.state.savings, GameCoins(33));
    expect(r.state.available, GameCoins(4));
    expect(r.state.lastCreditSourceId, 'interest:1');
    expect(r.explanationIds, ['exp.interest']);
  });

  test('confirmed withdraw lowers savedThisPeriod, never below zero (F-061)', () {
    var st = EconomyState.empty().copyWith(available: GameCoins(20), savings: GameCoins(40), savedThisPeriod: GameCoins(18));
    st = engine.apply(st, RequestWithdraw(GameCoins(15))).state;
    st = engine.apply(st, const ConfirmWithdraw()).state;
    expect(st.savedThisPeriod, GameCoins(3));
    st = engine.apply(st, RequestWithdraw(GameCoins(10))).state;
    st = engine.apply(st, const ConfirmWithdraw()).state;
    expect(st.savedThisPeriod, GameCoins.zero);
    expect(st.savings, GameCoins(15));
  });
}
