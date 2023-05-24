```solidity
import "@wraith-works/contracts/tokens/ERC721/AutoIncrementERC721.sol";
```

The `AutoIncrementERC721` contract provides auto incrementing functionality to the [BaseERC721](/tokens/ERC721/BaseERC721) contract.

[View Contract :fontawesome-brands-github:](https://github.com/Wraith-Works/wraith-works-contracts/blob/main/contracts/tokens/ERC721/AutoIncrementERC721.sol){ .md-button target="_blank" }

## Implementation

The `AutoIncrementERC721` contract requires the following variables to be passed into the constructor:

| Name             | Type      | Description                              |
|------------------|-----------|------------------------------------------|
| `_startingIndex` | `uint256` | The index to start at for the token Ids. |

### Inherits From

- [BaseERC721](/tokens/ERC721/BaseERC721)

## Usage

??? "_autoIncrementMint"
    ```solidity
    function _autoIncrementMint(address _to, uint256 _amount) internal
    ```

    - Auto incrementing mint function. Token ID will increment for each internal mint call.
    - `_to`: The address to mint to.
    - `_amount`: The amount to mint out.

## Example

```solidity
pragma solidity ^0.8.19;

import "@wraith-works/contracts/tokens/ERC721/AutoIncrementERC721.sol";

contract MyNFT is AutoIncrementERC721 {
    constructor()
        BaseERC721(
            "MyNFT",
            "NFT",
            "https://example.com/",
            ".json",
            3333,
            0x14c84F8aBaD55F074Ef18BEb46A7cbede6a17B10,
            750
        )
        AutoIncrementERC721(1)
    {}

    function mint(uint256 _amount) external {
        _autoIncrementMint(msg.sender, _amount);
    }
}
```
