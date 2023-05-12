// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {console} from "forge-std/Console.sol";
import {TimelockVault} from "../src/TimelockVault.sol";
import "../src/interfaces/ITimelockVault.sol";

contract AccessControlTest is StdInvariant, Test, ITimelockVault {
    TimelockVault public vault;

    bytes32 public immutable USER_ROLE = keccak256("USER");
    bytes32 public immutable GUARDIAN_ROLE = keccak256("GUARDIAN");

    // skip the _ convention
    address private guardian;
    address private user;
    address private trudy;

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
    }

    function invariant_testUserRole() public {
        assertTrue(vault.hasRole(USER_ROLE, user), "test invariant user");
    }

    function invariant_testGuardianRole() public {
        assertTrue(vault.hasRole(GUARDIAN_ROLE, guardian), "test invariant guardian");
    }
}
