// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OracleTokenPrice} from "./oracle.tokenprice.sol";
import {OracleStorage} from "./oracle.storage.sol";

contract Oracle is OracleTokenPrice {
    constructor(address _mockAzuro) OracleStorage(_mockAzuro) {}
}
