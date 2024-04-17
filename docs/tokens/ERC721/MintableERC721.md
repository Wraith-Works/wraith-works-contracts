```solidity
import "@wraith-works/contracts/tokens/ERC721/MintableERC721.sol";
```

The `MintableERC721` provides a multi-stage mintable version of [AutoIncrementERC721](/tokens/ERC721/AutoIncrementERC721).

[View Contract :fontawesome-brands-github:](https://github.com/Wraith-Works/wraith-works-contracts/blob/main/contracts/tokens/ERC721/MintableERC721.sol){ .md-button target="_blank" }

### Inherits From

- [AutoIncrementERC721](/tokens/ERC721/AutoIncrementERC721)

## Usage

??? "addMintStage"
    ```solidity
    function addMintStage(
        uint256 _price,
        uint256 _maxPerWallet,
        uint256 _maxPerMint,
        bytes32 _merkleRoot
    ) public onlyOwner returns (uint256)
    ```

    - Add a new mint stage.
    - `_price`: The price of this mint stage.
    - `_maxPerWallet`: Maximum mints per wallet.
    - `_maxPerMint`: Maximum mints per mint function call.
    - `_merkleRoot`: The merkle root for this mint stage. Set to 0x0 for an open mint.
    - Returns the index of the added mint stage.

??? "removeMintStage"
    ```solidity
    function removeMintStage(uint256 _idx) public onlyOwner
    ```

    - Remove the mint stage at the given index. Resets the active mint stage and sets the mint to inactive.
    - `_idx`: The index of the mint stage.

??? "updateMintStagePricing"
    ```solidity
    function updateMintStagePricing(uint256 _idx, uint256 _price) public onlyOwner
    ```

    - Update the mint stage price.
    - `_idx`: The index of the mint stage.
    - `_price`: The price of the mint.

??? "updateMintStageMaxPer"
    ```solidity
    function updateMintStageMaxPer(uint256 _idx, uint256 _maxPerWallet, uint256 _maxPerMint) public onlyOwner
    ```

    - Update the mint stage max per wallet, and max per mint.
    - `_idx`: The index of the mint stage.
    - `_maxPerWallet`: Max mints per wallet.
    - `_maxPerMint`: Max mints per mint function call.

??? "updateMintStageMerkleRoot"
    ```solidity
    function updateMintStageMerkleRoot(uint256 _idx, bytes32 _merkleRoot) public onlyOwner
    ```

    - Update the mint stage merkle root.
    - `_idx`: The index of the mint stage.
    - `_merkleRoot`: The merkle root. Set to 0x0 for an open mint.

??? "setMintActive"
    ```solidity
    function setMintActive(bool _mintActive) public onlyOwner
    ```

    - Set mint to active or inactive.
    - `_mintActive`: True for active, false for inactive.

??? "setActiveMintStage"
    ```solidity
    function setActiveMintStage(uint256 _idx) public onlyOwner
    ```

    - Set active mint stage index.
    - `_idx`: The index of the active mint stage.

??? "setPaymentToken"
    ```solidity
    function setPaymentToken(address _paymentToken) public onlyOwner
    ```

    - Set the payment token address. Set to `address(0)` for native token payments.
    - `_paymentToken`: Payment token address.

??? "withdrawAllNative"
    ```solidity
    function withdrawAllNative() external onlyOwner
    ```

    - Withdraw all native tokens to the owner.

??? "withdrawAllTokens"
    ```solidity
    function withdrawAllTokens(address _tokenAddress) external onlyOwner
    ```

    - Withdraws all specified tokens to the owner.
    - `_tokenAddress`: Address of the token.

??? "maximumAmountForOwner"
    ```solidity
    function maximumAmountForOwner(
        address _owner,
        bytes32[] calldata _merkleProof
    ) public view returns (uint256)
    ```

    - Get the maximum mint amount for the given owner, in the current mint stage.
    - `_owner`: The owners address.
    - `_merkleProof`: The merkle proof to prove position in merkle tree.
    - Returns the amount an owner can mint in the current mint stage.

??? "mintPriceForAmount"
    ```solidity
    function mintPriceForAmount(
        address _owner,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) public view returns (uint256)
    ```

    - Get the mint price for the given owner and amount, in the current mint stage.
    - `_owner`: The owners address.
    - `_amount`: The amount to calculate price on. Needs to be within allowed amount.
    - `_merkleProof`: The merkle proof to prove position in merkle tree.
    - Returns the mint price for the given owner and amount.

??? "mint"
    ```solidity
    function mint(uint256 _amount, bytes32[] calldata _merkleProof) public payable
    ```

    - Mint the given amount to the callers wallet.
    - `_amount`: The amount to mint.
    - `_merkleProof`: The merkle proof to prove position in merkle tree.

## Example

```solidity
pragma solidity ^0.8.19;

import "@wraith-works/contracts/tokens/ERC721/MintableERC721.sol";

contract MyMintableERC721 is MintableERC721 {
    constructor(
        uint256 _maxSupply
    )
        BaseERC721(
            "Example",
            "EXAMPLE",
            "https://example.com/",
            ".json",
            _maxSupply,
            0x14c84F8aBaD55F074Ef18BEb46A7cbede6a17B10,
            750
        )
        AutoIncrementERC721(1)
    {
        addMintStage(0, 2, 2, 0x0); // Whitelist
        addMintStage(15 * 10**18, 1, 1, 0x0); // Allowlist
        addMintStage(25 * 10**18, 1, 1, 0x0); // Public
    }
}
```
