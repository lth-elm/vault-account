// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/Console.sol";
import {TimelockVault} from "../src/TimelockVault.sol";
import "../src/interfaces/ITimelockVault.sol";

contract TimelockVaultTest is Test, ITimelockVault {
    uint256 private constant _FALSE = 1;
    uint256 private constant _TRUE = 2;

    TimelockVault public vault;

    // https://ethereum.stackexchange.com/a/136286
    receive() external payable {}
    fallback() external payable {}

    function setUp() public {
        vault = new TimelockVault();
        vm.warp(1681904648); // set timestamp as if current
    }

    function testDeposit() public {
        vm.expectEmit(true, false, false, false, address(vault));
        emit Deposit(100 ether);
        vault.deposit{value: 100 ether}();
        assertEq(vault.balance(), 100 ether);
    }

    function testFailDeposit() public {
        vault.deposit{value: 100}();
        assertEq(vault.balance(), 100 ether);
    }

    function testWithdrawalRequestData() public {
        vault.deposit{value: 100}();
        (uint256 boolPendingWithdrawalRequest, uint256 lastWithdrawalRequestTimestamp, uint256 timeLeft) =
            vault.getWithdrawalRequestData();
        assertEq(boolPendingWithdrawalRequest, _FALSE, "test non pending withdrawal request");
        assertEq(lastWithdrawalRequestTimestamp, 0, "test last withdrawal request timestamp 0");
        assertEq(timeLeft, 0, "test 0 time left");
    }

    function testWithdrawal() public {
        vault.deposit{value: 100}();

        uint256 withdrawalRequestTimestamp = block.timestamp;
        vm.expectEmit(false, false, false, false, address(vault));
        emit WithdrawalRequest();
        vault.withdrawalRequest();

        (uint256 boolPendingWithdrawalRequest, uint256 lastWithdrawalRequestTimestamp, uint256 timeLeft) =
            vault.getWithdrawalRequestData();
        assertEq(boolPendingWithdrawalRequest, _TRUE, "test pending withdrawal request");
        assertEq(lastWithdrawalRequestTimestamp, block.timestamp, "test last withdrawal request timestamp");
        assertEq(timeLeft, 1 days, "test 1 day left");

        vm.warp(block.timestamp + 0.7 days);

        (,, uint256 newTimeLeft) = vault.getWithdrawalRequestData();
        assertEq(newTimeLeft, 0.3 days, "test 0.3 days left");

        vm.warp(block.timestamp + 0.4 days);

        vm.expectEmit(true, false, false, false, address(vault));
        emit Withdraw(vault.balance());
        vault.withdraw();
        assertEq(vault.balance(), 0, "test balance 0");

        (uint256 updatedPendingWithdrawalRequest, uint256 getLastWithdrawalRequestTimestamp, uint256 updatedTimeLeft) =
            vault.getWithdrawalRequestData();
        assertEq(updatedPendingWithdrawalRequest, _FALSE, "test non pending withdrawal request");
        assertEq(
            getLastWithdrawalRequestTimestamp, withdrawalRequestTimestamp, "test last withdrawal request timestamp"
        );
        assertEq(updatedTimeLeft, 0, "test 0 time left");
    }

    function testWithdrawalReverts() public {
        vault.deposit{value: 100}();

        vm.expectRevert(abi.encodeWithSelector(ITimelockVault.NoPendingWithdrawal.selector));
        vault.withdraw();

        uint256 withdrawalRequestTimestamp = block.timestamp;
        vault.withdrawalRequest();

        vm.warp(block.timestamp + 0.7 days);

        // bytes4 selector = bytes4(keccak256("TimeLeft(uint256)"));
        (, uint256 lastWithdrawalRequestTimestamp,) = vault.getWithdrawalRequestData();
        vm.expectRevert(
            abi.encodeWithSelector(
                ITimelockVault.TimeLeft.selector, lastWithdrawalRequestTimestamp + 1 days - block.timestamp
            )
        );
        vault.withdraw();
        vm.expectRevert(
            abi.encodeWithSelector(
                ITimelockVault.TimeLeft.selector, withdrawalRequestTimestamp + 1 days - block.timestamp
            )
        );
        vault.withdraw();

        vm.warp(block.timestamp + 0.3 days);

        vm.prank(address(1));
        vm.expectRevert("Ownable: caller is not the owner");
        vault.withdraw();

        vault.withdraw();

        vm.expectRevert(abi.encodeWithSelector(ITimelockVault.NoPendingWithdrawal.selector));
        vault.withdraw();
    }

    function testRevokeWithdrawal() public {
        vault.deposit{value: 100}();

        uint256 withdrawalRequestTimestamp = block.timestamp;
        vault.withdrawalRequest();

        vm.warp(block.timestamp + 0.7 days);

        vm.expectEmit(false, false, false, false, address(vault));
        emit RevokeWithdrawalRequest();
        vault.revokeWithdrawalRequest();

        (uint256 boolPendingWithdrawalRequest, uint256 lastWithdrawalRequestTimestamp, uint256 timeLeft) =
            vault.getWithdrawalRequestData();
        assertEq(boolPendingWithdrawalRequest, _FALSE, "test pending withdrawal request");
        assertEq(lastWithdrawalRequestTimestamp, withdrawalRequestTimestamp, "test last withdrawal request timestamp");
        assertEq(timeLeft, 0.3 days, "test 0.3 day left");

        vm.warp(block.timestamp + 0.4 days);

        (,, uint256 newTimeLeft) = vault.getWithdrawalRequestData();
        assertEq(newTimeLeft, 0, "test timelock over");

        vm.expectRevert(abi.encodeWithSelector(ITimelockVault.NoPendingWithdrawal.selector));
        vault.withdraw();
    }
}
