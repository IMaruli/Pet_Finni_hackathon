import 'game_coins.dart';

final class BudgetPlan {
  const BudgetPlan({required this.need, required this.want, required this.save, GameCoins? needDue}) : needDue = needDue ?? need;
  final GameCoins need;

  /// Сколько стоят нужды периода (≤ [need], F-061): «нужное куплено» = потрачено на нужное ≥ этой суммы.
  /// Лишние монеты в банке «Нужное» — не ошибка.
  final GameCoins needDue;
  final GameCoins want;
  final GameCoins save;
  GameCoins get total => need + want + save;
}
