// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MockAzuro} from "../src/mocks/MockAzuro.sol";
import {FunifyError} from "../src/fanify/fanify.error.sol";

contract MockAzuroTest is Test, FunifyError {
    MockAzuro public mockAzuro;
    address public owner;
    address public user;
    
    function setUp() public {
        owner = address(this);
        user = address(0x123);
        mockAzuro = new MockAzuro();
    }
    
    function test_Constructor() public {
        assertEq(mockAzuro.owner(), owner);
        assertEq(mockAzuro.getSupportedTokensCount(), 0);
    }
    
    function test_AddToken() public {
        mockAzuro.addToken("CHZ", 100000000); // $1.00 com 8 casas decimais
        
        assertTrue(mockAzuro.isTokenSupported("CHZ"));
        assertEq(mockAzuro.getPrice("CHZ"), 100000000);
        assertEq(mockAzuro.getSupportedTokensCount(), 1);
    }
    
    function test_UpdateTokenPrice() public {
        mockAzuro.addToken("CHZ", 100000000);
        mockAzuro.updateTokenPrice("CHZ", 150000000); // $1.50
        
        assertEq(mockAzuro.getPrice("CHZ"), 150000000);
    }
    
    function test_GetPriceNonExistentToken() public {
        vm.expectRevert();
        mockAzuro.getPrice("NONEXISTENT");
    }
    
    function test_AddTokenEmptySymbol() public {
        vm.expectRevert();
        mockAzuro.addToken("", 100000000);
    }
    
    function test_AddTokenZeroPrice() public {
        vm.expectRevert();
        mockAzuro.addToken("CHZ", 0);
    }
    
    function test_AddTokenAlreadyExists() public {
        mockAzuro.addToken("CHZ", 100000000);
        vm.expectRevert();
        mockAzuro.addToken("CHZ", 200000000);
    }
    
    function test_UpdateTokenPriceNonOwner() public {
        mockAzuro.addToken("CHZ", 100000000);
        
        vm.prank(user);
        vm.expectRevert();
        mockAzuro.updateTokenPrice("CHZ", 150000000);
    }
    
    function test_AddTokenNonOwner() public {
        vm.prank(user);
        vm.expectRevert();
        mockAzuro.addToken("CHZ", 100000000);
    }
    
    function test_GetSupportedTokens() public {
        mockAzuro.addToken("CHZ", 100000000);
        mockAzuro.addToken("PSG", 200000000);
        
        string[] memory tokens = mockAzuro.getSupportedTokens();
        assertEq(tokens.length, 2);
        assertEq(tokens[0], "CHZ");
        assertEq(tokens[1], "PSG");
    }
} 