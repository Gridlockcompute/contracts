// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title FeeCollector — native ETH fee routing (60/20/10/10 pools).
contract FeeCollector {
    uint256 public constant STAKERS_BPS = 6000;
    uint256 public constant WORKERS_BPS = 2000;
    uint256 public constant BURN_BPS = 1000;

    address public immutable authority;
    address public stakersPool;
    address public workersPool;
    address public treasury;

    uint256 public totalCollected;

    event FeeDistributed(uint256 total, uint256 stakers, uint256 workers, uint256 burn, uint256 treasury);
    event PoolsUpdated(address stakersPool, address workersPool, address treasury);

    error Unauthorized();
    error InsufficientBalance();
    error TransferFailed();

    modifier onlyAuthority() {
        if (msg.sender != authority) revert Unauthorized();
        _;
    }

    constructor(address authority_, address stakersPool_, address workersPool_, address treasury_) {
        authority = authority_;
        stakersPool = stakersPool_;
        workersPool = workersPool_;
        treasury = treasury_;
    }

    receive() external payable {
        totalCollected += msg.value;
    }

    function updatePools(address stakersPool_, address workersPool_, address treasury_) external onlyAuthority {
        stakersPool = stakersPool_;
        workersPool = workersPool_;
        treasury = treasury_;
        emit PoolsUpdated(stakersPool_, workersPool_, treasury_);
    }

    function distribute(uint256 amount) external onlyAuthority {
        if (address(this).balance < amount) revert InsufficientBalance();

        uint256 stakersShare = amount * STAKERS_BPS / 10_000;
        uint256 workersShare = amount * WORKERS_BPS / 10_000;
        uint256 burnShare = amount * BURN_BPS / 10_000;
        uint256 treasuryShare = amount - stakersShare - workersShare - burnShare;

        _safeTransfer(stakersPool, stakersShare);
        _safeTransfer(workersPool, workersShare);
        _safeTransfer(address(0), burnShare);
        _safeTransfer(treasury, treasuryShare);

        emit FeeDistributed(amount, stakersShare, workersShare, burnShare, treasuryShare);
    }

    function _safeTransfer(address to, uint256 amount) internal {
        if (amount == 0) return;
        (bool ok,) = payable(to).call{value: amount}("");
        if (!ok) revert TransferFailed();
    }
}
