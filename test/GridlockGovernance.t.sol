// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {FeeCollector} from "../src/FeeCollector.sol";
import {GridlockGovernance} from "../src/GridlockGovernance.sol";

contract GridlockGovernanceTest is Test {
    FeeCollector feeCollector;
    GridlockGovernance governance;
    address owner = address(0xA11CE);
    address stakers = address(0x100);
    address workers = address(0x200);
    address treasury = address(0x300);

    function setUp() public {
        address predicted = vm.computeCreateAddress(owner, vm.getNonce(owner));
        feeCollector = new FeeCollector(predicted, stakers, workers, treasury);
        vm.prank(owner);
        governance = new GridlockGovernance(owner, address(feeCollector), 1 days);
        assertEq(address(governance), predicted);
    }

    function test_queueAndExecuteAfterTimelock() public {
        address newStakers = address(0x101);
        address newWorkers = address(0x201);
        address newTreasury = address(0x301);

        vm.prank(owner);
        governance.queuePoolsUpdate(newStakers, newWorkers, newTreasury);

        vm.expectRevert(GridlockGovernance.TimelockPending.selector);
        governance.executePoolsUpdate();

        vm.warp(block.timestamp + 1 days);
        governance.executePoolsUpdate();

        assertEq(feeCollector.stakersPool(), newStakers);
        assertEq(feeCollector.workersPool(), newWorkers);
        assertEq(feeCollector.treasury(), newTreasury);
    }

    function test_onlyOwnerCanQueue() public {
        vm.prank(address(0xBEEF));
        vm.expectRevert(GridlockGovernance.Unauthorized.selector);
        governance.queuePoolsUpdate(stakers, workers, treasury);
    }

    function test_distributeFees() public {
        vm.deal(address(feeCollector), 1 ether);
        vm.prank(owner);
        governance.distributeFees(1 ether);
        assertEq(address(feeCollector).balance, 0);
    }
}
