// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract BaseERC721 is ERC721Enumerable, ERC2981, Ownable, Pausable {
    string public baseURI;
    uint256 public immutable MAX_SUPPLY;

    uint256 internal _tokenIdCounter;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _maxSupply
    ) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        MAX_SUPPLY = _maxSupply;
        _pause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function _baseMint(address _to, uint256 _amount) internal {
        for (uint256 i = 0; i < _amount; ) {
            _safeMint(_to, _tokenIdCounter);
            _tokenIdCounter += 1;

            unchecked {
                i++;
            }
        }
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _firstTokenId,
        uint256 _batchSize
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(_from, _to, _firstTokenId, _batchSize);
    }

    function supportsInterface(bytes4 _interfaceId) public view override(ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }
}
