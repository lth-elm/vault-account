// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {console} from "forge-std/Console.sol";
import {TimelockVault} from "../src/TimelockVault.sol";
import "../src/interfaces/ITimelockVault.sol";

contract SafeLockTest is StdInvariant, Test, ITimelockVault {
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

        // Run Operation
        vm.prank(user);
        vault.safeLock();

        excludeSender(user);
    }

    function invariant_testShouldBeLocked() public {
        assertEq(vault.paused(), true, "test isLocked");
    }
}
