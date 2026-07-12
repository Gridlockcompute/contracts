// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {GridlockRegistry} from "./GridlockRegistry.sol";

/// @title JobRouter — job submit / complete / cancel anchored by oracle.
contract JobRouter {
    enum JobStatus {
        None,
        Running,
        Completed,
        Cancelled
    }

    struct Job {
        bytes16 id;
        address owner;
        uint8 guarantee;
        JobStatus status;
        uint64 x402Amount;
        bytes32 toploc;
        uint64 createdAt;
        uint64 completedAt;
        bool exists;
    }

    address public immutable oracle;
    GridlockRegistry public workerRegistry;

    mapping(bytes16 => Job) private _jobs;

    event JobSubmitted(bytes16 indexed id, address indexed owner, uint8 guarantee, uint64 x402Amount);
    event JobCompleted(bytes16 indexed id, bytes32 toploc);
    event JobCancelled(bytes16 indexed id);

    error AlreadySubmitted();
    error NotRunning();
    error AlreadyDone();
    error NotOwner();
    error Unauthorized();

    modifier onlyOracle() {
        if (msg.sender != oracle) revert Unauthorized();
        _;
    }

    constructor(address oracle_, address workerRegistry_) {
        oracle = oracle_;
        workerRegistry = GridlockRegistry(workerRegistry_);
    }

    function submitJob(bytes16 id, uint8 guarantee, uint64 x402Amount) external {
        Job storage job = _jobs[id];
        if (job.exists) revert AlreadySubmitted();
        job.id = id;
        job.owner = msg.sender;
        job.guarantee = guarantee;
        job.status = JobStatus.Running;
        job.x402Amount = x402Amount;
        job.createdAt = uint64(block.timestamp);
        job.exists = true;
        emit JobSubmitted(id, msg.sender, guarantee, x402Amount);
    }

    function completeJob(bytes16 id, bytes32 toploc) external onlyOracle {
        Job storage job = _jobs[id];
        if (!job.exists || job.status != JobStatus.Running) revert NotRunning();
        job.status = JobStatus.Completed;
        job.toploc = toploc;
        job.completedAt = uint64(block.timestamp);
        emit JobCompleted(id, toploc);
    }

    function cancelJob(bytes16 id) external {
        Job storage job = _jobs[id];
        if (!job.exists) revert NotRunning();
        if (job.status >= JobStatus.Completed) revert AlreadyDone();
        if (msg.sender != job.owner && msg.sender != oracle) revert NotOwner();
        job.status = JobStatus.Cancelled;
        emit JobCancelled(id);
    }

    function getJob(bytes16 id) external view returns (Job memory) {
        return _jobs[id];
    }

    function isWorkerActive(address worker) external view returns (bool) {
        if (address(workerRegistry) == address(0)) return true;
        return workerRegistry.isActive(worker);
    }
}
