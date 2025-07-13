// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SeasonfyEvents
 * @dev Contrato que define os eventos do sistema Seasonfy
 */
abstract contract SeasonfyEvents {
    // Eventos de stake
    event FanTokenStaked(
        address indexed user,
        address indexed fanToken,
        uint256 fanTokenAmount,
        uint256 hypeAmount,
        uint256 teamId,
        uint256 seasonId,
        uint256 nftTokenId
    );

    event FanTokenUnstaked(
        address indexed user,
        address indexed fanToken,
        uint256 fanTokenAmount,
        uint256 nftTokenId
    );

    // Eventos de aposta
    event BetPlaced(
        bytes4 indexed hypeId,
        address indexed user,
        bool teamA,
        uint256 amount
    );

    event PrizesDistributed(
        bytes4 indexed hypeId,
        address indexed user,
        uint256 amount
    );

    // Eventos de administração
    event HouseProfitWithdrawn(bytes4 indexed hypeId, uint256 amount);
    event SeasonEndTimestampUpdated(uint256 newTimestamp);
    event FanTokenAdded(address indexed fanToken, uint256 teamId);
    event FanTokenRemoved(address indexed fanToken);
} 