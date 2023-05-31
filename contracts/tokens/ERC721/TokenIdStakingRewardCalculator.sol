// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./IStakingRewardCalculator.sol";
import "../../common/Errors.sol";

/// @dev Staking reward calculator based on a per token basis.
abstract contract TokenIdStakingRewardCalculator is IStakingRewardCalculator, Ownable, Pausable {
    event TokenMultiplierSet(uint256 indexed tokenId, uint256 multiplier);

    /// @dev The reward multiplier by token ID.
    mapping(uint256 => uint256) public tokenIdRewardMultiplier;
    /// @dev The decimals in the reward multiplier.
    uint256 public decimals = 18;

    constructor() {
        _pause();
    }

    /// @dev Pause the contract.
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Unpause the contract.
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Set the multipliers for the given token IDs.
     * @param _tokenIds The IDs of the tokens.
     * @param _multipliers The reward multipliers.
     */
    function setTokenMultipliers(uint256[] calldata _tokenIds, uint256[] calldata _multipliers) external onlyOwner {
        uint256 length = _tokenIds.length;
        if (length != _multipliers.length) revert Errors.InvalidLength(length);
        for (uint256 i = 0; i < length; ) {
            _setTokenMultiplier(_tokenIds[i], _multipliers[i]);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev Set the multiplier for the given token ID.
     * @param _tokenId The ID of the token.
     * @param _multiplier The reward multiplier.
     */
    function _setTokenMultiplier(uint256 _tokenId, uint256 _multiplier) internal {
        tokenIdRewardMultiplier[_tokenId] = _multiplier;
        emit TokenMultiplierSet(_tokenId, _multiplier);
    }

    /**
     * @dev Calculate the staking reward based on the base reward and a potential multiplier.
     * @param _tokenId The ID of the token.
     * @param _reward The base reward.
     * @return Returns the new reward.
     */
    function calculateStakingReward(address, uint256 _tokenId, uint256 _reward) external view override returns (uint256) {
        if (tokenIdRewardMultiplier[_tokenId] == 0) {
            return _reward;
        }
        return (_reward * tokenIdRewardMultiplier[_tokenId]) / (1 * 10**decimals);
    }
}