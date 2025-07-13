// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OracleSec} from "./oracle.sec.sol";
import {MockAzuro} from "../mocks/MockAzuro.sol";

abstract contract OracleCrud is OracleSec {
    // Enum para status do jogo
    enum GameStatus {
        NOT_STARTED, // Jogo ainda não começou
        IN_PROGRESS, // Jogo em andamento
        FINISHED     // Jogo finalizado
    }

    // 1. Criar um Jogo
    function scheduleMatch(
        bytes4 hypeId,
        string memory teamAAbbreviation,
        string memory teamBAbbreviation,
        string memory hashtag
    ) public onlyOwner {
        if (matchHypes[hypeId].startTimestamp != 0) revert(MatchAlreadyFinished);
        if (bytes(teamAAbbreviation).length == 0) revert(InvalidTeamAbbreviation);
        if (bytes(teamBAbbreviation).length == 0) revert(InvalidTeamAbbreviation);
        if (bytes(hashtag).length == 0) revert(OracleCallFailed);

        // Usar o timestamp atual como startTimestamp
        uint256 startTimestamp = block.timestamp;

        matchHypes[hypeId] = MatchHype({
            startTimestamp: startTimestamp,
            gameTime: GAME_TIME, // Usar a constante padrão
            HypeA: 0,
            HypeB: 0,
            goalsA: 0,
            goalsB: 0,
            teamAAbbreviation: teamAAbbreviation,
            teamBAbbreviation: teamBAbbreviation,
            hashtag: hashtag
        });

        hypeIds.push(hypeId);
        emit MatchScheduled(hypeId, startTimestamp, GAME_TIME);
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
        if (block.timestamp >= matchHype.startTimestamp + matchHype.gameTime) revert(InvalidMatchStatus); // Só pode durante o jogo
        matchHype.goalsA = goalsA;
        matchHype.goalsB = goalsB;
        emit ScoreUpdated(hypeId, goalsA, goalsB);
    }

    // Função para obter o status do jogo
    function getGameStatus(bytes4 hypeId) public view onlyMatchExists(hypeId) returns (GameStatus) {
        MatchHype storage matchHype = matchHypes[hypeId];
        uint256 currentTime = block.timestamp;
        
        if (currentTime < matchHype.startTimestamp) {
            return GameStatus.NOT_STARTED;
        } else if (currentTime >= matchHype.startTimestamp + matchHype.gameTime) {
            return GameStatus.FINISHED;
        } else {
            return GameStatus.IN_PROGRESS;
        }
    }

    // CRUD para gameTime
    function updateGameTime(bytes4 hypeId, uint256 newGameTime)
        public
        onlyOwner
        onlyMatchExists(hypeId)
    {
        if (newGameTime == 0) revert(OracleCallFailed);
        matchHypes[hypeId].gameTime = newGameTime;
    }

    function getGameTime(bytes4 hypeId)
        public
        view
        onlyMatchExists(hypeId)
        returns (uint256)
    {
        return matchHypes[hypeId].gameTime;
    }

    // CRUD para seasonEndTimestamp
    function updateSeasonEndTimestamp(uint256 newSeasonEndTimestamp)
        public
        onlyOwner
    {
        if (newSeasonEndTimestamp <= block.timestamp) revert(OracleCallFailed);
        seasonEndTimestamp = newSeasonEndTimestamp;
    }

    function getSeasonEndTimestamp() public view returns (uint256) {
        return seasonEndTimestamp;
    }

    // Função para verificar se a temporada terminou
    function isSeasonEnded() public view returns (bool) {
        return block.timestamp >= seasonEndTimestamp;
    }

    // CRUD para startTimestamp (mantido para compatibilidade)
    function updateStartTimestamp(bytes4 hypeId, uint256 newStartTimestamp)
        public
        onlyOwner
        onlyMatchExists(hypeId)
    {
        if (newStartTimestamp <= block.timestamp) revert(OracleCallFailed);
        matchHypes[hypeId].startTimestamp = newStartTimestamp;
    }

    function getStartTimestamp(bytes4 hypeId)
        public
        view
        onlyMatchExists(hypeId)
        returns (uint256)
    {
        return matchHypes[hypeId].startTimestamp;
    }
} 