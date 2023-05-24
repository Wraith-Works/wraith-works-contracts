// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBaseERC20 is IERC20 {
    function pause() external;

    function unpause() external;

    function setAuthorizedMinter(address _minter, bool _authorized) external;

    function authorizedMint(address _account, uint256 _amount) external;
}
