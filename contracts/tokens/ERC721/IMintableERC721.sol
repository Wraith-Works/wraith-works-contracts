// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMintableERC721 {
    error InvalidAmount();
    error InvalidPayment();
    error InvalidPrice();

    error MintInactive();
    error NoBalance();

    struct MintStage {
        uint256 price;
        uint256 maxPerWallet;
        uint256 maxPerMint;
        bytes32 merkleRoot;
        uint256 ownerMintCounterIdx;
    }

    function addMintStage(
        uint256 _price,
        uint256 _maxPerWallet,
        uint256 _maxPerMint,
        bytes32 _merkleRoot
    ) external returns (uint256);

    function removeMintStage(uint256 _idx) external;

    function updateMintStagePricing(uint256 _idx, uint256 _price) external;

    function updateMintStageMaxPer(uint256 _idx, uint256 _maxPerWallet, uint256 _maxPerMint) external;

    function updateMintStageMerkelRoot(uint256 _idx, bytes32 _merkleRoot) external;

    function setMintActive(bool _mintActive) external;

    function setActiveMintStage(uint256 _idx) external;

    function setPaymentToken(address _paymentToken) external;

    function maximumAmountForOwner(address _owner, bytes32[] calldata _merkleProof) external view returns (uint256);

    function mintPriceForAmount(
        address _owner,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external view returns (uint256);

    function mint(uint256 _amount, bytes32[] calldata _merkleProof) external payable;
}
