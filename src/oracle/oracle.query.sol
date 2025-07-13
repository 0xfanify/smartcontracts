// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OracleCrud} from "./oracle.crud.sol";

abstract contract OracleQuery is OracleCrud {
    // Função para obter informações completas do jogo
    function getMatch(bytes4 hypeId)
        public
        view
        returns (
            uint256 HypeA,
            uint256 HypeB,
            uint8 goalsA,
            uint8 goalsB,
            uint256 startTimestamp,
            uint256 gameTime,
            string memory teamAAbbreviation,
            string memory teamBAbbreviation,
            string memory hashtag
        )
    {
        MatchHype memory matchHype = matchHypes[hypeId];
        require(matchHype.startTimestamp != 0, "Match not found");

        return (
            matchHype.HypeA,
            matchHype.HypeB,
            matchHype.goalsA,
            matchHype.goalsB,
            matchHype.startTimestamp,
            matchHype.gameTime,
            matchHype.teamAAbbreviation,
            matchHype.teamBAbbreviation,
            matchHype.hashtag
        );
    }

    // Função para verificar se um jogo existe
    function matchExists(bytes4 hypeId) public view returns (bool) {
        return matchHypes[hypeId].startTimestamp != 0;
    }

    // Função para obter todos os hypeIds
    function getAllHypeIds() public view returns (bytes4[] memory) {
        return hypeIds;
    }

    // Função para obter o número total de jogos
    function getTotalMatches() public view returns (uint256) {
        return hypeIds.length;
    }

    function getMatchGoals(bytes4 hypeId) public view returns (uint8 goalsA, uint8 goalsB) {
        return (matchHypes[hypeId].goalsA, matchHypes[hypeId].goalsB);
    }

    // Função para buscar jogo por hashtag
    function getMatchByHashtag(string memory hashtag) public view returns (bytes4 hypeId, MatchHype memory matchHype) {
        for (uint256 i = 0; i < hypeIds.length; i++) {
            MatchHype memory m = matchHypes[hypeIds[i]];
            if (keccak256(bytes(m.hashtag)) == keccak256(bytes(hashtag))) {
                return (hypeIds[i], m);
            }
        }
        revert(MatchNotFound);
    }
} 