// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @dev Common library of errors.
library Errors {
    /// @dev Zero address found/given.
    error ZeroAddress();
    /// @dev Unexpected length.
    error InvalidLength(uint256 length);
    /// @dev Invalid index provided.
    error InvalidIndex(uint256 index);
    /// @dev Unauthorized access.
    error Unauthorized(address accessor);
}
