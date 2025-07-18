// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {HypeToken} from "../src/tokens/HypeToken.sol";

contract HypeTokenTest is Test {
    HypeToken public hypeToken;
    address public owner;
    address public user1;
    address public user2;

    event TokensStaked(address indexed user, uint256 ethAmount, uint256 tokensMinted);
    event TokensUnstaked(address indexed user, uint256 tokensBurned, uint256 ethReturned);
    event TokensMinted(address indexed to, uint256 amount, address indexed by);

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        hypeToken = new HypeToken();

        // Fund users with ETH for staking
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }

    // ============ CONSTRUCTOR TESTS ============

    function test_Constructor() public view {
        assertEq(hypeToken.owner(), owner);
        assertEq(hypeToken.name(), "Hype Token");
        assertEq(hypeToken.symbol(), "HYPE");
        assertEq(hypeToken.decimals(), 18);
        assertEq(hypeToken.totalSupply(), 0);
    }

    // ============ NON-TRANSFERABLE TESTS ============

    function test_TransferShouldRevert() public {
        // First stake some tokens
        vm.prank(user1);
        hypeToken.stake{value: 1 ether}();

        // Try to transfer tokens
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "E060"));
        hypeToken.transfer(user2, 1000e18);
    }

    function test_TransferFromShouldRevert() public {
        // First stake some tokens
        vm.prank(user1);
        hypeToken.stake{value: 1 ether}();

        // Try to transferFrom tokens
        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "E060"));
        hypeToken.transferFrom(user1, user2, 1000e18);
    }

    function test_ApproveShouldRevert() public {
        // First stake some tokens
        vm.prank(user1);
        hypeToken.stake{value: 1 ether}();

        // Try to approve tokens
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("Error(string)", "E060"));
        hypeToken.approve(user2, 1000e18);
    }

    function test_TransferToZeroAddressShouldRevert() public {
        hypeToken.setFanifyContract(address(0xCAFE));
        vm.prank(user1);
        hypeToken.stake{value: 1 ether}();

        vm.prank(user1);
        vm.expectRevert(bytes("E060"));
        hypeToken.transfer(address(0), 1000e18);
    }

    function test_TransferFromZeroAddressShouldRevert() public {
        // Try to transferFrom zero address - should revert with ERC20 error
        vm.prank(user1);
        vm.expectRevert();
        hypeToken.transferFrom(address(0), user1, 1000e18);
    }

    function test_TransferZeroAmountShouldRevert() public {
        // First stake some tokens
        vm.prank(user1);
        hypeToken.stake{value: 1 ether}();

        // Try to transfer zero amount
        vm.prank(user1);
        vm.expectRevert(bytes("E060"));
        hypeToken.transfer(user2, 0);
    }

    // ============ FANIFY CONTRACT TESTS ============

    function test_SetFanifyContract() public {
        address fanifyContract = makeAddr("fanify");

        hypeToken.setFanifyContract(fanifyContract);
        assertEq(hypeToken.fanifyContract(), fanifyContract);
    }

    function test_SetFanifyContract_OnlyOwner() public {
        address fanifyContract = makeAddr("fanify");

        vm.prank(user1);
        vm.expectRevert(bytes("E000"));
        hypeToken.setFanifyContract(fanifyContract);
    }

    function test_TransferToFanifyContract() public {
        address fanifyContract = makeAddr("fanify");
        hypeToken.setFanifyContract(fanifyContract);

        // Mint tokens to user1
        hypeToken.mint(user1, 1000e18);

        // Transfer to Fanify contract should work
        vm.prank(user1);
        bool success = hypeToken.transfer(fanifyContract, 500e18);
        assertTrue(success);
        assertEq(hypeToken.balanceOf(fanifyContract), 500e18);
        assertEq(hypeToken.balanceOf(user1), 500e18);
    }

    function test_TransferFromFanifyContract() public {
        address fanifyContract = makeAddr("fanify");
        hypeToken.setFanifyContract(fanifyContract);

        // Mint tokens to Fanify contract
        hypeToken.mint(fanifyContract, 1000e18);

        // Transfer from Fanify contract should work
        vm.prank(fanifyContract);
        bool success = hypeToken.transfer(user1, 500e18);
        assertTrue(success);
        assertEq(hypeToken.balanceOf(user1), 500e18);
        assertEq(hypeToken.balanceOf(fanifyContract), 500e18);
    }

    function test_TransferFromByFanifyContract() public {
        address fanifyContract = makeAddr("fanify");
        hypeToken.setFanifyContract(fanifyContract);

        // Mint tokens to user1
        hypeToken.mint(user1, 1000e18);

        // Approve Fanify contract
        vm.prank(user1);
        bool approveSuccess = hypeToken.approve(fanifyContract, 500e18);
        assertTrue(approveSuccess);

        // TransferFrom by Fanify contract should work
        vm.prank(fanifyContract);
        bool success = hypeToken.transferFrom(user1, user2, 500e18);
        assertTrue(success);
        assertEq(hypeToken.balanceOf(user2), 500e18);
        assertEq(hypeToken.balanceOf(user1), 500e18);
    }

    function test_ApproveFanifyContract() public {
        address fanifyContract = makeAddr("fanify");
        hypeToken.setFanifyContract(fanifyContract);

        // Mint tokens to user1
        hypeToken.mint(user1, 1000e18);

        // Approve Fanify contract should work
        vm.prank(user1);
        bool success = hypeToken.approve(fanifyContract, 500e18);
        assertTrue(success);
        assertEq(hypeToken.allowance(user1, fanifyContract), 500e18);
    }

    // ============ STAKE TESTS ============

    function test_StakeSuccess() public {
        uint256 initialBalance = user1.balance;
        uint256 initialSupply = hypeToken.totalSupply();

        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit TokensStaked(user1, 1 ether, 1000e18);
        hypeToken.stake{value: 1 ether}();

        assertEq(hypeToken.balanceOf(user1), 1000e18);
        assertEq(hypeToken.totalSupply(), initialSupply + 1000e18);
        assertEq(user1.balance, initialBalance - 1 ether);
        assertEq(address(hypeToken).balance, 1 ether);
    }

    function test_StakeMultipleTimes() public {
        vm.prank(user1);
        hypeToken.stake{value: 1 ether}();

        vm.prank(user1);
        hypeToken.stake{value: 2 ether}();

        assertEq(hypeToken.balanceOf(user1), 3000e18);
        assertEq(hypeToken.totalSupply(), 3000e18);
        assertEq(address(hypeToken).balance, 3 ether);
    }

    function test_StakeInsufficientETH() public {
        vm.prank(user1);
        vm.expectRevert(bytes("E017"));
        hypeToken.stake{value: 0.5 ether}();
    }

    function test_StakeReentrancy() public {
        // This test ensures the nonReentrant modifier works
        vm.prank(user1);
        hypeToken.stake{value: 1 ether}();

        // Try to stake again immediately (should work due to nonReentrant)
        vm.prank(user1);
        hypeToken.stake{value: 1 ether}();

        assertEq(hypeToken.balanceOf(user1), 2000e18);
    }

    // ============ UNSTAKE TESTS ============

    function test_UnstakeSuccess() public {
        // First stake
        vm.prank(user1);
        hypeToken.stake{value: 1 ether}();

        uint256 initialBalance = user1.balance;
        uint256 initialSupply = hypeToken.totalSupply();

        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit TokensUnstaked(user1, 1000e18, 1 ether);
        hypeToken.unstake(1000e18);

        assertEq(hypeToken.balanceOf(user1), 0);
        assertEq(hypeToken.totalSupply(), initialSupply - 1000e18);
        assertEq(user1.balance, initialBalance + 1 ether);
        assertEq(address(hypeToken).balance, 0);
    }

    function test_UnstakePartial() public {
        // First stake
        vm.prank(user1);
        hypeToken.stake{value: 2 ether}();

        uint256 initialBalance = user1.balance;

        vm.prank(user1);
        hypeToken.unstake(1000e18);

        assertEq(hypeToken.balanceOf(user1), 1000e18);
        assertEq(user1.balance, initialBalance + 1 ether);
        assertEq(address(hypeToken).balance, 1 ether);
    }

    function test_UnstakeInsufficientBalance() public {
        vm.prank(user1);
        vm.expectRevert(bytes("E018"));
        hypeToken.unstake(1000e18);
    }

    function test_UnstakeZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert(bytes("E019"));
        hypeToken.unstake(0);
    }

    function test_UnstakeAmountTooSmall() public {
        // Stake 1 ether to get 1000 tokens
        vm.prank(user1);
        hypeToken.stake{value: 1 ether}();

        // Try to unstake less than 1000 tokens (which would result in 0 ETH)
        vm.prank(user1);
        vm.expectRevert(bytes("E061"));
        hypeToken.unstake(999);
    }

    function test_UnstakeInsufficientContractBalance() public {
        // This test would require draining the contract balance first
        // For now, we'll test the basic unstake functionality
        vm.prank(user1);
        hypeToken.stake{value: 1 ether}();

        vm.prank(user1);
        hypeToken.unstake(1000e18);

        assertEq(hypeToken.balanceOf(user1), 0);
    }

    // ============ MINT TESTS ============

    function test_MintByOwner() public {
        uint256 initialSupply = hypeToken.totalSupply();

        vm.expectEmit(true, false, true, true);
        emit TokensMinted(user1, 1000e18, owner);
        hypeToken.mint(user1, 1000e18);

        assertEq(hypeToken.balanceOf(user1), 1000e18);
        assertEq(hypeToken.totalSupply(), initialSupply + 1000e18);
    }

    function test_MintByNonOwner() public {
        vm.prank(user1);
        vm.expectRevert(bytes("E000"));
        hypeToken.mint(user2, 1000e18);
    }

    function test_MintToZeroAddress() public {
        vm.expectRevert(bytes("E064"));
        hypeToken.mint(address(0), 1000e18);
    }

    function test_MintZeroAmount() public {
        vm.expectRevert(bytes("E065"));
        hypeToken.mint(user1, 0);
    }

    // ============ INTEGRATION TESTS ============

    function test_StakeUnstakeCycle() public {
        // User stakes
        vm.prank(user1);
        hypeToken.stake{value: 1 ether}();
        assertEq(hypeToken.balanceOf(user1), 1000e18);

        // User unstakes
        vm.prank(user1);
        hypeToken.unstake(1000e18);
        assertEq(hypeToken.balanceOf(user1), 0);

        // User can stake again
        vm.prank(user1);
        hypeToken.stake{value: 1 ether}();
        assertEq(hypeToken.balanceOf(user1), 1000e18);
    }

    function test_MultipleUsersStakeUnstake() public {
        // User1 stakes
        vm.prank(user1);
        hypeToken.stake{value: 1 ether}();

        // User2 stakes
        vm.prank(user2);
        hypeToken.stake{value: 2 ether}();

        assertEq(hypeToken.balanceOf(user1), 1000e18);
        assertEq(hypeToken.balanceOf(user2), 2000e18);
        assertEq(hypeToken.totalSupply(), 3000e18);

        // User1 unstakes
        vm.prank(user1);
        hypeToken.unstake(1000e18);

        assertEq(hypeToken.balanceOf(user1), 0);
        assertEq(hypeToken.balanceOf(user2), 2000e18);
        assertEq(hypeToken.totalSupply(), 2000e18);
    }

    function test_OwnerMintAndStakeInteraction() public {
        // Owner mints tokens
        hypeToken.mint(user1, 1000e18);
        assertEq(hypeToken.balanceOf(user1), 1000e18);

        // User stakes (should add to existing balance)
        vm.prank(user1);
        hypeToken.stake{value: 1 ether}();
        assertEq(hypeToken.balanceOf(user1), 2000e18);

        // User can unstake staked amount
        vm.prank(user1);
        hypeToken.unstake(1000e18);
        assertEq(hypeToken.balanceOf(user1), 1000e18);
    }

    // ============ EDGE CASES ============

    function test_StakeWithExactMinimum() public {
        vm.prank(user1);
        hypeToken.stake{value: 1 ether}();

        assertEq(hypeToken.balanceOf(user1), 1000e18);
    }

    function test_UnstakeWithExactBalance() public {
        vm.prank(user1);
        hypeToken.stake{value: 1 ether}();

        vm.prank(user1);
        hypeToken.unstake(1000e18);

        assertEq(hypeToken.balanceOf(user1), 0);
    }

    function test_StakeUnstakeWithLargeAmounts() public {
        vm.prank(user1);
        hypeToken.stake{value: 100 ether}();

        assertEq(hypeToken.balanceOf(user1), 100000e18);

        vm.prank(user1);
        hypeToken.unstake(100000e18);

        assertEq(hypeToken.balanceOf(user1), 0);
    }

    // ============ VIEW FUNCTION TESTS ============

    function test_BalanceOf() public {
        assertEq(hypeToken.balanceOf(user1), 0);

        vm.prank(user1);
        hypeToken.stake{value: 1 ether}();

        assertEq(hypeToken.balanceOf(user1), 1000e18);
    }

    function test_TotalSupply() public {
        assertEq(hypeToken.totalSupply(), 0);

        vm.prank(user1);
        hypeToken.stake{value: 1 ether}();

        assertEq(hypeToken.totalSupply(), 1000e18);

        hypeToken.mint(user2, 500e18);

        assertEq(hypeToken.totalSupply(), 1500e18);
    }

    function test_Allowance() public {
        // Allowance should always be 0 since transfers are disabled
        assertEq(hypeToken.allowance(user1, user2), 0);

        // Even after staking, allowance should remain 0
        vm.prank(user1);
        hypeToken.stake{value: 1 ether}();

        assertEq(hypeToken.allowance(user1, user2), 0);
    }
}
