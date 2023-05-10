// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/Console.sol";
import {TimelockVault} from "../src/TimelockVault.sol";
import "../src/interfaces/ITimelockVault.sol";

contract CallFail is Test, ITimelockVault {
    TimelockVault public vault;

    function setUp() public {
        vault = new TimelockVault(address(this), makeAddr("guardian"));
    }

    function testWithdrawalRevert() public {
        vault.deposit{value: 100}();
        vault.withdrawalRequest();

        skip(1.0 days);

        vm.expectRevert(abi.encodeWithSelector(ITimelockVault.CallFail.selector));
        vault.withdraw();
    }
}
