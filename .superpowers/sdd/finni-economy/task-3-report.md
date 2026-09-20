# Task 3 report: State, commands, Credit

## RED

Command:

`flutter test test/economy/credit_test.dart`

Result: failed as expected because `commands.dart`, `economy_engine.dart`, and
`economy_state.dart` did not exist. The test could not resolve
`EconomyEngine`, `EconomyState`, or `Credit`.

## GREEN

Implemented:

- sealed economy command hierarchy with `Credit` and planned command stubs;
- `EconomyState.empty()` and `copyWith`;
- `EconomyResult`;
- `EconomyEngine.apply` support for `Credit`;
- economy barrel exports.

Targeted command:

`flutter test test/economy/credit_test.dart`

Result: passed, 1 test.

Full command:

`flutter test`

Result: passed, 5 tests.
