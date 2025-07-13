// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {TeamNFT} from "../src/TeamNFT.sol";

contract DeployTeamNFT is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address stakeContract = vm.envAddress("STAKE_CONTRACT");
        
        vm.startBroadcast(deployerPrivateKey);
        
        TeamNFT teamNFT = new TeamNFT();
        teamNFT.setStakeContract(stakeContract);
        
        vm.stopBroadcast();
        
        console.log("TeamNFT deployed at:", address(teamNFT));
        console.log("Stake contract set to:", stakeContract);
    }
} 