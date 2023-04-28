// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAutoBurnERC721 {
    error InvalidBurnPeriod();
    error InvalidState();
    error BurnAlreadyStarted();
    error BurnNotStarted();
    error AllBurned();
    error TokenAlreadyBurned();

    struct TokenBurnState {
        bool safeFromBurn;
        uint256 ttl;
    }

    function startBurn() external;
    function purge(uint256 _limit) external;
    function tokenTTL(uint256 _tokenId) external view returns (uint256);
    function isTokenSafeFromBurn(uint256 _tokenId) external view returns (bool);
    function isTokenExpired(uint256 _tokenId) external view returns (bool);
}