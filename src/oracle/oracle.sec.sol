// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OracleStorage} from "./oracle.storage.sol";

abstract contract OracleSec is OracleStorage {
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert(NotOwner);
        }
        _;
    }

    modifier onlyMatchExists(bytes4 hypeId) {
        if (matchHypes[hypeId].startTimestamp == 0) {
            revert(MatchNotFound);
        }
        _;
    }
} 