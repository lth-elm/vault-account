// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/ITimelockVault.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract TimelockVault is Ownable, ITimelockVault {
    uint256 private constant _FALSE = 1;
    uint256 private constant _TRUE = 2;

    uint256 private _s_lastWithdrawalRequestTimestamp;
    uint256 private _s_boolPendingWithdrawalRequest;

    constructor() {
        _s_boolPendingWithdrawalRequest = _FALSE;
    }

    function deposit() external payable {
        _s_boolPendingWithdrawalRequest = _FALSE; // reset withdrawal request
        emit Deposit(msg.value);
    }

    function balance() external view returns (uint256) {
        return address(this).balance;
    }

    function getWithdrawalRequestData() external view returns (uint256, uint256, uint256) {
        uint256 lastWithdrawalRequestTimestamp = _s_lastWithdrawalRequestTimestamp;
        return (
            _s_boolPendingWithdrawalRequest,
            lastWithdrawalRequestTimestamp,
            lastWithdrawalRequestTimestamp + 1 days > block.timestamp ? _timeLeft(lastWithdrawalRequestTimestamp) : 0
        );
    }

    function withdrawalRequest() external onlyOwner {
        _s_boolPendingWithdrawalRequest = _TRUE;
        _s_lastWithdrawalRequestTimestamp = block.timestamp;
        emit WithdrawalRequest();
    }

    function revokeWithdrawalRequest() external onlyOwner {
        _s_boolPendingWithdrawalRequest = _FALSE;
        emit RevokeWithdrawalRequest();
    }

    function withdraw() external onlyOwner isPendingWithdrawalRequest {
        uint256 lastWithdrawalRequestTimestamp = _s_lastWithdrawalRequestTimestamp;
        if (block.timestamp < lastWithdrawalRequestTimestamp + 1 days) {
            revert TimeLeft(_timeLeft(lastWithdrawalRequestTimestamp));
        }

        _s_boolPendingWithdrawalRequest = _FALSE;

        emit Withdraw(address(this).balance);

        (bool hs,) = payable(owner()).call{value: address(this).balance}("");
        if (!hs) revert CallFail();
    }

    function _timeLeft(uint256 _lastWithdrawalRequestTimestamp) internal view returns (uint256) {
        return _lastWithdrawalRequestTimestamp + 1 days - block.timestamp;
    }

    modifier isPendingWithdrawalRequest() {
        if (_s_boolPendingWithdrawalRequest == _FALSE) revert NoPendingWithdrawal();
        _;
    }
}
