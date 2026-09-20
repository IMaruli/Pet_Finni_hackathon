import 'budget_plan.dart';
import 'game_coins.dart';

enum PetMood { steady, glad, uneasy }

final class EconomyState {
  const EconomyState({
    required this.available,
    required this.savings,
    required this.plan,
    required this.spentNeed,
    required this.spentWant,
    required this.savedThisPeriod,
    required this.petMood,
    required this.petStage,
    required this.goodPeriods,
    required this.processedBuyIds,
    required this.pendingWithdraw,
    required this.lastCreditSourceId,
  });

  factory EconomyState.empty() => const EconomyState(
    available: GameCoins.zero,
    savings: GameCoins.zero,
    plan: null,
    spentNeed: GameCoins.zero,
    spentWant: GameCoins.zero,
    savedThisPeriod: GameCoins.zero,
    petMood: PetMood.steady,
    petStage: 1,
    goodPeriods: 0,
    processedBuyIds: [],
    pendingWithdraw: null,
    lastCreditSourceId: null,
  );

  final GameCoins available;
  final GameCoins savings;
  final BudgetPlan? plan;
  final GameCoins spentNeed;
  final GameCoins spentWant;
  final GameCoins savedThisPeriod;
  final PetMood petMood;
  final int petStage;
  final int goodPeriods;
  final List<String> processedBuyIds;
  final GameCoins? pendingWithdraw;
  final String? lastCreditSourceId;

  EconomyState copyWith({
    GameCoins? available,
    GameCoins? savings,
    BudgetPlan? plan,
    bool clearPlan = false,
    GameCoins? spentNeed,
    GameCoins? spentWant,
    GameCoins? savedThisPeriod,
    PetMood? petMood,
    int? petStage,
    int? goodPeriods,
    List<String>? processedBuyIds,
    GameCoins? pendingWithdraw,
    bool clearPendingWithdraw = false,
    String? lastCreditSourceId,
  }) {
    return EconomyState(
      available: available ?? this.available,
      savings: savings ?? this.savings,
      plan: clearPlan ? null : (plan ?? this.plan),
      spentNeed: spentNeed ?? this.spentNeed,
      spentWant: spentWant ?? this.spentWant,
      savedThisPeriod: savedThisPeriod ?? this.savedThisPeriod,
      petMood: petMood ?? this.petMood,
      petStage: petStage ?? this.petStage,
      goodPeriods: goodPeriods ?? this.goodPeriods,
      processedBuyIds: processedBuyIds ?? this.processedBuyIds,
      pendingWithdraw: clearPendingWithdraw
          ? null
          : (pendingWithdraw ?? this.pendingWithdraw),
      lastCreditSourceId: lastCreditSourceId ?? this.lastCreditSourceId,
    );
  }
}
