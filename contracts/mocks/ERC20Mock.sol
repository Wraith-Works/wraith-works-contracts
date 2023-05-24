// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../tokens/ERC20/BaseERC20.sol";

contract ERC20Mock is BaseERC20 {
    constructor() BaseERC20("Example", "EXAMPLE") {}
}
