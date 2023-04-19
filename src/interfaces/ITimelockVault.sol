// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ITimelockVault {
    event Deposit(uint256 indexed amount);

    event Withdraw(uint256 indexed amount);

    error TimeLeft(uint256 timeLeft);

    // add external functions here
}
