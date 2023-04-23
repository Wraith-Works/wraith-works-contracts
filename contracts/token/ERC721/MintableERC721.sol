// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./BaseERC721.sol";
import "./IMintableERC721.sol";

abstract contract MintableERC721 is IMintableERC721, BaseERC721 {
    MintStage[] public mintStages;
    mapping(uint256 => mapping(address => uint256)) public ownerMintCounter;
    uint256 private nextOwnerMintCounter;
    bool public mintActive;
    uint256 public activeMintStage;

    bool public nativePayment = true;
    address public paymentToken;

    function addMintStage(
        uint256 _price,
        uint256 _maxPerWallet,
        uint256 _maxPerMint,
        bytes32 _merkleRoot
    ) public onlyOwner returns (uint256) {
        mintStages.push(
            MintStage({
                price: _price,
                maxPerWallet: _maxPerWallet,
                maxPerMint: _maxPerMint,
                merkleRoot: _merkleRoot,
                ownerMintCounterIdx: nextOwnerMintCounter
            })
        );
        nextOwnerMintCounter += 1;
        return mintStages.length - 1;
    }

    function removeMintStage(uint256 _idx) public onlyOwner {
        if (_idx >= mintStages.length) revert InvalidIndex();

        uint256 length = mintStages.length - 1;
        for (uint256 i = _idx; i < length; ) {
            mintStages[i] = mintStages[i + i];
            unchecked {
                i++;
            }
        }
        mintStages.pop();

        // No clean way to reshift, just reset
        activeMintStage = 0;
        mintActive = false;
    }

    function updateMintStagePricing(uint256 _idx, uint256 _price) public onlyOwner {
        if (_idx >= mintStages.length) revert InvalidIndex();

        mintStages[_idx].price = _price;
    }

    function updateMintStageMaxPer(uint256 _idx, uint256 _maxPerWallet, uint256 _maxPerMint) public onlyOwner {
        if (_idx >= mintStages.length) revert InvalidIndex();

        mintStages[_idx].maxPerWallet = _maxPerWallet;
        mintStages[_idx].maxPerMint = _maxPerMint;
    }

    function updateMintStageMerkelRoot(uint256 _idx, bytes32 _merkleRoot) public onlyOwner {
        if (_idx >= mintStages.length) revert InvalidIndex();

        mintStages[_idx].merkleRoot = _merkleRoot;
    }

    function setMintActive(bool _mintActive) public onlyOwner {
        mintActive = _mintActive;
    }

    function setActiveMintStage(uint256 _idx) public onlyOwner {
        if (_idx >= mintStages.length) revert InvalidIndex();

        activeMintStage = _idx;
    }

    function setPaymentToken(address _paymentToken) public onlyOwner {
        if (_paymentToken == address(0)) {
            paymentToken = address(0);
            nativePayment = true;
        } else {
            paymentToken = _paymentToken;
            nativePayment = false;
        }
    }

    function recordOwnerMintCount(address _owner, uint256 _amount, bytes32[] calldata _merkleProof) private {
        uint256 remainingAmount = _amount;

        uint256 active = activeMintStage + 1;
        for (uint256 i = 0; i < active; ) {
            if (remainingAmount == 0) break;

            uint256 amount = maximumAmountForStage(i, _owner, _merkleProof);
            if (amount > 0) {
                amount = Math.min(amount, remainingAmount);
                ownerMintCounter[mintStages[i].ownerMintCounterIdx][_owner] += amount;
                remainingAmount -= amount;
            }

            unchecked {
                i++;
            }
        }
    }

    function verifyMerkleProof(
        address _owner,
        bytes32 _merkleRoot,
        bytes32[] calldata _merkleProof
    ) private pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_owner));
        return MerkleProof.verify(_merkleProof, _merkleRoot, leaf);
    }

    function maximumAmountForStage(
        uint256 _idx,
        address _owner,
        bytes32[] calldata _merkleProof
    ) private view returns (uint256) {
        if (_idx >= mintStages.length) revert InvalidIndex();

        if (mintStages[_idx].merkleRoot != 0) {
            if (_merkleProof.length == 0) return 0;
            if (!verifyMerkleProof(_owner, mintStages[_idx].merkleRoot, _merkleProof)) return 0;
        }

        if (ownerMintCounter[mintStages[_idx].ownerMintCounterIdx][_owner] >= mintStages[_idx].maxPerWallet) return 0;

        return
            Math.min(
                mintStages[_idx].maxPerWallet - ownerMintCounter[mintStages[_idx].ownerMintCounterIdx][_owner],
                mintStages[_idx].maxPerMint
            );
    }

    function mintPriceForStage(
        uint256 _idx,
        address _owner,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) private view returns (uint256) {
        if (_idx >= mintStages.length) revert InvalidIndex();
        if (maximumAmountForStage(_idx, _owner, _merkleProof) < _amount) revert InvalidAmount();

        return _amount * mintStages[_idx].price;
    }

    function maximumAmountForOwner(address _owner, bytes32[] calldata _merkleProof) public view returns (uint256) {
        if (_owner == address(0)) revert InvalidAddress();
        if (!mintActive) return 0;
        if (_tokenIdCounter >= MAX_SUPPLY - 1) revert MaxMinted();
        if (activeMintStage >= mintStages.length) revert InvalidIndex();

        uint256 allowedAmount = 0;

        uint256 active = activeMintStage + 1;
        for (uint256 i = 0; i < active; ) {
            allowedAmount += maximumAmountForStage(i, _owner, _merkleProof);

            unchecked {
                i++;
            }
        }

        return allowedAmount;
    }

    function mintPriceForAmount(
        address _owner,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) public view returns (uint256) {
        if (_owner == address(0)) revert InvalidAddress();
        if (_amount == 0) revert InvalidAmount();
        if (!mintActive) revert MintInactive();
        if (_tokenIdCounter >= MAX_SUPPLY - 1) revert MaxMinted();
        if (activeMintStage >= mintStages.length) revert InvalidIndex();

        uint256 allowedAmount = 0;
        uint256 remainingAmount = _amount;
        uint256 price = 0;

        uint256 active = activeMintStage + 1;
        for (uint256 i = 0; i < active; ) {
            if (remainingAmount == 0) break;

            uint256 amount = maximumAmountForStage(i, _owner, _merkleProof);
            if (amount > 0) {
                amount = Math.min(amount, remainingAmount);
                price += amount * mintStages[i].price;
                remainingAmount -= amount;
                allowedAmount += amount;
            }

            unchecked {
                i++;
            }
        }

        if (allowedAmount < _amount) revert InvalidAmount();

        return price;
    }

    function mint(uint256 _amount, bytes32[] calldata _merkleProof) public payable whenNotPaused {
        uint256 price = mintPriceForAmount(msg.sender, _amount, _merkleProof);
        if (nativePayment) {
            if (msg.value != price) revert InvalidPayment();
        } else {
            if (paymentToken == address(0)) revert InvalidAddress();
            if (msg.value != 0) revert InvalidPayment();
            if (price > 0) {
                if (IERC20(paymentToken).balanceOf(msg.sender) < price) revert NoBalance();
                IERC20(paymentToken).transferFrom(msg.sender, address(this), price);
            }
        }

        recordOwnerMintCount(msg.sender, _amount, _merkleProof);
        _baseMint(msg.sender, _amount);
    }
}
