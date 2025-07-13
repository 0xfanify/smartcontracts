// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../src/tokens/HypeToken.sol";
import "../../src/oracle/Oracle.sol";
import "../../src/mocks/MockAzuro.sol";
import "../../src/fanify/Funify.sol";
import "../BaseSetup.t.sol";

contract Fase2Cenario2Test is BaseSetup {
    HypeToken public token;
    Oracle public oracle;
    Funify public funify;
    address casa = address(0xCAFE);
    address payable[] apostadores;

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

        // Schedule match for future time
        oracle.scheduleMatch(0x12345678, "AAA", "BBB", "#aaa_bbb");

        // Update hype (70% for Team A, 30% for Team B)
        oracle.updateHype(0x12345678, 7000, 3000);

        // Salvar timestamps para uso no teste
        uint256 startTimestamp = oracle.getStartTimestamp(0x12345678);
        uint256 duration = oracle.getGameTime(0x12345678);
        vm.store(address(this), bytes32(uint256(0)), bytes32(startTimestamp));
        vm.store(address(this), bytes32(uint256(1)), bytes32(duration));

        apostadores = createUsers(10);
        for (uint256 i = 0; i < 10; i++) {
            token.mint(apostadores[i], 10000 ether);
            vm.prank(apostadores[i]);
            token.approve(address(funify), type(uint256).max);
        }
    }

    function getTimestamps() internal view returns (uint256 startTimestamp, uint256 duration) {
        startTimestamp = uint256(vm.load(address(this), bytes32(uint256(0))));
        duration = uint256(vm.load(address(this), bytes32(uint256(1))));
    }

    function testCenarioAleatorio2() public {
        (uint256 startTimestamp, uint256 duration) = getTimestamps();
        
        // Avançar para antes do início para apostar
        vm.warp(startTimestamp - 10);
        
        // Place random bets
        for (uint256 i = 0; i < 10; i++) {
            vm.prank(apostadores[i]);
            bool teamA = i < 3; // 3 no time A, 7 no time B
            uint256 amount = (200 + i * 100) * 1 ether;
            funify.placeBet(0x12345678, teamA, amount);
        }

        // Avançar para o início do jogo para updateScore
        vm.warp(startTimestamp + 1);
        // Random score - Team B wins
        oracle.updateScore(0x12345678, 0, 3);

        // Avançar para depois do fim do jogo para claim
        vm.warp(startTimestamp + duration + 1);

        // Winners claim prizes
        for (uint256 i = 0; i < 10; i++) {
            bool betOnTeamA = i < 3;
            bool teamBWon = 0 < 3; // Score: 0-3, Team B wins
            
            if (!betOnTeamA && teamBWon) { // Apostou no Team B e Team B venceu
                uint256 saldoAntes = token.balanceOf(apostadores[i]);
                vm.prank(apostadores[i]);
                funify.claimPrize(0x12345678);
                uint256 ganho = token.balanceOf(apostadores[i]) - saldoAntes;
                assertGt(ganho, 0, "Winner sem ganho");
            } else {
                vm.prank(apostadores[i]);
                vm.expectRevert(bytes("E025")); // Espera revert porque perdeu
                funify.claimPrize(0x12345678);
            }
        }
    }
}
