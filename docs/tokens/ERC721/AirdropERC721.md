```solidity
import "@wraith-works/contracts/tokens/ERC721/AirdropERC721.sol";
```

The `AirdropERC721` contract provides airdrop functionality to the [AutoIncrementERC721](/tokens/ERC721/AutoIncrementERC721) contract.

[View Contract :fontawesome-brands-github:](https://github.com/Wraith-Works/wraith-works-contracts/blob/main/contracts/tokens/ERC721/AirdropERC721.sol){ .md-button target="_blank" }

## Implementation

The `AirdropERC721` contract does not have any additional requirements except what is already outlined in [AutoIncrementERC721](/tokens/ERC721/AutoIncrementERC721).

### Inherits From

- [AutoIncrementERC721](/tokens/ERC721/AutoIncrementERC721)

## Usage

??? "airdrop"
    ```solidity
    function airdrop(address[] calldata _to, uint256[] calldata _amounts) public onlyOwner
    ```

    - Airdrop (mint) tokens to each address in `_to`, for the matching amount in `_amounts`.
    - `_to`: Array of addresses to mint to.
    - `_amounts`: Array of amounts to mint for each address.

## Example

```solidity
pragma solidity ^0.8.19;

import "@wraith-works/contracts/tokens/ERC721/AirdropERC721.sol";

contract MyAirdrop is AirDropERC721 {
    constructor()
        BaseERC721(
            "MyAirdrop",
            "AIRDROP",
            "https://example.com/",
            ".json",
            3333,
            0x14c84F8aBaD55F074Ef18BEb46A7cbede6a17B10,
            750
        )
        AutoIncrementERC721(1)
    {}
}
```
