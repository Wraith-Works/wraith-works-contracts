// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../tokens/ERC721/AirDropERC721.sol";

contract AirDropERC721Mock is AirDropERC721 {
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
