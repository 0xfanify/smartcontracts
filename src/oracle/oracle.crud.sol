// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OracleSec} from "./oracle.sec.sol";
import {MockAzuro} from "../mocks/MockAzuro.sol";

abstract contract OracleCrud is OracleSec {
    // 1. Criar um Jogo
    function scheduleMatch(
        bytes4 hypeId,
        uint256 startTimestamp,
        uint256 duration,
        string memory teamAAbbreviation,
        string memory teamBAbbreviation,
        string memory hashtag
    ) public onlyOwner {
        if (matchHypes[hypeId].startTimestamp != 0) revert(MatchAlreadyFinished);
        if (bytes(teamAAbbreviation).length == 0) revert(InvalidTeamAbbreviation);
        if (bytes(teamBAbbreviation).length == 0) revert(InvalidTeamAbbreviation);
        if (bytes(hashtag).length == 0) revert(OracleCallFailed);
        if (startTimestamp <= block.timestamp) revert(OracleCallFailed);
        if (duration == 0) revert(OracleCallFailed);

        matchHypes[hypeId] = MatchHype({
            startTimestamp: startTimestamp,
            duration: duration,
            HypeA: 0,
            HypeB: 0,
            goalsA: 0,
            goalsB: 0,
            teamAAbbreviation: teamAAbbreviation,
            teamBAbbreviation: teamBAbbreviation,
            hashtag: hashtag
        });

        hypeIds.push(hypeId);
        emit MatchScheduled(hypeId, startTimestamp, duration);
    }

    // 2. Alimentar esse jogo com hype (hype A, hype B)
    function updateHype(bytes4 hypeId, uint256 HypeA, uint256 HypeB)
        public
        onlyOwner
        onlyMatchExists(hypeId)
    {
        MatchHype storage matchHype = matchHypes[hypeId];
        if (block.timestamp >= matchHype.startTimestamp) revert(InvalidMatchStatus); // Só pode antes do início
        if (HypeA + HypeB != 10000) revert(InvalidHypeValues);
        matchHype.HypeA = HypeA;
        matchHype.HypeB = HypeB;
        emit HypeUpdated(hypeId, HypeA, HypeB);
    }

    // 3. Atualizar o placar do jogo (golA, golB)
    function updateScore(bytes4 hypeId, uint8 goalsA, uint8 goalsB)
        public
        onlyOwner
        onlyMatchExists(hypeId)
    {
        MatchHype storage matchHype = matchHypes[hypeId];
        if (block.timestamp < matchHype.startTimestamp) revert(InvalidMatchStatus); // Só pode depois do início
        if (block.timestamp >= matchHype.startTimestamp + matchHype.duration) revert(InvalidMatchStatus); // Só pode durante o jogo
        matchHype.goalsA = goalsA;
        matchHype.goalsB = goalsB;
        emit ScoreUpdated(hypeId, goalsA, goalsB);
    }

    // CRUD para startTimestamp e duration
    function updateStartTimestamp(bytes4 hypeId, uint256 newStartTimestamp)
        public
        onlyOwner
        onlyMatchExists(hypeId)
    {
        if (newStartTimestamp <= block.timestamp) revert(OracleCallFailed);
        matchHypes[hypeId].startTimestamp = newStartTimestamp;
    }

    function updateDuration(bytes4 hypeId, uint256 newDuration)
        public
        onlyOwner
        onlyMatchExists(hypeId)
    {
        if (newDuration == 0) revert(OracleCallFailed);
        matchHypes[hypeId].duration = newDuration;
    }

    function getStartTimestamp(bytes4 hypeId)
        public
        view
        onlyMatchExists(hypeId)
        returns (uint256)
    {
        return matchHypes[hypeId].startTimestamp;
    }

    function getDuration(bytes4 hypeId)
        public
        view
        onlyMatchExists(hypeId)
        returns (uint256)
    {
        return matchHypes[hypeId].duration;
    }
} 