// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BaseERC721 is ERC721Enumerable, ERC2981, Ownable, Pausable {
    using Strings for uint256;

    error NoTokenId();
    error MaxMinted();

    string public baseURI;
    string public baseURIExtension;
    uint256 public immutable MAX_SUPPLY;

    uint256 internal _tokenIdCounter = 1;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        string memory _baseURIExtension,
        uint256 _maxSupply,
        address _royaltyReceiver,
        uint96 _royaltyFeeNumerator
    ) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        baseURIExtension = _baseURIExtension;
        MAX_SUPPLY = _maxSupply;

        _setDefaultRoyalty(_royaltyReceiver, _royaltyFeeNumerator);
        _pause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setBaseURI(string memory _baseURI, string memory _baseURIExtension) public onlyOwner {
        baseURI = _baseURI;
        baseURIExtension = _baseURIExtension;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (!_exists(_tokenId)) revert NoTokenId();
        return
            bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString(), baseURIExtension)) : "";
    }

    function _baseMint(address _to, uint256 _amount) internal {
        if (_tokenIdCounter + _amount >= MAX_SUPPLY) revert MaxMinted();
        for (uint256 i = 0; i < _amount; ) {
            _safeMint(_to, _tokenIdCounter);

            unchecked {
                _tokenIdCounter += 1;
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
