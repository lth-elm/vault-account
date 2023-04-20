// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/ITimelockVault.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract TimelockVault is Ownable, ITimelockVault {
    uint256 private s_lastWithdrawalRequestTimestamp = 0;
    bool private s_isPendingWithdrawalRequest = false;

    function deposit() external payable {
        s_isPendingWithdrawalRequest = false; // reset withdrawal request
        emit Deposit(block.timestamp, msg.value);
    }

    function balance() external view returns (uint256) {
        return address(this).balance;
    }

    function getWithdrawalRequestData() external view returns (bool, uint256, uint256) {
        uint256 lastWithdrawalRequestTimestamp = s_lastWithdrawalRequestTimestamp;
        return (
            s_isPendingWithdrawalRequest,
            lastWithdrawalRequestTimestamp,
            lastWithdrawalRequestTimestamp + 1 days > block.timestamp
                ? lastWithdrawalRequestTimestamp + 1 days - block.timestamp
                : 0
        );
    }

    function withdrawalRequest() external onlyOwner {
        s_isPendingWithdrawalRequest = true;
        s_lastWithdrawalRequestTimestamp = block.timestamp;
        emit WithdrawalRequest(block.timestamp);
    }

    function revokeWithdrawalRequest() external onlyOwner {
        s_isPendingWithdrawalRequest = false;
        emit RevokeWithdrawalRequest(block.timestamp);
    }

    function withdraw() external onlyOwner isPendingWithdrawalRequest {
        uint256 lastWithdrawalRequestTimestamp = s_lastWithdrawalRequestTimestamp;
        if (block.timestamp < lastWithdrawalRequestTimestamp + 1 days) {
            revert TimeLeft(lastWithdrawalRequestTimestamp + 1 days - block.timestamp);
        }

        s_isPendingWithdrawalRequest = false;

        emit Withdraw(block.timestamp, address(this).balance);

        (bool hs,) = payable(owner()).call{value: address(this).balance}("");
        require(hs, "The Withdrawal could not be achieved");
    }

    modifier isPendingWithdrawalRequest() {
        require(s_isPendingWithdrawalRequest, "No pending withdrawal request");
        _;
    }
}
