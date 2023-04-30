const { expect } = require('chai');
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');

describe('BaseERC721 contract test', function() {
    async function deployERC721MockFixture() {
        const [owner, user1] = await ethers.getSigners();
        const ERC721Mock = await ethers.getContractFactory('ERC721Mock');
        const erc721Mock = await ERC721Mock.deploy(0);
        await erc721Mock.deployed();

        return { ERC721Mock, erc721Mock, owner, user1 };
    }

    async function deployMaxSupplyERC721MockFixture() {
        const [owner, user1] = await ethers.getSigners();
        const ERC721Mock = await ethers.getContractFactory('ERC721Mock');
        const erc721Mock = await ERC721Mock.deploy(3333);
        await erc721Mock.deployed();

        return { ERC721Mock, erc721Mock, owner, user1 };
    }

    it('Deployment should succeed', async function() {
        const { erc721Mock } = await loadFixture(deployERC721MockFixture);

        expect(await erc721Mock.baseURI()).to.equal('https://example.com/');
        expect(await erc721Mock.baseURIExtension()).to.equal('.json');
        expect(await erc721Mock.MAX_SUPPLY()).to.equal(0);
        const royaltyInfo = await erc721Mock.royaltyInfo(1, 10000);
        expect(royaltyInfo[0]).to.equal('0x14c84F8aBaD55F074Ef18BEb46A7cbede6a17B10');
        expect(royaltyInfo[1]).to.equal(ethers.BigNumber.from(750));
        expect(await erc721Mock.paused()).to.equal(true);
    });

    it('Deployment with max supply should succeed', async function() {
        const { erc721Mock } = await loadFixture(deployMaxSupplyERC721MockFixture);

        expect(await erc721Mock.MAX_SUPPLY()).to.equal(3333);
    });

    it('BaseERC721 security checks', async function() {
        const { erc721Mock, user1 } = await loadFixture(deployERC721MockFixture);

        await expect(erc721Mock.connect(user1).unpause()).to.be.revertedWith('Ownable: caller is not the owner');
        await expect(erc721Mock.connect(user1).pause()).to.be.revertedWith('Ownable: caller is not the owner');
        await expect(erc721Mock.connect(user1).setBaseURI('test1', 'test2')).to.be.revertedWith('Ownable: caller is not the owner');
        await expect(erc721Mock.connect(user1).setDefaultRoyalty(user1.address, 750)).to.be.revertedWith('Ownable: caller is not the owner');
        await expect(erc721Mock.connect(user1).deleteDefaultRoyalty()).to.be.revertedWith('Ownable: caller is not the owner');
        await expect(erc721Mock.connect(user1).setTokenRoyalty(1, user1.address, 750)).to.be.revertedWith('Ownable: caller is not the owner');
        await expect(erc721Mock.connect(user1).resetTokenRoyalty(1)).to.be.revertedWith('Ownable: caller is not the owner');
    });

    it('Can pause and unpause contract', async function() {
        const { erc721Mock } = await loadFixture(deployERC721MockFixture);

        await erc721Mock.unpause();
        expect(await erc721Mock.paused()).to.equal(false);

        await erc721Mock.pause();
        expect(await erc721Mock.paused()).to.equal(true);
    });

    it('Mint fails when paused', async function() {
        const { erc721Mock, user1 } = await loadFixture(deployERC721MockFixture);

        expect(await erc721Mock.paused()).to.equal(true);
        await expect(erc721Mock.connect(user1).mint(1)).to.be.revertedWith('Pausable: paused');
    });

    it('Unlimited mint more than one', async function() {
        const { erc721Mock, user1 } = await loadFixture(deployERC721MockFixture);

        await erc721Mock.unpause();
        expect(await erc721Mock.paused()).to.equal(false);
        await erc721Mock.connect(user1).mint(5);
        expect(await erc721Mock.balanceOf(user1.address)).to.equal(5);
    });

    it('Max supply mint more than one', async function() {
        const { erc721Mock, user1 } = await loadFixture(deployMaxSupplyERC721MockFixture);

        await erc721Mock.unpause();
        expect(await erc721Mock.paused()).to.equal(false);
        await erc721Mock.connect(user1).mint(5);
        expect(await erc721Mock.balanceOf(user1.address)).to.equal(5);
    });

    it('Max supply mint total supply', async function() {
        const { erc721Mock, user1 } = await loadFixture(deployMaxSupplyERC721MockFixture);

        await erc721Mock.unpause();
        expect(await erc721Mock.paused()).to.equal(false);

        for (let i = 0; i < 101; i++) {
            await erc721Mock.connect(user1).mint(33);
        }
        expect(await erc721Mock.balanceOf(user1.address)).to.equal(3333);

        await expect(erc721Mock.connect(user1).mint(1)).to.be.reverted;
    });

    it('Correct tokenURI', async function() {
        const { erc721Mock, user1 } = await loadFixture(deployERC721MockFixture);

        await erc721Mock.unpause();
        expect(await erc721Mock.paused()).to.equal(false);

        await erc721Mock.connect(user1).mint(5);
        expect(await erc721Mock.balanceOf(user1.address)).to.equal(5);

        for (let i = 1; i <= 5; i++) {
            expect(await erc721Mock.tokenURI(i)).to.equal(`https://example.com/${i}.json`);
        }
        await expect(erc721Mock.tokenURI(0)).to.be.reverted;

        await erc721Mock.setBaseURI('https://example2.com/', '');
        expect(await erc721Mock.baseURI()).to.equal('https://example2.com/');
        expect(await erc721Mock.baseURIExtension()).to.equal('');
        expect(await erc721Mock.tokenURI(1)).to.equal('https://example2.com/1');
    });
});
