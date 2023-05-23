// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./AutoIncrementERC721.sol";
import "../../common/Errors.sol";

/// @dev Provides airdrop functionality to the BaseERC721 contract.
abstract contract AirdropERC721 is AutoIncrementERC721 {
    /**
     * @dev Airdrop (mint) tokens to each address in `_to`, for the matching amount in `_amounts`.
     * @param _to Array of addresses to mint to.
     * @param _amounts Array of amounts to mint for each address.
     */
    function airdrop(address[] calldata _to, uint256[] calldata _amounts) public onlyOwner {
        uint256 toLength = _to.length;
        if (toLength != _amounts.length) revert Errors.InvalidLength(toLength);
        for (uint256 i = 0; i < toLength; ) {
            _autoIncrementMint(_to[i], _amounts[i]);

            unchecked {
                i++;
            }
        }
    }
}
