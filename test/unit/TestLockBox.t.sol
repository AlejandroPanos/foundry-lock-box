// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployLockBox} from "script/DeployLockBox.s.sol";
import {LockBox} from "src/LockBox.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract TestLockBox is Test {
    /* Instantiate a new contract */
    LockBox lockBox;
    HelperConfig helperConfig;

    /* State variables */
    address USER = makeAddr("USER");
    address JOINER = makeAddr("JOINER");
    uint256 public constant DEAL = 10 ether;
    uint256 public constant SEND_AMOUNT = 0.1 ether;

    /* Events */
    event NewDeposit(address indexed sender);
    event NewWithdraw(address indexed sender);
    event UpdatedLocktime(address indexed sender, uint256 indexed newLockTime);

    /* Set up function */
    function setUp() external {
        DeployLockBox deploy = new DeployLockBox();
        (lockBox, helperConfig) = deploy.run();
        vm.deal(USER, DEAL);
    }

    /* General testing functions */
    function testOwnerIsMsgSender() public view {
        assertEq(lockBox.getOwner(), msg.sender);
    }

    function testMinimumAmountIsTwoHundred() public view {
        assertEq(lockBox.getMinUsdAmonut(), 200e18);
    }

    function testMinimumLockIsSevenDays() public view {
        assertEq(lockBox.getMinLockDuration(), 7 days);
    }

    function testMinimumExtensionIsOneDay() public view {
        assertEq(lockBox.getMinExtension(), 1 days);
    }

    /* Deposit testing functions */

    /* Withdraw testing functions */

    /* Extend lock testing functions */
}
