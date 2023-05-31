// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @dev Interface for a staking reward calculator.
interface IStakingRewardCalculator {
    /**
     * @dev Calculate the staking reward based on the base reward and a potential multiplier.
     * @param _owner The owner of the token.
     * @param _tokenId The ID of the token.
     * @param _reward The base reward.
     * @return Returns the new reward.
     */
    function calculateStakingReward(address _owner, uint256 _tokenId, uint256 _reward) external view returns (uint256);
}
