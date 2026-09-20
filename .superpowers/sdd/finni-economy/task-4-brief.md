# Task 4 brief

Implement **only** `### Task 4` in `docs/superpowers/plans/2026-09-20-finni-economy.md` until `### Task 5`.

**Ruling:** never `const GameCoins(n)` or `const CatalogItem(... price: GameCoins(n))` or `const ConfirmPlan(... GameCoins ...)`. Drop `const` on those call sites. `const engine = EconomyEngine()` is fine. `GameCoins.zero` is fine.

TDD: write plan_and_buy_test.dart first (engine will UnimplementedError on ConfirmPlan/BuyItem), then implement ConfirmPlan + BuyItem in apply as specified (duplicate commandId, noPlan, insufficientFunds with exp.insufficient+exp.recover, exact balance buy, need/want actuals).

PATH: C:\Program Files\Git\cmd + %USERPROFILE%\sdk\flutter\bin
Ivan_DevStand, no push, no git config
Commit env Ivan / IMaruli@users.noreply.github.com
Message: feat(economy): confirm budget plan and idempotent purchases
Full flutter test green before commit.
Work: D:\Работа\Pet_Finni_hackathon
