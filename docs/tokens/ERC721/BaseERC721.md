```solidity
import "@wraith-works/contracts/tokens/ERC721/BaseERC721.sol";
```

The `BaseERC721` contract extends the basic `ERC721` contract with various extensions for controlling a max mint supply and setting royalities.

[View Contract :fontawesome-brands-github:](https://github.com/Wraith-Works/wraith-works-contracts/blob/main/contracts/tokens/ERC721/BaseERC721.sol){ .md-button target="_blank" }

## Implementation

The `BaseERC721` contract requires the following variables to be passed into the constructor:

| Name                   | Type            | Description                                                                                                             |
|------------------------|-----------------|-------------------------------------------------------------------------------------------------------------------------|
| `_name`                | `string memory` | Name of the collection.                                                                                                 |
| `_symbol`              | `string memory` | Symbol for the token.                                                                                                   |
| `_baseURI`             | `string memory` | The URI for the token metadata.                                                                                         |
| `_baseURIExtension`    | `string memory` | The extension to be appended to the tokenID when formin the URI.                                                        |
| `_maxSupply`           | `uint256`       | The maximum amount of tokens that can be minted. Setting this to 0 will allow for an unlimited supply.                  |
| `_royaltyReceiver`     | `address`       | The address that should receive royalties for secondary sales.                                                          |
| `_royaltyFeeNumerator` | `uint96`        | The fee percentage to charge. The denominator is fixed to 10000, so setting to 750 would make the fee 7.5% (750/10000). |

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

??? "setBaseURI"
    ```solidity
    function setBaseURI(string memory _baseURI, string memory _baseURIExtension) external onlyOwner
    ```

    - Set the base URI and extension for the token metadata.
    - `_baseURI`: The URI that will get prepended to the token ID.
    - `_baseURIExtension`: The extension that will get appended to the token ID.

??? "setDefaultRoyalty"
    ```solidity
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner
    ```

    - Set the default royalty to be received for secondary sales. The denominator used for the numerator to form the fraction is 10000.
    - `_receiver`: The address that should receive the royalties.
    - `_feeNumerator`: The fee percentage to charge. The denominator is fixed to 10000, so setting the `_feeNumerator` to 750 would make the fee 7.5% (750/10000).

??? "deleteDefaultRoyalty"
    ```solidity
    function deleteDefaultRoyalty() external onlyOwner
    ```

    - Delete the default royalty (i.e. reset back to 0% with no receiver).

??? "setTokenRoyalty"
    ```solidity
    function setTokenRoyalty(uint256 _tokenId, address _receiver, uint96 _feeNumerator) external onlyOwner
    ```

    - Set royalties on a per token basis.
    - `_tokenId`: The token to set the royalties for.
    - `_receiver`: The address that should receive the royalties.
    - `_feeNumerator`: The fee percentage to charge. The denominator is fixed to 10000, so setting the `_feeNumerator` to 750 would make the fee 7.5% (750/10000).

??? "resetTokenRoyalty"
    ```solidity
    function resetTokenRoyalty(uint256 _tokenId) external onlyOwner
    ```

    - Reset the royalties for a specific token (i.e. reset back to 0% with no receiver).
    - `_tokenId`: The token ID to reset royalties for.

??? "tokenURI"
    ```solidity
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory)
    ```

    - Get the URI to the metadata for a specific token. Format is `[baseURI][tokenId][baseURIExtension]`.
    - `_tokenId`: The token ID to get the metadata URI for.
    - Returns the metadata URI for a specific token.

??? "_baseMint"
    ```solidity
    function _baseMint(address _to, uint256 _amount) internal
    ```

    - Mint the supplied number of tokens to the given address, up to the `MAX_SUPPLY` (which may be unlimited).
    - `_to`: The address to mint tokens to.
    - `_amount`: How many tokens to mint.

## Example

```solidity
pragma solidity ^0.8.19;

import "@wraith-works/contracts/tokens/ERC721/BaseERC721.sol";

contract MyNFT is BaseERC721 {
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
    {}
}
```
