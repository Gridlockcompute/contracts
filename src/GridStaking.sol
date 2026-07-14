// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "./IERC20.sol";

/// @title GridStaking — GRID ERC20 staking pool (deposit + withdraw).
contract GridStaking {
    IERC20 public immutable gridToken;

    mapping(address => uint256) public staked;
    uint256 public totalStaked;

    event Deposited(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);

    error ZeroAmount();
    error InsufficientStake();
    error TransferFailed();

    constructor(address gridToken_) {
        require(gridToken_ != address(0), "zero token");
        gridToken = IERC20(gridToken_);
    }

    function deposit(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        if (!gridToken.transferFrom(msg.sender, address(this), amount)) revert TransferFailed();
        staked[msg.sender] += amount;
        totalStaked += amount;
        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        if (staked[msg.sender] < amount) revert InsufficientStake();
        staked[msg.sender] -= amount;
        totalStaked -= amount;
        if (!gridToken.transfer(msg.sender, amount)) revert TransferFailed();
        emit Withdrawn(msg.sender, amount);
    }
}
