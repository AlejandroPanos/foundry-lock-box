// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "src/PriceConverter.sol";

contract LockBox {
    /* Initialise library */
    using PriceConverter for uint256;

    /* Errors */
    error LockBox__NotEnoughSent();
    error LockBox__NotEnoughDuration();

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
    uint256 private constant MIN_EXTENSION = 7 days;
    mapping(address => DepositInfo) private s_depositInfo;

    /* Events */
    event NewDeposit(address indexed sender);

    /* Constructor */
    constructor(AggregatorV3Interface priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = priceFeed;
    }

    /* Functions */
    function deposit(uint256 lockTime) external payable {
        // Checks
        if (msg.value.convertPrice(s_priceFeed) < MIN_USD_AMOUNT) {
            revert LockBox__NotEnoughSent();
        }

        if (lockTime < MIN_LOCK_DURATION) {
            revert LockBox__NotEnoughDuration();
        }

        // Effects
        DepositInfo memory depositInfo = DepositInfo({amount: msg.value, duration: lockTime, state: State.Active});

        s_depositInfo[msg.sender] = depositInfo;

        // Interactions
        emit NewDeposit(msg.sender);
    }

    function witdraw() external {
        // Checks

        // Effects

        // Interactions
    }

    /* Getter functions */
    function getOwner() external view returns (address) {
        return i_owner;
    }
}
