// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../tokens/ERC721/RevealableERC721.sol";

contract RevealableERC721Mock is RevealableERC721 {
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
        RevealableERC721("https://prereveal.example.com/prereveal.json")
    {}

    function mint(uint256 _amount) external {
        _baseMint(msg.sender, _amount);
    }
}
