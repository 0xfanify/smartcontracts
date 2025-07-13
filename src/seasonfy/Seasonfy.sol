// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SeasonfyClaim} from "./seasonfy.claim.sol";

contract Seasonfy is SeasonfyClaim {
    constructor(address _token, address _oracle, address _teamNFT, address _mockFanX) 
        SeasonfyClaim(_token, _oracle, _teamNFT, _mockFanX) {}

    /**
     * @dev Função para sacar lucro da casa
     * @param hypeId ID do jogo
     */
    function withdrawHouseProfit(bytes4 hypeId) external onlyOwner {
        uint256 profit = houseProfit[hypeId];
        if (profit == 0) {
            revert(NoProfitToWithdraw);
        }

        houseProfit[hypeId] = 0;
        if (!token.transfer(owner, profit)) {
            revert(TokenTransferFailed);
        }

        emit HouseProfitWithdrawn(hypeId, profit);
    }
} 