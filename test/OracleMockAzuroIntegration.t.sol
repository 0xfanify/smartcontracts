// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Oracle} from "../src/oracle/Oracle.sol";
import {MockAzuro} from "../src/mocks/MockAzuro.sol";
import {FunifyError} from "../src/fanify/fanify.error.sol";

contract OracleMockAzuroIntegrationTest is Test, FunifyError {
    Oracle public oracle;
    MockAzuro public mockAzuro;
    address public owner;
    address public user;
    
    function setUp() public {
        owner = address(this);
        user = address(0x123);
        mockAzuro = new MockAzuro();
        oracle = new Oracle(address(mockAzuro));
    }
    
    function test_OracleConstructor() public view {
        assertEq(oracle.owner(), owner);
        assertEq(address(oracle.mockAzuro()), address(mockAzuro));
    }
    
    /**
     * @dev Teste que verifica que o Oracle NÃO pode atualizar preços no MockAzuro
     * porque apenas o owner do MockAzuro pode fazer isso (modelo de segurança escolhido)
     */
    function test_UpdateTokenPriceThroughOracle() public {
        // Primeiro adicionar o token no MockAzuro
        mockAzuro.addToken("CHZ", 100000000);
        
        // Tentar atualizar o preço através do Oracle deve falhar
        // porque o Oracle não é o owner do MockAzuro
        vm.expectRevert();
        oracle.updateTokenPrice("CHZ", 150000000);
        
        // O preço deve permanecer o mesmo
        assertEq(oracle.getTokenPrice("CHZ"), 100000000);
        assertEq(mockAzuro.getPrice("CHZ"), 100000000);
    }
    
    function test_GetTokenPriceThroughOracle() public {
        mockAzuro.addToken("CHZ", 150000000); // $1.50
        
        assertEq(oracle.getTokenPrice("CHZ"), 150000000);
    }
    
    function test_UpdateTokenPriceNonOwner() public {
        vm.prank(user);
        vm.expectRevert();
        oracle.updateTokenPrice("CHZ", 100000000);
    }
    
    function test_GetTokenPriceNonExistent() public {
        vm.expectRevert();
        oracle.getTokenPrice("NONEXISTENT");
    }
} 