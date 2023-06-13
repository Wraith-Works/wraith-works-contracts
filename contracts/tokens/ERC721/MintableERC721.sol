// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../../common/Errors.sol";
import "./AutoIncrementERC721.sol";
import "./IMintableERC721.sol";

/// @dev Provides a multi-stage mintable version of AutoIncrementERC721.
abstract contract MintableERC721 is IMintableERC721, AutoIncrementERC721 {
    /// @dev List of mint stages.
    MintStage[] public mintStages;
    /// @dev Mint counter by owner for stages.
    mapping(uint256 => mapping(address => uint256)) public ownerMintCounter;
    /// @dev Next index of mint counter mapping.
    uint256 private nextOwnerMintCounter;
    /// @dev Flag indicating whether minting is active.
    bool public mintActive;
    /// @dev Index of the current active mint stage.
    uint256 public activeMintStage;

    /// @dev Utilizing native payments, or token payments.
    bool public nativePayment = true;
    /// @dev The payment token address, if not native.
    address public paymentToken;

    /**
     * @dev Add a new mint stage.
     * @param _price The price of this mint stage.
     * @param _maxPerWallet Maximum mints per wallet.
     * @param _maxPerMint Maximum mints per mint function call.
     * @param _merkleRoot The merkle root for this mint stage. Set to 0x0 for an open mint.
     * @return Returns the index of the added mint stage.
     */
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

    /**
     * @dev Remove the mint stage at the given index. Resets the active mint stage and sets the mint to inactive.
     * @param _idx The index of the mint stage.
     */
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

    /**
     * @dev Update the mint stage price.
     * @param _idx The index of the mint stage.
     * @param _price The price of the mint.
     */
    function updateMintStagePricing(uint256 _idx, uint256 _price) public override onlyOwner {
        if (_idx >= mintStages.length) revert Errors.InvalidIndex(_idx);

        mintStages[_idx].price = _price;
    }

    /**
     * @dev Update the mint stage max per wallet, and max per mint.
     * @param _idx The index of the mint stage.
     * @param _maxPerWallet Max mints per wallet.
     * @param _maxPerMint Max mints per mint function call.
     */
    function updateMintStageMaxPer(uint256 _idx, uint256 _maxPerWallet, uint256 _maxPerMint) public override onlyOwner {
        if (_idx >= mintStages.length) revert Errors.InvalidIndex(_idx);

        mintStages[_idx].maxPerWallet = _maxPerWallet;
        mintStages[_idx].maxPerMint = _maxPerMint;
    }

    /**
     * @dev Update the mint stage merkle root.
     * @param _idx The index of the mint stage.
     * @param _merkleRoot The merkle root. Set to 0x0 for an open mint.
     */
    function updateMintStageMerkleRoot(uint256 _idx, bytes32 _merkleRoot) public override onlyOwner {
        if (_idx >= mintStages.length) revert Errors.InvalidIndex(_idx);

        mintStages[_idx].merkleRoot = _merkleRoot;
    }

    /**
     * @dev Set mint to active or inactive.
     * @param _mintActive True for active, false for inactive.
     */
    function setMintActive(bool _mintActive) public override onlyOwner {
        mintActive = _mintActive;
    }

    /**
     * @dev Set active mint stage index.
     * @param _idx The index of the active mint stage.
     */
    function setActiveMintStage(uint256 _idx) public override onlyOwner {
        if (_idx >= mintStages.length) revert Errors.InvalidIndex(_idx);

        activeMintStage = _idx;
    }

    /**
     * @dev Set the payment token address. Set to `address(0)` for native token payments.
     * @param _paymentToken Payment token address.
     */
    function setPaymentToken(address _paymentToken) public override onlyOwner {
        if (_paymentToken == address(0)) {
            paymentToken = address(0);
            nativePayment = true;
        } else {
            paymentToken = _paymentToken;
            nativePayment = false;
        }
    }

    /// @dev Withdraw all native tokens to the owner
    function withdrawAll() external override onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NoBalance();
        (bool success, ) = owner().call{value: balance}("");
        if (!success) revert WithdrawFailed();
    }

    /**
     * @dev Withdraws all specified tokens to the owner
     * @param _tokenAddress Address of the token.
     */
    function withdrawAll(address _tokenAddress) external override onlyOwner {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        if (balance == 0) revert NoBalance();
        IERC20(_tokenAddress).transfer(owner(), balance);
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

        uint256 maxAmount = Math.min(
            mintStages[activeMintStage].maxPerWallet -
                ownerMintCounter[mintStages[activeMintStage].ownerMintCounterIdx][_owner],
            mintStages[activeMintStage].maxPerMint
        );

        if (MAX_SUPPLY > 0) {
            maxAmount = Math.min(maxAmount, MAX_SUPPLY - _mintCounter);
        }

        return maxAmount;
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

    /**
     * @dev Get the maximum mint amount for the given owner, in the current mint stage.
     * @param _owner The owners address.
     * @param _merkleProof The merkle proof to prove position in merkle tree.
     * @return Returns the amount an owner can mint in the current mint stage.
     */
    function maximumAmountForOwner(
        address _owner,
        bytes32[] calldata _merkleProof
    ) public view override returns (uint256) {
        return maximumAmountForActiveStage(_owner, _merkleProof);
    }

    /**
     * @dev Get the mint price for the given owner and amount, in the current mint stage.
     * @param _owner The owners address.
     * @param _amount The amount to calculate price on. Needs to be within allowed amount.
     * @param _merkleProof The merkle proof to prove position in merkle tree.
     * @return Returns the mint price for the given owner and amount.
     */
    function mintPriceForAmount(
        address _owner,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) public view override returns (uint256) {
        return mintPriceForActiveStage(_owner, _amount, _merkleProof);
    }

    /**
     * @dev Mint the given amount to the callers wallet.
     * @param _amount The amount to mint.
     * @param _merkleProof The merkle proof to prove position in merkle tree.
     */
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
