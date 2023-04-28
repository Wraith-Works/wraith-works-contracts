// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IAutoBurnERC721.sol";
import "../BaseERC721.sol";

abstract contract AutoBurnERC721 is IAutoBurnERC721, BaseERC721 {
    uint256 public burnPeriod;
    uint256 public burnStartedTimestamp;
    uint256 public totalBurnedCounter;
    mapping(address => uint256) public ownerBurnCounter;
    mapping(address => mapping(uint256 => uint256)) public ownerBurnedTokenIds;
    mapping(uint256 => uint256) public tokenBurnTimestamp;

    uint256 private startingTokenTTL;
    mapping(uint256 => TokenBurnState) private tokenBurnStates;

    constructor(uint256 _burnPeriod) {
        if (_burnPeriod == 0) revert InvalidBurnPeriod();
        burnPeriod = _burnPeriod;
    }

    function startBurn() public override onlyOwner {
        if (burnStartedTimestamp > 0) revert BurnAlreadyStarted();
        burnStartedTimestamp = block.timestamp;
        startingTokenTTL = block.timestamp + burnPeriod;
    }

    function purge(uint256 _limit) public override onlyOwner {
        if (burnStartedTimestamp == 0) revert BurnNotStarted();
        if (totalSupply() == 0) revert AllBurned();

        if (_limit == 0) {
            _limit = totalSupply();
        }

        uint256 burnCounter = 0;
        uint256 tokenId = 0;

        while (burnCounter < _limit && tokenId < _tokenIdCounter) {
            if (_exists(tokenId) && isTokenExpired(tokenId)) {
                _burn(tokenId);
                unchecked {
                    burnCounter += 1;
                }
            }
            unchecked {
                tokenId += 1;
            }
        }
    }

    function tokenTTL(uint256 _tokenId) public view override returns (uint256) {
        if (isTokenSafeFromBurn(_tokenId)) return 0;
        return tokenBurnStates[_tokenId].ttl > 0 ? tokenBurnStates[_tokenId].ttl : startingTokenTTL;
    }

    function isTokenSafeFromBurn(uint256 _tokenId) public view override returns (bool) {
        if (!_exists(_tokenId)) revert InvalidTokenId();
        return tokenBurnStates[_tokenId].safeFromBurn;
    }

    function isTokenExpired(uint256 _tokenId) public view override returns (bool) {
        if (startingTokenTTL == 0 || isTokenSafeFromBurn(_tokenId)) return false;
        return tokenTTL(_tokenId) <= block.timestamp;
    }

    function _setTokenSafeFromBurn(uint256 _tokenId, bool _safeFromBurn) internal {
        if (!_exists(_tokenId)) revert InvalidTokenId();
        if (tokenBurnStates[_tokenId].safeFromBurn == _safeFromBurn) revert InvalidState();
        if (isTokenExpired(_tokenId)) revert TokenAlreadyBurned();

        tokenBurnStates[_tokenId].safeFromBurn = _safeFromBurn;
        tokenBurnStates[_tokenId].ttl = _safeFromBurn ? 0 : block.timestamp + burnPeriod;
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _batchSize
    ) internal override(BaseERC721) {
        super._beforeTokenTransfer(_from, _to, _tokenId, _batchSize);
        if (_to == address(0)) {
            tokenBurnTimestamp[_tokenId] = tokenBurnStates[_tokenId].ttl;
            ownerBurnedTokenIds[_from][ownerBurnCounter[_from]] = _tokenId;
            unchecked {
                ownerBurnCounter[_from] += 1;
                totalBurnedCounter += 1;
            }
        }
    }
}