// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../tokens/ERC721/MintableERC721.sol";

contract MintableERC721Mock is MintableERC721 {
    constructor(
        uint256 _maxSupply,
        uint256 _maxPerMint
    )
        MintableERC721(_maxPerMint)
        BaseERC721(
            "Example",
            "EXAMPLE",
            "https://example.com/",
            ".json",
            _maxSupply,
            0x14c84F8aBaD55F074Ef18BEb46A7cbede6a17B10,
            750
        )
        AutoIncrementERC721(1)
    {}
}
