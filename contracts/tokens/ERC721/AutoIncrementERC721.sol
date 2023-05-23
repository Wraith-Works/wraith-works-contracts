// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseERC721.sol";

/// @dev Provides an autoincrementing version of BaseERC721.
abstract contract AutoIncrementERC721 is BaseERC721 {
    /// @dev The token Id counter.
    uint256 internal _tokenIdCounter;

    /**
     * @param _startingIndex The index to start at for the token Ids.
     */
    constructor(uint256 _startingIndex) {
        _tokenIdCounter = _startingIndex;
    }

    /**
     * @dev Auto incrementing mint function. Token ID will increment for each internal mint call.
     * @param _to The address to mint to.
     * @param _amount The amount to mint out.
     */
    function _autoIncrementMint(address _to, uint256 _amount) internal {
        for (uint256 i = 0; i < _amount; ) {
            _baseMint(_to, _tokenIdCounter);
            unchecked {
                i++;
                _tokenIdCounter++;
            }
        }
    }
}
