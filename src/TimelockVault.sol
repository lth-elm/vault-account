// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/ITimelockVault.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract TimelockVault is Ownable, ITimelockVault {
    uint256 public s_lastDepositTimestamp = 0;

    function deposit() external payable {
        emit Deposit(msg.value);
        s_lastDepositTimestamp = block.timestamp;
    }

    function balance() external view returns (uint256) {
        return address(this).balance;
    }

    function timeLeft() external view returns (uint256) {
        uint256 lastDepositTimestamp = s_lastDepositTimestamp;
        return lastDepositTimestamp + 1 days - block.timestamp;
    }

    function withdraw() external onlyOwner {
        uint256 lastDepositTimestamp = s_lastDepositTimestamp;
        if (block.timestamp < lastDepositTimestamp + 1 days) {
            revert TimeLeft(lastDepositTimestamp + 1 days - block.timestamp);
        }

        (bool hs,) = payable(owner()).call{value: address(this).balance}("");
        require(hs, "The Withdrawal could not be achieved");
    }
}
