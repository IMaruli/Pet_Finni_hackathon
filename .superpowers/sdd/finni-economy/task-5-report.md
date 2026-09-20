# Task 5 report: Savings transfer and two-step withdraw

## RED

Command:

`flutter test test/economy/savings_test.dart`

Result: failed as expected, 4 tests failed with `UnimplementedError` from
`EconomyEngine.apply` for `TransferToSavings` and `ConfirmWithdraw`.

## GREEN

Implemented:

- transfer from available game coins to savings;
- per-period savings tracking;
- withdrawal preview without changing balances;
- confirmed withdrawal from savings back to available;
- rejection of confirmation without a pending withdrawal;
- rejection of transfers and withdrawal requests with insufficient coins.

Targeted command:

`flutter test test/economy/savings_test.dart`

Result: passed, 4 tests.

Full command:

`flutter test`

Result: passed, 15 tests.

IDE diagnostics reported no linter errors.
