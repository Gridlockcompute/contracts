// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {GridStaking} from "../src/GridStaking.sol";
import {MockERC20} from "./MockERC20.sol";

contract GridStakingTest is Test {
    GridStaking internal staking;
    MockERC20 internal grid;
    address internal staker = address(0xCAFE);

    function setUp() public {
        grid = new MockERC20();
        staking = new GridStaking(address(grid));
        grid.mint(staker, 10 ether);
    }

    function test_deposit() public {
        vm.startPrank(staker);
        grid.approve(address(staking), 0.5 ether);
        staking.deposit(0.5 ether);
        vm.stopPrank();

        assertEq(staking.staked(staker), 0.5 ether);
        assertEq(staking.totalStaked(), 0.5 ether);
        assertEq(grid.balanceOf(address(staking)), 0.5 ether);
    }

    function test_withdraw() public {
        vm.startPrank(staker);
        grid.approve(address(staking), 0.5 ether);
        staking.deposit(0.5 ether);

        uint256 before = grid.balanceOf(staker);
        staking.withdraw(0.2 ether);
        vm.stopPrank();

        assertEq(staking.staked(staker), 0.3 ether);
        assertEq(staking.totalStaked(), 0.3 ether);
        assertEq(grid.balanceOf(staker), before + 0.2 ether);
    }

    function test_withdraw_reverts_insufficient() public {
        vm.startPrank(staker);
        grid.approve(address(staking), 0.1 ether);
        staking.deposit(0.1 ether);

        vm.expectRevert(GridStaking.InsufficientStake.selector);
        staking.withdraw(0.2 ether);
        vm.stopPrank();
    }
}
