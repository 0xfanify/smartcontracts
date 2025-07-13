// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SeasonfyStorage} from "./seasonfy.storage.sol";
import {OracleStorage} from "../oracle/oracle.storage.sol";
import {OracleCrud} from "../oracle/oracle.crud.sol";


abstract contract SeasonfySec is SeasonfyStorage {
    constructor(address _token, address _oracle, address _teamNFT, address _mockFanX) 
        SeasonfyStorage(_token, _oracle, _teamNFT, _mockFanX) {}

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert(NotOwner);
        }
        _;
    }

    modifier onlyValidClaim(uint256 seasonId, bytes4 hypeId) {
        if (bets[hypeId][msg.sender].amount == 0) {
            revert(NoBetOnMatch);
        }
        if (bets[hypeId][msg.sender].seasonId != seasonId) {
            revert(InvalidSeasonId);
        }
        _;
    }

    modifier onlyMatchFinished(bytes4 hypeId) {
        OracleCrud.GameStatus status = oracle.getGameStatus(hypeId);
        if (status != OracleCrud.GameStatus.FINISHED) {
            revert(MatchNotFinished);
        }
        _;
    }

    modifier onlyNoDraw(bytes4 hypeId) {
        (uint8 goalsA, uint8 goalsB) = oracle.getMatchGoals(hypeId);
        if (goalsA == goalsB) {
            revert(MatchEndedInDraw);
        }
        _;
    }

    modifier onlyUserWon(bytes4 hypeId) {
        Bet storage bet = bets[hypeId][msg.sender];
        (uint8 goalsA, uint8 goalsB) = oracle.getMatchGoals(hypeId);
        bool teamAWon = goalsA > goalsB;
        bool userBetOnTeamA = bet.teamA;
        if (!((teamAWon && userBetOnTeamA) || (!teamAWon && !userBetOnTeamA))) {
            revert(UserDidNotWin);
        }
        _;
    }

    modifier onlyValidPlaceBet(uint256 seasonId, bytes4 hypeId, uint256 amount) {
        if (oracle.matchExists(hypeId) == false) {
            revert(NoBetOnMatch);
        }
        
        // Verificar se o jogo pertence à temporada correta
        (,,,,,,,,, uint256 matchSeasonId) = oracle.getMatch(hypeId);
        if (matchSeasonId != seasonId) {
            revert(InvalidSeasonId);
        }
        
        OracleCrud.GameStatus status = oracle.getGameStatus(hypeId);
        if (status != OracleCrud.GameStatus.NOT_STARTED) {
            revert(MatchNotOpen);
        }
        
        if (amount == 0) {
            revert(InvalidBetAmount);
        }
        if (bets[hypeId][msg.sender].amount != 0) {
            revert(UserAlreadyBet);
        }
        _;
    }

    modifier onlyValidStake(address fanToken, uint256 amount, uint256 seasonId) {
        if (amount == 0) {
            revert(InvalidStakeAmount);
        }
        if (stakes[msg.sender].fanTokenAmount != 0) {
            revert(UserAlreadyStaked);
        }
        if (oracle.getTokenPrice("CHZ") == 0) {
            revert(FanTokenNotSupported);
        }
        if (!oracle.isSeasonActive(seasonId)) {
            revert(InvalidSeasonId);
        }
        _;
    }

    modifier onlySeasonEnded(uint256 seasonId) {
        if (!oracle.isSeasonEnded(seasonId)) {
            revert(SeasonNotEnded);
        }
        _;
    }

    modifier onlyValidUnstake() {
        if (stakes[msg.sender].fanTokenAmount == 0) {
            revert(NoStakeFound);
        }
        if (!oracle.isSeasonEnded(stakes[msg.sender].seasonId)) {
            revert(SeasonNotEnded);
        }
        _;
    }

    modifier onlyCanBetForTeam(uint256 seasonId, bytes4 hypeId, bool teamA) {
        Stake storage stake = stakes[msg.sender];
        if (stake.fanTokenAmount == 0) {
            revert(NoNFTForTeam);
        }
        if (stake.seasonId != seasonId) {
            revert(InvalidSeasonId);
        }

        // Verificar se o time do NFT está jogando neste match
        (,,,,,,,,, uint256 matchSeasonId) = oracle.getMatch(hypeId);
        // Aqui você pode implementar a lógica para verificar se o time do NFT está jogando
        // Por enquanto, vamos permitir apostas apenas a favor do time (não contra)
        if (!teamA) {
            revert(CannotBetAgainstTeam);
        }
        _;
    }

    function _getOdds(uint256 hypeA, uint256 hypeB, bool teamA) internal pure returns (uint256) {
        uint256 totalHype = hypeA + hypeB;
        if (totalHype != 10000) {
            revert(InvalidHypeValues);
        }
        return teamA ? (1e18 * totalHype) / hypeA : (1e18 * totalHype) / hypeB;
    }

    function _getTotalProporcao(bool teamAWon, uint256 prizePoolA_, uint256 prizePoolB_, uint256 odds)
        internal
        pure
        returns (uint256)
    {
        return teamAWon ? prizePoolA_ * odds : prizePoolB_ * odds;
    }
} 