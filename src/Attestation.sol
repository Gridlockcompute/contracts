// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Attestation — anchor TEE report hashes on-chain.
contract Attestation {
    struct Record {
        address worker;
        uint8 teeType;
        bytes32 reportHash;
        bool verified;
        uint64 timestamp;
        uint64 verifiedAt;
        bool exists;
    }

    address public immutable oracle;
    mapping(address => Record) private _records;

    event AttestationSubmitted(address indexed worker, uint8 teeType, bytes32 reportHash, uint64 timestamp);
    event AttestationVerified(address indexed worker, uint8 teeType);

    error AlreadySubmitted();
    error NotSubmitted();
    error AlreadyVerified();
    error Unauthorized();

    modifier onlyOracle() {
        if (msg.sender != oracle) revert Unauthorized();
        _;
    }

    constructor(address oracle_) {
        oracle = oracle_;
    }

    function submitAttestation(uint8 teeType, bytes32 reportHash, uint64 timestamp) external {
        Record storage r = _records[msg.sender];
        if (r.exists) revert AlreadySubmitted();
        r.worker = msg.sender;
        r.teeType = teeType;
        r.reportHash = reportHash;
        r.verified = false;
        r.timestamp = timestamp;
        r.verifiedAt = 0;
        r.exists = true;
        emit AttestationSubmitted(msg.sender, teeType, reportHash, timestamp);
    }

    function verifyAttestation(address worker) external onlyOracle {
        Record storage r = _records[worker];
        if (!r.exists) revert NotSubmitted();
        if (r.verified) revert AlreadyVerified();
        r.verified = true;
        r.verifiedAt = uint64(block.timestamp);
        emit AttestationVerified(worker, r.teeType);
    }

    function getRecord(address worker) external view returns (Record memory) {
        return _records[worker];
    }
}
