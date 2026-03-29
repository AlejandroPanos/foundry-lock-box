// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract LockBox {
    /* Errors */
    error LockBox__NotEnoughSent();

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
    uint256 private constant MIN_AMOUNT = 1 ether;
    uint256 private constant MIN_LOCK_DURATION = 7 days;
    uint256 private constant MIN_EXTENSION = 7 days;
    mapping(address => DepositInfo) private s_depositInfo;

    /* Events */
    event NewDeposit(address indexed sender);

    /* Constructor */
    constructor() {
        i_owner = msg.sender;
    }

    /* Functions */
    function deposit(uint256 lockTime) external {}

    /* Getter functions */
    function getOwner() external view returns (address) {
        return i_owner;
    }
}
