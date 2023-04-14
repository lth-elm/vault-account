// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
        counter.setNumber(0);
    }

    function testIncrement() public {
        counter.increment();
        console.log("Incremented number:", counter.number());
        assertEq(counter.number(), 1);
    }

    function tesFailtIncrement() public {
        counter.increment();
        assertEq(counter.number(), 0);
    }

    function testSetNumber(uint256 x) public {
        console.log("Set number to:", x);
        assertEq(counter.number(), x);
    }
}
