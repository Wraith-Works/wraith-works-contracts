// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./BaseERC721.sol";

abstract contract AirDropERC721 is BaseERC721 {
    error InvalidLength();

    function airdrop(address[] calldata _to, uint256[] calldata _amounts) public onlyOwner {
        uint256 toLength = _to.length;
        if (toLength != _amounts.length) revert InvalidLength();
        for (uint256 i = 0; i < toLength; ) {
            _baseMint(_to[i], _amounts[i]);

            unchecked {
                i++;
            }
        }
    }
}
