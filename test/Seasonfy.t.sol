// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {HypeToken} from "../src/tokens/HypeToken.sol";
import {Oracle} from "../src/oracle/Oracle.sol";
import {MockAzuro} from "../src/oracle/MockAzuro.sol";
import {TeamNFT} from "../src/tokens/TeamNFT.sol";
import {MockFanX} from "../src/mocks/MockFanX.sol";
import {Seasonfy} from "../src/seasonfy/Seasonfy.sol";
import {ERC20} from "lib/solady/src/tokens/ERC20.sol";

contract SeasonfyTest is Test {
    HypeToken public hypeToken;
    Oracle public oracle;
    MockAzuro public mockAzuro;
    TeamNFT public teamNFT;
    MockFanX public mockFanX;
    Seasonfy public seasonfy;
    
    address public owner;
    address public user1;
    address public user2;
    
    // Mock Fan Token
    address public mockFanToken;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        // Deploy contracts
        hypeToken = new HypeToken();
        mockAzuro = new MockAzuro();
        oracle = new Oracle(address(mockAzuro));
        teamNFT = new TeamNFT();
        mockFanX = new MockFanX();
        seasonfy = new Seasonfy(address(hypeToken), address(oracle), address(teamNFT), address(mockFanX));
        
        // Configure contracts
        hypeToken.setFanifyContract(address(seasonfy));
        hypeToken.setSeasonfyContract(address(seasonfy));
        teamNFT.setStakeContract(address(seasonfy));
        
        // Setup oracle with CHZ price
        mockAzuro.addToken("CHZ", 100000000); // $1.00
        
        // Fund users
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        
        // Create mock fan token (we'll use a simple ERC20 mock)
        mockFanToken = address(new MockERC20("FanToken", "FAN", 18));
        MockERC20(mockFanToken).mint(user1, 1000e18);
    }

    function test_Constructor() public view {
        assertEq(seasonfy.owner(), owner);
        assertEq(address(seasonfy.token()), address(hypeToken));
        assertEq(address(seasonfy.oracle()), address(oracle));
        assertEq(address(seasonfy.teamNFT()), address(teamNFT));
        assertEq(seasonfy.mockFanX(), address(mockFanX));
    }

    function test_StakeFanToken() public {
        uint256 stakeAmount = 100e18;
        uint256 teamId = 1;
        
        // Approve fan token
        vm.prank(user1);
        MockERC20(mockFanToken).approve(address(seasonfy), stakeAmount);
        
        // Stake fan token
        vm.prank(user1);
        seasonfy.stakeFanToken(mockFanToken, stakeAmount, teamId);
        
        // Check stake info
        (uint256 fanTokenAmount, uint256 hypeAmount, uint256 stakedTeamId, uint256 seasonId, uint256 nftTokenId, uint256 stakedAt) = seasonfy.getStakeInfo(user1);
        
        assertEq(fanTokenAmount, stakeAmount);
        assertEq(stakedTeamId, teamId);
        assertEq(seasonId, 1);
        assertEq(nftTokenId, 1);
        assertEq(stakedAt, block.timestamp);
        
        // Check HYPE was minted (1000 HYPE = 1 USD, então 100 tokens = 100.000 HYPE)
        assertEq(hypeAmount, 100000e18);
        assertEq(hypeToken.balanceOf(user1), 100000e18);
        
        // Check NFT was minted
        assertEq(teamNFT.ownerOf(1), user1);
    }

    function test_CannotStakeTwice() public {
        uint256 stakeAmount = 100e18;
        uint256 teamId = 1;
        
        // First stake
        vm.prank(user1);
        MockERC20(mockFanToken).approve(address(seasonfy), stakeAmount);
        vm.prank(user1);
        seasonfy.stakeFanToken(mockFanToken, stakeAmount, teamId);
        
        // Try to stake again
        vm.prank(user1);
        MockERC20(mockFanToken).approve(address(seasonfy), stakeAmount);
        vm.prank(user1);
        vm.expectRevert();
        seasonfy.stakeFanToken(mockFanToken, stakeAmount, teamId);
    }

    function test_CannotUnstakeBeforeSeasonEnd() public {
        uint256 stakeAmount = 100e18;
        uint256 teamId = 1;
        
        // Stake
        vm.prank(user1);
        MockERC20(mockFanToken).approve(address(seasonfy), stakeAmount);
        vm.prank(user1);
        seasonfy.stakeFanToken(mockFanToken, stakeAmount, teamId);
        
        // Try to unstake before season end
        vm.prank(user1);
        vm.expectRevert();
        seasonfy.unstakeFanToken();
    }

    function test_PlaceBet() public {
        uint256 stakeAmount = 100e18;
        uint256 teamId = 1;
        
        // Stake fan token
        vm.prank(user1);
        MockERC20(mockFanToken).approve(address(seasonfy), stakeAmount);
        vm.prank(user1);
        seasonfy.stakeFanToken(mockFanToken, stakeAmount, teamId);
        
        // Schedule match
        uint256 startTimestamp = block.timestamp + 3600;
        uint256 duration = 7200;
        oracle.scheduleMatch(0x12345678, startTimestamp, duration, "AAA", "BBB", "#aaa_bbb");
        oracle.updateHype(0x12345678, 7000, 3000);
        
        // Approve HYPE for betting
        vm.prank(user1);
        hypeToken.approve(address(seasonfy), 1000e18);
        
        // Place bet (only for team A, as per modifier)
        vm.prank(user1);
        seasonfy.placeBet(0x12345678, true, 100e18);
        
        // Check bet was placed
        (uint256 amount, bool teamA) = seasonfy.bets(0x12345678, user1);
        assertEq(amount, 100e18);
        assertTrue(teamA);
    }

    function test_CannotBetAgainstTeam() public {
        uint256 stakeAmount = 100e18;
        uint256 teamId = 1;
        
        // Stake fan token
        vm.prank(user1);
        MockERC20(mockFanToken).approve(address(seasonfy), stakeAmount);
        vm.prank(user1);
        seasonfy.stakeFanToken(mockFanToken, stakeAmount, teamId);
        
        // Schedule match
        uint256 startTimestamp = block.timestamp + 3600;
        uint256 duration = 7200;
        oracle.scheduleMatch(0x12345678, startTimestamp, duration, "AAA", "BBB", "#aaa_bbb");
        oracle.updateHype(0x12345678, 7000, 3000);
        
        // Approve HYPE for betting
        vm.prank(user1);
        hypeToken.approve(address(seasonfy), 1000e18);
        
        // Try to bet against team (should fail)
        vm.prank(user1);
        vm.expectRevert();
        seasonfy.placeBet(0x12345678, false, 100e18);
    }
}

// Mock ERC20 for testing
contract MockERC20 is ERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }
    
    function name() public view override returns (string memory) {
        return _name;
    }
    
    function symbol() public view override returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
    
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
} 