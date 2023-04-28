// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./BaseERC721.sol";

abstract contract RevealableERC721 is BaseERC721 {
    string public prerevealURI;
    bool public revealed = false;

    constructor(string memory _prerevealURI) {
        prerevealURI = _prerevealURI;
    }

    function setPrerevealURI(string memory _prerevealURI) public onlyOwner {
        prerevealURI = _prerevealURI;
    }

    function toggleReveal() public onlyOwner {
        revealed = !revealed;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (!revealed) {
            return bytes(prerevealURI).length > 0 ? prerevealURI : "";
        }
        return super.tokenURI(_tokenId);
    }
}
