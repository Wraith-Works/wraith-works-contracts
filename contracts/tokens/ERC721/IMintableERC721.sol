// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMintableERC721 {
    error InvalidIndex();
    error InvalidAddress();
    error InvalidAmount();
    error InvalidPayment();
    error InvalidPrice();

    error MintInactive();
    error NoMintsAvailable();
    error NoBalance();

    struct MintStage {
        uint256 price;
        uint256 maxPerWallet;
        uint256 maxPerMint;
        bytes32 merkleRoot;
        uint256 ownerMintCounterIdx;
    }
}
