// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMintableERC721 {
    error InvalidAmount();
    error InvalidPayment();
    error InvalidPrice();
    error InvalidProofLength();

    error MintInactive();
    error NoBalance();
    error WithdrawFailed();

    struct MintStage {
        uint256 price;
        uint256 maxPerWallet;
        bytes32 merkleRoot;
    }

    function addMintStage(uint256 _price, uint256 _maxPerWallet, bytes32 _merkleRoot) external returns (uint256);

    function removeMintStage(uint256 _idx) external;

    function updateMintStagePricing(uint256 _idx, uint256 _price) external;

    function updateMintStageMaxPerWallet(uint256 _idx, uint256 _maxPerWallet) external;

    function updateMintStageMerkleRoot(uint256 _idx, bytes32 _merkleRoot) external;

    function setMintActive(bool _mintActive) external;

    function setActiveMintStage(uint256 _idx) external;

    function setMaxPerMint(uint256 _maxPerMint) external;

    function setMaxPerWallet(uint256 _maxPerWallet) external;

    function setPaymentToken(address _paymentToken) external;

    function withdrawAllNative() external;

    function withdrawAllTokens(address _tokenAddress) external;

    function maximumAmountForOwner(address _owner, bytes32[][] calldata _merkleProofs) external view returns (uint256);

    function mintPriceForAmount(
        address _owner,
        uint256 _amount,
        bytes32[][] calldata _merkleProofs
    ) external view returns (uint256);

    function mint(uint256 _amount, bytes32[][] calldata _merkleProofs) external payable;
}
