// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../token/ERC721/AirDropERC721.sol";
import "../token/ERC721/MintableERC721.sol";
import "../token/ERC721/RevealableERC721.sol";

contract ExampleMintableERC721 is MintableERC721, AirDropERC721, RevealableERC721 {
    enum MintStages {
        WHITE_LIST,
        ALLOW_LIST,
        PUBLIC
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        string memory _prerevealURI,
        uint256 _maxSupply
    ) BaseERC721(_name, _symbol, _baseURI, _maxSupply) RevealableERC721(_prerevealURI) {
        addMintStage(0, 1, 1, 0x0);
        addMintStage(15000000000000000000, 1, 1, 0x0);
        addMintStage(25000000000000000000, 3, 3, 0x0);
    }
}
