// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SeasonfySec} from "./seasonfy.sec.sol";
import {OracleStorage} from "../oracle/oracle.storage.sol";

abstract contract SeasonfyCrud is SeasonfySec {
    constructor(address _token, address _oracle, address _teamNFT, address _mockFanX) 
        SeasonfySec(_token, _oracle, _teamNFT, _mockFanX) {}

    function getOdds(bytes4 hypeId) public view returns (uint256 oddsA, uint256 oddsB) {
        (uint256 hypeA, uint256 hypeB, , , , , , , ,) = oracle.getMatch(hypeId);
        if (hypeA + hypeB == 0) {
            revert(InvalidHypeValues);
        }
        oddsA = _getOdds(hypeA, hypeB, true);
        oddsB = _getOdds(hypeA, hypeB, false);
    }

    function getPrizePools(bytes4 hypeId) external view returns (uint256 poolA, uint256 poolB, uint256 houseCut) {
        uint256 totalPool = prizePoolA[hypeId] + prizePoolB[hypeId];
        houseCut = (totalPool * HOUSE_FEE) / 1e18;
        poolA = prizePoolA[hypeId];
        poolB = prizePoolB[hypeId];
    }

    function getStakeInfo(address user) external view returns (
        uint256 fanTokenAmount,
        uint256 hypeAmount,
        uint256 teamId,
        uint256 seasonId,
        uint256 nftTokenId,
        uint256 stakedAt
    ) {
        Stake storage stake = stakes[user];
        return (
            stake.fanTokenAmount,
            stake.hypeAmount,
            stake.teamId,
            stake.seasonId,
            stake.nftTokenId,
            stake.stakedAt
        );
    }

    function getSeasonInfo() external view returns (uint256 endTimestamp, uint256 duration) {
        OracleStorage.Season memory season = oracle.getCurrentSeason();
        return (season.endTimestamp, season.endTimestamp - season.startTimestamp);
    }

    function isSeasonEnded() external view returns (bool) {
        return oracle.isSeasonEnded();
    }
} 