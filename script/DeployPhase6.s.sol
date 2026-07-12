// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {GridlockGovernance} from "../src/GridlockGovernance.sol";

/// @notice Deploy GridlockGovernance (Phase 6).
contract DeployPhase6 is Script {
    function run() external {
        address feeCollector = vm.envAddress("EVM_FEE_COLLECTOR");
        uint256 timelockDelay = vm.envOr("GOVERNANCE_TIMELOCK_SEC", uint256(86400));

        vm.startBroadcast();

        GridlockGovernance governance = new GridlockGovernance(
            msg.sender,
            feeCollector,
            timelockDelay
        );

        vm.stopBroadcast();

        console2.log("GridlockGovernance", address(governance));
        console2.log("FeeCollector", feeCollector);
        console2.log("TimelockSec", timelockDelay);
    }
}
