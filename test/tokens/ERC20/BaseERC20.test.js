const { expect } = require('chai');
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');

describe('BaseERC20 contract test', function() {
    async function deployERC20MockFixture() {
        const [owner, user1] = await ethers.getSigners();
        const ERC20Mock = await ethers.getContractFactory('ERC20Mock');
        const erc20Mock = await ERC20Mock.deploy();
        await erc20Mock.deployed();

        return { ERC20Mock, erc20Mock, owner, user1 };
    }

    it('Deployment should succeed', async function() {
        const { erc20Mock } = await loadFixture(deployERC20MockFixture);

        expect(await erc20Mock.paused()).to.equal(true);
    });

    it('BaseERC20 security checks', async function() {
        const { erc20Mock, user1 } = await loadFixture(deployERC20MockFixture);

        await expect(erc20Mock.connect(user1).unpause()).to.be.revertedWith('Ownable: caller is not the owner');
        await expect(erc20Mock.connect(user1).pause()).to.be.revertedWith('Ownable: caller is not the owner');
        await expect(erc20Mock.connect(user1).setAuthorizedMinter(user1.address, true)).to.be.revertedWith('Ownable: caller is not the owner');

        await erc20Mock.unpause();
        await expect(erc20Mock.connect(user1).authorizedMint(user1.address, ethers.utils.parseEther('1'))).to.be.reverted;
    });

    it('Can pause and unpause contract', async function() {
        const { erc20Mock } = await loadFixture(deployERC20MockFixture);

        await erc20Mock.unpause();
        expect(await erc20Mock.paused()).to.equal(false);

        await erc20Mock.pause();
        expect(await erc20Mock.paused()).to.equal(true);
    });

    it('Can add/remove authorized minter', async function() {
        const { erc20Mock, user1 } = await loadFixture(deployERC20MockFixture);

        expect(await erc20Mock.authorizedMinters(user1.address)).to.equal(false);
        await erc20Mock.setAuthorizedMinter(user1.address, true);
        expect(await erc20Mock.authorizedMinters(user1.address)).to.equal(true);
        await erc20Mock.setAuthorizedMinter(user1.address, false);
        expect(await erc20Mock.authorizedMinters(user1.address)).to.equal(false);
    });

    it('Authorized minter can mint', async function() {
        const { erc20Mock, user1 } = await loadFixture(deployERC20MockFixture);

        await erc20Mock.unpause();

        expect(await erc20Mock.balanceOf(user1.address)).to.equal(0);
        await erc20Mock.authorizedMint(user1.address, ethers.utils.parseEther('1'));
        expect(await erc20Mock.balanceOf(user1.address)).to.equal(ethers.utils.parseEther('1'));

        await erc20Mock.setAuthorizedMinter(user1.address, true);
        await erc20Mock.connect(user1).authorizedMint(user1.address, ethers.utils.parseEther('1'));
        expect(await erc20Mock.balanceOf(user1.address)).to.equal(ethers.utils.parseEther('2'));
    });
});
