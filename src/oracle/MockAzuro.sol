// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FunifyError} from "../fanify/fanify.error.sol";

contract MockAzuro is FunifyError {
    address public immutable owner;
    
    // Mapeamento de símbolo do token para preço em USD (com 8 casas decimais)
    mapping(string => uint256) public tokenPrices;
    
    // Lista de tokens suportados
    string[] public supportedTokens;
    
    event PriceUpdated(string indexed tokenSymbol, uint256 price);
    event TokenAdded(string indexed tokenSymbol, uint256 initialPrice);
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert(NotOwner);
        }
        _;
    }
    
    /**
     * @dev Obtém o preço de um token em USD
     * @param _tokenSymbol Símbolo do token (ex: "CHZ", "PSG", "REAL")
     * @return Preço do token em USD com 8 casas decimais
     */
    function getPrice(string memory _tokenSymbol) public view returns (uint256) {
        uint256 price = tokenPrices[_tokenSymbol];
        if (price == 0) {
            revert(OracleCallFailed);
        }
        return price;
    }
    
    /**
     * @dev Atualiza o preço de um token (apenas owner)
     * @param _tokenSymbol Símbolo do token
     * @param _price Novo preço em USD com 8 casas decimais
     */
    function updateTokenPrice(string memory _tokenSymbol, uint256 _price) public onlyOwner {
        if (bytes(_tokenSymbol).length == 0) revert(OracleCallFailed);
        if (_price == 0) revert(OracleCallFailed);
        
        // Se é um novo token, adiciona à lista
        if (tokenPrices[_tokenSymbol] == 0) {
            supportedTokens.push(_tokenSymbol);
            emit TokenAdded(_tokenSymbol, _price);
        }
        
        tokenPrices[_tokenSymbol] = _price;
        emit PriceUpdated(_tokenSymbol, _price);
    }
    
    /**
     * @dev Adiciona um novo token com preço inicial
     * @param _tokenSymbol Símbolo do token
     * @param _initialPrice Preço inicial em USD com 8 casas decimais
     */
    function addToken(string memory _tokenSymbol, uint256 _initialPrice) public onlyOwner {
        if (bytes(_tokenSymbol).length == 0) revert(OracleCallFailed);
        if (_initialPrice == 0) revert(OracleCallFailed);
        if (tokenPrices[_tokenSymbol] != 0) revert(OracleCallFailed); // Token já existe
        
        supportedTokens.push(_tokenSymbol);
        tokenPrices[_tokenSymbol] = _initialPrice;
        
        emit TokenAdded(_tokenSymbol, _initialPrice);
    }
    
    /**
     * @dev Verifica se um token é suportado
     * @param _tokenSymbol Símbolo do token
     * @return true se o token é suportado
     */
    function isTokenSupported(string memory _tokenSymbol) public view returns (bool) {
        return tokenPrices[_tokenSymbol] != 0;
    }
    
    /**
     * @dev Retorna todos os tokens suportados
     * @return Array com símbolos dos tokens suportados
     */
    function getSupportedTokens() public view returns (string[] memory) {
        return supportedTokens;
    }
    
    /**
     * @dev Retorna o número de tokens suportados
     * @return Número de tokens suportados
     */
    function getSupportedTokensCount() public view returns (uint256) {
        return supportedTokens.length;
    }
} 