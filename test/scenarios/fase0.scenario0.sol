// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../src/tokens/HypeToken.sol";
import "../../src/oracle/Oracle.sol";
import "../../src/mocks/MockAzuro.sol";
import "../../src/mocks/MockAzuro.sol";
import "../../src/fanify/Funify.sol";
import "../BaseSetup.t.sol";

contract Fase0Cenario0Test is BaseSetup {
    HypeToken public token;
    Oracle public oracle;
    Funify public funify;
    address casa = address(0xCAFE);
    address payable apostador1;
    address payable apostador2;
    address payable apostador3;
    address payable apostador4;
    address payable apostador5;

    function setUp() public override {
        super.setUp();
        token = new HypeToken();
        MockAzuro mockAzuro = new MockAzuro();
        oracle = new Oracle(address(mockAzuro));
        // Deploy Funify com casa como owner
        vm.prank(casa);
        funify = new Funify(address(token), address(oracle));

        // Set Funify contract in HypeToken to allow transfers
        vm.prank(address(this));
        token.setFanifyContract(address(funify));

        uint256 seasonId = oracle.currentSeasonId();
        // Simular criação do jogo no futuro
        uint256 desiredStart = block.timestamp + 3600;
        vm.warp(desiredStart - 100); // 100 segundos antes do início
        oracle.scheduleMatch(seasonId, 0x11111111, "AAA", "BBB", "#aaa_bbb");

        // Update hype (80% for Team A, 20% for Team B)
        oracle.updateHype(0x11111111, 8000, 2000);

        // Salvar timestamps para uso no teste
        uint256 startTimestamp = oracle.getStartTimestamp(0x11111111);
        uint256 duration = oracle.getGameTime(0x11111111);
        vm.store(address(this), bytes32(uint256(0)), bytes32(startTimestamp));
        vm.store(address(this), bytes32(uint256(1)), bytes32(duration));

        apostador1 = createUsers(1)[0];
        apostador2 = createUsers(2)[1];
        apostador3 = createUsers(3)[2];
        apostador4 = createUsers(4)[3];
        apostador5 = createUsers(5)[4];

        token.mint(apostador1, 10000 ether);
        token.mint(apostador2, 10000 ether);
        token.mint(apostador3, 10000 ether);
        token.mint(apostador4, 10000 ether);
        token.mint(apostador5, 10000 ether);

        vm.prank(apostador1);
        token.approve(address(funify), type(uint256).max);
        vm.prank(apostador2);
        token.approve(address(funify), type(uint256).max);
        vm.prank(apostador3);
        token.approve(address(funify), type(uint256).max);
        vm.prank(apostador4);
        token.approve(address(funify), type(uint256).max);
        vm.prank(apostador5);
        token.approve(address(funify), type(uint256).max);
    }

    function getTimestamps() internal view returns (uint256 startTimestamp, uint256 duration) {
        startTimestamp = uint256(vm.load(address(this), bytes32(uint256(0))));
        duration = uint256(vm.load(address(this), bytes32(uint256(1))));
    }

    function testCenarioSimples() public {
        (uint256 startTimestamp, uint256 duration) = getTimestamps();
        
        // Avançar para antes do início para apostar
        vm.warp(startTimestamp - 10);
        
        // Apostador 1 aposta no Time A
        vm.prank(apostador1);
        funify.placeBet(0x11111111, true, 100 ether);
        // Apostador 3 aposta no Time A
        vm.prank(apostador3);
        funify.placeBet(0x11111111, true, 300 ether);
        // Apostador 5 aposta no Time A
        vm.prank(apostador5);
        funify.placeBet(0x11111111, true, 500 ether);
        // Apostador 4 aposta no Time B
        vm.prank(apostador4);
        funify.placeBet(0x11111111, false, 400 ether);
        // Apostador 2 aposta no Time B
        vm.prank(apostador2);
        funify.placeBet(0x11111111, false, 200 ether);

        // Avançar para o início do jogo para updateScore
        vm.warp(startTimestamp + 1);
        // Atualizar placar: Time A vence
        oracle.updateScore(0x11111111, 3, 2);
        (uint8 A, uint8 B) = oracle.getMatchGoals(0x11111111);
        assertEq(A, 3);
        assertEq(B, 2);

        // Avançar para depois do fim do jogo para claim
        vm.warp(startTimestamp + duration + 1);

        // Apostadores do Time A retiram prêmio
        uint256 saldoAntes1 = token.balanceOf(apostador1);
        vm.prank(apostador1);
        funify.claimPrize(0x11111111);
        assertGt(token.balanceOf(apostador1), saldoAntes1, "Apostador1 sem ganho");

        uint256 saldoAntes3 = token.balanceOf(apostador3);
        vm.prank(apostador3);
        funify.claimPrize(0x11111111);
        assertGt(token.balanceOf(apostador3), saldoAntes3, "Apostador3 sem ganho");

        uint256 saldoAntes5 = token.balanceOf(apostador5);
        vm.prank(apostador5);
        funify.claimPrize(0x11111111);
        assertGt(token.balanceOf(apostador5), saldoAntes5, "Apostador5 sem ganho");

        // Apostadores do Time B não recebem nada
        vm.prank(apostador2);
        vm.expectRevert(bytes("E025")); // Espera revert porque apostador2 perdeu
        funify.claimPrize(0x11111111);

        vm.prank(apostador4);
        vm.expectRevert(bytes("E025")); // Espera revert porque apostador4 perdeu
        funify.claimPrize(0x11111111);
    }
}
