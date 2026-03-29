# LockBox

A time-locked ETH vault contract built on Solidity. Depositors commit ETH with a self-chosen unlock period and a minimum deposit threshold enforced in USD via Chainlink price feeds. Funds are inaccessible until the unlock time elapses. Lock periods can be extended at any time before expiry. Multiple depositors can hold independent locks simultaneously, each tracked by address.

---

## What It Does

- Accepts ETH deposits with a minimum value of $200 USD, enforced via Chainlink at deposit time
- Each depositor sets their own unlock timestamp, with a minimum lock period of 7 days
- Funds are locked and cannot be withdrawn until the specified time has passed
- Depositors can extend their lock period at any time before expiry, with a minimum extension of 1 day
- Each address can hold one active deposit at a time
- Direct ETH transfers to the contract are rejected
- Multi-network deployment supported via HelperConfig with automated mock infrastructure for local development

---

## Project Structure

```
.
├── src/
│   ├── LockBox.sol                     # Main contract
│   └── PriceConverter.sol              # Chainlink price conversion library
├── script/
│   ├── DeployLockBox.s.sol             # Foundry deploy script
│   └── HelperConfig.s.sol              # Network configuration and mock deployment
└── test/
    ├── unit/
    │   └── TestLockBox.t.sol           # Unit tests
    └── mocks/
        └── MockV3Aggregator.sol        # Chainlink price feed mock for local testing
```

---

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed

### Install dependencies and build

```bash
forge install
forge build
```

### Run tests

```bash
forge test
```

### Run tests with gas report

```bash
forge test --gas-report
```

### Run tests with coverage report

```bash
forge coverage
```

### Deploy to a local Anvil chain

In one terminal, start Anvil:

```bash
anvil
```

In another terminal, run the deploy script:

```bash
forge script script/DeployLockBox.s.sol --rpc-url http://localhost:8545 --broadcast
```

### Deploy to Sepolia

```bash
forge script script/DeployLockBox.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

---

## Contract Overview

### Deposit Lifecycle

Each address independently progresses through the following states:

```
Inactive -> Active (deposit) -> Inactive (withdraw)
```

A deposit can also have its lock extended while in the Active state before expiry.

### State

| Variable            | Type                              | Description                                             |
| ------------------- | --------------------------------- | ------------------------------------------------------- |
| `i_owner`           | `address`                         | Immutable contract owner set at deployment              |
| `s_priceFeed`       | `AggregatorV3Interface`           | Chainlink ETH/USD price feed                            |
| `s_depositInfo`     | `mapping(address => DepositInfo)` | Per-address deposit records                             |
| `MIN_USD_AMOUNT`    | `uint256`                         | Minimum deposit value ($200 USD, scaled to 18 decimals) |
| `MIN_LOCK_DURATION` | `uint256`                         | Minimum lock period (7 days)                            |
| `MIN_EXTENSION`     | `uint256`                         | Minimum lock extension (1 day)                          |

### Struct

```solidity
struct DepositInfo {
    uint256 amount;     // ETH deposited in wei
    uint256 duration;   // Absolute unlock timestamp
    State state;        // Inactive or Active
}
```

### Functions

| Function                          | Visibility         | Description                                                                               |
| --------------------------------- | ------------------ | ----------------------------------------------------------------------------------------- |
| `deposit(uint256 lockTime)`       | `external payable` | Locks ETH for the specified duration. Minimum $200 USD and 7 days.                        |
| `withdraw()`                      | `external`         | Withdraws the depositor's funds after the unlock time has passed.                         |
| `extendLock(uint256 newLockTime)` | `external`         | Extends the lock period. Must be greater than the current unlock time and at least 1 day. |
| `getOwner()`                      | `external view`    | Returns the contract owner address                                                        |
| `getMinUsdAmount()`               | `external pure`    | Returns the minimum deposit amount in USD (scaled)                                        |
| `getMinLockDuration()`            | `external pure`    | Returns the minimum lock duration in seconds                                              |
| `getMinExtension()`               | `external pure`    | Returns the minimum extension duration in seconds                                         |
| `getLockState(address)`           | `external view`    | Returns the deposit state for a given address                                             |
| `getLockAmount(address)`          | `external view`    | Returns the deposited ETH amount for a given address                                      |
| `getLockDuration(address)`        | `external view`    | Returns the absolute unlock timestamp for a given address                                 |
| `getContractBalance()`            | `external view`    | Returns the total ETH held by the contract                                                |

### Custom Errors

| Error                                                | When It Triggers                                              |
| ---------------------------------------------------- | ------------------------------------------------------------- |
| `LockBox__AlreadyHasActiveDeposit()`                 | Depositor tries to deposit while an active deposit exists     |
| `LockBox__NotEnoughSent()`                           | ETH value is below the $200 USD minimum                       |
| `LockBox__NotEnoughDuration()`                       | Lock duration is below the 7 day minimum                      |
| `LockBox__YouHaveNoActiveDeposit()`                  | withdraw() or extendLock() called with no active deposit      |
| `LockBox__NotEnoughTimeHasPassed()`                  | withdraw() called before the unlock timestamp                 |
| `LockBox__TransferFailed()`                          | ETH transfer to the depositor fails                           |
| `LockBox__DurationHasExpired()`                      | extendLock() called after the lock has already expired        |
| `LockBox__ExtensionMustBeGreater()`                  | Extension duration is below the 1 day minimum                 |
| `LockBox__ExtensionCannotBeBehindOriginalDuration()` | New unlock time would be earlier than the current unlock time |
| `LockBox__DirectTransfersNotAllowed()`               | ETH sent directly to the contract via receive() or fallback() |

### Events

| Event                                                                  | When It Emits                            |
| ---------------------------------------------------------------------- | ---------------------------------------- |
| `NewDeposit(address indexed sender)`                                   | A deposit is successfully created        |
| `NewWithdraw(address indexed sender)`                                  | A withdrawal is successfully completed   |
| `UpdatedLocktime(address indexed sender, uint256 indexed newLockTime)` | A lock extension is successfully applied |

---

## HelperConfig

Handles network detection and price feed configuration automatically.

| Network       | Chain ID | Behaviour                                                                          |
| ------------- | -------- | ---------------------------------------------------------------------------------- |
| Sepolia       | 11155111 | Uses the real Chainlink ETH/USD feed at 0x694AA1769357215DE4FAC081bf1f309aDC325306 |
| Anvil (local) | 31337    | Deploys a MockV3Aggregator with 8 decimals and an initial price of $2,000          |

---

## Tests

26 tests across deposit, withdraw, and extendLock functions.

### General

| Test                            | What It Checks                              |
| ------------------------------- | ------------------------------------------- |
| `testOwnerIsMsgSender`          | Owner is correctly set to the deployer      |
| `testMinimumAmountIsTwoHundred` | Minimum USD amount is correctly set         |
| `testMinimumLockIsSevenDays`    | Minimum lock duration is correctly set      |
| `testMinimumExtensionIsOneDay`  | Minimum extension duration is correctly set |

### deposit()

| Test                                  | What It Checks                                                   |
| ------------------------------------- | ---------------------------------------------------------------- |
| `testRevertsIfStateIsActive`          | Reverts when a deposit already exists for the caller             |
| `testRevertsIfNotEnoughMoneySent`     | Reverts when ETH value is below the minimum USD threshold        |
| `testRevertsIfNotEnoughDurationSet`   | Reverts when lock duration is below the minimum                  |
| `testDepositAmountGetsSetCorrectly`   | Deposited amount is stored correctly                             |
| `testDepositDurationGetsSetCorrectly` | Unlock timestamp is stored as block.timestamp plus lock duration |
| `testDepositStateGetsSetCorrectly`    | Deposit state is set to Active                                   |
| `testEmitsWhenDepositMade`            | NewDeposit event is emitted with the correct address             |

### withdraw()

| Test                                          | What It Checks                                        |
| --------------------------------------------- | ----------------------------------------------------- |
| `testRevertsIsStateIsInactive`                | Reverts when no active deposit exists                 |
| `testRevertsIfNotEnoughTimeHasPassed`         | Reverts when called before the unlock timestamp       |
| `testStateIsInactiveAfterWithdraw`            | Deposit state is reset to Inactive after withdrawal   |
| `testAmountIsZeroAfterWithdraw`               | Deposited amount is zeroed out after withdrawal       |
| `testDurationIsZeroAfterWithdraw`             | Unlock timestamp is zeroed out after withdrawal       |
| `testContractsBalanceIsZeroAfterTransfer`     | Contract ETH balance is zero after withdrawal         |
| `testEmitsNewWithdrawAfterSuccessfulWithdraw` | NewWithdraw event is emitted with the correct address |

### extendLock()

| Test                                               | What It Checks                                                   |
| -------------------------------------------------- | ---------------------------------------------------------------- |
| `testRevertsIfStateIsInactiveWhenExtending`        | Reverts when no active deposit exists                            |
| `testRevertsIfDurationHasExpiredAndCannotIncrease` | Reverts when the lock has already expired                        |
| `testRevertsIfExtensionBehindOriginalDuration`     | Reverts when the new unlock time is earlier than the current one |
| `testRevertsIfNewLockTimeIsBelowMinimum`           | Reverts when the extension is below the 1 day minimum            |
| `testNewDurationGetsSetCorrectly`                  | New unlock timestamp is stored correctly after extension         |
| `testEmitsUpdatedLocktimeAfterSuccessfulUpdate`    | UpdatedLocktime event is emitted with correct parameters         |

---

## License

MIT
