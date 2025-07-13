// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OracleError} from "./oracle.error.sol";
import {OracleEvents} from "./oracle.events.sol";
import {MockAzuro} from "../mocks/MockAzuro.sol";

/**
 * @title OracleStorage
 * @dev Contrato base que define a estrutura de dados e constantes do sistema Oracle
 *
 * Este contrato gerencia o estado dos jogos com as seguintes etapas:
 * 1. Scheduled - Jogo criado e agendado
 * 2. Started - Jogo iniciado (fechado para apostas)
 * 3. Finished - Jogo finalizado
 * 4. Canceled - Jogo cancelado
 */
abstract contract OracleStorage is OracleError, OracleEvents {
    address public immutable owner;
    MockAzuro public immutable mockAzuro;

    // Constantes de tempo
    uint256 public constant GAME_TIME = 7200; // 2 horas em segundos
    uint256 public constant SEASON_TIME = 5256000; // 2 meses em segundos (60 dias)

    /**
     * @dev Estrutura para rastrear temporadas
     * @param seasonId ID único da temporada
     * @param startTimestamp Timestamp de início da temporada
     * @param endTimestamp Timestamp de fim da temporada
     * @param isActive Se a temporada está ativa
     */
    struct Season {
        uint256 seasonId;
        uint256 startTimestamp;
        uint256 endTimestamp;
        bool isActive;
    }

    struct MatchHype {
        uint256 HypeA;
        uint256 HypeB;
        uint8 goalsA;
        uint8 goalsB;
        uint256 startTimestamp; // Quando o jogo começa (timestamp futuro)
        uint256 gameTime; // Duração do jogo em segundos (configurável)
        string teamAAbbreviation; // Sigla do Time A (ex: "PSG", "REAL")
        string teamBAbbreviation; // Sigla do Time B (ex: "BAR", "JUV")
        string hashtag;
        uint256 seasonId; // ID da temporada à qual o jogo pertence
    }

    mapping(bytes4 hypeId => MatchHype) public matchHypes;
    bytes4[] public hypeIds; // Lista de todos os hypeIds

    // Mappings para temporadas
    mapping(uint256 => Season) public seasons; // Temporadas por seasonId
    uint256[] public seasonIds; // Lista de todos os seasonIds
    uint256 public currentSeasonId; // ID da temporada atual

    /**
     * @dev Construtor que inicializa os contratos externos
     * @param _mockAzuro Endereço do contrato MockAzuro
     */
    constructor(address _mockAzuro) {
        owner = msg.sender;
        mockAzuro = MockAzuro(_mockAzuro);
        
        // Criar a primeira temporada automaticamente
        currentSeasonId = 1;
        seasons[currentSeasonId] = Season({
            seasonId: currentSeasonId,
            startTimestamp: block.timestamp,
            endTimestamp: block.timestamp + SEASON_TIME,
            isActive: true
        });
        seasonIds.push(currentSeasonId);
    }
} 