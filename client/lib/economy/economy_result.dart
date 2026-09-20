import 'economy_error.dart';
import 'economy_state.dart';

final class EconomyResult {
  const EconomyResult({
    required this.state,
    required this.explanationIds,
    this.error,
  });
  final EconomyState state;
  final List<String> explanationIds;
  final EconomyError? error;
}
