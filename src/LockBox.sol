// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "src/PriceConverter.sol";

contract LockBox {
    /* Initialise library */
    using PriceConverter for uint256;

    /* Errors */
    error LockBox__NotEnoughDuration();

    /* Type declarations */
    enum State {
        Active,
        Inactive
    }

    struct DepositInfo {
        uint256 amount;
        uint256 timestamp;
        State state;
    }

    /* State variables */
    address immutable i_owner;
    AggregatorV3Interface private s_priceFeed;
    uint256 private constant MIN_AMOUNT = 200e18;
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
    function deposit(uint256 lockTime) external {
        // Checks
        if (lockTime < MIN_LOCK_DURATION) {
            revert LockBox__NotEnoughDuration();
        }

        // Effects

        // Interactions
    }

    /* Getter functions */
    function getOwner() external view returns (address) {
        return i_owner;
    }
}
