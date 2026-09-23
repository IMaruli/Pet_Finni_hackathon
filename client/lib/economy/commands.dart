import 'budget_plan.dart';
import 'catalog_item.dart';
import 'game_coins.dart';

sealed class EconomyCommand {
  const EconomyCommand();
}

final class Credit extends EconomyCommand {
  const Credit(this.amount, this.sourceId);
  final GameCoins amount;
  final String sourceId;
}

final class ConfirmPlan extends EconomyCommand {
  const ConfirmPlan(this.plan);
  final BudgetPlan plan;
}

final class BuyItem extends EconomyCommand {
  const BuyItem({required this.commandId, required this.item});
  final String commandId;
  final CatalogItem item;
}

final class TransferToSavings extends EconomyCommand {
  const TransferToSavings(this.amount);
  final GameCoins amount;
}

final class RequestWithdraw extends EconomyCommand {
  const RequestWithdraw(this.amount);
  final GameCoins amount;
}

final class ConfirmWithdraw extends EconomyCommand {
  const ConfirmWithdraw();
}

final class ClosePeriod extends EconomyCommand {
  const ClosePeriod();
}

final class RedeemGoal extends EconomyCommand {
  const RedeemGoal({required this.goalId, required this.cost});
  final String goalId;
  final GameCoins cost;
}
