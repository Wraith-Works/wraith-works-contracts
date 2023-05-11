// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../tokens/ERC721/AirdropERC721.sol";

contract AirdropERC721Mock is AirdropERC721 {
    constructor()
        BaseERC721(
            "Example",
            "EXAMPLE",
            "https://example.com/",
            ".json",
            3333,
            0x14c84F8aBaD55F074Ef18BEb46A7cbede6a17B10,
            750
        )
    {}
}
