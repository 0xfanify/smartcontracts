// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "lib/forge-std/src/Test.sol";
import {TeamNFT} from "../src/tokens/TeamNFT.sol";

contract TeamNFTTest is Test {
    TeamNFT public nft;
    address public owner;
    address public stakeContract;
    address public user;
    address public user2;

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setUp() public {
        owner = makeAddr("owner");
        stakeContract = makeAddr("stakeContract");
        user = makeAddr("user");
        user2 = makeAddr("user2");

        vm.startPrank(owner);
        nft = new TeamNFT();
        nft.setStakeContract(stakeContract);
        vm.stopPrank();
    }

    function test_Constructor() public view {
        assertEq(nft.owner(), owner);
        assertEq(nft.name(), "TeamNFT");
        assertEq(nft.symbol(), "TNFT");
    }

    function test_SetStakeContract() public {
        address newStakeContract = makeAddr("newStakeContract");

        vm.prank(owner);
        nft.setStakeContract(newStakeContract);

        assertEq(nft.stakeContract(), newStakeContract);
    }

    function test_SetStakeContract_OnlyOwner() public {
        address newStakeContract = makeAddr("newStakeContract");

        vm.prank(user);
        vm.expectRevert();
        nft.setStakeContract(newStakeContract);
    }

    function test_MintTo() public {
        uint256 teamId = 1;
        uint256 seasonId = 2025;

        vm.prank(stakeContract);
        uint256 tokenId = nft.mintTo(user, teamId, seasonId);

        assertEq(tokenId, 1);
        assertEq(nft.ownerOf(tokenId), user);

        (uint256 storedTeamId, uint256 storedSeasonId) = nft.getMetadata(tokenId);
        assertEq(storedTeamId, teamId);
        assertEq(storedSeasonId, seasonId);

        string memory expectedURI =
            string(abi.encodePacked("https://api.fanify.xyz/metadata?teamId=", "1", "&seasonId=", "2025"));
        assertEq(nft.tokenURI(tokenId), expectedURI);
    }

    function test_MintTo_OnlyStakeContract() public {
        vm.prank(user);
        vm.expectRevert("Only stake contract can call this");
        nft.mintTo(user, 1, 2025);
    }

    function test_MintTo_MultipleTokens() public {
        vm.startPrank(stakeContract);

        uint256 tokenId1 = nft.mintTo(user, 1, 2025);
        uint256 tokenId2 = nft.mintTo(user, 2, 2026);
        uint256 tokenId3 = nft.mintTo(user2, 3, 2027);

        vm.stopPrank();

        assertEq(tokenId1, 1);
        assertEq(tokenId2, 2);
        assertEq(tokenId3, 3);

        assertEq(nft.ownerOf(tokenId1), user);
        assertEq(nft.ownerOf(tokenId2), user);
        assertEq(nft.ownerOf(tokenId3), user2);
    }

    function test_GetMetadata() public {
        vm.prank(stakeContract);
        uint256 tokenId = nft.mintTo(user, 42, 2024);

        (uint256 teamId, uint256 seasonId) = nft.getMetadata(tokenId);
        assertEq(teamId, 42);
        assertEq(seasonId, 2024);
    }

    function test_GetMetadata_NonExistentToken() public {
        vm.expectRevert("Token does not exist");
        nft.getMetadata(999);
    }

    function test_Burn() public {
        vm.startPrank(stakeContract);
        uint256 tokenId = nft.mintTo(user, 1, 2025);
        vm.stopPrank();

        assertEq(nft.ownerOf(tokenId), user);

        vm.prank(stakeContract);
        nft.burn(tokenId);

        vm.expectRevert();
        nft.ownerOf(tokenId);

        vm.expectRevert("Token does not exist");
        nft.getMetadata(tokenId);
    }

    function test_Burn_OnlyStakeContract() public {
        vm.prank(stakeContract);
        nft.mintTo(user, 1, 2025);

        vm.prank(user);
        vm.expectRevert("Only stake contract can call this");
        nft.burn(1);
    }

    function test_Burn_NonExistentToken() public {
        vm.prank(stakeContract);
        vm.expectRevert();
        nft.burn(999);
    }

    // Test non-transferability
    function test_TransferFrom_Reverts() public {
        vm.prank(stakeContract);
        uint256 tokenId = nft.mintTo(user, 1, 2025);

        vm.prank(user);
        vm.expectRevert("Transfers disabled");
        nft.transferFrom(user, user2, tokenId);
    }

    function test_SafeTransferFrom_Reverts() public {
        vm.prank(stakeContract);
        uint256 tokenId = nft.mintTo(user, 1, 2025);

        vm.prank(user);
        vm.expectRevert("Transfers disabled");
        nft.safeTransferFrom(user, user2, tokenId);
    }

    function test_SafeTransferFromWithData_Reverts() public {
        vm.prank(stakeContract);
        uint256 tokenId = nft.mintTo(user, 1, 2025);

        vm.prank(user);
        vm.expectRevert("Transfers disabled");
        nft.safeTransferFrom(user, user2, tokenId, "");
    }

    function test_Approve_Reverts() public {
        vm.prank(stakeContract);
        uint256 tokenId = nft.mintTo(user, 1, 2025);

        vm.prank(user);
        vm.expectRevert("Transfers disabled");
        nft.approve(user2, tokenId);
    }

    function test_SetApprovalForAll_Reverts() public {
        vm.prank(stakeContract);
        nft.mintTo(user, 1, 2025);

        vm.prank(user);
        vm.expectRevert("Transfers disabled");
        nft.setApprovalForAll(user2, true);
    }

    function test_BalanceOf() public {
        vm.startPrank(stakeContract);
        nft.mintTo(user, 1, 2025);
        nft.mintTo(user, 2, 2026);
        nft.mintTo(user2, 3, 2027);
        vm.stopPrank();

        assertEq(nft.balanceOf(user), 2);
        assertEq(nft.balanceOf(user2), 1);
        assertEq(nft.balanceOf(owner), 0);
    }

    function test_TokenURI() public {
        vm.prank(stakeContract);
        uint256 tokenId = nft.mintTo(user, 123, 2024);

        string memory expectedURI =
            string(abi.encodePacked("https://api.fanify.xyz/metadata?teamId=", "123", "&seasonId=", "2024"));
        assertEq(nft.tokenURI(tokenId), expectedURI);
    }

    function test_TokenURI_NonExistentToken() public {
        vm.expectRevert("Token does not exist");
        nft.tokenURI(999);
    }

    function test_OwnerOf() public {
        vm.prank(stakeContract);
        uint256 tokenId = nft.mintTo(user, 1, 2025);

        assertEq(nft.ownerOf(tokenId), user);
    }

    function test_OwnerOf_NonExistentToken() public {
        vm.expectRevert();
        nft.ownerOf(999);
    }

    // Test events are still emitted during minting
    function test_MintTo_EmitsTransferEvent() public {
        vm.prank(stakeContract);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), user, 1);
        nft.mintTo(user, 1, 2025);
    }

    // Test that burning emits Transfer event
    function test_Burn_EmitsTransferEvent() public {
        vm.startPrank(stakeContract);
        uint256 tokenId = nft.mintTo(user, 1, 2025);

        vm.expectEmit(true, true, true, true);
        emit Transfer(user, address(0), tokenId);
        nft.burn(tokenId);
        vm.stopPrank();
    }
}
