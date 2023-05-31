```solidity
import "@wraith-works/contracts/tokens/ERC721/IStakingRewardCalculator.sol";
```

The `IStakingRewardCalculator` provides an interface that can be implemented for calculating extra staking rewards.

[View Contract :fontawesome-brands-github:](https://github.com/Wraith-Works/wraith-works-contracts/blob/main/contracts/tokens/ERC721/IStakingRewardCalculator.sol){ .md-button target="_blank" }

## Usage

??? "calculateStakingReward"
    ```solidity
    function calculateStakingReward(address _owner, uint256 _tokenId, uint256 _reward) external view returns (uint256);
    ```

    - Calculate the staking reward based on the base reward and a potential multiplier. Calculation defined by implementer.
    - `_owner`: The owner of the token.
    - `_tokenId`: The ID of the token.
    - `_reward`: The base reward.
    - Returns the new reward.

## Example

See [TokenIdStakingRewardCalculator](/tokens/ERC721/TokenIdStakingRewardCalculator) for an example.
