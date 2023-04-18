// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/Console.sol";
import {TimelockVault} from "../src/TimelockVault.sol";

contract CounterTest is Test {
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

    function testWithdrawal() public {
        vault.deposit{value: 100}();
        console.log(vault.owner());
        vault.withdraw();
        assertEq(vault.balance(), 0);
    }

    function testFailWithdrawal() public {
        vault.deposit{value: 100}();
        vault.withdraw();
        assertEq(vault.balance(), 100);
    }

    function testWithdrawalRevert() public {
        vault.deposit{value: 100}();

        vm.prank(address(1));
        vm.expectRevert("Ownable: caller is not the owner");
        vault.withdraw();
    }
}
