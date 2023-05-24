```solidity
import "@wraith-works/contracts/tokens/ERC721/RevealableERC721.sol";
```

The `RevealableERC721` contract provides reveal functionality to the [BaseERC721](/tokens/ERC721/BaseERC721) contract.

[View Contract :fontawesome-brands-github:](https://github.com/Wraith-Works/wraith-works-contracts/blob/main/contracts/tokens/ERC721/RevealableERC721.sol){ .md-button target="_blank" }

## Implementation

The `RevealableERC721` contract requires the following variables to be passed into the constructor:

| Name            | Type            | Description                         |
|-----------------|-----------------|-------------------------------------|
| `_prerevealURI` | `string memory` | The URI for the prereveal metadata. |

### Inherits From

- [BaseERC721](/tokens/ERC721/BaseERC721)

## Usage

??? "setPrerevealURI"
    ```solidity
    function setPrerevealURI(string memory _prerevealURI) external onlyOwner
    ```

    - Set the URI for te preveal metadata.
    - `_prerevealURI`: The URI for the prereveal metadata.

??? "toggleReveal"
    ```solidity
    function toggleReveal() external onlyOwner
    ```

    - Toggle the reveal. When `revealed` is `true`, the token specific metadata URI will be returned.

??? "tokenURI"
    ```solidity
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory)
    ```

    - Get either the prereveal metadata, or the token specific metadata.
    - `_tokenId`: The token ID to get the metadata URI for.
    - Returns the metadata URI for a specific token or the prereveal metadata URI, depending on the state of `revealed`.

## Example

```solidity
pragma solidity ^0.8.19;

import "@wraith-works/contracts/tokens/ERC721/RevealableERC721.sol";

contract MyRevealable is RevealableERC721 {
    constructor()
        BaseERC721(
            "MyRevealable",
            "REVEALABLE",
            "https://example.com/",
            ".json",
            3333,
            0x14c84F8aBaD55F074Ef18BEb46A7cbede6a17B10,
            750
        )
        RevealableERC721("https://example.com/prereveal.json")
    {}

    function tokenURI(uint256 _tokenId) public view override(BaseERC721, RevealableERC721) returns (string memory) {
        return RevealableERC721.tokenURI(_tokenId);
    }
}
```
