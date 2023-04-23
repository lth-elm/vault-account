// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ITimelockVault {
    event Deposit(uint256 indexed amount);

    event WithdrawalRequest();

    event RevokeWithdrawalRequest();

    event Withdraw(uint256 indexed amount);

    error TimeLeft(uint256 timeLeft);

    error NoPendingWithdrawal();

    error CallFail();

    // add external functions here
}
