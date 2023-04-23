// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ITimelockVault {
    event Deposit(uint256 timestamp, uint256 indexed amount);

    event WithdrawalRequest(uint256 indexed timestamp);

    event RevokeWithdrawalRequest(uint256 indexed timestamp);

    event Withdraw(uint256 timestamp, uint256 indexed amount);

    error TimeLeft(uint256 timeLeft);

    error NoPendingWithdrawal();

    error CallFail();

    // add external functions here
}
