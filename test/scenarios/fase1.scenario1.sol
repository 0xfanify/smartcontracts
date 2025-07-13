// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../src/tokens/HypeToken.sol";
import "../../src/oracle/Oracle.sol";
import "../../src/mocks/MockAzuro.sol";
import "../../src/fanify/Funify.sol";
import "../BaseSetup.t.sol";

contract Fase1Cenario1Test is BaseSetup {
    HypeToken public token;
    Oracle public oracle;
    Funify public funify;
    address casa = address(0xCAFE);
    address payable[] apostadores;
    uint256[10] apostasA = [100, 200, 100, 200, 200, 200, 200, 400, 800, 1000];
    uint256[5] apostasB = [100, 200, 100, 800, 1000];

    function setUp() public override {
        super.setUp();
        token = new HypeToken();
        MockAzuro mockAzuro = new MockAzuro();
        oracle = new Oracle(address(mockAzuro));
        vm.prank(casa);
        funify = new Funify(address(token), address(oracle));

        // Set Funify contract in HypeToken to allow transfers
        vm.prank(address(this));
        token.setFanifyContract(address(funify));

        uint256 seasonId = oracle.currentSeasonId();
        // Simular criação do jogo no futuro
        uint256 desiredStart = block.timestamp + 3600;
        vm.warp(desiredStart - 100); // 100 segundos antes do início
        oracle.scheduleMatch(seasonId, 0x12345678, "AAA", "BBB", "#aaa_bbb");

        // Update hype (70% for Team A, 30% for Team B)
        oracle.updateHype(0x12345678, 7000, 3000);

        // Salvar timestamps para uso no teste
        uint256 startTimestamp = oracle.getStartTimestamp(0x12345678);
        uint256 duration = oracle.getGameTime(0x12345678);
        vm.store(address(this), bytes32(uint256(0)), bytes32(startTimestamp));
        vm.store(address(this), bytes32(uint256(1)), bytes32(duration));

        apostadores = createUsers(15);
        for (uint256 i = 0; i < 15; i++) {
            token.mint(apostadores[i], 10000 ether);
            vm.prank(apostadores[i]);
            token.approve(address(funify), type(uint256).max);
        }
    }

    function getTimestamps() internal view returns (uint256 startTimestamp, uint256 duration) {
        startTimestamp = uint256(vm.load(address(this), bytes32(uint256(0))));
        duration = uint256(vm.load(address(this), bytes32(uint256(1))));
    }

    function testCenario1() public {
        (uint256 startTimestamp, uint256 duration) = getTimestamps();
        
        // Avançar para antes do início para apostar
        vm.warp(startTimestamp - 10);
        
        // Place bets on Team A (10 users)
        for (uint256 i = 0; i < 10; i++) {
            vm.prank(apostadores[i]);
            funify.placeBet(0x12345678, true, apostasA[i] * 1 ether);
        }

        // Place bets on Team B (5 users)
        for (uint256 i = 0; i < 5; i++) {
            vm.prank(apostadores[10 + i]);
            funify.placeBet(0x12345678, false, apostasB[i] * 1 ether);
        }

        // Avançar para o início do jogo para updateScore
        vm.warp(startTimestamp + 1);
        // Update score: Team A wins (1-0)
        oracle.updateScore(0x12345678, 1, 0);

        // Avançar para depois do fim do jogo para claim
        vm.warp(startTimestamp + duration + 1);

        // Winners claim prizes (Team A bettors)
        uint256 totalPrize;
        for (uint256 i = 0; i < 10; i++) {
            uint256 saldoAntes = token.balanceOf(apostadores[i]);
            vm.prank(apostadores[i]);
            funify.claimPrize(0x12345678);
            uint256 ganho = token.balanceOf(apostadores[i]) - saldoAntes;
            assertGt(ganho, 0, "Apostador A sem ganho");
            totalPrize += ganho;
        }

        // Losers should not receive anything (Team B bettors)
        for (uint256 i = 10; i < 15; i++) {
            vm.prank(apostadores[i]);
            vm.expectRevert(bytes("E025")); // Espera revert porque perdeu
            funify.claimPrize(0x12345678);
        }

        // House withdraws profit
        vm.prank(casa);
        funify.withdrawHouseProfit(0x12345678);
        uint256 lucroCasa = token.balanceOf(casa);
        uint256 totalApostado = 5600 ether;
        assertEq(lucroCasa, totalApostado * 5 / 100, "Lucro da casa incorreto");
    }
}
