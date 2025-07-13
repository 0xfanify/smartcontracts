// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SeasonfyStake} from "./seasonfy.stake.sol";

abstract contract SeasonfyPlaceBet is SeasonfyStake {
    constructor(address _token, address _oracle, address _teamNFT, address _mockFanX) 
        SeasonfyStake(_token, _oracle, _teamNFT, _mockFanX) {}

    /**
     * @dev Função para fazer aposta (apenas a favor do time do NFT)
     * @param hypeId ID do jogo
     * @param teamA true para Time A, false para Time B
     * @param amount Quantidade de HYPE para apostar
     */
    function placeBet(bytes4 hypeId, bool teamA, uint256 amount) 
        external 
        onlyValidPlaceBet(hypeId, amount)
        onlyCanBetForTeam(hypeId, teamA)
    {
        // Transferir HYPE do usuário para o contrato
        if (!token.transferFrom(msg.sender, address(this), amount)) {
            revert(TokenTransferFailed);
        }

        // Registrar aposta
        bets[hypeId][msg.sender] = Bet({amount: amount, teamA: teamA});
        if (teamA) {
            prizePoolA[hypeId] += amount;
        } else {
            prizePoolB[hypeId] += amount;
        }

        emit BetPlaced(hypeId, msg.sender, teamA, amount);
    }
} 