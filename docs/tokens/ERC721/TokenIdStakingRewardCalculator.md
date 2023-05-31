```solidity
import "@wraith-works/contracts/tokens/ERC721/TokenIdStakingRewardCalculator.sol";
```

The `TokenIdStakingRewardCalculator` provides a mechanism for adding staking reward multipliers per token.

[View Contract :fontawesome-brands-github:](https://github.com/Wraith-Works/wraith-works-contracts/blob/main/contracts/tokens/ERC721/TokenIdStakingRewardCalculator.sol){ .md-button target="_blank" }

### Inherits From

- [IStakingRewardCalculator](/tokens/ERC721/IStakingRewardCalculator)

## Usage

??? "pause"
    ```solidity
    function pause() external onlyOwner
    ```

    - Pause the contract.

??? "unpause"
    ```solidity
    function unpause() external onlyOwner
    ```

    - Unpause the contract.

??? "setTokenMultipliers"
    ```solidity
    function setTokenMultipliers(uint256[] calldata _tokenIds, uint256[] calldata _multipliers) external onlyOwner
    ```

    - Set the multipliers for the given token IDs.
    - `_tokenIds`: The IDs of the tokens.
    - `_multipliers`: The reward multipliers.

??? "_setTokenMultiplier"
    ```solidity
    function _setTokenMultiplier(uint256 _tokenId, uint256 _multiplier) internal
    ```

    - Set the multiplier for the given token ID.
    - `_tokenId`: The ID for the token.
    - `_multiplier`: The reward multiplier.

??? "calculateStakingReward"
    ```solidity
    function calculateStakingReward(address _owner, uint256 _tokenId, uint256 _reward) external view returns (uint256);
    ```

    - See [IStakingRewardCalculator](/tokens/ERC721/IStakingRewardCalculator).

## Example

```solidity
pragma solidity ^0.8.19;

import "@wraith-works/contracts/tokens/ERC721/TokenIdStakingRewardCalculator.sol";

contract MyRewardCalculator is TokenIdStakingRewardCalculator {
    constructor() {
        // Set token ID 1 to a 1.5x multiplier.
        _setTokenMultiplier(1, 15000000000000000000);
    }
}
```
