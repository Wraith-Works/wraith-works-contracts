// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../tokens/ERC721/StakingPoolsERC721.sol";

contract StakingPoolsERC721Mock is StakingPoolsERC721 {
    constructor(address _stakingToken, address _rewardToken) StakingPoolsERC721(_stakingToken, _rewardToken) {
        _addStakingPool(true, 86400, 1 * 10 ** 18);
        _activateStakingPool(0);

        _addStakingPool(false, 86400 * 7, 10 * 10 ** 18);
        _activateStakingPool(1);

        _addStakingPool(true, 86400 * 30, 50 * 10 ** 18);
        _activateStakingPool(2);
    }
}
