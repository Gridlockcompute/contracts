// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {GridStaking} from "../src/GridStaking.sol";

contract GridStakingTest is Test {
    GridStaking internal staking;
    address internal staker = address(0xCAFE);

    function setUp() public {
        staking = new GridStaking();
    }

    function test_deposit() public {
        vm.deal(staker, 1 ether);
        vm.prank(staker);
        staking.deposit{value: 0.5 ether}();

        assertEq(staking.staked(staker), 0.5 ether);
        assertEq(staking.totalStaked(), 0.5 ether);
    }

    function test_receive() public {
        vm.deal(staker, 1 ether);
        vm.prank(staker);
        (bool ok,) = address(staking).call{value: 0.25 ether}("");
        assertTrue(ok);
        assertEq(staking.staked(staker), 0.25 ether);
    }

    function test_withdraw() public {
        vm.deal(staker, 1 ether);
        vm.prank(staker);
        staking.deposit{value: 0.5 ether}();

        uint256 before = staker.balance;
        vm.prank(staker);
        staking.withdraw(0.2 ether);

        assertEq(staking.staked(staker), 0.3 ether);
        assertEq(staking.totalStaked(), 0.3 ether);
        assertEq(staker.balance, before + 0.2 ether);
    }

    function test_withdraw_reverts_insufficient() public {
        vm.deal(staker, 1 ether);
        vm.prank(staker);
        staking.deposit{value: 0.1 ether}();

        vm.prank(staker);
        vm.expectRevert("Insufficient stake");
        staking.withdraw(0.2 ether);
    }
}
