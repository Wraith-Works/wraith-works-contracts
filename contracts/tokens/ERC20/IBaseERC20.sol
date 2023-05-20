// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBaseERC20 is IERC20 {
    /// @dev Unexpected address found/given.
    error InvalidAddress();
    /// @dev Unauthorized access.
    error Unauthorized();

    function pause() external;

    function unpause() external;

    function setAuthorizedMinter(address _minter, bool _authorized) external;

    function authorizedMint(address _account, uint256 _amount) external;
}
