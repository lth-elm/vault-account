// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {console} from "forge-std/Console.sol";
import {TimelockVault} from "../src/TimelockVault.sol";
import "../src/interfaces/ITimelockVault.sol";

contract SafeTest is StdInvariant, Test, ITimelockVault {
    uint256 private constant _FALSE = 1;
    uint256 private constant _TRUE = 2;

    TimelockVault public vault;

    // skip the _ convention
    address private guardian;
    address private user;
    address private trudy;

    // https://ethereum.stackexchange.com/a/136286
    // receive() external payable {}
    // fallback() external payable {}

    function setUp() public {
        guardian = makeAddr("guardian");
        user = makeAddr("user");
        trudy = makeAddr("trudy");

        vm.deal(guardian, 1000 ether);
        vm.deal(user, 1000 ether);
        vm.deal(trudy, 1000 ether);

        vault = new TimelockVault(user, guardian);
        targetContract(address(vault));

        vm.warp(1681904648); // set timestamp as if current

        excludeSender(user);

        // Run operations for every test
        vm.prank(user);
        vault.deposit{value: 100 ether}();
    }

    function invariant_testBalanceUnchanged() public {
        assertEq(vault.balance(), 100 ether, "test balance unchanged");

        // vm.prank(user);
        // vault.withdrawalRequest();

        // skip(1.5 days);
        // assertEq(vault.balance(), 100 ether, "test balance unchanged after withdraw request");

        // vm.prank(user);
        // vault.withdraw();

        // assertEq(vault.balance(), 0, "test emptied balance");
    }

    function invariant_testVariableUnchanged() public {
        (uint256 isPendingWithdrawalRequest,,) = vault.getWithdrawalRequestData();
        assertEq(isPendingWithdrawalRequest, _FALSE, "test pending false");

        // vm.prank(user);
        // vault.withdrawalRequest();

        // (uint256 newPendingWithdrawalRequest,,) = vault.getWithdrawalRequestData();
        // assertEq(newPendingWithdrawalRequest, _TRUE, "test pending true");

        // skip(1.5 days);

        // vm.prank(user);
        // vault.withdraw();

        // (uint256 getNewPendingWithdrawalRequest,,) = vault.getWithdrawalRequestData();
        // assertEq(getNewPendingWithdrawalRequest, _FALSE, "test pending false after withdraw");
    }
}
