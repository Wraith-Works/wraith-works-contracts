// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./IBaseERC20.sol";
import "../../common/Errors.sol";

/// @dev Basic ERC20 contract with owner, pausability, and authorized minting.
contract BaseERC20 is IBaseERC20, ERC20, Ownable2Step, Pausable {
    mapping(address => bool) public authorizedMinters;

    /// @dev Modifier to restrict a function to only the owner or an authorized minter.
    modifier onlyAuthorizedMinter() {
        if (msg.sender != owner() && !authorizedMinters[msg.sender]) revert Errors.Unauthorized(msg.sender);
        _;
    }

    /**
     * @param _name Name of the token.
     * @param _symbol Symbol for the token.
     */
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _pause();
    }

    /// @dev Pause the contract, and disable token transfers.
    function pause() external override onlyOwner {
        _pause();
    }

    /// @dev Unpause the contract, and allow token transfers.
    function unpause() external override onlyOwner {
        _unpause();
    }

    /**
     * @dev Add or remove an authorized minter.
     * @param _minter The address of the authorized minter.
     * @param _authorized Whether to add or remove as authorized.
     */
    function setAuthorizedMinter(address _minter, bool _authorized) external override onlyOwner {
        if (_minter == address(0)) revert Errors.ZeroAddress();
        authorizedMinters[_minter] = _authorized;
    }

    /**
     * @dev An authorized only mint to the provided account for the given amount.
     * @param _account Account to mint to.
     * @param _amount Amount to mint.
     */
    function authorizedMint(address _account, uint256 _amount) external override onlyAuthorizedMinter {
        _mint(_account, _amount);
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal override whenNotPaused {
        super._beforeTokenTransfer(_from, _to, _amount);
    }
}
