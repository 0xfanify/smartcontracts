// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Errors} from "../errors/Errors.sol";

/**
 * @title OracleError
 * @dev Contrato que herda os erros padronizados do sistema Oracle
 */
abstract contract OracleError is Errors {
    // Este contrato agora herda todos os erros do contrato centralizado Errors
} 