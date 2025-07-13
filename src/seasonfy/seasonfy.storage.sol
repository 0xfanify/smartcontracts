// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Oracle} from "../oracle/Oracle.sol";
import {OracleStorage} from "../oracle/oracle.storage.sol";
import {HypeToken} from "../tokens/HypeToken.sol";
import {TeamNFT} from "../tokens/TeamNFT.sol";
import {SeasonfyError} from "./seasonfy.error.sol";
import {SeasonfyEvents} from "./seasonfy.events.sol";

/**
 * @title SeasonfyStorage
 * @dev Contrato base que define a estrutura de dados e constantes do sistema Seasonfy
 *
 * Este contrato trabalha com Fan Tokens e NFTs de times:
 * - Usuário faz stake de Fan Token
 * - Recebe HYPE na proporção de 1000 HYPE para 1 USD
 * - Recebe NFT do time (não-transferível)
 * - Só pode apostar a favor do time do NFT
 * - Lock até o fim da temporada
 */
abstract contract SeasonfyStorage is SeasonfyError, SeasonfyEvents {
    // Contratos externos
    HypeToken public immutable token; // Contrato do token HYPE
    Oracle public immutable oracle; // Contrato Oracle
    TeamNFT public immutable teamNFT; // Contrato NFT dos times
    address public immutable mockFanX; // Contrato MockFanX para receber fan tokens
    address public immutable owner; // Endereço do owner do contrato

    /**
     * @dev Estrutura para rastrear stakes dos usuários
     * @param fanTokenAmount Quantidade de Fan Token staked
     * @param hypeAmount Quantidade de HYPE emitida
     * @param teamId ID do time do NFT
     * @param seasonId ID da temporada
     * @param nftTokenId ID do NFT mintado
     * @param stakedAt Timestamp do stake
     */
    struct Stake {
        uint256 fanTokenAmount; // Amount of Fan Token staked
        uint256 hypeAmount; // Amount of HYPE minted
        uint256 teamId; // Team ID from NFT
        uint256 seasonId; // Season ID
        uint256 nftTokenId; // NFT token ID
        uint256 stakedAt; // Timestamp when staked
    }

    /**
     * @dev Estrutura para rastrear apostas dos usuários
     * @param amount Quantidade de HYPE apostada
     * @param teamA true para Time A, false para Time B
     */
    struct Bet {
        uint256 amount; // Amount of HYPE bet
        bool teamA; // true for Team A, false for Team B
    }

    // Mappings para armazenar dados do sistema
    mapping(address => Stake) public stakes; // Stakes por usuário
    mapping(bytes4 => mapping(address => Bet)) public bets; // Apostas por match e usuário
    mapping(bytes4 => uint256) public prizePoolA; // Pool de prêmios para Time A
    mapping(bytes4 => uint256) public prizePoolB; // Pool de prêmios para Time B
    mapping(bytes4 => uint256) public houseProfit; // Lucro da casa por match

    // Configurações da temporada
    uint256 public seasonEndTimestamp; // Timestamp do fim da temporada
    uint256 public constant SEASON_DURATION = 365 days; // Duração da temporada

    // Taxa da casa (5%)
    uint256 public constant HOUSE_FEE = 5e16; // 5% = 0.05 * 1e18

    /**
     * @dev Construtor que inicializa os contratos externos
     * @param _token Endereço do contrato HypeToken
     * @param _oracle Endereço do contrato Oracle
     * @param _teamNFT Endereço do contrato TeamNFT
     * @param _mockFanX Endereço do contrato MockFanX
     */
    constructor(address _token, address _oracle, address _teamNFT, address _mockFanX) {
        token = HypeToken(_token);
        oracle = Oracle(_oracle);
        teamNFT = TeamNFT(_teamNFT);
        mockFanX = _mockFanX;
        owner = msg.sender;
        
        // Inicializa a temporada atual
        seasonEndTimestamp = block.timestamp + SEASON_DURATION;
    }
} 