// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OracleQuery} from "./oracle.query.sol";

abstract contract OracleTokenPrice is OracleQuery {
    /**
     * @dev Atualiza o preço de um token no MockAzuro (apenas owner)
     * @param _tokenSymbol Símbolo do token
     * @param _price Novo preço em USD com 8 casas decimais
     */
    function updateTokenPrice(string memory _tokenSymbol, uint256 _price) public onlyOwner {
        mockAzuro.updateTokenPrice(_tokenSymbol, _price);
    }
    
    /**
     * @dev Obtém o preço de um token do MockAzuro
     * @param _tokenSymbol Símbolo do token
     * @return Preço do token em USD com 8 casas decimais
     */
    function getTokenPrice(string memory _tokenSymbol) public view returns (uint256) {
        return mockAzuro.getPrice(_tokenSymbol);
    }
} 