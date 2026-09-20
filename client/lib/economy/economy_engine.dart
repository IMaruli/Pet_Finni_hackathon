import 'commands.dart';
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
      default:
        throw UnimplementedError(command.runtimeType.toString());
    }
  }
}
