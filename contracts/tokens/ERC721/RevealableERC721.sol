// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./BaseERC721.sol";

/// @dev Provides reveal functionality to the BaseERC721 contract.
abstract contract RevealableERC721 is BaseERC721 {
    /// @dev The URI for the prereveal metadata.
    string public prerevealURI;
    /// @dev Flag to determine whether the token metadata should be revealed.
    bool public revealed = false;

    /// @param _prerevealURI The URI for the prereveal metadata.
    constructor(string memory _prerevealURI) {
        prerevealURI = _prerevealURI;
    }

    /**
     * @dev Set the URI for te preveal metadata.
     * @param _prerevealURI The URI for the prereveal metadata.
     */
    function setPrerevealURI(string memory _prerevealURI) external onlyOwner {
        prerevealURI = _prerevealURI;
    }

    /// @dev Toggle the reveal. When `revealed` is `true`, the token specific metadata URI will be returned.
    function toggleReveal() external onlyOwner {
        revealed = !revealed;
    }

    /**
     * @dev Get either the prereveal metadata, or the token specific metadata.
     * @param _tokenId The token ID to get the metadata URI for.
     * @return Returns the metadata URI for a specific token or the prereveal metadata URI, depending on the state of `revealed`.
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if (!revealed) {
            return bytes(prerevealURI).length > 0 ? prerevealURI : "";
        }
        return super.tokenURI(_tokenId);
    }
}
