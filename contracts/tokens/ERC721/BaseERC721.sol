// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @dev Basic ERC721 contract with various extensions for controlling max mint supply and royalities.
contract BaseERC721 is ERC721Enumerable, ERC2981, Ownable, Pausable {
    using Strings for uint256;

    /// @dev Token does not exist.
    error DoesNotExist(uint256 tokenId);
    /// @dev Max mint limit reached.
    error MaxMinted();

    /// @dev The URI for the token metadata.
    string public baseURI;
    /// @dev The extension to be appended to the token ID when forming the URI.
    string public baseURIExtension;
    /// @dev The maximum amount of tokens that can be minted.
    uint256 public immutable MAX_SUPPLY;

    /// @dev The token ID counter. Starts at 1.
    uint256 internal _tokenIdCounter = 1;

    /**
     * @param _name Name of the collection.
     * @param _symbol Symbol for the token.
     * @param _baseURI The URI for the token metadata.
     * @param _baseURIExtension The extension to be appended to the tokenID when formin the URI.
     * @param _maxSupply The maximum amount of tokens that can be minted. Setting this to 0 will allow for an unlimited supply.
     * @param _royaltyReceiver The address that should receive royalties for secondary sales.
     * @param _royaltyFeeNumerator The fee percentage to charge. The denominator is fixed to 10000, so setting to 750 would make the fee 7.5% (750/10000).
     */
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

    /// @dev Pause the contract, and disable token transfers.
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Unpause the contract, and allow token transfers.
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Set the base URI and extension for the token metadata.
     * @param _baseURI The URI that will get prepended to the token ID.
     * @param _baseURIExtension The extension that will get appended to the token ID.
     */
    function setBaseURI(string memory _baseURI, string memory _baseURIExtension) external onlyOwner {
        baseURI = _baseURI;
        baseURIExtension = _baseURIExtension;
    }

    /**
     * @dev Set the default royalty to be received for secondary sales. The denominator used for the numerator to form the fraction is 10000.
     * @param _receiver The address that should receive the royalties.
     * @param _feeNumerator The fee percentage to charge. The denominator is fixed to 10000, so setting the `_feeNumerator` to 750 would make the fee 7.5% (750/10000).
     */
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    /// @dev Delete the default royalty (i.e. reset back to 0% with no receiver).
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev Set royalties on a per token basis.
     * @param _tokenId The token to set the royalties for.
     * @param _receiver The address that should receive the royalties.
     * @param _feeNumerator The fee percentage to charge. The denominator is fixed to 10000, so setting the `_feeNumerator` to 750 would make the fee 7.5% (750/10000).
     */
    function setTokenRoyalty(uint256 _tokenId, address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
    }

    /**
     * @dev Reset the royalties for a specific token (i.e. reset back to 0% with no receiver).
     * @param _tokenId The token ID to reset royalties for.
     */
    function resetTokenRoyalty(uint256 _tokenId) external onlyOwner {
        _resetTokenRoyalty(_tokenId);
    }

    /**
     * @dev Get the URI to the metadata for a specific token. Format is `[baseURI][tokenId][baseURIExtension]`.
     * @param _tokenId The token ID to get the metadata URI for.
     * @return Returns the metadata URI for a specific token.
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (!_exists(_tokenId)) revert DoesNotExist(_tokenId);
        return
            bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString(), baseURIExtension)) : "";
    }

    /**
     * @dev Mint the supplied number of tokens to the given address, up to the `MAX_SUPPLY` (which may be unlimited).
     * @param _to The address to mint tokens to.
     * @param _amount How many tokens to mint.
     */
    function _baseMint(address _to, uint256 _amount) internal {
        if (MAX_SUPPLY > 0 && (_tokenIdCounter + _amount) - 1 > MAX_SUPPLY) revert MaxMinted();
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
