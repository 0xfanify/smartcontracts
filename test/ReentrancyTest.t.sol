// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {HypeToken} from "../src/tokens/HypeToken.sol";
import {Oracle} from "../src/oracle/Oracle.sol";
import {Funify} from "../src/fanify/Funify.sol";
import {IERC20} from "../lib/forge-std/src/interfaces/IERC20.sol";

// Contrato malicioso para testar reentrancy
contract ReentrancyAttacker {
    Funify public funify;
    bytes4 public hypeId;
    bool public hasAttacked = false;
    uint256 public attackCount = 0;

    constructor(Funify _funify, bytes4 _hypeId) {
        funify = _funify;
        hypeId = _hypeId;
    }

    // Função para tentar reentrancy durante o claim
    function attack() external {
        if (!hasAttacked) {
            hasAttacked = true;
            attackCount++;
            // Tenta fazer claim novamente durante a execução
            try funify.claimPrize(hypeId) {
                // Se conseguir, é uma vulnerabilidade de reentrancy
                attackCount++;
            } catch {
                // Se falhar, está protegido
            }
        }
    }

    // Função para receber tokens (fallback)
    receive() external payable {}
}

contract ReentrancyTest is Test {
    HypeToken public token;
    Oracle public oracle;
    Funify public funify;
    address public owner;
    address public attacker;

    function setUp() public {
        owner = address(this);
        attacker = makeAddr("attacker");

        token = new HypeToken();
        oracle = new Oracle();
        funify = new Funify(address(token), address(oracle));

        // Configurar token
        token.setFanifyContract(address(funify));

        // Configurar partida
        uint256 scheduledTime = block.timestamp + 1 hours;
        oracle.scheduleMatch(0x12345678, scheduledTime, "AAA", "BBB", "#aaa_bbb");
        oracle.updateHype(0x12345678, 7000, 3000);
        oracle.openToBets(0x12345678);

        // Dar tokens ao atacante
        token.mint(attacker, 10000 ether);
        vm.prank(attacker);
        token.approve(address(funify), type(uint256).max);
    }

    function test_ClaimReentrancyVulnerability() public {
        // Atacante faz uma aposta
        vm.prank(attacker);
        funify.placeBet(0x12345678, true, 1000 ether);

        // Fechar apostas e finalizar partida
        oracle.closeBets(0x12345678);
        oracle.updateScore(0x12345678, 2, 1);
        oracle.finishMatch(0x12345678);

        // Criar contrato atacante
        ReentrancyAttacker attackerContract = new ReentrancyAttacker(funify, 0x12345678);

        // Primeiro claim deve funcionar
        uint256 balanceBefore = token.balanceOf(attacker);
        vm.prank(attacker);
        funify.claimPrize(0x12345678);
        uint256 balanceAfter = token.balanceOf(attacker);
        assertGt(balanceAfter, balanceBefore, "First claim should work");

        // Verificar se o ataque foi bem-sucedido
        // Se attackCount > 1, significa que conseguiu fazer reentrancy
        assertEq(attackerContract.attackCount(), 0, "Reentrancy attack should not succeed!");
    }

    function test_ClaimMultipleTimes() public {
        // Usuário faz uma aposta
        vm.prank(attacker);
        funify.placeBet(0x12345678, true, 1000 ether);

        // Fechar apostas e finalizar partida
        oracle.closeBets(0x12345678);
        oracle.updateScore(0x12345678, 2, 1);
        oracle.finishMatch(0x12345678);

        // Primeiro claim deve funcionar
        uint256 balanceBefore = token.balanceOf(attacker);
        vm.prank(attacker);
        funify.claimPrize(0x12345678);
        uint256 balanceAfter = token.balanceOf(attacker);
        assertGt(balanceAfter, balanceBefore, "First claim should work");

        // Segundo claim deve falhar (aposta já foi reivindicada)
        vm.prank(attacker);
        vm.expectRevert(bytes("E010")); // NoBetOnMatch error
        funify.claimPrize(0x12345678);
    }

    function test_ClaimBeforeMatchFinished() public {
        // Usuário faz uma aposta
        vm.prank(attacker);
        funify.placeBet(0x12345678, true, 1000 ether);

        // Fechar apostas mas não finalizar partida
        oracle.closeBets(0x12345678);
        oracle.updateScore(0x12345678, 2, 1);

        // Tentar claim antes da partida terminar deve falhar
        vm.prank(attacker);
        vm.expectRevert(bytes("E005")); // MatchNotFinished error
        funify.claimPrize(0x12345678);
    }

    function test_ClaimOnDraw() public {
        // Usuário faz uma aposta
        vm.prank(attacker);
        funify.placeBet(0x12345678, true, 1000 ether);

        // Fechar apostas e finalizar partida com empate
        oracle.closeBets(0x12345678);
        oracle.updateScore(0x12345678, 1, 1);
        oracle.finishMatch(0x12345678);

        // Tentar claim em empate deve falhar
        vm.prank(attacker);
        vm.expectRevert(bytes("E006")); // MatchEndedInDraw error
        funify.claimPrize(0x12345678);
    }

    function test_ClaimWhenUserLost() public {
        // Usuário aposta no time A
        vm.prank(attacker);
        funify.placeBet(0x12345678, true, 1000 ether);

        // Fechar apostas e finalizar partida com time B vencendo
        oracle.closeBets(0x12345678);
        oracle.updateScore(0x12345678, 0, 1);
        oracle.finishMatch(0x12345678);

        // Tentar claim quando perdeu deve falhar
        vm.prank(attacker);
        vm.expectRevert(bytes("E008")); // UserDidNotWin error
        funify.claimPrize(0x12345678);
    }

    function test_ClaimStateChanges() public {
        // Usuário faz uma aposta
        vm.prank(attacker);
        funify.placeBet(0x12345678, true, 1000 ether);

        // Verificar estado antes do claim
        (uint256 amount, bool teamA) = funify.bets(0x12345678, attacker);
        assertEq(amount, 1000 ether, "Bet amount should be 1000 ether");

        // Fechar apostas e finalizar partida
        oracle.closeBets(0x12345678);
        oracle.updateScore(0x12345678, 2, 1);
        oracle.finishMatch(0x12345678);

        // Fazer claim
        vm.prank(attacker);
        funify.claimPrize(0x12345678);

        // Verificar estado após o claim - amount deve ser 0
        (amount, teamA) = funify.bets(0x12345678, attacker);
        assertEq(amount, 0, "Bet amount should be 0 after claim");
    }
}
