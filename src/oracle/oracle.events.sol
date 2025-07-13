// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract OracleEvents {
    // Events para temporadas
    event SeasonCreated(uint256 indexed seasonId, uint256 startTimestamp, uint256 endTimestamp);
    event SeasonEnded(uint256 indexed seasonId);
    event CurrentSeasonUpdated(uint256 indexed newSeasonId);

    // Events para cada etapa
    event MatchScheduled(bytes4 indexed hypeId, uint256 indexed seasonId, uint256 startTimestamp, uint256 duration);
    event HypeUpdated(bytes4 indexed hypeId, uint256 HypeA, uint256 HypeB);
    event ScoreUpdated(bytes4 indexed hypeId, uint8 goalsA, uint8 goalsB);
} 