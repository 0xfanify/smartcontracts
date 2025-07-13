// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SeasonfyCrud} from "./seasonfy.crud.sol";
import {ERC20} from "lib/solady/src/tokens/ERC20.sol";

abstract contract SeasonfyStake is SeasonfyCrud {
    constructor(address _token, address _oracle, address _teamNFT, address _mockFanX) 
        SeasonfyCrud(_token, _oracle, _teamNFT, _mockFanX) {}

    /**
     * @dev Função para fazer stake de Fan Token
     * @param fanToken Endereço do Fan Token
     * @param amount Quantidade de Fan Token para fazer stake
     * @param teamId ID do time para o NFT
     */
    function stakeFanToken(address fanToken, uint256 amount, uint256 teamId) 
        external 
        onlyValidStake(fanToken, amount) 
    {
        // Transferir Fan Token do usuário para o MockFanX
        if (!ERC20(fanToken).transferFrom(msg.sender, mockFanX, amount)) {
            revert(TokenTransferFailed);
        }

        // Buscar preço do Fan Token no oracle
        uint256 fanTokenPrice = oracle.getTokenPrice("CHZ"); // Usando CHZ como referência
        
        // Calcular quantidade de HYPE a emitir (1000 HYPE = 1 USD)
        uint256 usdValue = (amount * fanTokenPrice) / 1e8; // valor em USD, 18 casas
        uint256 hypeAmount = usdValue * 1000; // 1000 HYPE por USD, mantém 18 casas
        
        // Emitir HYPE para o usuário
        token.mintBySeasonfy(msg.sender, hypeAmount);
        
        // Mintar NFT do time
        uint256 nftTokenId = teamNFT.mintTo(msg.sender, teamId, 1); // seasonId = 1 para primeira temporada
        
        // Registrar stake
        stakes[msg.sender] = Stake({
            fanTokenAmount: amount,
            hypeAmount: hypeAmount,
            teamId: teamId,
            seasonId: 1, // Primeira temporada
            nftTokenId: nftTokenId,
            stakedAt: block.timestamp
        });

        emit FanTokenStaked(msg.sender, fanToken, amount, hypeAmount, teamId, 1, nftTokenId);
    }

    /**
     * @dev Função para fazer unstake de Fan Token (apenas após fim da temporada)
     */
    function unstakeFanToken() external onlyValidUnstake {
        Stake storage stake = stakes[msg.sender];
        
        // Queimar NFT
        teamNFT.burn(stake.nftTokenId);
        
        // Transferir Fan Token de volta para o usuário via MockFanX
        // Aqui você precisaria implementar a lógica para identificar qual Fan Token foi staked
        // Por enquanto, vamos apenas emitir o evento
        
        uint256 fanTokenAmount = stake.fanTokenAmount;
        uint256 nftTokenId = stake.nftTokenId;
        
        // Limpar stake
        delete stakes[msg.sender];
        
        emit FanTokenUnstaked(msg.sender, address(0), fanTokenAmount, nftTokenId);
    }

    /**
     * @dev Função para atualizar o fim da temporada (apenas owner)
     * @param newEndTimestamp Novo timestamp do fim da temporada
     */
    function updateSeasonEndTimestamp(uint256 newEndTimestamp) external onlyOwner {
        if (newEndTimestamp <= block.timestamp) {
            revert(InvalidStakeAmount);
        }
        oracle.updateSeasonEndTimestamp(newEndTimestamp);
        emit SeasonEndTimestampUpdated(newEndTimestamp);
    }
} 