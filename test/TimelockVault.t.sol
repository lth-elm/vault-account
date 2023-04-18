// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/Console.sol";
import {TimelockVault} from "../src/TimelockVault.sol";

contract TimelockVaultTest is Test {
    TimelockVault public vault;

    // https://ethereum.stackexchange.com/a/136286
    receive() external payable {}
    fallback() external payable {}

    function setUp() public {
        vault = new TimelockVault();
    }

    function testDeposit() public {
        vault.deposit{value: 100 ether}();
        assertEq(vault.balance(), 100 ether);
    }

    // function testWithdrawal() public {
    //     vault.deposit{value: 100}();
    //     // vm add 24 hours
    //     vault.withdraw();
    //     assertEq(vault.balance(), 0);
    // }

    // function testFailWithdrawal() public {
    //     vault.deposit{value: 100}();
    //     // vm add 24 hours
    //     vault.withdraw();
    //     assertEq(vault.balance(), 100 ether);
    // }

    function testWithdrawalRevert() public {
        vault.deposit{value: 100}();

        vm.prank(address(1));
        vm.expectRevert("Ownable: caller is not the owner");
        vault.withdraw();
    }

    function testWithdrawalTimeRevert() public {
        vault.deposit{value: 100}();

        bytes4 selector = bytes4(keccak256("TimeLeft(uint256)"));
        vm.expectRevert(abi.encodeWithSelector(selector, vault.s_lastDepositTimestamp() + 1 days - block.timestamp));
        vault.withdraw();
    }

    function testWithdrawalVaultTimeRevert() public {
        vault.deposit{value: 100}();

        bytes4 selector = bytes4(keccak256("TimeLeft(uint256)"));
        vm.expectRevert(abi.encodeWithSelector(selector, vault.timeLeft()));
        vault.withdraw();
    }
}
