// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../tokens/ERC721/BaseERC721.sol";

contract ERC721Mock is BaseERC721 {
    constructor(
        uint256 _maxSupply
    )
        BaseERC721(
            "Example",
            "EXAMPLE",
            "https://example.com/",
            ".json",
            _maxSupply,
            0x14c84F8aBaD55F074Ef18BEb46A7cbede6a17B10,
            750
        )
    {}

    function mint(uint256 _amount) external {
        _baseMint(msg.sender, _amount);
    }
}
