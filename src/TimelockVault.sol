// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/ITimelockVault.sol";
import "openzeppelin-contracts/contracts/security/Pausable.sol";
import "openzeppelin-contracts/contracts/access/AccessControl.sol";

contract TimelockVault is AccessControl, Pausable, ITimelockVault {
    uint256 private constant _FALSE = 1;
    uint256 private constant _TRUE = 2;

    bytes32 public immutable USER_ROLE = keccak256("USER");
    bytes32 public immutable GUARDIAN_ROLE = keccak256("GUARDIAN");

    uint256 private _s_lastWithdrawalRequestTimestamp;
    uint256 private _s_boolPendingWithdrawalRequest;

    constructor(address user, address guardian) {
        _s_boolPendingWithdrawalRequest = _FALSE;
        _grantRole(USER_ROLE, user);
        _grantRole(GUARDIAN_ROLE, guardian);
    }

    function deposit() external payable whenNotPaused onlyRole(USER_ROLE) {
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

    function withdrawalRequest() external whenNotPaused onlyRole(USER_ROLE) {
        _s_boolPendingWithdrawalRequest = _TRUE;
        _s_lastWithdrawalRequestTimestamp = block.timestamp;
        emit WithdrawalRequest();
    }

    function revokeWithdrawalRequest() external whenNotPaused onlyRole(USER_ROLE) {
        _s_boolPendingWithdrawalRequest = _FALSE;
        emit RevokeWithdrawalRequest();
    }

    function withdraw() external whenNotPaused isPendingWithdrawalRequest onlyRole(USER_ROLE) {
        uint256 lastWithdrawalRequestTimestamp = _s_lastWithdrawalRequestTimestamp;
        if (block.timestamp < lastWithdrawalRequestTimestamp + 1 days) {
            revert TimeLeft(_timeLeft(lastWithdrawalRequestTimestamp));
        }

        _s_boolPendingWithdrawalRequest = _FALSE;

        emit Withdraw(address(this).balance);

        (bool hs,) = payable(msg.sender).call{value: address(this).balance}("");
        if (!hs) revert CallFail();
    }

    function safeLock() external onlyRole(USER_ROLE) {
        _s_boolPendingWithdrawalRequest = _FALSE;
        emit RevokeWithdrawalRequest();

        _pause();
    }

    function _timeLeft(uint256 _lastWithdrawalRequestTimestamp) internal view returns (uint256) {
        return _lastWithdrawalRequestTimestamp + 1 days - block.timestamp;
    }

    modifier isPendingWithdrawalRequest() {
        if (_s_boolPendingWithdrawalRequest == _FALSE) revert NoPendingWithdrawal();
        _;
    }
}
