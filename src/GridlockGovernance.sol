// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IFeeCollector {
    function updatePools(address stakersPool_, address workersPool_, address treasury_) external;
    function distribute(uint256 amount) external;
}

/// @title GridlockGovernance — timelocked FeeCollector pool updates (minimal on-chain governance).
contract GridlockGovernance {
    address public immutable owner;
    address public immutable feeCollector;
    uint256 public timelockDelay;

    struct PendingPools {
        address stakersPool;
        address workersPool;
        address treasury;
        uint256 eta;
        bool exists;
    }

    PendingPools public pendingPools;

    event TimelockUpdated(uint256 delaySec);
    event PoolsQueued(address stakersPool, address workersPool, address treasury, uint256 eta);
    event PoolsExecuted(address stakersPool, address workersPool, address treasury);

    error Unauthorized();
    error NoPendingProposal();
    error TimelockPending();

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor(address owner_, address feeCollector_, uint256 timelockDelay_) {
        owner = owner_;
        feeCollector = feeCollector_;
        timelockDelay = timelockDelay_;
    }

    function setTimelockDelay(uint256 delaySec) external onlyOwner {
        timelockDelay = delaySec;
        emit TimelockUpdated(delaySec);
    }

    function queuePoolsUpdate(address stakersPool, address workersPool, address treasury) external onlyOwner {
        pendingPools = PendingPools({
            stakersPool: stakersPool,
            workersPool: workersPool,
            treasury: treasury,
            eta: block.timestamp + timelockDelay,
            exists: true
        });
        emit PoolsQueued(stakersPool, workersPool, treasury, pendingPools.eta);
    }

    function executePoolsUpdate() external {
        PendingPools memory pending = pendingPools;
        if (!pending.exists) revert NoPendingProposal();
        if (block.timestamp < pending.eta) revert TimelockPending();

        IFeeCollector(feeCollector).updatePools(
            pending.stakersPool,
            pending.workersPool,
            pending.treasury
        );

        delete pendingPools;
        emit PoolsExecuted(pending.stakersPool, pending.workersPool, pending.treasury);
    }

    function distributeFees(uint256 amount) external onlyOwner {
        IFeeCollector(feeCollector).distribute(amount);
    }
}
