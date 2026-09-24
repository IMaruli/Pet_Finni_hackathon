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
    var s = engine
        .apply(EconomyState.empty(), Credit(GameCoins(50), 'starter'))
        .state;
    s = engine
        .apply(
          s,
          ConfirmPlan(
            BudgetPlan(
              need: GameCoins(10),
              want: GameCoins.zero,
              save: GameCoins.zero,
            ),
          ),
        )
        .state;
    s = engine.apply(s, TransferToSavings(GameCoins(5))).state;
    final closed = engine.apply(s, const ClosePeriod());
    expect(closed.state.petMood, PetMood.uneasy);
    expect(closed.state.petStage, 1);
    expect(closed.state.savings, GameCoins(5));
    expect(closed.state.plan, isNull);
    expect(closed.state.spentNeed, GameCoins.zero);
  });

  test('two good periods raise stage to 2', () {
    var s = EconomyState.empty();
    for (var i = 0; i < 2; i++) {
      s = engine.apply(s, Credit(GameCoins(30), 'job')).state;
      s = engine
          .apply(
            s,
            ConfirmPlan(
              BudgetPlan(
                need: GameCoins(10),
                want: GameCoins.zero,
                save: GameCoins(5),
              ),
            ),
          )
          .state;
      s = engine
          .apply(
            s,
            BuyItem(
              commandId: 'n$i',
              item: CatalogItem(
                id: 'food',
                kind: ItemKind.need,
                price: GameCoins(10),
              ),
            ),
          )
          .state;
      s = engine.apply(s, TransferToSavings(GameCoins(5))).state;
      s = engine.apply(s, const ClosePeriod()).state;
    }
    expect(s.petStage, 2);
    expect(s.goodPeriods, 2);
    expect(s.petMood, PetMood.glad);
  });

  test('failed buy does not reset stage or savings', () {
    var s = EconomyState.empty();
    for (var i = 0; i < 2; i++) {
      s = engine.apply(s, Credit(GameCoins(30), 'job')).state;
      s = engine
          .apply(
            s,
            ConfirmPlan(
              BudgetPlan(
                need: GameCoins(10),
                want: GameCoins.zero,
                save: GameCoins(5),
              ),
            ),
          )
          .state;
      s = engine
          .apply(
            s,
            BuyItem(
              commandId: 'keep$i',
              item: CatalogItem(
                id: 'food',
                kind: ItemKind.need,
                price: GameCoins(10),
              ),
            ),
          )
          .state;
      s = engine.apply(s, TransferToSavings(GameCoins(5))).state;
      s = engine.apply(s, const ClosePeriod()).state;
    }
    expect(s.petStage, 2);
    final savingsBefore = s.savings;
    s = engine.apply(s, Credit(GameCoins(10), 'job')).state;
    s = engine
        .apply(
          s,
          ConfirmPlan(
            BudgetPlan(
              need: GameCoins(1),
              want: GameCoins.zero,
              save: GameCoins.zero,
            ),
          ),
        )
        .state;
    final failed = engine.apply(
      s,
      BuyItem(
        commandId: 'x',
        item: CatalogItem(
          id: 'yacht',
          kind: ItemKind.want,
          price: GameCoins(999),
        ),
      ),
    );
    expect(failed.state.petStage, 2);
    expect(failed.state.savings, savingsBefore);
  });

  test('overspending the want plan is not a good period (TZ 2.5.10, F-054)', () {
    EconomyState day(EconomyState s, {required int want, required int spendWant}) {
      s = engine.apply(s, Credit(GameCoins(40), 'pocket')).state;
      s = engine
          .apply(s, ConfirmPlan(BudgetPlan(need: GameCoins(10), want: GameCoins(want), save: GameCoins(5))))
          .state;
      s = engine
          .apply(s, BuyItem(commandId: 'n${s.goodPeriods}$spendWant', item: CatalogItem(id: 'food', kind: ItemKind.need, price: GameCoins(10))))
          .state;
      if (spendWant > 0) {
        s = engine
            .apply(s, BuyItem(commandId: 'w${s.goodPeriods}$spendWant', item: CatalogItem(id: 'toy', kind: ItemKind.want, price: GameCoins(spendWant))))
            .state;
      }
      s = engine.apply(s, TransferToSavings(GameCoins(5))).state;
      return engine.apply(s, const ClosePeriod()).state;
    }

    var s = day(EconomyState.empty(), want: 5, spendWant: 12); // хотелки 12 при плане 5
    expect(s.goodPeriods, 0);
    s = day(s, want: 12, spendWant: 12); // ровно по плану
    expect(s.goodPeriods, 1);
    s = day(s, want: 10, spendWant: 0); // хотелки можно не брать
    expect(s.goodPeriods, 2);
    expect(s.petStage, 2);
  });
}
