// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {FeeCollector} from "../src/FeeCollector.sol";

/// @notice Redeploy FeeCollector with governance as authority (immutable handoff).
contract DeployFeeCollectorHandoff is Script {
    function run() external {
        address governance = vm.envAddress("EVM_GOVERNANCE");
        address stakersPool = vm.envAddress("EVM_GRID_STAKING");
        address workersPool = vm.envOr("FEE_WORKERS_POOL", msg.sender);
        address treasury = vm.envOr("FEE_TREASURY", msg.sender);

        vm.startBroadcast();

        FeeCollector feeCollector = new FeeCollector(governance, stakersPool, workersPool, treasury);

        vm.stopBroadcast();

        console2.log("GridlockGovernance (authority)", governance);
        console2.log("FeeCollector (new)", address(feeCollector));
        console2.log("StakersPool", stakersPool);
        console2.log("WorkersPool", workersPool);
        console2.log("Treasury", treasury);
    }
}
