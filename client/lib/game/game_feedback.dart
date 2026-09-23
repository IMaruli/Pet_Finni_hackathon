enum FeedbackReason {
  none,
  planTooBig,
  planNeedLow,
  noPlan,
  notToday,
  alreadyBought,
  alreadyOwned,
  insufficient,
  noGoal,
  needOption,
  withdrawNotPending,
}

/// Результат действия игрока: удалось ли и что сказать ребёнку.
final class GameFeedback {
  const GameFeedback({
    required this.ok,
    this.reason = FeedbackReason.none,
    this.messages = const [],
    this.reward = 0,
    this.missing = 0,
    this.repeat = false,
  });

  final bool ok;
  final FeedbackReason reason;

  /// Готовые тексты для ребёнка.
  final List<String> messages;

  /// Начислено монет (задание / мини-игра).
  final int reward;

  /// Сколько монет не хватает (insufficient).
  final int missing;

  /// Повтор без эффекта.
  final bool repeat;
}
