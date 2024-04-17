const { expect } = require('chai');
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

describe('MintableERC721 contract test', function() {
    async function deployMintableERC721MockFixture() {
        const [owner, user1, user2, user3, user4, user5] = await ethers.getSigners();
        const MintableERC721Mock = await ethers.getContractFactory('MintableERC721Mock');
        const mintableERC721Mock = await MintableERC721Mock.deploy(100, 15);
        await mintableERC721Mock.deployed();

        return { mintableERC721Mock, owner, user1, user2, user3, user4, user5 };
    }

    it('Deployment should succeed', async function() {
        const { mintableERC721Mock } = await loadFixture(deployMintableERC721MockFixture);

        expect(await mintableERC721Mock.baseURI()).to.equal('https://example.com/');
        expect(await mintableERC721Mock.baseURIExtension()).to.equal('.json');
        expect(await mintableERC721Mock.MAX_SUPPLY()).to.equal(100);
        expect(await mintableERC721Mock.maxPerMint()).to.equal(15);
        const royaltyInfo = await mintableERC721Mock.royaltyInfo(1, 10000);
        expect(royaltyInfo[0]).to.equal('0x14c84F8aBaD55F074Ef18BEb46A7cbede6a17B10');
        expect(royaltyInfo[1]).to.equal(ethers.BigNumber.from(750));
        expect(await mintableERC721Mock.paused()).to.equal(true);
    });

    it('MintableERC721 security checks', async function() {
        const { mintableERC721Mock, user1 } = await loadFixture(deployMintableERC721MockFixture);

        await expect(
            mintableERC721Mock.connect(user1).addMintStage(1, 1, ethers.constants.HashZero),
        ).to.be.revertedWith('Ownable: caller is not the owner');
        await expect(mintableERC721Mock.connect(user1).removeMintStage(0)).to.be.revertedWith(
            'Ownable: caller is not the owner',
        );
        await expect(mintableERC721Mock.connect(user1).updateMintStagePricing(0, 1)).to.be.revertedWith(
            'Ownable: caller is not the owner',
        );
        await expect(mintableERC721Mock.connect(user1).updateMintStageMaxPerWallet(0, 1)).to.be.revertedWith(
            'Ownable: caller is not the owner',
        );
        await expect(
            mintableERC721Mock.connect(user1).updateMintStageMerkleRoot(0, ethers.constants.HashZero),
        ).to.be.revertedWith('Ownable: caller is not the owner');
        await expect(mintableERC721Mock.connect(user1).setMintActive(true)).to.be.revertedWith(
            'Ownable: caller is not the owner',
        );
        await expect(mintableERC721Mock.connect(user1).setActiveMintStage(0)).to.be.revertedWith(
            'Ownable: caller is not the owner',
        );
        await expect(mintableERC721Mock.connect(user1).setMaxPerMint(0)).to.be.revertedWith(
            'Ownable: caller is not the owner',
        );
        await expect(mintableERC721Mock.connect(user1).setMaxPerWallet(0)).to.be.revertedWith(
            'Ownable: caller is not the owner',
        );
        await expect(mintableERC721Mock.connect(user1).setPaymentToken(user1.address)).to.be.revertedWith(
            'Ownable: caller is not the owner',
        );
        await expect(mintableERC721Mock.connect(user1).withdrawAllNative()).to.be.revertedWith(
            'Ownable: caller is not the owner',
        );
        await expect(mintableERC721Mock.connect(user1).withdrawAllTokens(user1.address)).to.be.revertedWith(
            'Ownable: caller is not the owner',
        );
    });

    it('Mint fails when paused', async function() {
        const { mintableERC721Mock, user1 } = await loadFixture(deployMintableERC721MockFixture);

        await mintableERC721Mock.addMintStage(0, 1, ethers.constants.HashZero);
        await mintableERC721Mock.setMintActive(true);
        await mintableERC721Mock.setActiveMintStage(0);

        expect(await mintableERC721Mock.paused()).to.equal(true);
        await expect(mintableERC721Mock.connect(user1).mint(1, [[]])).to.be.revertedWith('Pausable: paused');
    });

    it('Mint more than one', async function() {
        const { mintableERC721Mock, user1 } = await loadFixture(deployMintableERC721MockFixture);

        await mintableERC721Mock.unpause();
        expect(await mintableERC721Mock.paused()).to.equal(false);

        await mintableERC721Mock.addMintStage(0, 5, ethers.constants.HashZero);
        await mintableERC721Mock.setMintActive(true);
        await mintableERC721Mock.setActiveMintStage(0);

        await mintableERC721Mock.connect(user1).mint(5, [[]]);
        expect(await mintableERC721Mock.balanceOf(user1.address)).to.equal(5);
    });

    it('Max supply mint total supply', async function() {
        const { mintableERC721Mock, user1 } = await loadFixture(deployMintableERC721MockFixture);

        await mintableERC721Mock.unpause();
        expect(await mintableERC721Mock.paused()).to.equal(false);

        await mintableERC721Mock.addMintStage(0, 100, ethers.constants.HashZero);
        await mintableERC721Mock.setMintActive(true);
        await mintableERC721Mock.setActiveMintStage(0);

        for (let i = 0; i < 10; i++) {
            await mintableERC721Mock.connect(user1).mint(10, [[]]);
        }
        expect(await mintableERC721Mock.balanceOf(user1.address)).to.equal(100);

        await expect(mintableERC721Mock.connect(user1).mint(1, [[]])).to.be.reverted;
    });

    it('Mint multiple stages', async function() {
        const { mintableERC721Mock, user1, user2, user3, user4, user5 } = await loadFixture(
            deployMintableERC721MockFixture,
        );

        await mintableERC721Mock.unpause();
        expect(await mintableERC721Mock.paused()).to.equal(false);

        const whitelistAddresses = [user1.address, user2.address];
        const leafNodesWL = whitelistAddresses.map((addr) => keccak256(addr));
        const merkleTreeWL = new MerkleTree(leafNodesWL, keccak256, { sortPairs: true });
        await mintableERC721Mock.addMintStage(0, 10, merkleTreeWL.getHexRoot());
        await mintableERC721Mock.setMintActive(true);
        await mintableERC721Mock.setActiveMintStage(0);

        const allowlistAddresses = [user2.address, user3.address, user4.address];
        const leafNodesAL = allowlistAddresses.map((addr) => keccak256(addr));
        const merkleTreeAL = new MerkleTree(leafNodesAL, keccak256, { sortPairs: true });
        await mintableERC721Mock.addMintStage(ethers.utils.parseEther('15'), 10, merkleTreeAL.getHexRoot());

        await mintableERC721Mock.addMintStage(ethers.utils.parseEther('25'), 10, ethers.constants.HashZero);

        // Allowed users can mint WL
        await mintableERC721Mock.connect(user1).mint(10, [merkleTreeWL.getHexProof(keccak256(user1.address))]);
        await mintableERC721Mock.connect(user2).mint(5, [merkleTreeWL.getHexProof(keccak256(user2.address))]);
        expect(await mintableERC721Mock.balanceOf(user1.address)).to.equal(10);
        expect(await mintableERC721Mock.balanceOf(user2.address)).to.equal(5);

        // Disallowed user cannot mint WL
        await expect(mintableERC721Mock.connect(user3).mint(10, [merkleTreeWL.getHexProof(keccak256(user3.address))]))
            .to.be.reverted;
        await expect(mintableERC721Mock.connect(user3).mint(10, [merkleTreeWL.getHexProof(keccak256(user2.address))]))
            .to.be.reverted;

        // Authorized user cannot mint on inactive mint stage
        await expect(mintableERC721Mock.connect(user2).mint(10, [merkleTreeAL.getHexProof(keccak256(user2.address))]))
            .to.be.reverted;

        // Allowed users can mint AL
        await mintableERC721Mock.setActiveMintStage(1);
        await mintableERC721Mock
            .connect(user2)
            .mint(
                15,
                [
                    merkleTreeWL.getHexProof(keccak256(user2.address)),
                    merkleTreeAL.getHexProof(keccak256(user2.address)),
                ],
                { value: ethers.utils.parseEther('225') },
            );
        await mintableERC721Mock
            .connect(user3)
            .mint(10, [[], merkleTreeAL.getHexProof(keccak256(user3.address))], {
                value: ethers.utils.parseEther('150'),
            });
        await mintableERC721Mock
            .connect(user4)
            .mint(10, [[], merkleTreeAL.getHexProof(keccak256(user4.address))], {
                value: ethers.utils.parseEther('150'),
            });
        expect(await mintableERC721Mock.balanceOf(user2.address)).to.equal(20);
        expect(await mintableERC721Mock.balanceOf(user3.address)).to.equal(10);
        expect(await mintableERC721Mock.balanceOf(user4.address)).to.equal(10);

        // Disallowed user cannot mint WL
        await expect(
            mintableERC721Mock.connect(user1).mint(10, [[], merkleTreeAL.getHexProof(keccak256(user1.address))]),
        ).to.be.reverted;

        // Users can mint public
        await mintableERC721Mock.setActiveMintStage(2);
        await mintableERC721Mock
            .connect(user1)
            .mint(10, [merkleTreeWL.getHexProof(keccak256(user1.address)), [], []], {
                value: ethers.utils.parseEther('250'),
            });
        await mintableERC721Mock
            .connect(user2)
            .mint(
                10,
                [
                    merkleTreeWL.getHexProof(keccak256(user2.address)),
                    merkleTreeAL.getHexProof(keccak256(user2.address)),
                    [],
                ],
                {
                    value: ethers.utils.parseEther('250'),
                },
            );
        await mintableERC721Mock
            .connect(user3)
            .mint(10, [[], merkleTreeAL.getHexProof(keccak256(user3.address)), []], {
                value: ethers.utils.parseEther('250'),
            });
        await mintableERC721Mock
            .connect(user4)
            .mint(10, [[], merkleTreeAL.getHexProof(keccak256(user4.address)), []], {
                value: ethers.utils.parseEther('250'),
            });
        await mintableERC721Mock.connect(user5).mint(10, [[], [], []], { value: ethers.utils.parseEther('250') });
        expect(await mintableERC721Mock.balanceOf(user1.address)).to.equal(20);
        expect(await mintableERC721Mock.balanceOf(user2.address)).to.equal(30);
        expect(await mintableERC721Mock.balanceOf(user3.address)).to.equal(20);
        expect(await mintableERC721Mock.balanceOf(user4.address)).to.equal(20);
        expect(await mintableERC721Mock.balanceOf(user5.address)).to.equal(10);

        expect(await mintableERC721Mock.totalSupply()).to.equal(100);
        await expect(mintableERC721Mock.connect(user1).mint(1, [[], [], []]), { value: ethers.utils.parseEther('250') })
            .to.be.reverted;
    });
});
