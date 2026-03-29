// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "src/PriceConverter.sol";

contract LockBox {
    /* Initialise library */
    using PriceConverter for uint256;

    /* Errors */
    error LockBox__AlreadyHasActiveDeposit();
    error LockBox__NotEnoughSent();
    error LockBox__NotEnoughDuration();
    error LockBox__YouHaveNoActiveDeposit();
    error LockBox__NotEnoughTimeHasPassed();
    error LockBox__TransferFailed();
    error LockBox__DurationHasExpired();
    error LockBox__ExtensionCannotBeBehindOriginalDuration();
    error LockBox__ExtensionMustBeGreater();

    /* Type declarations */
    enum State {
        Inactive,
        Active
    }

    struct DepositInfo {
        uint256 amount;
        uint256 duration;
        State state;
    }

    /* State variables */
    address immutable i_owner;
    AggregatorV3Interface private s_priceFeed;
    uint256 private constant MIN_USD_AMOUNT = 200e18;
    uint256 private constant MIN_LOCK_DURATION = 7 days;
    uint256 private constant MIN_EXTENSION = 1 days;
    mapping(address => DepositInfo) private s_depositInfo;

    /* Events */
    event NewDeposit(address indexed sender);
    event NewWithdraw(address indexed sender);
    event UpdatedLocktime(address indexed sender, uint256 indexed newLockTime);

    /* Constructor */
    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    /* Functions */
    function deposit(uint256 lockTime) external payable {
        // Checks
        if (s_depositInfo[msg.sender].state == State.Active) {
            revert LockBox__AlreadyHasActiveDeposit();
        }

        if (msg.value.convertPrice(s_priceFeed) < MIN_USD_AMOUNT) {
            revert LockBox__NotEnoughSent();
        }

        if (lockTime < MIN_LOCK_DURATION) {
            revert LockBox__NotEnoughDuration();
        }

        // Effects
        DepositInfo memory depositInfo =
            DepositInfo({amount: msg.value, duration: block.timestamp + lockTime, state: State.Active});

        s_depositInfo[msg.sender] = depositInfo;

        // Interactions
        emit NewDeposit(msg.sender);
    }

    function withdraw() external {
        // Checks
        if (s_depositInfo[msg.sender].state == State.Inactive) {
            revert LockBox__YouHaveNoActiveDeposit();
        }

        if (s_depositInfo[msg.sender].duration > block.timestamp) {
            revert LockBox__NotEnoughTimeHasPassed();
        }

        // Effects
        uint256 amount = s_depositInfo[msg.sender].amount;
        s_depositInfo[msg.sender].state = State.Inactive;
        s_depositInfo[msg.sender].amount = 0;
        s_depositInfo[msg.sender].duration = 0;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert LockBox__TransferFailed();
        }

        // Interactions
        emit NewWithdraw(msg.sender);
    }

    function extendLock(uint256 newLockTime) external {
        // Checks
        if (s_depositInfo[msg.sender].state == State.Inactive) {
            revert LockBox__YouHaveNoActiveDeposit();
        }

        if (s_depositInfo[msg.sender].duration <= block.timestamp) {
            revert LockBox__DurationHasExpired();
        }

        if (s_depositInfo[msg.sender].duration > block.timestamp + newLockTime) {
            revert LockBox__ExtensionCannotBeBehindOriginalDuration();
        }

        if (newLockTime < MIN_EXTENSION) {
            revert LockBox__ExtensionMustBeGreater();
        }

        // Effects
        s_depositInfo[msg.sender].duration = block.timestamp + newLockTime;

        // Interactions
        emit UpdatedLocktime(msg.sender, newLockTime);
    }

    /* Getter functions */
    function getOwner() external view returns (address) {
        return i_owner;
    }

    function getMinUsdAmonut() external pure returns (uint256) {
        return MIN_USD_AMOUNT;
    }

    function getMinLockDuration() external pure returns (uint256) {
        return MIN_LOCK_DURATION;
    }

    function getMinExtension() external pure returns (uint256) {
        return MIN_EXTENSION;
    }

    function getLockState(address depositor) external view returns (State) {
        return s_depositInfo[depositor].state;
    }

    function getLockAmount(address depositor) external view returns (uint256) {
        return s_depositInfo[depositor].amount;
    }

    function getLockDuration(address depositor) external view returns (uint256) {
        return s_depositInfo[depositor].duration;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
