// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/ITimelockVault.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract TimelockVault is Ownable, ITimelockVault {
    uint256 private _s_lastWithdrawalRequestTimestamp = 0;
    bool private _s_isPendingWithdrawalRequest = false;

    function deposit() external payable {
        _s_isPendingWithdrawalRequest = false; // reset withdrawal request
        emit Deposit(block.timestamp, msg.value);
    }

    function balance() external view returns (uint256) {
        return address(this).balance;
    }

    function getWithdrawalRequestData() external view returns (bool, uint256, uint256) {
        uint256 lastWithdrawalRequestTimestamp = _s_lastWithdrawalRequestTimestamp;
        return (
            _s_isPendingWithdrawalRequest,
            lastWithdrawalRequestTimestamp,
            lastWithdrawalRequestTimestamp + 1 days > block.timestamp
                ? lastWithdrawalRequestTimestamp + 1 days - block.timestamp
                : 0
        );
    }

    function withdrawalRequest() external onlyOwner {
        _s_isPendingWithdrawalRequest = true;
        _s_lastWithdrawalRequestTimestamp = block.timestamp;
        emit WithdrawalRequest(block.timestamp);
    }

    function revokeWithdrawalRequest() external onlyOwner {
        _s_isPendingWithdrawalRequest = false;
        emit RevokeWithdrawalRequest(block.timestamp);
    }

    function withdraw() external onlyOwner isPendingWithdrawalRequest {
        uint256 lastWithdrawalRequestTimestamp = _s_lastWithdrawalRequestTimestamp;
        if (block.timestamp < lastWithdrawalRequestTimestamp + 1 days) {
            revert TimeLeft(lastWithdrawalRequestTimestamp + 1 days - block.timestamp);
        }

        _s_isPendingWithdrawalRequest = false;

        emit Withdraw(block.timestamp, address(this).balance);

        (bool hs,) = payable(owner()).call{value: address(this).balance}("");
        require(hs, "The Withdrawal could not be achieved");
    }

    modifier isPendingWithdrawalRequest() {
        require(_s_isPendingWithdrawalRequest, "No pending withdrawal request");
        _;
    }
}
