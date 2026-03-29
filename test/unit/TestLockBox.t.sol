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
    uint256 public constant SEND_AMOUNT = 0.5 ether;

    uint256 public constant LOCK_DURATION = 10 days;
    uint256 public constant BELOW_MIN_LOCK_DURATION = 2 days;

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
    function testRevertsIfStateIsActive() public {
        // Arrange
        vm.prank(USER);
        lockBox.deposit{value: SEND_AMOUNT}(LOCK_DURATION);

        vm.prank(USER);
        vm.expectRevert(LockBox.LockBox__AlreadyHasActiveDeposit.selector);

        // Act / Assert
        lockBox.deposit{value: SEND_AMOUNT}(LOCK_DURATION);
    }

    function testRevertsIfNotEnoughMoneySent() public {
        // Arrange
        vm.prank(USER);
        vm.expectRevert(LockBox.LockBox__NotEnoughSent.selector);

        // Act / Assert
        lockBox.deposit(LOCK_DURATION);
    }

    function testRevertsIfNotEnoughDurationSet() public {
        // Arrange
        vm.prank(USER);
        vm.expectRevert(LockBox.LockBox__NotEnoughDuration.selector);

        // Act / Assert
        lockBox.deposit{value: SEND_AMOUNT}(BELOW_MIN_LOCK_DURATION);
    }

    function testDepositAmountGetsSetCorrectly() public {
        // Arrange
        vm.prank(USER);

        // Act
        lockBox.deposit{value: SEND_AMOUNT}(LOCK_DURATION);

        // Assert
        assertEq(lockBox.getLockAmount(USER), SEND_AMOUNT);
    }

    function testDepositDurationGetsSetCorrectly() public {
        // Arrange
        vm.prank(USER);

        // Act
        lockBox.deposit{value: SEND_AMOUNT}(LOCK_DURATION);

        // Assert
        assertEq(lockBox.getLockDuration(USER), (block.timestamp + LOCK_DURATION));
    }

    function testDepositStateGetsSetCorrectly() public {
        // Arrange
        vm.prank(USER);

        // Act
        lockBox.deposit{value: SEND_AMOUNT}(LOCK_DURATION);

        // Assert
        assertEq(uint256(lockBox.getLockState(USER)), uint256(LockBox.State.Active));
    }

    function testEmitsWhenDepositMade() public {
        // Arrange
        vm.prank(USER);
        vm.expectEmit(true, false, false, false);
        emit NewDeposit(USER);

        // Act / Assert
        lockBox.deposit{value: SEND_AMOUNT}(LOCK_DURATION);
    }

    /* Withdraw testing functions */
    function testRevertsIsStateIsInacive() public {
        // Arrange
        vm.prank(USER);
        vm.expectRevert(LockBox.LockBox__YouHaveNoActiveDeposit.selector);

        // Act / Assert
        lockBox.withdraw();
    }

    function testRevertsIfNotEnoughTimeHasPassed() public {
        // Arrange
        vm.prank(USER);
        lockBox.deposit{value: SEND_AMOUNT}(LOCK_DURATION);

        vm.prank(USER);
        vm.expectRevert(LockBox.LockBox__NotEnoughTimeHasPassed.selector);

        // Act / Assert
        lockBox.withdraw();
    }

    function testStateIsInactiveBeforeTransfer() public {
        // Arrange
        vm.prank(USER);
        lockBox.deposit{value: SEND_AMOUNT}(LOCK_DURATION);

        // Act
        vm.prank(USER);
        vm.warp(LOCK_DURATION + 10 days);
        lockBox.withdraw();

        // Assert
        assertEq(uint256(lockBox.getLockState(USER)), uint256(LockBox.State.Inactive));
    }

    function testAmountIsZeroBeforeTransfer() public {
        // Arrange
        vm.prank(USER);
        lockBox.deposit{value: SEND_AMOUNT}(LOCK_DURATION);

        // Act
        vm.prank(USER);
        vm.warp(LOCK_DURATION + 10 days);
        lockBox.withdraw();

        // Assert
        assertEq(lockBox.getLockAmount(USER), 0);
    }

    function testDurationIsZeroBeforeTransfer() public {
        // Arrange
        vm.prank(USER);
        lockBox.deposit{value: SEND_AMOUNT}(LOCK_DURATION);

        // Act
        vm.prank(USER);
        vm.warp(LOCK_DURATION + 10 days);
        lockBox.withdraw();

        // Assert
        assertEq(lockBox.getLockDuration(USER), 0);
    }

    function testContractsBalanceIsZeroAfterTransfer() public {
        // Arrange
        vm.prank(USER);
        lockBox.deposit{value: SEND_AMOUNT}(LOCK_DURATION);

        // Act
        vm.prank(USER);
        vm.warp(LOCK_DURATION + 10 days);
        lockBox.withdraw();

        // Assert
        assertEq(lockBox.getContractBalance(), 0);
    }

    function testEmitsNewWithdrawAfterSuccessfulWithdraw() public {
        // Arrange
        vm.prank(USER);
        lockBox.deposit{value: SEND_AMOUNT}(LOCK_DURATION);

        vm.prank(USER);
        vm.warp(LOCK_DURATION + 10 days);

        // Act
        vm.expectEmit(true, false, false, false);
        emit NewWithdraw(USER);

        // Assert
        lockBox.withdraw();
    }

    /* Extend lock testing functions */
}
