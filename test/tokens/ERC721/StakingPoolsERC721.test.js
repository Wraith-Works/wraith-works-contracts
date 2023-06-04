const { expect } = require('chai');
const { loadFixture, time } = require('@nomicfoundation/hardhat-network-helpers');
const { ethers } = require('hardhat');

describe('StakingPoolsERC721 contract test', function() {
    async function deployStakingPoolsMockFixture() {
        const [owner, user1] = await ethers.getSigners();

        const ERC721Mock = await ethers.getContractFactory('ERC721Mock');
        const erc721Mock = await ERC721Mock.deploy(0);
        await erc721Mock.deployed();

        const ERC20Mock = await ethers.getContractFactory('ERC20Mock');
        const erc20Mock = await ERC20Mock.deploy();
        await erc20Mock.deployed();

        const StakingPoolsERC721Mock = await ethers.getContractFactory('StakingPoolsERC721Mock');
        const stakingPoolsERC721Mock = await StakingPoolsERC721Mock.deploy(erc721Mock.address, erc20Mock.address);
        await stakingPoolsERC721Mock.deployed();

        const TokenIdStakingRewardCalculatorMock = await ethers.getContractFactory('TokenIdStakingRewardCalculatorMock');
        const tokenIdStakingRewardCalculatorMock = await TokenIdStakingRewardCalculatorMock.deploy();
        await tokenIdStakingRewardCalculatorMock.deployed();

        return { erc721Mock, erc20Mock, stakingPoolsERC721Mock, tokenIdStakingRewardCalculatorMock, owner, user1 };
    }

    it('Deployment should succeed', async function() {
        const { erc721Mock, erc20Mock, stakingPoolsERC721Mock } = await loadFixture(deployStakingPoolsMockFixture);

        expect(await stakingPoolsERC721Mock.stakingToken()).to.equal(erc721Mock.address);
        expect(await stakingPoolsERC721Mock.rewardToken()).to.equal(erc20Mock.address);
        expect(await stakingPoolsERC721Mock.paused()).to.equal(true);
        expect(await stakingPoolsERC721Mock.stakingPoolCount()).to.equal(3);
    });

    it('StakingPoolsERC721 security checks', async function() {
        const { stakingPoolsERC721Mock, tokenIdStakingRewardCalculatorMock, user1 } = await loadFixture(deployStakingPoolsMockFixture);

        await expect(stakingPoolsERC721Mock.connect(user1).unpause()).to.be.revertedWith('Ownable: caller is not the owner');
        await expect(stakingPoolsERC721Mock.connect(user1).pause()).to.be.revertedWith('Ownable: caller is not the owner');
        await expect(stakingPoolsERC721Mock.connect(user1).setStakingToken(user1.address)).to.be.revertedWith(
            'Ownable: caller is not the owner',
        );
        await expect(stakingPoolsERC721Mock.connect(user1).setRewardToken(user1.address)).to.be.revertedWith(
            'Ownable: caller is not the owner',
        );
        await expect(stakingPoolsERC721Mock.connect(user1).addStakingPool(true, 1, 1)).to.be.revertedWith(
            'Ownable: caller is not the owner',
        );
        await expect(stakingPoolsERC721Mock.connect(user1).activateStakingPool(0)).to.be.revertedWith(
            'Ownable: caller is not the owner',
        );
        await expect(stakingPoolsERC721Mock.connect(user1).deactivateStakingPool(0)).to.be.revertedWith(
            'Ownable: caller is not the owner',
        );
        await expect(stakingPoolsERC721Mock.connect(user1).invalidateStakingPool(0)).to.be.revertedWith(
            'Ownable: caller is not the owner',
        );
        await expect(stakingPoolsERC721Mock.connect(user1).stake(0, [1])).to.be.revertedWith('Pausable: paused');
        await expect(stakingPoolsERC721Mock.connect(user1).unstake()).to.be.revertedWith('Pausable: paused');
        await expect(stakingPoolsERC721Mock.connect(user1).claimRewards()).to.be.revertedWith('Pausable: paused');

        await expect(tokenIdStakingRewardCalculatorMock.connect(user1).setTokenMultipliers([1], [ethers.utils.parseEther('1.5')])).to.be.revertedWith('Ownable: caller is not the owner');
    });

    it('Can pause and unpause contract', async function() {
        const { stakingPoolsERC721Mock, tokenIdStakingRewardCalculatorMock } = await loadFixture(deployStakingPoolsMockFixture);

        await stakingPoolsERC721Mock.unpause();
        await tokenIdStakingRewardCalculatorMock.unpause();
        expect(await stakingPoolsERC721Mock.paused()).to.equal(false);
        expect(await tokenIdStakingRewardCalculatorMock.paused()).to.equal(false);

        await stakingPoolsERC721Mock.pause();
        await tokenIdStakingRewardCalculatorMock.pause();
        expect(await stakingPoolsERC721Mock.paused()).to.equal(true);
        expect(await tokenIdStakingRewardCalculatorMock.paused()).to.equal(true);
    });

    it('User can stake', async function() {
        const { erc721Mock, stakingPoolsERC721Mock, user1 } = await loadFixture(deployStakingPoolsMockFixture);

        await erc721Mock.unpause();
        await erc721Mock.connect(user1).mint(2);
        await stakingPoolsERC721Mock.unpause();

        await erc721Mock.connect(user1).setApprovalForAll(stakingPoolsERC721Mock.address, true);
        expect(await erc721Mock.balanceOf(user1.address)).to.equal(2);
        await stakingPoolsERC721Mock.connect(user1).stake(0, [1, 2]);
        expect(await erc721Mock.balanceOf(user1.address)).to.equal(0);
        expect(await stakingPoolsERC721Mock.getStakedTokenBalance(user1.address)).to.equal(2);
    });

    it('User can claim and unstake', async function() {
        const { erc721Mock, erc20Mock, stakingPoolsERC721Mock, tokenIdStakingRewardCalculatorMock, user1 } = await loadFixture(deployStakingPoolsMockFixture);

        await erc721Mock.unpause();
        await erc20Mock.unpause();
        await stakingPoolsERC721Mock.unpause();
        await tokenIdStakingRewardCalculatorMock.unpause();
        await erc20Mock.setAuthorizedMinter(stakingPoolsERC721Mock.address, true);
        await stakingPoolsERC721Mock.setStakingRewardCalculator(tokenIdStakingRewardCalculatorMock.address);
        await tokenIdStakingRewardCalculatorMock.setTokenMultipliers([1], [ethers.utils.parseEther('1.5')]);
        await erc721Mock.connect(user1).mint(2);
        await erc721Mock.connect(user1).setApprovalForAll(stakingPoolsERC721Mock.address, true);

        await stakingPoolsERC721Mock.connect(user1).stake(0, [1, 2]);
        expect(await erc721Mock.balanceOf(user1.address)).to.equal(0);

        await time.increase(86400 / 2);
        expect(await stakingPoolsERC721Mock.rewardsAvailable(user1.address)).to.equal(ethers.utils.parseEther('1.25'));
        await stakingPoolsERC721Mock.connect(user1).claimRewards();
        expect(await erc20Mock.balanceOf(user1.address)).to.greaterThanOrEqual(ethers.utils.parseEther('1.25'));

        await time.increase(86400 / 2);
        const unlockedTokenIds = await stakingPoolsERC721Mock.getUnlockedTokenIds(user1.address);
        expect(unlockedTokenIds[0]).to.equal(2);
        await stakingPoolsERC721Mock.connect(user1).unstake();
        expect(await erc721Mock.balanceOf(user1.address)).to.equal(2);
        expect(await erc20Mock.balanceOf(user1.address)).to.equal(ethers.utils.parseEther('2.5'));
    });

    it('Test getStakedTokenIds', async function() {
        const { erc721Mock, erc20Mock, stakingPoolsERC721Mock, user1 } = await loadFixture(deployStakingPoolsMockFixture);

        await erc721Mock.unpause();
        await erc20Mock.unpause();
        await stakingPoolsERC721Mock.unpause();
        await erc20Mock.setAuthorizedMinter(stakingPoolsERC721Mock.address, true);
        await erc721Mock.connect(user1).mint(5);
        await erc721Mock.connect(user1).setApprovalForAll(stakingPoolsERC721Mock.address, true);

        let lockedTokenIds = await stakingPoolsERC721Mock.getLockedTokenIds(user1.address, 0);
        expect(lockedTokenIds[0]).to.equal(0);
        await stakingPoolsERC721Mock.connect(user1).stake(0, [1, 2, 3]);
        expect(await erc721Mock.balanceOf(user1.address)).to.equal(2);

        lockedTokenIds = await stakingPoolsERC721Mock.getLockedTokenIds(user1.address, 0);
        expect(lockedTokenIds[0]).to.equal(3);
        let stakedTokenIds = await stakingPoolsERC721Mock.getStakedTokenIds(user1.address);
        expect(stakedTokenIds.map((item) => { return item.toNumber(); })).to.eql([1, 2, 3]);

        await time.increase(86400);
        const unlockedTokenIds = await stakingPoolsERC721Mock.getUnlockedTokenIds(user1.address);
        expect(unlockedTokenIds[0]).to.equal(3);
        stakedTokenIds = await stakingPoolsERC721Mock.getStakedTokenIds(user1.address);
        expect(stakedTokenIds.map((item) => { return item.toNumber(); })).to.eql([1, 2, 3]);
    });

    it('Test getLockedTokenIds/getUnlockedTokenIds', async function() {
        const { erc721Mock, erc20Mock, stakingPoolsERC721Mock, user1 } = await loadFixture(deployStakingPoolsMockFixture);

        await erc721Mock.unpause();
        await erc20Mock.unpause();
        await stakingPoolsERC721Mock.unpause();
        await erc20Mock.setAuthorizedMinter(stakingPoolsERC721Mock.address, true);
        await erc721Mock.connect(user1).mint(2);
        await erc721Mock.connect(user1).setApprovalForAll(stakingPoolsERC721Mock.address, true);

        let lockedTokenIds = await stakingPoolsERC721Mock.getLockedTokenIds(user1.address, 0);
        expect(lockedTokenIds[0]).to.equal(0);
        await stakingPoolsERC721Mock.connect(user1).stake(0, [1, 2]);
        expect(await erc721Mock.balanceOf(user1.address)).to.equal(0);

        lockedTokenIds = await stakingPoolsERC721Mock.getLockedTokenIds(user1.address, 0);
        expect(lockedTokenIds[0]).to.equal(2);
        lockedTokenIds = await stakingPoolsERC721Mock.getLockedTokenIds(user1.address, 1);
        expect(lockedTokenIds[0]).to.equal(0);

        await time.increase(86400);
        const unlockedTokenIds = await stakingPoolsERC721Mock.getUnlockedTokenIds(user1.address);
        expect(unlockedTokenIds[0]).to.equal(2);
    });
});
