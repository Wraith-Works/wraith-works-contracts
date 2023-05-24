```solidity
import "@wraith-works/contracts/tokens/ERC20/BaseERC20.sol";
```

The `BaseERC20` contract extends the basic `ERC20` contract with ownership, pausability, and authorized minting capabilities.

[View Contract :fontawesome-brands-github:](https://github.com/Wraith-Works/wraith-works-contracts/blob/main/contracts/tokens/ERC20/Base20.sol){ .md-button target="_blank" }

## Implementation

The `BaseERC20` contract requires the following variables to be passed into the constructor:

| Name      | Type            | Description           |
|-----------|-----------------|-----------------------|
| `_name`   | `string memory` | Name of the token.    |
| `_symbol` | `string memory` | Symbol for the token. |

## Usage

??? "pause"
    ```solidity
    function pause() external onlyOwner
    ```

    - Pause the contract, and disable token transfers.

??? "unpause"
    ```solidity
    function unpause() external onlyOwner
    ```

    - Unpause the contract, and allow token transfers.

??? "setAuthorizedMinter"
    ```solidity
    function setAuthorizedMinter(address _minter, bool _authorized) external onlyOwner
    ```

    - Add or remove an authorized minter.
    - `_minter`: The address of the authorized minter.
    - `_authorized`: Whether to add or remove as authorized.

??? "authorizedMint"
    ```solidity
    function authorizedMint(address _account, uint256 _amount) external onlyAuthorizedMinter
    ```

    - An authorized only mint to the provided account for the given amount.
    - `_account`: Account to mint to.
    - `_amount`: Amount to mint.

## Example

```solidity
pragma solidity ^0.8.19;

import "@wraith-works/contracts/tokens/ERC20/BaseERC20.sol";

contract MyToken is BaseERC20 {
    constructor() BaseERC20("MyToken", "MYTKN") {}
}
```
