// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../../common/Errors.sol";
import "./AutoIncrementERC721.sol";
import "./IMintableERC721.sol";

abstract contract MintableERC721 is IMintableERC721, AutoIncrementERC721 {
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
    ) public override onlyOwner returns (uint256) {
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

    function removeMintStage(uint256 _idx) public override onlyOwner {
        if (_idx >= mintStages.length) revert Errors.InvalidIndex(_idx);

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

    function updateMintStagePricing(uint256 _idx, uint256 _price) public override onlyOwner {
        if (_idx >= mintStages.length) revert Errors.InvalidIndex(_idx);

        mintStages[_idx].price = _price;
    }

    function updateMintStageMaxPer(uint256 _idx, uint256 _maxPerWallet, uint256 _maxPerMint) public override onlyOwner {
        if (_idx >= mintStages.length) revert Errors.InvalidIndex(_idx);

        mintStages[_idx].maxPerWallet = _maxPerWallet;
        mintStages[_idx].maxPerMint = _maxPerMint;
    }

    function updateMintStageMerkelRoot(uint256 _idx, bytes32 _merkleRoot) public override onlyOwner {
        if (_idx >= mintStages.length) revert Errors.InvalidIndex(_idx);

        mintStages[_idx].merkleRoot = _merkleRoot;
    }

    function setMintActive(bool _mintActive) public override onlyOwner {
        mintActive = _mintActive;
    }

    function setActiveMintStage(uint256 _idx) public override onlyOwner {
        if (_idx >= mintStages.length) revert Errors.InvalidIndex(_idx);

        activeMintStage = _idx;
    }

    function setPaymentToken(address _paymentToken) public override onlyOwner {
        if (_paymentToken == address(0)) {
            paymentToken = address(0);
            nativePayment = true;
        } else {
            paymentToken = _paymentToken;
            nativePayment = false;
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

    function maximumAmountForActiveStage(
        address _owner,
        bytes32[] calldata _merkleProof
    ) private view returns (uint256) {
        if (_owner == address(0)) revert Errors.ZeroAddress();
        if (!mintActive) return 0;
        if (activeMintStage >= mintStages.length) revert Errors.InvalidIndex(activeMintStage);

        if (mintStages[activeMintStage].merkleRoot != 0) {
            if (_merkleProof.length == 0) return 0;
            if (!verifyMerkleProof(_owner, mintStages[activeMintStage].merkleRoot, _merkleProof)) return 0;
        }

        if (
            ownerMintCounter[mintStages[activeMintStage].ownerMintCounterIdx][_owner] >=
            mintStages[activeMintStage].maxPerWallet
        ) return 0;

        return
            Math.min(
                mintStages[activeMintStage].maxPerWallet -
                    ownerMintCounter[mintStages[activeMintStage].ownerMintCounterIdx][_owner],
                mintStages[activeMintStage].maxPerMint
            );
    }

    function mintPriceForActiveStage(
        address _owner,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) private view returns (uint256) {
        if (_owner == address(0)) revert Errors.ZeroAddress();
        if (_amount == 0) revert InvalidAmount();
        if (!mintActive) revert MintInactive();
        if (activeMintStage >= mintStages.length) revert Errors.InvalidIndex(activeMintStage);

        uint256 allowedAmount = maximumAmountForActiveStage(_owner, _merkleProof);
        if (allowedAmount < _amount) revert InvalidAmount();

        return _amount * mintStages[activeMintStage].price;
    }

    function maximumAmountForOwner(
        address _owner,
        bytes32[] calldata _merkleProof
    ) public view override returns (uint256) {
        return maximumAmountForActiveStage(_owner, _merkleProof);
    }

    function mintPriceForAmount(
        address _owner,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) public view override returns (uint256) {
        return mintPriceForActiveStage(_owner, _amount, _merkleProof);
    }

    function mint(uint256 _amount, bytes32[] calldata _merkleProof) public payable override {
        uint256 price = mintPriceForActiveStage(msg.sender, _amount, _merkleProof);
        if (nativePayment) {
            if (msg.value != price) revert InvalidPayment();
        } else {
            if (paymentToken == address(0)) revert Errors.ZeroAddress();
            if (msg.value != 0) revert InvalidPayment();
            if (price > 0) {
                if (IERC20(paymentToken).balanceOf(msg.sender) < price) revert NoBalance();
                IERC20(paymentToken).transferFrom(msg.sender, address(this), price);
            }
        }

        ownerMintCounter[mintStages[activeMintStage].ownerMintCounterIdx][msg.sender] += _amount;
        _autoIncrementMint(msg.sender, _amount);
    }
}
