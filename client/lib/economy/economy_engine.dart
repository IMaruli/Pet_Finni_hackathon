import 'catalog_item.dart';
import 'commands.dart';
import 'economy_error.dart';
import 'economy_result.dart';
import 'economy_state.dart';

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
        return EconomyResult(
          state: state.copyWith(
            available: state.available - item.price,
            spentNeed: item.kind == ItemKind.need
                ? state.spentNeed + item.price
                : state.spentNeed,
            spentWant: item.kind == ItemKind.want
                ? state.spentWant + item.price
                : state.spentWant,
            processedBuyIds: [...state.processedBuyIds, commandId],
          ),
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
        return EconomyResult(
          state: state.copyWith(
            available: state.available - amount,
            savings: state.savings + amount,
            savedThisPeriod: state.savedThisPeriod + amount,
          ),
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
      default:
        throw UnimplementedError(command.runtimeType.toString());
    }
  }
}
