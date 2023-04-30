const { expect } = require('chai');
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');

describe('BaseERC721 airdrop contract test', function() {
    async function deployAirDropERC721MockFixture() {
        const [owner, user1] = await ethers.getSigners();
        const AirDropERC721Mock = await ethers.getContractFactory('AirDropERC721Mock');
        const airDropERC721Mock = await AirDropERC721Mock.deploy();
        await airDropERC721Mock.deployed();

        return { AirDropERC721Mock, airDropERC721Mock, owner, user1 };
    }

    it('BaseERC721 airdrop security checks', async function() {
        const { airDropERC721Mock, user1 } = await loadFixture(deployAirDropERC721MockFixture);

        await airDropERC721Mock.unpause();
        expect(await airDropERC721Mock.paused()).to.equal(false);

        await expect(airDropERC721Mock.connect(user1).airdrop([user1.address], [1])).to.be.revertedWith('Ownable: caller is not the owner');
    });

    it('Can airdrop total supply', async function() {
        const { airDropERC721Mock, user1 } = await loadFixture(deployAirDropERC721MockFixture);

        await airDropERC721Mock.unpause();
        expect(await airDropERC721Mock.paused()).to.equal(false);

        for (let i = 0; i < 101; i++) {
            await airDropERC721Mock.airdrop([user1.address], [33]);
        }
        expect(await airDropERC721Mock.balanceOf(user1.address)).to.equal(3333);

        await expect(airDropERC721Mock.airdrop([user1.address], [1])).to.be.reverted;
    });
});
