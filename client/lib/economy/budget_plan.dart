import 'game_coins.dart';

final class BudgetPlan {
  const BudgetPlan({required this.need, required this.want, required this.save});
  final GameCoins need;
  final GameCoins want;
  final GameCoins save;
  GameCoins get total => need + want + save;
}
