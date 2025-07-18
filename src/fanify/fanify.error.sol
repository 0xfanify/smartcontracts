// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Errors} from "../errors/Errors.sol";

/**
 * @title FunifyError
 * @dev Contrato que herda os erros padronizados do sistema Funify
 */
abstract contract FunifyError is Errors {
    // Este contrato agora herda todos os erros do contrato centralizado Errors
}
