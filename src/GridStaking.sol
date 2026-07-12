// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title GridStaking — native ETH staking pool (deposit + withdraw).
contract GridStaking {
    mapping(address => uint256) public staked;
    uint256 public totalStaked;

    event Deposited(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);

    receive() external payable {
        staked[msg.sender] += msg.value;
        totalStaked += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function deposit() external payable {
        staked[msg.sender] += msg.value;
        totalStaked += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "zero amount");
        require(staked[msg.sender] >= amount, "Insufficient stake");
        staked[msg.sender] -= amount;
        totalStaked -= amount;
        emit Withdrawn(msg.sender, amount);
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "ETH transfer failed");
    }
}
