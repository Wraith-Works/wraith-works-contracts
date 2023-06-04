// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IStakingPoolsERC721 is IERC721Receiver {
    error InvalidLockPeriod();
    error StakingPoolInactive(uint256 index);
    error StakingPoolInvalid(uint256 index);
    error NotOwner();

    event StakingTokenSet(address indexed stakingToken);
    event RewardTokenSet(address indexed rewardToken);
    event StakingRewardCalculatorSet(address indexed stakingRewardCalculator);
    event StakingPoolAdded(uint256 index);
    event StakingPoolActivated(uint256 index);
    event StakingPoolDeactivated(uint256 index);
    event StakingPoolInvalidated(uint256 index);
    event Staked(address indexed owner, uint256 indexed tokenId);
    event Unstaked(address indexed owner, uint256 indexed tokenId);
    event RewardClaimed(address indexed owner, uint256 amount);

    struct StakingPool {
        bool active;
        bool invalidated;
        bool rewardWhileLocked;
        uint256 lockPeriod;
        uint256 reward;
        uint256 stakedCount;
    }

    struct StakedTokenInfo {
        uint256 tokenId;
        uint256 poolIndex;
        uint256 expiresAt;
        uint256 rewardClaimed;
    }

    function pause() external;

    function unpause() external;

    function setStakingToken(address _stakingToken) external;

    function setRewardToken(address _rewardToken) external;

    function setStakingRewardCalculator(address _stakingRewardCalculator) external;

    function addStakingPool(bool _rewardWhileLocked, uint256 _lockPeriod, uint256 _reward) external returns (uint256);

    function activateStakingPool(uint256 _index) external;

    function deactivateStakingPool(uint256 _index) external;

    function invalidateStakingPool(uint256 _index) external;

    function stake(uint256 _poolIndex, uint256[] calldata _tokenIds) external;

    function unstake() external;

    function claimRewards() external;

    function rewardsAvailable(address _owner) external view returns (uint256);

    function stakingPoolCount() external view returns (uint256);

    function getStakedTokenIds(address _owner) external view returns (uint256[] memory);

    function getLockedTokenIds(address _owner, uint256 _poolIndex) external view returns (uint256, uint256[] memory);

    function getUnlockedTokenIds(address _owner) external view returns (uint256, uint256[] memory);

    function getStakedTokenBalance(address _owner) external view returns (uint256);

    function rewardsRatePerTimeUnit(address _owner, uint256 _timeUnit) external view returns (uint256);
}
