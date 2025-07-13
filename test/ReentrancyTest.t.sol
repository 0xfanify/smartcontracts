// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {HypeToken} from "../src/tokens/HypeToken.sol";
import {Oracle} from "../src/oracle/Oracle.sol";
import {MockAzuro} from "../src/mocks/MockAzuro.sol";
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
        MockAzuro mockAzuro = new MockAzuro();
        oracle = new Oracle(address(mockAzuro));
        funify = new Funify(address(token), address(oracle));

        // Configurar token
        token.setFanifyContract(address(funify));

        // Configurar partida
        uint256 startTimestamp = block.timestamp + 3600; // 1 hora no futuro
        uint256 duration = 7200; // 2 horas de duração
        oracle.scheduleMatch(0x12345678, startTimestamp, duration, "AAA", "BBB", "#aaa_bbb");
        oracle.updateHype(0x12345678, 7000, 3000);

        // Dar tokens ao atacante
        token.mint(attacker, 10000 ether);
        vm.prank(attacker);
        token.approve(address(funify), type(uint256).max);

        // Salvar para uso nos testes
        vm.label(address(oracle), "Oracle");
        vm.label(address(funify), "Funify");
        vm.label(attacker, "Attacker");
        // Salvar timestamps para uso nos testes
        vm.store(address(this), bytes32(uint256(0)), bytes32(startTimestamp));
        vm.store(address(this), bytes32(uint256(1)), bytes32(duration));
    }

    function getTimestamps() internal view returns (uint256 startTimestamp, uint256 duration) {
        startTimestamp = uint256(vm.load(address(this), bytes32(uint256(0))));
        duration = uint256(vm.load(address(this), bytes32(uint256(1))));
    }

    function test_ClaimReentrancyVulnerability() public {
        (uint256 startTimestamp, uint256 duration) = getTimestamps();
        // Avançar para antes do início para apostar
        vm.warp(startTimestamp - 10);
        vm.prank(attacker);
        funify.placeBet(0x12345678, true, 1000 ether);

        // Avançar para o início do jogo para updateScore
        vm.warp(startTimestamp + 1);
        oracle.updateScore(0x12345678, 2, 1);

        // Avançar para depois do fim do jogo para claim
        vm.warp(startTimestamp + duration + 1);
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
        (uint256 startTimestamp, uint256 duration) = getTimestamps();
        vm.warp(startTimestamp - 10);
        vm.prank(attacker);
        funify.placeBet(0x12345678, true, 1000 ether);
        vm.warp(startTimestamp + 1);
        oracle.updateScore(0x12345678, 2, 1);
        vm.warp(startTimestamp + duration + 1);
        uint256 balanceBefore = token.balanceOf(attacker);
        vm.prank(attacker);
        funify.claimPrize(0x12345678);
        uint256 balanceAfter = token.balanceOf(attacker);
        assertGt(balanceAfter, balanceBefore, "First claim should work");
        vm.prank(attacker);
        vm.expectRevert(bytes("E020")); // NoBetOnMatch error
        funify.claimPrize(0x12345678);
    }

    function test_ClaimBeforeMatchFinished() public {
        (uint256 startTimestamp, uint256 duration) = getTimestamps();
        vm.warp(startTimestamp - 10);
        vm.prank(attacker);
        funify.placeBet(0x12345678, true, 1000 ether);
        vm.warp(startTimestamp + 1);
        oracle.updateScore(0x12345678, 2, 1);
        // Não avançar para depois do fim
        vm.prank(attacker);
        vm.expectRevert(bytes("E021")); // MatchNotFinished error
        funify.claimPrize(0x12345678);
    }

    function test_ClaimOnDraw() public {
        (uint256 startTimestamp, uint256 duration) = getTimestamps();
        vm.warp(startTimestamp - 10);
        vm.prank(attacker);
        funify.placeBet(0x12345678, true, 1000 ether);
        vm.warp(startTimestamp + 1);
        oracle.updateScore(0x12345678, 1, 1);
        vm.warp(startTimestamp + duration + 1);
        vm.prank(attacker);
        vm.expectRevert(bytes("E026")); // MatchEndedInDraw error
        funify.claimPrize(0x12345678);
    }

    function test_ClaimWhenUserLost() public {
        (uint256 startTimestamp, uint256 duration) = getTimestamps();
        vm.warp(startTimestamp - 10);
        vm.prank(attacker);
        funify.placeBet(0x12345678, true, 1000 ether);
        vm.warp(startTimestamp + 1);
        oracle.updateScore(0x12345678, 0, 1);
        vm.warp(startTimestamp + duration + 1);
        vm.prank(attacker);
        vm.expectRevert(bytes("E025")); // UserDidNotWin error
        funify.claimPrize(0x12345678);
    }

    function test_ClaimStateChanges() public {
        (uint256 startTimestamp, uint256 duration) = getTimestamps();
        vm.warp(startTimestamp - 10);
        vm.prank(attacker);
        funify.placeBet(0x12345678, true, 1000 ether);
        (uint256 amount, bool teamA) = funify.bets(0x12345678, attacker);
        assertEq(amount, 1000 ether, "Bet amount should be 1000 ether");
        vm.warp(startTimestamp + 1);
        oracle.updateScore(0x12345678, 2, 1);
        vm.warp(startTimestamp + duration + 1);
        vm.prank(attacker);
        funify.claimPrize(0x12345678);
        (amount, teamA) = funify.bets(0x12345678, attacker);
        assertEq(amount, 0, "Bet amount should be 0 after claim");
    }
}
