// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {HypeToken} from "../src/tokens/HypeToken.sol";

contract HypeTokenSimpleTest is Test {
    HypeToken public hypeToken;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        hypeToken = new HypeToken();

        // Fund users with ETH for staking
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }

    function test_NonTransferable() public {
        // Stake some tokens
        vm.prank(user1);
        hypeToken.stake{value: 1 ether}();

        // All transfer functions should revert
        vm.prank(user1);
        vm.expectRevert("HYPE tokens are non-transferable");
        hypeToken.transfer(user2, 1000e18);

        vm.prank(user1);
        vm.expectRevert("HYPE tokens are non-transferable");
        hypeToken.transferFrom(user1, user2, 1000e18);

        vm.prank(user1);
        vm.expectRevert("HYPE tokens are non-transferable");
        hypeToken.approve(user2, 1000e18);
    }

    function test_StakeUnstake() public {
        // Stake
        vm.prank(user1);
        hypeToken.stake{value: 1 ether}();
        assertEq(hypeToken.balanceOf(user1), 1000e18);

        // Unstake
        vm.prank(user1);
        hypeToken.unstake(1000e18);
        assertEq(hypeToken.balanceOf(user1), 0);
    }

    function test_OwnerMint() public {
        hypeToken.mint(user1, 1000e18);
        assertEq(hypeToken.balanceOf(user1), 1000e18);

        vm.prank(user1);
        vm.expectRevert("Only owner can call this function");
        hypeToken.mint(user2, 1000e18);
    }
}
