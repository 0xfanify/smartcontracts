// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract OracleError {
    string public constant MatchAlreadyFinished = "E000";
    string public constant InvalidHypeValues = "E003";
    string public constant MatchNotFound = "E013";
    string public constant InvalidMatchStatus = "E014";
    string public constant TeamAbbreviationsNotSet = "E019";
    string public constant InvalidTeamAbbreviation = "E020";
    string public constant OracleCallFailed = "E018";
    string public constant NotOwner = "E012";
} 