// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title GridlockRegistry — worker registration + attestation (EVM port of worker_registry).
contract GridlockRegistry {
    enum WorkerStatus {
        Active,
        Deregistered
    }

    struct Worker {
        address worker;
        bytes32 modelHash;
        uint32 tokPerSec;
        uint8 teeType;
        uint16 vramGb;
        uint16 reputation;
        uint64 registeredAt;
        bool confidentialOk;
        uint16 verifyPassRate;
        uint16 attestUptime;
        uint64 lastAttest;
        WorkerStatus status;
    }

    address public immutable oracle;
    mapping(address => Worker) private _workers;

    event WorkerRegistered(
        address indexed worker,
        bytes32 modelHash,
        uint32 tokPerSec,
        uint8 teeType,
        uint16 vramGb
    );
    event AttestationUpdated(address indexed worker, bool confidentialOk, uint64 lastAttest);
    event ReputationUpdated(address indexed worker, uint16 reputation);
    event WorkerDeregistered(address indexed worker);

    error AlreadyRegistered();
    error NotRegistered();
    error Unauthorized();

    modifier onlyOracle() {
        if (msg.sender != oracle) revert Unauthorized();
        _;
    }

    constructor(address oracle_) {
        oracle = oracle_;
    }

    function registerWorker(bytes32 modelHash, uint32 tokPerSec, uint8 teeType, uint16 vramGb) external {
        Worker storage w = _workers[msg.sender];
        if (w.worker != address(0) && w.status == WorkerStatus.Active) revert AlreadyRegistered();
        _workers[msg.sender] = Worker({
            worker: msg.sender,
            modelHash: modelHash,
            tokPerSec: tokPerSec,
            teeType: teeType,
            vramGb: vramGb,
            reputation: 10_000,
            registeredAt: uint64(block.timestamp),
            confidentialOk: false,
            verifyPassRate: 10_000,
            attestUptime: 0,
            lastAttest: 0,
            status: WorkerStatus.Active
        });
        emit WorkerRegistered(msg.sender, modelHash, tokPerSec, teeType, vramGb);
    }

    function updateAttestation(
        address worker,
        bool confidentialOk,
        uint16 verifyPassRate,
        uint16 attestUptime,
        uint64 lastAttest
    ) external onlyOracle {
        Worker storage w = _workers[worker];
        if (w.worker == address(0) || w.status != WorkerStatus.Active) revert NotRegistered();
        w.confidentialOk = confidentialOk;
        w.verifyPassRate = verifyPassRate > 10_000 ? 10_000 : verifyPassRate;
        w.attestUptime = attestUptime > 10_000 ? 10_000 : attestUptime;
        w.lastAttest = lastAttest;
        emit AttestationUpdated(worker, confidentialOk, lastAttest);
    }

    function dropConfidential(address worker) external onlyOracle {
        Worker storage w = _workers[worker];
        if (w.worker == address(0) || w.status != WorkerStatus.Active) revert NotRegistered();
        w.confidentialOk = false;
        emit AttestationUpdated(worker, false, w.lastAttest);
    }

    function updateReputation(address worker, int16 delta) external onlyOracle {
        Worker storage w = _workers[worker];
        if (w.worker == address(0) || w.status != WorkerStatus.Active) revert NotRegistered();
        int32 next = int32(uint32(w.reputation)) + int32(delta);
        if (next < 0) next = 0;
        if (next > 10_000) next = 10_000;
        w.reputation = uint16(uint32(next));
        emit ReputationUpdated(worker, w.reputation);
    }

    function deregisterWorker() external {
        Worker storage w = _workers[msg.sender];
        if (w.worker == address(0) || w.status != WorkerStatus.Active) revert NotRegistered();
        w.status = WorkerStatus.Deregistered;
        emit WorkerDeregistered(msg.sender);
    }

    function getWorker(address worker) external view returns (Worker memory) {
        return _workers[worker];
    }

    function isActive(address worker) external view returns (bool) {
        Worker storage w = _workers[worker];
        return w.worker != address(0) && w.status == WorkerStatus.Active;
    }
}
