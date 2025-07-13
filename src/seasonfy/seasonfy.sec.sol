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

    modifier onlyValidClaim(bytes4 hypeId) {
        if (bets[hypeId][msg.sender].amount == 0) {
            revert(NoBetOnMatch);
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

    modifier onlyValidPlaceBet(bytes4 hypeId, uint256 amount) {
        if (oracle.matchExists(hypeId) == false) {
            revert(NoBetOnMatch);
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

    modifier onlyValidStake(address fanToken, uint256 amount) {
        if (amount == 0) {
            revert(InvalidStakeAmount);
        }
        if (stakes[msg.sender].fanTokenAmount != 0) {
            revert(UserAlreadyStaked);
        }
        if (oracle.getTokenPrice("CHZ") == 0) {
            revert(FanTokenNotSupported);
        }
        _;
    }

    modifier onlySeasonEnded() {
        if (!oracle.isSeasonEnded()) {
            revert(SeasonNotEnded);
        }
        _;
    }

    modifier onlyValidUnstake() {
        if (stakes[msg.sender].fanTokenAmount == 0) {
            revert(NoStakeFound);
        }
        if (!oracle.isSeasonEnded()) {
            revert(SeasonNotEnded);
        }
        _;
    }

    modifier onlyCanBetForTeam(bytes4 hypeId, bool teamA) {
        Stake storage stake = stakes[msg.sender];
        if (stake.fanTokenAmount == 0) {
            revert(NoNFTForTeam);
        }

        // Verificar se o time do NFT está jogando neste match
        (uint256 hypeA, uint256 hypeB, , , , , string memory teamAAbbreviation, string memory teamBAbbreviation,) = oracle.getMatch(hypeId);
        
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