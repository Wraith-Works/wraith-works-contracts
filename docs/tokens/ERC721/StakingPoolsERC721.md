```solidity
import "@wraith-works/contracts/tokens/ERC721/StakingPoolsERC721.sol";
```

The `StakingPoolsERC721` provides staking pools for ERC721 tokens, earning a ERC20 reward token while staked.

[View Contract :fontawesome-brands-github:](https://github.com/Wraith-Works/wraith-works-contracts/blob/main/contracts/tokens/ERC721/StakingPoolsERC721.sol){ .md-button target="_blank" }

## Implementation

The `StakingPoolsERC721` contract requires the following variables to be passed into the constructor:

| Name            | Type      | Description                                                         |
|-----------------|-----------|---------------------------------------------------------------------|
| `_stakingToken` | `address` | The address of the ERC721 token that can be staked in the contract. |
| `_rewardToken`  | `address` | The address of the ERC20 token to be rewarded for staking.          |

## Usage

??? "pause"
    ```solidity
    function pause() external onlyOwner
    ```

    - Pause the contract, and disable staking.

??? "unpause"
    ```solidity
    function unpause() external onlyOwner
    ```

    - Unpause the contract, and allow staking.

??? "setStakingToken"
    ```solidity
    function setStakingToken(address _stakingToken) external onlyOwner
    ```

    - Set the address of the ERC721 token that can be staked in the contract.
    - `_stakingToken`: Address of the ERC721 token.

??? "setRewardToken"
    ```solidity
    function setRewardToken(address _rewardToken) external onlyOwner
    ```

    - Set the address of the ERC20 token to be rewarded for staking.
    - `_receiver`: Address of the ERC20 token.

??? "addStakingPool"
    ```solidity
    function addStakingPool(
        bool _rewardWhileLocked,
        uint256 _lockPeriod,
        uint256 _reward
    ) external onlyOwner returns (uint256)
    ```

    - Add a staking pool. The pool starts disabled.
    - `_rewardWhileLocked`: Reward tokens can be claimed during the lock period.
    - `_lockPeriod`: The lock period in seconds that the token will be locked.
    - `_reward`: The amount of the ERC20 token to give at the end of the lock period.
    - Returns the index of the staking pool.

??? "_addStakingPool"
    ```solidity
    function _addStakingPool(
        bool _rewardWhileLocked,
        uint256 _lockPeriod,
        uint256 _reward
    ) internal returns (uint256)
    ```

    - Add a staking pool. The pool starts disabled.
    - `_rewardWhileLocked`: Reward tokens can be claimed during the lock period.
    - `_lockPeriod`: The lock period in seconds that the token will be locked.
    - `_reward`: The amount of the ERC20 token to give at the end of the lock period.
    - Returns the index of the staking pool.

??? "activateStakingPool"
    ```solidity
    function activateStakingPool(uint256 _index) external onlyOwner
    ```

    - Activate the given staking pool. Cannot activate an invalidated pool.
    - `_index`: The index of the staking pool.

??? "_activateStakingPool"
    ```solidity
    function _activateStakingPool(uint256 _index) internal
    ```

    - Activate the given staking pool. Cannot activate an invalidated pool.
    - `_index`: The index of the staking pool.

??? "deactivateStakingPool"
    ```solidity
    function deactivateStakingPool(uint256 _index) external onlyOwner
    ```

    - Deactivate the given staking pool. No new tokens can be staked in the pool, but existing tokens in the pool will continue to earn until unlocked.
    - `_index`: The index of the staking pool.

??? "invalidateStakingPool"
    ```solidity
    function invalidateStakingPool(uint256 _index) external onlyOwner
    ```

    - Invalidate the staking pool. No new tokens can be staked in the pool, and all existing tokens will be immediately unlocked. Unclaimed tokens will be lost.
    - `_index`: The index of the staking pool.

??? "stake"
    ```solidity
    function stake(uint256 _poolIndex, uint256[] calldata _tokenIds) external whenNotPaused
    ```

    - Stake the token Ids in the given staking pool.
    - `_poolIndex`: The index of the staking pool.
    - `_tokenIds`: The list of tokenIds to stake in the pool.

??? "unstake"
    ```solidity
    function unstake() external whenNotPaused nonReentrant
    ```

    - Unstake all unlocked tokens for the caller, and pay out any unclaimed rewards.

??? "claimRewards"
    ```solidity
    function claimRewards() external whenNotPaused nonReentrant
    ```

    - Claim any unclaimed rewards for the caller.

??? "rewardsAvailable"
    ```solidity
    function rewardsAvailable(address _owner) public view returns (uint256)
    ```

    - Get balance of reward token available to claim by user.
    - `_owner`: The owner to check balance for.
    - Returns the users reward balance.

??? "stakingPoolCount"
    ```solidity
    function stakingPoolCount() public view returns (uint256)
    ```

    - Get the number of staking pools available.
    - Returns the number of staking pools.

??? "totalStakedForOwner"
    ```solidity
    function totalStakedForOwner(address _owner) public view returns (uint256)
    ```

    - Get the number of staked tokens by owner.
    - `_owner`: The owner to lookup for.
    - Returns the number of tokens staked.

??? "rewardsRatePerTimeUnit"
    ```solidity
    function rewardsRatePerTimeUnit(address _owner, uint256 _timeUnit) public view returns (uint256)
    ```

    - Calculate the current rewards rate for a user over a given amount of time.
    - `_owner`: The owner to calculate for.
    - `_timeUnit`: The time in seconds to calculate rewards over. i.e. 86400 seconds to calculate rewards per day.
    - Returns the calculated rewards rate.

??? "unlockableTokenIds"
    ```solidity
    function unlockableTokenIds(address _owner) public view returns (uint256, uint256[] memory)
    ```

    - Get a list of unlockable (unstakable) token Ids for a user.
    - `_owner`: The owner to pull list for.
    - Returns the length of the array, and the array of token Ids.

## Example

```solidity
pragma solidity ^0.8.19;

import "@wraith-works/contracts/tokens/ERC721/StakingPoolsERC721.sol";

contract MyStakingPools is StakingPoolsERC721 {
    constructor(address _stakingToken, address _rewardToken) StakingPoolsERC721(_stakingToken, _rewardToken) {
        _addStakingPool(true, 86400, 1 * 10**18);
        _activateStakingPool(0);

        _addStakingPool(true, 86400 * 7, 10 * 10**18);
        _activateStakingPool(1);

        _addStakingPool(true, 86400 * 30, 50 * 10**18);
        _activateStakingPool(2);
    }
}
```
