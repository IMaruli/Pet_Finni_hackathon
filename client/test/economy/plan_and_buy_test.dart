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
      .apply(EconomyState.empty(), Credit(GameCoins(50), 'starter'))
      .state;

  test('plan exceeding available is rejected', () {
    final start = credited();
    final result = engine.apply(
      start,
      ConfirmPlan(
        BudgetPlan(
          need: GameCoins(40),
          want: GameCoins(10),
          save: GameCoins(1),
        ),
      ),
    );
    expect(result.error, EconomyError.planExceedsAvailable);
    expect(result.state.available, start.available);
    expect(result.state.plan, isNull);
  });

  test('buy without plan is rejected', () {
    final start = credited();
    final result = engine.apply(
      start,
      BuyItem(
        commandId: 'b1',
        item: CatalogItem(
          id: 'food',
          kind: ItemKind.need,
          price: GameCoins(10),
        ),
      ),
    );
    expect(result.error, EconomyError.noPlan);
    expect(result.state.available, GameCoins(50));
  });

  test('need and want purchases debit and record actuals', () {
    var state = credited();
    state = engine
        .apply(
          state,
          ConfirmPlan(
            BudgetPlan(
              need: GameCoins(20),
              want: GameCoins(10),
              save: GameCoins(5),
            ),
          ),
        )
        .state;
    state = engine
        .apply(
          state,
          BuyItem(
            commandId: 'n1',
            item: CatalogItem(
              id: 'food',
              kind: ItemKind.need,
              price: GameCoins(20),
            ),
          ),
        )
        .state;
    final want = engine.apply(
      state,
      BuyItem(
        commandId: 'w1',
        item: CatalogItem(id: 'toy', kind: ItemKind.want, price: GameCoins(10)),
      ),
    );
    expect(want.error, isNull);
    expect(want.state.available, GameCoins(20));
    expect(want.state.spentNeed, GameCoins(20));
    expect(want.state.spentWant, GameCoins(10));
    expect(want.explanationIds, ['exp.buy']);
  });

  test('buy equal to entire available leaves zero', () {
    var state = credited();
    state = engine
        .apply(
          state,
          ConfirmPlan(
            BudgetPlan(
              need: GameCoins(50),
              want: GameCoins.zero,
              save: GameCoins.zero,
            ),
          ),
        )
        .state;
    final result = engine.apply(
      state,
      BuyItem(
        commandId: 'all',
        item: CatalogItem(
          id: 'food',
          kind: ItemKind.need,
          price: GameCoins(50),
        ),
      ),
    );
    expect(result.error, isNull);
    expect(result.state.available, GameCoins.zero);
  });

  test('insufficient funds does not debit or reset stage', () {
    var state = credited();
    state = engine
        .apply(
          state,
          ConfirmPlan(
            BudgetPlan(
              need: GameCoins(10),
              want: GameCoins.zero,
              save: GameCoins.zero,
            ),
          ),
        )
        .state;
    final result = engine.apply(
      state,
      BuyItem(
        commandId: 'big',
        item: CatalogItem(
          id: 'castle',
          kind: ItemKind.want,
          price: GameCoins(51),
        ),
      ),
    );
    expect(result.error, EconomyError.insufficientFunds);
    expect(result.state.available, GameCoins(50));
    expect(result.state.petStage, 1);
    expect(result.explanationIds, ['exp.insufficient', 'exp.recover']);
  });

  test('duplicate buy commandId does not debit twice', () {
    var state = credited();
    state = engine
        .apply(
          state,
          ConfirmPlan(
            BudgetPlan(
              need: GameCoins(10),
              want: GameCoins.zero,
              save: GameCoins.zero,
            ),
          ),
        )
        .state;
    final buy = BuyItem(
      commandId: 'dup',
      item: CatalogItem(id: 'food', kind: ItemKind.need, price: GameCoins(10)),
    );
    state = engine.apply(state, buy).state;
    final again = engine.apply(state, buy);
    expect(again.error, isNull);
    expect(again.state.available, GameCoins(40));
    expect(again.state.spentNeed, GameCoins(10));
  });
}
