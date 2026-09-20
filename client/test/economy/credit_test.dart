import 'package:finni/economy/commands.dart';
import 'package:finni/economy/economy_engine.dart';
import 'package:finni/economy/economy_state.dart';
import 'package:finni/economy/game_coins.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('credit increases available and records source', () {
    const engine = EconomyEngine();
    final result = engine.apply(
      EconomyState.empty(),
      Credit(GameCoins(50), 'starter'),
    );
    expect(result.error, isNull);
    expect(result.state.available, GameCoins(50));
    expect(result.state.lastCreditSourceId, 'starter');
    expect(result.explanationIds, ['exp.credit']);
  });
}
