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

    // 1. Criar uma nova temporada
    function createSeason(uint256 seasonId, uint256 startTimestamp, uint256 endTimestamp)
        public
        onlyOwner
    {
        if (seasons[seasonId].seasonId != 0) revert(InvalidSeasonId);
        if (startTimestamp >= endTimestamp) revert(InvalidTimestamp);
        if (startTimestamp <= block.timestamp) revert(InvalidTimestamp);

        seasons[seasonId] = Season({
            seasonId: seasonId,
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp,
            isActive: true
        });

        seasonIds.push(seasonId);
        emit SeasonCreated(seasonId, startTimestamp, endTimestamp);
    }

    // 2. Finalizar uma temporada
    function endSeason(uint256 seasonId) public onlyOwner {
        Season storage season = seasons[seasonId];
        if (season.seasonId == 0) revert(InvalidSeasonId);
        if (!season.isActive) revert(InvalidState);

        season.isActive = false;
        emit SeasonEnded(seasonId);
    }

    // 3. Atualizar temporada atual
    function setCurrentSeason(uint256 seasonId) public onlyOwner {
        if (seasons[seasonId].seasonId == 0) revert(InvalidSeasonId);
        if (!seasons[seasonId].isActive) revert(InvalidState);

        currentSeasonId = seasonId;
        emit CurrentSeasonUpdated(seasonId);
    }

    // 4. Criar um Jogo (agora com seasonId)
    function scheduleMatch(
        uint256 seasonId,
        bytes4 hypeId,
        string memory teamAAbbreviation,
        string memory teamBAbbreviation,
        string memory hashtag
    ) public onlyOwner {
        if (matchHypes[hypeId].startTimestamp != 0) revert(MatchAlreadyFinished);
        if (seasons[seasonId].seasonId == 0) revert(InvalidSeasonId);
        if (!seasons[seasonId].isActive) revert(InvalidState);
        if (bytes(teamAAbbreviation).length == 0) revert(InvalidTeamAbbreviation);
        if (bytes(teamBAbbreviation).length == 0) revert(InvalidTeamAbbreviation);
        if (bytes(hashtag).length == 0) revert(OracleCallFailed);

        // Usar um timestamp futuro (1 hora a partir de agora) como startTimestamp
        uint256 startTimestamp = block.timestamp + 3600; // 1 hora no futuro

        matchHypes[hypeId] = MatchHype({
            startTimestamp: startTimestamp,
            gameTime: GAME_TIME, // Usar a constante padrão
            HypeA: 0,
            HypeB: 0,
            goalsA: 0,
            goalsB: 0,
            teamAAbbreviation: teamAAbbreviation,
            teamBAbbreviation: teamBAbbreviation,
            hashtag: hashtag,
            seasonId: seasonId
        });

        hypeIds.push(hypeId);
        emit MatchScheduled(hypeId, seasonId, startTimestamp, GAME_TIME);
    }

    // 5. Alimentar esse jogo com hype (hype A, hype B)
    function updateHype(bytes4 hypeId, uint256 HypeA, uint256 HypeB)
        public
        onlyOwner
    
    {
        MatchHype storage matchHype = matchHypes[hypeId];
        if (block.timestamp >= matchHype.startTimestamp) revert(InvalidMatchStatus); // Só pode antes do início
        if (HypeA + HypeB != 10000) revert(InvalidHypeValues);
        matchHype.HypeA = HypeA;
        matchHype.HypeB = HypeB;
        emit HypeUpdated(hypeId, HypeA, HypeB);
    }

    // 6. Atualizar o placar do jogo (golA, golB)
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

    // CRUD para temporadas
    function getSeason(uint256 seasonId) public view returns (Season memory) {
        return seasons[seasonId];
    }

    function getCurrentSeason() public view returns (Season memory) {
        return seasons[currentSeasonId];
    }

    function getAllSeasonIds() public view returns (uint256[] memory) {
        return seasonIds;
    }

    function isSeasonActive(uint256 seasonId) public view returns (bool) {
        Season storage season = seasons[seasonId];
        return season.isActive && block.timestamp >= season.startTimestamp && block.timestamp < season.endTimestamp;
    }

    function isSeasonEnded(uint256 seasonId) public view returns (bool) {
        Season storage season = seasons[seasonId];
        return block.timestamp >= season.endTimestamp;
    }

    // Função para verificar se a temporada atual terminou (mantida para compatibilidade)
    function isSeasonEnded() public view returns (bool) {
        return isSeasonEnded(currentSeasonId);
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