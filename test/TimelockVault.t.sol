// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/Console.sol";
import {TimelockVault} from "../src/TimelockVault.sol";
import "../src/interfaces/ITimelockVault.sol";

contract TimelockVaultTest is Test, ITimelockVault {
    TimelockVault public vault;

    // https://ethereum.stackexchange.com/a/136286
    receive() external payable {}
    fallback() external payable {}

    function setUp() public {
        vault = new TimelockVault();
        vm.warp(1681904648); // set timestamp as if time passed
    }

    function testDeposit() public {
        vm.expectEmit(true, true, true, true, address(vault));
        emit Deposit(block.timestamp, 100 ether);
        vault.deposit{value: 100 ether}();
        assertEq(vault.balance(), 100 ether);
    }

    function testFailDeposit() public {
        vault.deposit{value: 100}();
        assertEq(vault.balance(), 100 ether);
    }

    function testWithdrawalRequestData() public {
        vault.deposit{value: 100}();
        (bool isPendingWithdrawalRequest, uint256 lastWithdrawalRequestTimestamp, uint256 timeLeft) =
            vault.getWithdrawalRequestData();
        assertEq(isPendingWithdrawalRequest, false);
        assertEq(lastWithdrawalRequestTimestamp, 0);
        assertEq(timeLeft, 0);
    }

    function testWithdrawal() public {
        vault.deposit{value: 100}();

        uint256 withdrawalRequestTimestamp = block.timestamp;
        vm.expectEmit(true, true, true, true, address(vault));
        emit WithdrawalRequest(block.timestamp);
        vault.withdrawalRequest();

        (bool isPendingWithdrawalRequest, uint256 lastWithdrawalRequestTimestamp, uint256 timeLeft) =
            vault.getWithdrawalRequestData();
        assertEq(isPendingWithdrawalRequest, true);
        assertEq(lastWithdrawalRequestTimestamp, block.timestamp);
        assertEq(timeLeft, 1 days);

        vm.warp(block.timestamp + 0.7 days);

        (,, uint256 newTimeLeft) = vault.getWithdrawalRequestData();
        assertEq(newTimeLeft, 0.3 days);

        vm.warp(block.timestamp + 0.4 days);

        vm.expectEmit(true, true, true, true, address(vault));
        emit Withdraw(block.timestamp, vault.balance());
        vault.withdraw();
        assertEq(vault.balance(), 0);

        (bool updatedPendingWithdrawalRequest, uint256 getLastWithdrawalRequestTimestamp, uint256 updatedTimeLeft) =
            vault.getWithdrawalRequestData();
        assertEq(updatedPendingWithdrawalRequest, false);
        assertEq(getLastWithdrawalRequestTimestamp, withdrawalRequestTimestamp);
        assertEq(updatedTimeLeft, 0);
    }

    function testWithdrawalReverts() public {
        vault.deposit{value: 100}();

        vm.expectRevert("No withdrawal request made");
        vault.withdraw();

        uint256 withdrawalRequestTimestamp = block.timestamp;
        vault.withdrawalRequest();

        vm.warp(block.timestamp + 0.7 days);

        (, uint256 lastWithdrawalRequestTimestamp,) = vault.getWithdrawalRequestData();
        bytes4 selector = bytes4(keccak256("TimeLeft(uint256)"));
        vm.expectRevert(abi.encodeWithSelector(selector, lastWithdrawalRequestTimestamp + 1 days - block.timestamp));
        vault.withdraw();
        vm.expectRevert(abi.encodeWithSelector(selector, withdrawalRequestTimestamp + 1 days - block.timestamp));
        vault.withdraw();

        vm.warp(block.timestamp + 0.3 days);

        vm.prank(address(1));
        vm.expectRevert("Ownable: caller is not the owner");
        vault.withdraw();

        vault.withdraw();

        vm.expectRevert("No withdrawal request made");
        vault.withdraw();
    }
}
