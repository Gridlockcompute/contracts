// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {GridStaking} from "../src/GridStaking.sol";

/// @notice Deploy GridStaking (Phase 5). Requires EVM_GRID_TOKEN.
contract DeployPhase5 is Script {
    function run() external {
        address gridToken = vm.envAddress("EVM_GRID_TOKEN");

        vm.startBroadcast();

        GridStaking gridStaking = new GridStaking(gridToken);

        vm.stopBroadcast();

        console2.log("GridToken", gridToken);
        console2.log("GridStaking", address(gridStaking));
    }
}
