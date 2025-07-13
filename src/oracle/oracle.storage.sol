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

    struct MatchHype {
        uint256 HypeA;
        uint256 HypeB;
        uint8 goalsA;
        uint8 goalsB;
        uint256 startTimestamp; // Quando o jogo começa (timestamp futuro)
        uint256 duration; // Duração do jogo em segundos
        string teamAAbbreviation; // Sigla do Time A (ex: "PSG", "REAL")
        string teamBAbbreviation; // Sigla do Time B (ex: "BAR", "JUV")
        string hashtag;
    }

    mapping(bytes4 hypeId => MatchHype) public matchHypes;
    bytes4[] public hypeIds; // Lista de todos os hypeIds

    /**
     * @dev Construtor que inicializa os contratos externos
     * @param _mockAzuro Endereço do contrato MockAzuro
     */
    constructor(address _mockAzuro) {
        owner = msg.sender;
        mockAzuro = MockAzuro(_mockAzuro);
    }
} 