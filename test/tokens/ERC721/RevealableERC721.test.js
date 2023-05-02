const { expect } = require('chai');
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');

describe('BaseERC721 revealable contract test', function() {
    async function deployRevealableERC721MockFixture() {
        const [owner, user1] = await ethers.getSigners();
        const RevealableERC721Mock = await ethers.getContractFactory('RevealableERC721Mock');
        const revealableERC721Mock = await RevealableERC721Mock.deploy();
        await revealableERC721Mock.deployed();

        return { RevealableERC721Mock, revealableERC721Mock, owner, user1 };
    }

    it('Deployment should succeed', async function() {
        const { revealableERC721Mock } = await loadFixture(deployRevealableERC721MockFixture);

        expect(await revealableERC721Mock.prerevealURI()).to.equal('https://prereveal.example.com/prereveal.json');
        expect(await revealableERC721Mock.revealed()).to.equal(false);
    });

    it('BaseERC721 revealable security checks', async function() {
        const { revealableERC721Mock, user1 } = await loadFixture(deployRevealableERC721MockFixture);

        await expect(revealableERC721Mock.connect(user1).setPrerevealURI('test')).to.be.revertedWith(
            'Ownable: caller is not the owner',
        );
        await expect(revealableERC721Mock.connect(user1).toggleReveal()).to.be.revertedWith(
            'Ownable: caller is not the owner',
        );
    });

    it('tokenURI returns prereveal URI', async function() {
        const { revealableERC721Mock } = await loadFixture(deployRevealableERC721MockFixture);

        expect(await revealableERC721Mock.revealed()).to.equal(false);
        expect(await revealableERC721Mock.tokenURI(1)).to.equal('https://prereveal.example.com/prereveal.json');

        await revealableERC721Mock.setPrerevealURI('https://prereveal.example2.com/prereveal.json');
        expect(await revealableERC721Mock.tokenURI(1)).to.equal('https://prereveal.example2.com/prereveal.json');
    });

    it('tokenURI returns URI for token when revealed', async function() {
        const { revealableERC721Mock, user1 } = await loadFixture(deployRevealableERC721MockFixture);

        await revealableERC721Mock.toggleReveal();
        expect(await revealableERC721Mock.revealed()).to.equal(true);
        await expect(revealableERC721Mock.tokenURI(1)).to.be.reverted;

        await revealableERC721Mock.unpause();
        expect(await revealableERC721Mock.paused()).to.equal(false);
        await revealableERC721Mock.connect(user1).mint(1);
        expect(await revealableERC721Mock.tokenURI(1)).to.equal('https://example.com/1.json');
    });
});
