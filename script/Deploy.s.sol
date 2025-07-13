// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {HypeToken} from "../src/tokens/HypeToken.sol";
import {Oracle} from "../src/oracle/Oracle.sol";
import {MockAzuro} from "../src/mocks/MockAzuro.sol";
import {Funify} from "../src/fanify/Funify.sol";
import {TeamNFT} from "../src/tokens/TeamNFT.sol";
import {MockFanX} from "../src/mocks/MockFanX.sol";
import {Seasonfy} from "../src/seasonfy/Seasonfy.sol";

contract DeployScript is Script {
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

        // Deploy Fanify
        console.log("[9] Deploying Fanify...");
        Funify fanify = new Funify(address(hypeToken), address(oracle));
        console.log("[10] Fanify deployed at:", address(fanify));

        // Deploy TeamNFT
        console.log("[11] Deploying TeamNFT...");
        TeamNFT teamNFT = new TeamNFT();
        console.log("[12] TeamNFT deployed at:", address(teamNFT));

        // Deploy MockFanX
        console.log("[13] Deploying MockFanX...");
        MockFanX mockFanX = new MockFanX();
        console.log("[14] MockFanX deployed at:", address(mockFanX));

        // Deploy Seasonfy
        console.log("[15] Deploying Seasonfy...");
        Seasonfy seasonfy = new Seasonfy(address(hypeToken), address(oracle), address(teamNFT), address(mockFanX));
        console.log("[16] Seasonfy deployed at:", address(seasonfy));

        // Set contract dependencies
        hypeToken.setFanifyContract(address(fanify));
        hypeToken.setSeasonfyContract(address(seasonfy));
        teamNFT.setStakeContract(address(seasonfy));

        vm.stopBroadcast();
    }
}
