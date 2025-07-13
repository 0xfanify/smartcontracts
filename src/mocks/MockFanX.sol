// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "lib/solady/src/tokens/ERC20.sol";
import {Errors} from "../errors/Errors.sol";

contract MockFanX is Errors {
    address public immutable owner;
    
    // Mapeamento de endereço do token para quantidade staked
    mapping(address => uint256) public stakedTokens;
    
    // Lista de tokens staked
    address[] public stakedTokenAddresses;
    
    event TokenStaked(address indexed token, address indexed user, uint256 amount);
    event TokenUnstaked(address indexed token, address indexed user, uint256 amount);
    
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
     * @dev Função para receber Fan Tokens do Seasonfy
     * @param token Endereço do Fan Token
     * @param user Endereço do usuário
     * @param amount Quantidade de tokens
     */
    function receiveFanToken(address token, address user, uint256 amount) external onlyOwner {
        if (amount == 0) revert(InvalidStakeAmount);
        
        // Se é um novo token, adiciona à lista
        if (stakedTokens[token] == 0) {
            stakedTokenAddresses.push(token);
        }
        
        stakedTokens[token] += amount;
        
        emit TokenStaked(token, user, amount);
    }
    
    /**
     * @dev Função para retornar Fan Token ao usuário
     * @param token Endereço do Fan Token
     * @param user Endereço do usuário
     * @param amount Quantidade de tokens
     */
    function returnFanToken(address token, address user, uint256 amount) external onlyOwner {
        if (amount == 0) revert(InvalidStakeAmount);
        if (stakedTokens[token] < amount) revert(InvalidStakeAmount);
        
        stakedTokens[token] -= amount;
        
        // Transferir token para o usuário
        if (!ERC20(token).transfer(user, amount)) {
            revert(TokenTransferFailed);
        }
        
        emit TokenUnstaked(token, user, amount);
    }
    
    /**
     * @dev Função para obter quantidade staked de um token
     * @param token Endereço do token
     * @return Quantidade staked
     */
    function getStakedAmount(address token) external view returns (uint256) {
        return stakedTokens[token];
    }
    
    /**
     * @dev Função para obter todos os tokens staked
     * @return Array com endereços dos tokens
     */
    function getStakedTokens() external view returns (address[] memory) {
        return stakedTokenAddresses;
    }
    
    /**
     * @dev Função para obter número de tokens staked
     * @return Número de tokens
     */
    function getStakedTokensCount() external view returns (uint256) {
        return stakedTokenAddresses.length;
    }
} 