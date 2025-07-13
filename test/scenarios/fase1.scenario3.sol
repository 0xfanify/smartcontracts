// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../src/tokens/HypeToken.sol";
import "../../src/oracle/Oracle.sol";
import "../../src/oracle/MockAzuro.sol";
import "../../src/fanify/Funify.sol";
import "../BaseSetup.t.sol";

contract Fase1Cenario3Test is BaseSetup {
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
        uint256 startTimestamp = block.timestamp + 3600;
        uint256 duration = 7200;
        oracle.scheduleMatch(0x12345678, startTimestamp, duration, "AAA", "BBB", "#aaa_bbb");

        // Update hype (70% for Team A, 30% for Team B)
        oracle.updateHype(0x12345678, 7000, 3000);

        // Salvar timestamps para uso no teste
        vm.store(address(this), bytes32(uint256(0)), bytes32(startTimestamp));
        vm.store(address(this), bytes32(uint256(1)), bytes32(duration));

        // Inicializar apostadores
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

    function testAposFechamento() public {
        (uint256 startTimestamp, uint256 duration) = getTimestamps();
        
        // Avançar para antes do início para apostar
        vm.warp(startTimestamp - 10);
        
        // Place some bets while match is open
        for (uint256 i = 0; i < 10; i++) {
            vm.prank(apostadores[i]);
            funify.placeBet(0x12345678, true, 100 ether);
        }

        // Avançar para depois do início para fechar apostas
        vm.warp(startTimestamp + 1);

        // Try to place a bet after match is closed - should revert
        vm.expectRevert(bytes("E022"));
        vm.prank(apostadores[0]);
        funify.placeBet(0x12345678, true, 100 ether);
    }
}
