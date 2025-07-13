// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {HypeToken} from "../src/tokens/HypeToken.sol";
import {Oracle} from "../src/oracle/Oracle.sol";
import {MockAzuro} from "../src/mocks/MockAzuro.sol";
import {Funify} from "../src/fanify/Funify.sol";
import {FunifyError} from "../src/fanify/fanify.error.sol";

contract TimeValidationTest is Test, FunifyError {
    HypeToken public token;
    Oracle public oracle;
    MockAzuro public mockAzuro;
    Funify public funify;
    address public owner;
    address public user;
    
    function setUp() public {
        owner = address(this);
        user = address(0x123);
        
        token = new HypeToken();
        mockAzuro = new MockAzuro();
        oracle = new Oracle(address(mockAzuro));
        funify = new Funify(address(token), address(oracle));
        
        // Configurar token
        token.setFanifyContract(address(funify));
        
        // Dar tokens ao usuário
        token.mint(user, 10000 ether);
        vm.prank(user);
        token.approve(address(funify), type(uint256).max);
    }
    
    function test_PlaceBetBeforeMatchStart() public {
        // Agendar jogo para 1 hora no futuro
        uint256 startTimestamp = block.timestamp + 3600;
        uint256 duration = 7200;
        oracle.scheduleMatch(0x12345678, "AAA", "BBB", "#aaa_bbb");
        oracle.updateHype(0x12345678, 7000, 3000);
        // Para os testes de aposta, não iniciar o jogo ainda
        
        // Aposta deve funcionar antes do início do jogo
        vm.prank(user);
        funify.placeBet(0x12345678, true, 1000 ether);
        
        // Verificar se a aposta foi registrada
        (uint256 amount, bool teamA) = funify.bets(0x12345678, user);
        assertEq(amount, 1000 ether);
        assertTrue(teamA);
    }
    
    function test_PlaceBetAfterMatchStart() public {
        // Agendar jogo para 1 hora no futuro
        uint256 startTimestamp = block.timestamp + 3600;
        uint256 duration = 7200;
        oracle.scheduleMatch(0x12345678, "AAA", "BBB", "#aaa_bbb");
        oracle.updateHype(0x12345678, 7000, 3000);
        // Para os testes de aposta, não iniciar o jogo ainda
        
        // Avançar o tempo para depois do início do jogo
        vm.warp(startTimestamp + 1);
        
        // Aposta deve falhar após o início do jogo
        vm.prank(user);
        vm.expectRevert();
        funify.placeBet(0x12345678, true, 1000 ether);
    }
    
    function test_PlaceBetExactlyAtMatchStart() public {
        // Agendar jogo para 1 hora no futuro
        uint256 startTimestamp = block.timestamp + 3600;
        uint256 duration = 7200;
        oracle.scheduleMatch(0x12345678, "AAA", "BBB", "#aaa_bbb");
        oracle.updateHype(0x12345678, 7000, 3000);
        // Para os testes de aposta, não iniciar o jogo ainda
        
        // Avançar o tempo para exatamente o início do jogo
        vm.warp(startTimestamp);
        
        // Aposta deve falhar exatamente no início do jogo
        vm.prank(user);
        vm.expectRevert();
        funify.placeBet(0x12345678, true, 1000 ether);
    }
    
    function test_PlaceBetOneSecondBeforeMatchStart() public {
        // Agendar jogo para 1 hora no futuro
        uint256 startTimestamp = block.timestamp + 3600;
        uint256 duration = 7200;
        oracle.scheduleMatch(0x12345678, "AAA", "BBB", "#aaa_bbb");
        oracle.updateHype(0x12345678, 7000, 3000);
        // Para os testes de aposta, não iniciar o jogo ainda
        
        // Avançar o tempo para 1 segundo antes do início do jogo
        vm.warp(startTimestamp - 1);
        
        // Aposta deve funcionar 1 segundo antes do início
        vm.prank(user);
        funify.placeBet(0x12345678, true, 1000 ether);
        
        // Verificar se a aposta foi registrada
        (uint256 amount, bool teamA) = funify.bets(0x12345678, user);
        assertEq(amount, 1000 ether);
        assertTrue(teamA);
    }
} 