// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {FeeCollector} from "../src/FeeCollector.sol";
import {JobRouter} from "../src/JobRouter.sol";

/// @notice Deploy FeeCollector + JobRouter (Phase 4b).
/// Requires EVM_WORKER_REGISTRY env for JobRouter constructor.
contract DeployPhase4b is Script {
    function run() external {
        address deployer = msg.sender;
        address workerRegistry = vm.envAddress("EVM_WORKER_REGISTRY");

        vm.startBroadcast();

        FeeCollector feeCollector = new FeeCollector(deployer, deployer, deployer, deployer);
        JobRouter jobRouter = new JobRouter(deployer, workerRegistry);

        vm.stopBroadcast();

        console2.log("Deployer", deployer);
        console2.log("WorkerRegistry (existing)", workerRegistry);
        console2.log("FeeCollector", address(feeCollector));
        console2.log("JobRouter", address(jobRouter));
    }
}
