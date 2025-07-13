// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {HypeToken} from "../src/tokens/HypeToken.sol";
import {Oracle} from "../src/oracle/Oracle.sol";
import {MockAzuro} from "../src/oracle/MockAzuro.sol";
import {TeamNFT} from "../src/tokens/TeamNFT.sol";
import {MockFanX} from "../src/mocks/MockFanX.sol";
import {Seasonfy} from "../src/seasonfy/Seasonfy.sol";

contract DeploySeasonfyScript is Script {
    function setUp() public {}

    function run() public {
        address deployer = msg.sender;

        console.log("[1] Deployer address:", deployer);
        console.log("[2] Deployer balance:", deployer.balance);

        vm.startBroadcast();

        // Deploy HypeToken
        console.log("[3] Deploying HypeToken...");
        HypeToken hypeToken = new HypeToken();
        console.log("[4] HypeToken deployed at:", address(hypeToken));

        // Deploy MockAzuro
        console.log("[5] Deploying MockAzuro...");
        MockAzuro mockAzuro = new MockAzuro();
        console.log("[6] MockAzuro deployed at:", address(mockAzuro));

        // Deploy Oracle
        console.log("[7] Deploying Oracle...");
        Oracle oracle = new Oracle(address(mockAzuro));
        console.log("[8] Oracle deployed at:", address(oracle));

        // Deploy TeamNFT
        console.log("[9] Deploying TeamNFT...");
        TeamNFT teamNFT = new TeamNFT();
        console.log("[10] TeamNFT deployed at:", address(teamNFT));

        // Deploy MockFanX
        console.log("[11] Deploying MockFanX...");
        MockFanX mockFanX = new MockFanX();
        console.log("[12] MockFanX deployed at:", address(mockFanX));

        // Deploy Seasonfy
        console.log("[13] Deploying Seasonfy...");
        Seasonfy seasonfy = new Seasonfy(address(hypeToken), address(oracle), address(teamNFT), address(mockFanX));
        console.log("[14] Seasonfy deployed at:", address(seasonfy));

        // Configurar contratos
        console.log("[15] Configurando contratos...");
        
        // Set Seasonfy contract in HypeToken to allow transfers
        hypeToken.setFanifyContract(address(seasonfy));
        console.log("[16] HypeToken fanifyContract set to:", address(seasonfy));
        
        // Set Seasonfy contract in TeamNFT to allow minting/burning
        teamNFT.setStakeContract(address(seasonfy));
        console.log("[17] TeamNFT stakeContract set to:", address(seasonfy));

        vm.stopBroadcast();

        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("HypeToken:", address(hypeToken));
        console.log("MockAzuro:", address(mockAzuro));
        console.log("Oracle:", address(oracle));
        console.log("TeamNFT:", address(teamNFT));
        console.log("MockFanX:", address(mockFanX));
        console.log("Seasonfy:", address(seasonfy));
    }
} 