// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./IStakingPoolsERC721.sol";
import "./IStakingRewardCalculator.sol";
import "../ERC20/IBaseERC20.sol";
import "../../common/Errors.sol";

/// @dev Staking pools for ERC721 tokens, earning a ERC20 reward token.
contract StakingPoolsERC721 is IStakingPoolsERC721, Ownable, Pausable, ReentrancyGuard {
    /// @dev The address of the ERC721 token that can be staked in the contract.
    IERC721 public stakingToken;
    /// @dev The address of the ERC20 token to be rewarded for staking.
    IBaseERC20 public rewardToken;
    /// @dev The address of the IStakingRewardCalculator to calculate any extra rewards.
    IStakingRewardCalculator public stakingRewardCalculator;
    /// @dev The list of staking pools.
    StakingPool[] public stakingPools;
    /// @dev List of token staking info by owner address.
    mapping(address => StakedTokenInfo[]) public stakedTokens;

    /**
     * @param _stakingToken The address of the ERC721 token that can be staked in the contract.
     * @param _rewardToken The address of the ERC20 token to be rewarded for staking.
     */
    constructor(address _stakingToken, address _rewardToken) {
        if (_stakingToken == address(0) || _rewardToken == address(0)) revert Errors.ZeroAddress();
        stakingToken = IERC721(_stakingToken);
        rewardToken = IBaseERC20(_rewardToken);

        _pause();
    }

    /// @dev Pause the contract, and disable staking.
    function pause() external override onlyOwner {
        _pause();
    }

    /// @dev Unpause the contract, and allow staking.
    function unpause() external override onlyOwner {
        _unpause();
    }

    /**
     * @dev Set the address of the ERC721 token that can be staked in the contract.
     * @param _stakingToken Address of the ERC721 token.
     */
    function setStakingToken(address _stakingToken) external override onlyOwner {
        if (_stakingToken == address(0)) revert Errors.ZeroAddress();
        stakingToken = IERC721(_stakingToken);
        emit StakingTokenSet(_stakingToken);
    }

    /**
     * @dev Set the address of the ERC20 token to be rewarded for staking.
     * @param _rewardToken Address of the ERC20 token.
     */
    function setRewardToken(address _rewardToken) external override onlyOwner {
        if (_rewardToken == address(0)) revert Errors.ZeroAddress();
        rewardToken = IBaseERC20(_rewardToken);
        emit RewardTokenSet(_rewardToken);
    }

    /**
     * @dev Set the address of the IStakingRewardCalculator contract.
     * @param _stakingRewardCalculator Address of the contract.
     */
    function setStakingRewardCalculator(address _stakingRewardCalculator) external override onlyOwner {
        stakingRewardCalculator = IStakingRewardCalculator(_stakingRewardCalculator);
        emit StakingRewardCalculatorSet(_stakingRewardCalculator);
    }

    /**
     * @dev Add a staking pool. The pool starts disabled.
     * @param _rewardWhileLocked Reward tokens can be claimed during the lock period.
     * @param _lockPeriod The lock period in seconds that the token will be locked.
     * @param _reward The amount of the ERC20 token to give at the end of the lock period.
     * @return Returns the index of the staking pool.
     */
    function addStakingPool(
        bool _rewardWhileLocked,
        uint256 _lockPeriod,
        uint256 _reward
    ) external override onlyOwner returns (uint256) {
        return _addStakingPool(_rewardWhileLocked, _lockPeriod, _reward);
    }

    /**
     * @dev Activate the given staking pool. Cannot activate an invalidated pool.
     * @param _index The index of the staking pool.
     */
    function activateStakingPool(uint256 _index) external override onlyOwner {
        _activateStakingPool(_index);
    }

    /**
     * @dev Deactivate the given staking pool. No new tokens can be staked in the pool,
     * but existing tokens in the pool will continue to earn until unlocked.
     * @param _index The index of the staking pool.
     */
    function deactivateStakingPool(uint256 _index) external override onlyOwner {
        if (_index >= stakingPools.length) revert Errors.InvalidIndex(_index);
        stakingPools[_index].active = false;
        emit StakingPoolDeactivated(_index);
    }

    /**
     * @dev Invalidate the staking pool. No new tokens can be staked in the pool,
     * and all existing tokens will be immediately unlocked. Unclaimed tokens will be lost.
     * @param _index The index of the staking pool.
     */
    function invalidateStakingPool(uint256 _index) external override onlyOwner {
        if (_index >= stakingPools.length) revert Errors.InvalidIndex(_index);
        stakingPools[_index].active = false;
        stakingPools[_index].invalidated = true;
        emit StakingPoolInvalidated(_index);
    }

    /**
     * @dev Stake the token Ids in the given staking pool.
     * @param _poolIndex The index of the staking pool.
     * @param _tokenIds The list of tokenIds to stake in the pool.
     */
    function stake(uint256 _poolIndex, uint256[] calldata _tokenIds) external override whenNotPaused {
        if (_poolIndex >= stakingPools.length) revert Errors.InvalidIndex(_poolIndex);
        if (!stakingPools[_poolIndex].active) revert StakingPoolInactive(_poolIndex);

        uint256 length = _tokenIds.length;
        for (uint256 i = 0; i < length; ) {
            if (stakingToken.ownerOf(_tokenIds[i]) != msg.sender) revert NotOwner();

            stakingToken.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            stakedTokens[msg.sender].push(
                StakedTokenInfo({
                    tokenId: _tokenIds[i],
                    poolIndex: _poolIndex,
                    expiresAt: block.timestamp + stakingPools[_poolIndex].lockPeriod,
                    rewardClaimed: 0
                })
            );

            emit Staked(msg.sender, _tokenIds[i]);

            unchecked {
                i++;
            }
        }

        stakingPools[_poolIndex].stakedCount += _tokenIds.length;
    }

    /// @dev Unstake all unlocked tokens for the caller, and pay out any unclaimed rewards.
    function unstake() external override whenNotPaused nonReentrant {
        uint256 reward = 0;
        uint256 length = stakedTokens[msg.sender].length;
        for (uint256 i = length; i > 0; ) {
            StakedTokenInfo storage stakedTokenInfo = stakedTokens[msg.sender][i - 1];

            if (stakingPools[stakedTokenInfo.poolIndex].invalidated) {
                _removeStakedToken(msg.sender, i - 1);
            } else if (block.timestamp >= stakedTokenInfo.expiresAt) {
                reward += _calculateReward(msg.sender, i - 1, true);
                _removeStakedToken(msg.sender, i - 1);
            }

            unchecked {
                i--;
            }
        }
        if (reward > 0) {
            rewardToken.authorizedMint(msg.sender, reward);
            emit RewardClaimed(msg.sender, reward);
        }
    }

    /// @dev Claim any unclaimed rewards for the caller.
    function claimRewards() external override whenNotPaused nonReentrant {
        uint256 reward = 0;

        uint256 length = stakedTokens[msg.sender].length;
        for (uint256 i = 0; i < length; ) {
            uint256 _reward = _calculateReward(msg.sender, i, false);
            if (_reward > 0) {
                stakedTokens[msg.sender][i].rewardClaimed += _reward;
                reward += _reward;
            }
            unchecked {
                i++;
            }
        }

        if (reward > 0) {
            rewardToken.authorizedMint(msg.sender, reward);
            emit RewardClaimed(msg.sender, reward);
        }
    }

    /**
     * @dev Add a staking pool. The pool starts disabled.
     * @param _rewardWhileLocked Reward tokens can be claimed during the lock period.
     * @param _lockPeriod The lock period in seconds that the token will be locked.
     * @param _reward The amount of the ERC20 token to give at the end of the lock period.
     * @return Returns the index of the staking pool.
     */
    function _addStakingPool(bool _rewardWhileLocked, uint256 _lockPeriod, uint256 _reward) internal returns (uint256) {
        if (_lockPeriod == 0) revert InvalidLockPeriod();
        stakingPools.push(
            StakingPool({
                active: false,
                invalidated: false,
                rewardWhileLocked: _rewardWhileLocked,
                lockPeriod: _lockPeriod,
                reward: _reward,
                stakedCount: 0
            })
        );
        emit StakingPoolAdded(stakingPools.length - 1);
        return stakingPools.length - 1;
    }

    /**
     * @dev Activate the given staking pool. Cannot activate an invalidated pool.
     * @param _index The index of the staking pool.
     */
    function _activateStakingPool(uint256 _index) internal {
        if (_index >= stakingPools.length) revert Errors.InvalidIndex(_index);
        if (stakingPools[_index].invalidated) revert StakingPoolInvalid(_index);
        stakingPools[_index].active = true;
        emit StakingPoolActivated(_index);
    }

    function _removeStakedToken(address _owner, uint256 _index) private {
        uint256 length = stakedTokens[_owner].length;
        if (_index >= length) revert Errors.InvalidIndex(_index);

        stakingToken.safeTransferFrom(address(this), msg.sender, stakedTokens[_owner][_index].tokenId);
        stakingPools[stakedTokens[_owner][_index].poolIndex].stakedCount -= 1;
        emit Unstaked(_owner, stakedTokens[_owner][_index].tokenId);

        stakedTokens[_owner][_index] = stakedTokens[_owner][length - 1];
        stakedTokens[_owner].pop();
    }

    function _calculateExtraReward(address _owner, uint256 _tokenId, uint256 _reward) private view returns (uint256) {
        uint256 reward = _reward;
        if (address(stakingRewardCalculator) != address(0)) {
            reward = stakingRewardCalculator.calculateStakingReward(
                _owner,
                _tokenId,
                _reward
            );
        }
        return reward;
    }

    function _calculateReward(address _owner, uint256 _index, bool _unstaking) private view returns (uint256) {
        uint256 length = stakedTokens[_owner].length;
        if (_index >= length) revert Errors.InvalidIndex(_index);

        StakedTokenInfo storage stakedTokenInfo = stakedTokens[_owner][_index];
        StakingPool storage stakingPool = stakingPools[stakedTokenInfo.poolIndex];
        uint256 reward = _calculateExtraReward(_owner, stakedTokenInfo.tokenId, stakingPool.reward);

        if (stakingPool.invalidated) {
            return 0;
        } else if (block.timestamp >= stakedTokenInfo.expiresAt) {
            return reward - stakedTokenInfo.rewardClaimed;
        } else if (!_unstaking && !stakingPool.rewardWhileLocked) {
            return 0;
        }

        uint256 start = stakedTokenInfo.expiresAt - stakingPool.lockPeriod;
        return
            (((block.timestamp - start) * reward) / stakingPool.lockPeriod) - stakedTokenInfo.rewardClaimed;
    }

    /**
     * @dev Get balance of reward token available to claim by user.
     * @param _owner The owner to check balance for.
     * @return Returns the users reward balance.
     */
    function rewardsAvailable(address _owner) external view override returns (uint256) {
        uint256 reward = 0;

        uint256 length = stakedTokens[_owner].length;
        for (uint256 i = 0; i < length; ) {
            reward += _calculateReward(_owner, i, false);
            unchecked {
                i++;
            }
        }

        return reward;
    }

    /**
     * @dev Get the number of staking pools available.
     * @return Returns the number of staking pools.
     */
    function stakingPoolCount() external view override returns (uint256) {
        return stakingPools.length;
    }

    /**
     * @dev Get the number of staked tokens by owner.
     * @param _owner The owner to lookup for.
     * @return Returns the number of tokens staked.
     */
    function totalStakedForOwner(address _owner) external view override returns (uint256) {
        return stakedTokens[_owner].length;
    }

    /**
     * @dev Calculate the current rewards rate for a user over a given amount of time.
     * @param _owner The owner to calculate for.
     * @param _timeUnit The time in seconds to calculate rewards over. i.e. 86400 seconds to calculate rewards per day.
     * @return Returns the calculated rewards rate.
     */
    function rewardsRatePerTimeUnit(address _owner, uint256 _timeUnit) external view override returns (uint256) {
        uint256 rewardsRate = 0;

        uint256 length = stakedTokens[_owner].length;
        for (uint256 i = 0; i < length; ) {
            StakedTokenInfo storage stakedTokenInfo = stakedTokens[_owner][i];
            if (block.timestamp < stakedTokenInfo.expiresAt) {
                StakingPool storage stakingPool = stakingPools[stakedTokenInfo.poolIndex];
                uint256 reward = _calculateExtraReward(_owner, stakedTokenInfo.tokenId, stakingPool.reward);
                if (!stakingPool.invalidated) {
                    rewardsRate += reward / stakingPool.lockPeriod;
                }
            }

            unchecked {
                i++;
            }
        }

        return rewardsRate * _timeUnit;
    }

    /**
     * @dev Get a list of unlockable (unstakable) token Ids for a user.
     * @param _owner The owner to pull list for.
     * @return Returns the length of the array, and the array of token Ids.
     */
    function unlockableTokenIds(address _owner) external view override returns (uint256, uint256[] memory) {
        uint256 length = stakedTokens[_owner].length;
        uint256 unlockableCount = 0;
        uint256[] memory tokenIds = new uint256[](length);

        for (uint256 i = 0; i < length; ) {
            StakingPool storage stakingPool = stakingPools[stakedTokens[_owner][i].poolIndex];
            if (stakingPool.invalidated || block.timestamp >= stakedTokens[_owner][i].expiresAt) {
                tokenIds[unlockableCount] = stakedTokens[_owner][i].tokenId;
                unlockableCount += 1;
            }

            unchecked {
                i++;
            }
        }

        return (unlockableCount, tokenIds);
    }

    /**
     * @dev Check if user has tokens locked in a pool.
     * @param _owner The owners wallet address.
     * @param _poolIndex The pool to check in.
     * @return Returns true if the owner has tokens locked in the pool, false if not.
     */
    function isLockedInPool(address _owner, uint256 _poolIndex) external view override returns (bool) {
        if (_poolIndex >= stakingPools.length) revert Errors.InvalidIndex(_poolIndex);
        if (stakingPools[_poolIndex].invalidated) return false;

        uint256 length = stakedTokens[_owner].length;
        for (uint256 i = 0; i < length; ) {
            if (
                stakedTokens[_owner][i].poolIndex == _poolIndex && block.timestamp < stakedTokens[_owner][i].expiresAt
            ) {
                return true;
            }

            unchecked {
                i++;
            }
        }

        return false;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
