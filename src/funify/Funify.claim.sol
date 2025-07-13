// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FunifyCrud} from "./funify.crud.sol";

abstract contract FunifyClaim is FunifyCrud {
    constructor(address _token, address _oracle) FunifyCrud(_token, _oracle) {}

    function claimPrize(bytes4 hypeId)
        external
        onlyMatchFinished(hypeId)
        onlyNoDraw(hypeId)
        onlyUserWon(hypeId)
        onlyValidClaim(hypeId)
    {
        Bet storage bet = bets[hypeId][msg.sender];
        uint256 userPrize = _calculatePrize(hypeId, bet);
        _updateHouseProfit(hypeId);
        bet.amount = 0;

        if (!token.transfer(msg.sender, userPrize)) {
            revert(TokenTransferFailed);
        }

        emit PrizesDistributed(hypeId, msg.sender, userPrize);
    }

    function _calculatePrize(bytes4 hypeId, Bet storage bet) internal view returns (uint256) {
        (bool teamAWon, uint256 oddsA, uint256 oddsB) = _getMatchOdds(hypeId);
        uint256 userOdds = bet.teamA ? oddsA : oddsB;

        uint256 prizePool = _getPrizePool(hypeId);
        uint256 totalProporcao = _getTotalProporcao(
            teamAWon, prizePoolA[hypeId], prizePoolB[hypeId], oddsA, oddsB
        );

        return _calculateFinalPrize(bet.amount, userOdds, prizePool, totalProporcao);
    }

    function _getMatchOdds(bytes4 hypeId) internal view returns (bool teamAWon, uint256 oddsA, uint256 oddsB) {
        (uint256 hypeA, uint256 hypeB,) = oracle.getHype(hypeId);
        (,, uint8 goalsA, uint8 goalsB,,,,,,,) = oracle.getMatch(hypeId);
        teamAWon = goalsA > goalsB;
        oddsA = _getOdds(hypeA, hypeB, true);
        oddsB = _getOdds(hypeA, hypeB, false);
    }

    function _getPrizePool(bytes4 hypeId) internal view returns (uint256) {
        uint256 totalPool = prizePoolA[hypeId] + prizePoolB[hypeId];
        uint256 houseCut = (totalPool * HOUSE_FEE) / 1e18;
        return totalPool - houseCut;
    }

    function _calculateFinalPrize(
        uint256 amount,
        uint256 userOdds,
        uint256 prizePool,
        uint256 totalProporcao
    ) internal pure returns (uint256) {
        return (amount * userOdds * prizePool) / totalProporcao;
    }

    function _getTotalProporcao(
        bool teamAWon,
        uint256 prizePoolA_,
        uint256 prizePoolB_,
        uint256 oddsA,
        uint256 oddsB
    ) internal pure returns (uint256) {
        return teamAWon ? prizePoolA_ * oddsA : prizePoolB_ * oddsB;
    }

    function _updateHouseProfit(bytes4 hypeId) internal {
        if (houseProfit[hypeId] == 0) {
            uint256 totalPool = prizePoolA[hypeId] + prizePoolB[hypeId];
            uint256 houseCut = (totalPool * HOUSE_FEE) / 1e18;
            houseProfit[hypeId] = houseCut;
        }
    }
}
