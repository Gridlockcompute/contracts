// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {GridStaking} from "../src/GridStaking.sol";

/// @notice Deploy GridStaking (Phase 5).
contract DeployPhase5 is Script {
    function run() external {
        vm.startBroadcast();

        GridStaking gridStaking = new GridStaking();

        vm.stopBroadcast();

        console2.log("GridStaking", address(gridStaking));
    }
}
