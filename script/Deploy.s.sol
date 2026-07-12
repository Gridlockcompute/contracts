// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {GridlockRegistry} from "../src/GridlockRegistry.sol";
import {Attestation} from "../src/Attestation.sol";

/// @notice Deploy GridlockRegistry + Attestation (Phase 4a).
contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        address deployer = msg.sender;
        GridlockRegistry registry = new GridlockRegistry(deployer);
        Attestation attestation = new Attestation(deployer);

        vm.stopBroadcast();

        console2.log("Deployer", deployer);
        console2.log("GridlockRegistry", address(registry));
        console2.log("Attestation", address(attestation));
    }
}
