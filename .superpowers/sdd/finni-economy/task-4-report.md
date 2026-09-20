# Task 4 report: ConfirmPlan + BuyItem

## RED

Command:

`flutter test test/economy/plan_and_buy_test.dart`

Result: failed as expected, 6 tests failed with `UnimplementedError` from
`EconomyEngine.apply` for `ConfirmPlan` and `BuyItem`.

## GREEN

Implemented:

- plan validation against available game coins;
- successful plan confirmation;
- need and want purchases with actual-spend tracking;
- no-plan and insufficient-funds errors without state mutation;
- exact-balance purchase support;
- idempotent purchases by `commandId`.

Targeted command:

`flutter test test/economy/plan_and_buy_test.dart`

Result: passed, 6 tests.

Full command:

`flutter test`

Result: passed, 11 tests.

IDE diagnostics reported no linter errors. `flutter analyze` could not complete
because the Flutter analysis server exited with a malformed LSP JSON message;
this was an analyzer-process failure rather than a source diagnostic.
