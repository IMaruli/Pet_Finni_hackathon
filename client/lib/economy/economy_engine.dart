import 'catalog_item.dart';
import 'commands.dart';
import 'economy_error.dart';
import 'economy_result.dart';
import 'economy_state.dart';
import 'game_coins.dart';

final class EconomyEngine {
  const EconomyEngine();

  EconomyResult apply(EconomyState state, EconomyCommand command) {
    switch (command) {
      case Credit(:final amount, :final sourceId):
        return EconomyResult(
          state: state.copyWith(
            available: state.available + amount,
            lastCreditSourceId: sourceId,
          ),
          explanationIds: const ['exp.credit'],
        );
      case ConfirmPlan(:final plan):
        if (!(plan.total <= state.available)) {
          return EconomyResult(
            state: state,
            explanationIds: const ['exp.plan_too_big'],
            error: EconomyError.planExceedsAvailable,
          );
        }
        return EconomyResult(
          state: state.copyWith(plan: plan),
          explanationIds: const ['exp.plan_ok'],
        );
      case BuyItem(:final commandId, :final item):
        if (state.processedBuyIds.contains(commandId)) {
          return EconomyResult(
            state: state,
            explanationIds: const ['exp.buy_repeat'],
          );
        }
        if (state.plan == null) {
          return EconomyResult(
            state: state,
            explanationIds: const ['exp.need_plan'],
            error: EconomyError.noPlan,
          );
        }
        if (!(item.price <= state.available)) {
          return EconomyResult(
            state: state,
            explanationIds: const ['exp.insufficient', 'exp.recover'],
            error: EconomyError.insufficientFunds,
          );
        }
        final nextState = state.copyWith(
          available: state.available - item.price,
          spentNeed: item.kind == ItemKind.need
              ? state.spentNeed + item.price
              : state.spentNeed,
          spentWant: item.kind == ItemKind.want
              ? state.spentWant + item.price
              : state.spentWant,
          processedBuyIds: [...state.processedBuyIds, commandId],
        );
        return EconomyResult(
          state: nextState.copyWith(petMood: _mood(nextState)),
          explanationIds: const ['exp.buy'],
        );
      case TransferToSavings(:final amount):
        if (!(amount <= state.available)) {
          return EconomyResult(
            state: state,
            explanationIds: const ['exp.insufficient', 'exp.recover'],
            error: EconomyError.insufficientFunds,
          );
        }
        final nextState = state.copyWith(
          available: state.available - amount,
          savings: state.savings + amount,
          savedThisPeriod: state.savedThisPeriod + amount,
        );
        return EconomyResult(
          state: nextState.copyWith(petMood: _mood(nextState)),
          explanationIds: const ['exp.save'],
        );
      case RequestWithdraw(:final amount):
        if (!(amount <= state.savings)) {
          return EconomyResult(
            state: state,
            explanationIds: const ['exp.insufficient', 'exp.recover'],
            error: EconomyError.insufficientFunds,
          );
        }
        return EconomyResult(
          state: state.copyWith(pendingWithdraw: amount),
          explanationIds: const ['exp.withdraw_preview'],
        );
      case ConfirmWithdraw():
        final pending = state.pendingWithdraw;
        if (pending == null) {
          return EconomyResult(
            state: state,
            explanationIds: const ['exp.withdraw_need_confirm'],
            error: EconomyError.withdrawNotPending,
          );
        }
        return EconomyResult(
          state: state.copyWith(
            available: state.available + pending,
            savings: state.savings - pending,
            clearPendingWithdraw: true,
          ),
          explanationIds: const ['exp.withdraw_done'],
        );
      case RedeemGoal(:final cost):
        if (!(cost <= state.savings)) {
          return EconomyResult(
            state: state,
            explanationIds: const ['exp.goal_not_yet'],
            error: EconomyError.insufficientFunds,
          );
        }
        return EconomyResult(
          state: state.copyWith(savings: state.savings - cost),
          explanationIds: const ['exp.goal_done'],
        );
      case AccrueInterest(:final amount, :final sourceId):
        return EconomyResult(
          state: state.copyWith(
            savings: state.savings + amount,
            lastCreditSourceId: sourceId,
          ),
          explanationIds: const ['exp.interest'],
        );
      case ClosePeriod():
        final plan = state.plan;
        final isGood =
            plan != null &&
            state.spentNeed >= plan.need &&
            state.savedThisPeriod.value > 0;
        final goodPeriods = state.goodPeriods + (isGood ? 1 : 0);
        return EconomyResult(
          state: state.copyWith(
            clearPlan: true,
            spentNeed: GameCoins.zero,
            spentWant: GameCoins.zero,
            savedThisPeriod: GameCoins.zero,
            petMood: _mood(state),
            petStage: _stageAfterClose(state.petStage, goodPeriods),
            goodPeriods: goodPeriods,
            processedBuyIds: const [],
            clearPendingWithdraw: true,
          ),
          explanationIds: const ['exp.period_closed', 'exp.mood'],
        );
    }
  }

  PetMood _mood(EconomyState state) {
    final plan = state.plan;
    if (plan == null) {
      return PetMood.steady;
    }

    final needMet = state.spentNeed >= plan.need;
    final actual =
        state.spentNeed.value +
        state.spentWant.value +
        state.savedThisPeriod.value;
    final planned = plan.total.value;
    if (needMet && actual * 5 >= planned * 4 && actual * 5 <= planned * 6) {
      return PetMood.glad;
    }
    if (plan.need.value > 0 && !needMet) {
      return PetMood.uneasy;
    }
    return PetMood.steady;
  }

  int _stageAfterClose(int currentStage, int goodPeriods) {
    final computed = goodPeriods >= 4
        ? 3
        : goodPeriods >= 2
        ? 2
        : 1;
    return currentStage > computed ? currentStage : computed;
  }
}
