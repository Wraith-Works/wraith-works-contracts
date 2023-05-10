const { expect } = require('chai');
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');

describe('BaseERC721 airdrop contract test', function() {
    async function deployAirdropERC721MockFixture() {
        const [owner, user1] = await ethers.getSigners();
        const AirdropERC721Mock = await ethers.getContractFactory('AirdropERC721Mock');
        const airdropERC721Mock = await AirdropERC721Mock.deploy();
        await airdropERC721Mock.deployed();

        return { AirdropERC721Mock, airdropERC721Mock, owner, user1 };
    }

    it('BaseERC721 airdrop security checks', async function() {
        const { airdropERC721Mock, user1 } = await loadFixture(deployAirdropERC721MockFixture);

        await airdropERC721Mock.unpause();
        expect(await airdropERC721Mock.paused()).to.equal(false);

        await expect(airdropERC721Mock.connect(user1).airdrop([user1.address], [1])).to.be.revertedWith(
            'Ownable: caller is not the owner',
        );
    });

    it('Can airdrop total supply', async function() {
        const { airdropERC721Mock, user1 } = await loadFixture(deployAirdropERC721MockFixture);

        await airdropERC721Mock.unpause();
        expect(await airdropERC721Mock.paused()).to.equal(false);

        for (let i = 0; i < 101; i++) {
            await airdropERC721Mock.airdrop([user1.address], [33]);
        }
        expect(await airdropERC721Mock.balanceOf(user1.address)).to.equal(3333);

        await expect(airdropERC721Mock.airdrop([user1.address], [1])).to.be.reverted;
    });
});
