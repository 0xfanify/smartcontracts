// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract OracleEvents {
    // Events para cada etapa
    event MatchScheduled(bytes4 indexed hypeId, uint256 startTimestamp, uint256 duration);
    event HypeUpdated(bytes4 indexed hypeId, uint256 HypeA, uint256 HypeB);
    event ScoreUpdated(bytes4 indexed hypeId, uint8 goalsA, uint8 goalsB);
} 