import '../economy/economy.dart';

/// JSON-кодек доменного состояния. Домен о JSON не знает.
abstract final class EconomyCodec {
  static Map<String, dynamic> encode(EconomyState s) => {
    'available': s.available.value,
    'savings': s.savings.value,
    'plan': s.plan == null
        ? null
        : {'need': s.plan!.need.value, 'want': s.plan!.want.value, 'save': s.plan!.save.value, 'needDue': s.plan!.needDue.value},
    'spentNeed': s.spentNeed.value,
    'spentWant': s.spentWant.value,
    'savedThisPeriod': s.savedThisPeriod.value,
    'petMood': s.petMood.name,
    'petStage': s.petStage,
    'goodPeriods': s.goodPeriods,
    'processedBuyIds': s.processedBuyIds,
    'pendingWithdraw': s.pendingWithdraw?.value,
    'lastCreditSourceId': s.lastCreditSourceId,
  };

  static EconomyState decode(Map<String, dynamic> j) {
    GameCoins c(String k) => GameCoins(j[k] as int);
    final plan = j['plan'] as Map<String, dynamic>?;
    final pending = j['pendingWithdraw'] as int?;
    return EconomyState(
      available: c('available'),
      savings: c('savings'),
      plan: plan == null
          ? null
          : BudgetPlan(
              need: GameCoins(plan['need'] as int),
              want: GameCoins(plan['want'] as int),
              save: GameCoins(plan['save'] as int),
              needDue: plan['needDue'] == null ? null : GameCoins(plan['needDue'] as int),
            ),
      spentNeed: c('spentNeed'),
      spentWant: c('spentWant'),
      savedThisPeriod: c('savedThisPeriod'),
      petMood: PetMood.values.byName(j['petMood'] as String),
      petStage: j['petStage'] as int,
      goodPeriods: j['goodPeriods'] as int,
      processedBuyIds: [for (final id in j['processedBuyIds'] as List) id as String],
      pendingWithdraw: pending == null ? null : GameCoins(pending),
      lastCreditSourceId: j['lastCreditSourceId'] as String?,
    );
  }
}
