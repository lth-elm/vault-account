// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract TimelockVault is Ownable {
    function deposit() external payable {}

    function balance() external view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() external onlyOwner {
        (bool hs,) = payable(owner()).call{value: address(this).balance}("");
        require(hs, "The Withdrawal could not be achieved");
    }
}
