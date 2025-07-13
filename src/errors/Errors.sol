// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Errors
 * @dev Contrato único que define todos os códigos de erro padronizados do sistema
 */
abstract contract Errors {
    // ============ ERROS DE AUTORIZAÇÃO (E000-E009) ============
    string public constant NotOwner = "E000";
    string public constant NotStakeContract = "E001";
    string public constant OnlyOwner = "E002";
    string public constant UnauthorizedAccess = "E003";

    // ============ ERROS DE STAKE (E010-E019) ============
    string public constant NoStakeFound = "E010";
    string public constant SeasonNotEnded = "E011";
    string public constant InvalidFanToken = "E012";
    string public constant FanTokenNotSupported = "E013";
    string public constant InvalidStakeAmount = "E014";
    string public constant UserAlreadyStaked = "E015";
    string public constant TokenTransferFailed = "E016";
    string public constant NotEnoughETH = "E017";
    string public constant InsufficientBalanceToUnstake = "E018";
    string public constant CannotUnstakeZero = "E019";

    // ============ ERROS DE APOSTA (E020-E029) ============
    string public constant NoBetOnMatch = "E020";
    string public constant MatchNotFinished = "E021";
    string public constant MatchNotOpen = "E022";
    string public constant InvalidBetAmount = "E023";
    string public constant UserAlreadyBet = "E024";
    string public constant UserDidNotWin = "E025";
    string public constant MatchEndedInDraw = "E026";
    string public constant CannotBetAgainstTeam = "E027";
    string public constant TeamNotInMatch = "E028";
    string public constant NoNFTForTeam = "E029";

    // ============ ERROS DE CLAIM (E030-E039) ============
    string public constant NoProfitToWithdraw = "E030";
    string public constant InvalidHypeValues = "E031";
    string public constant PrizeAlreadyClaimed = "E032";
    string public constant InsufficientPrizePool = "E033";

    // ============ ERROS DE NFT (E040-E049) ============
    string public constant NFTNotFound = "E040";
    string public constant NFTNotOwned = "E041";
    string public constant TokenDoesNotExistError = "E042";
    string public constant TransfersDisabled = "E043";

    // ============ ERROS DE ORACLE (E050-E059) ============
    string public constant MatchAlreadyFinished = "E050";
    string public constant MatchNotFound = "E051";
    string public constant InvalidMatchStatus = "E052";
    string public constant OracleCallFailed = "E053";
    string public constant TeamAbbreviationsNotSet = "E054";
    string public constant InvalidTeamAbbreviation = "E055";
    string public constant TeamAbbreviationTooLong = "E056";

    // ============ ERROS DE TOKEN (E060-E069) ============
    string public constant NonTransferable = "E060";
    string public constant AmountTooSmall = "E061";
    string public constant InsufficientContractBalance = "E062";
    string public constant ETHTransferFailed = "E063";
    string public constant CannotMintToZero = "E064";
    string public constant CannotMintZero = "E065";
    string public constant InvalidUserAddress = "E066";

    // ============ ERROS DE VALIDAÇÃO (E070-E079) ============
    string public constant InvalidTimestamp = "E070";
    string public constant InvalidAmount = "E071";
    string public constant InvalidAddress = "E072";
    string public constant InvalidTeamId = "E073";
    string public constant InvalidSeasonId = "E074";

    // ============ ERROS DE SISTEMA (E080-E089) ============
    string public constant ReentrantCall = "E080";
    string public constant OperationFailed = "E081";
    string public constant StateMismatch = "E082";
    string public constant InvalidState = "E083";
} 