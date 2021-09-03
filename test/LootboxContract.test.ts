import {expect} from './chai-setup';
import {
  createLootbox,
  addLoot,
  getLootBoxData,
  getLootData,
} from './fixtures/Lootbox.fixture';
import {setupNftGemGovernor} from './fixtures/Governance.fixture';
import {ethers} from 'ethers';

describe('Lootbox Contract test suite', () => {
  describe('Loot Box Initialization', () => {
    it('Should initialize lootbox', async () => {
      const {lootBox, LootboxFactory, NFTGemMultiToken} = await createLootbox();
      expect(await LootboxFactory.isInitialized()).to.be.true;
      expect(
        (await LootboxFactory.allLootboxesLength()).toNumber()
      ).to.be.equal(1);
      expect(lootBox.symbol).to.be.equal('TEST1');
      expect(lootBox.multitoken).to.be.equal(NFTGemMultiToken.address);
    });
    it('Should revert of lootbox already exists', async () => {
      const {LootboxFactory, lootBoxData, tokenSellerData, owner} =
        await createLootbox();
      await expect(
        LootboxFactory.createLootbox(
          owner.address,
          lootBoxData,
          tokenSellerData
        )
      ).to.be.revertedWith('Lootbox EXISTS');
    });
    it('Should revert if multitoken address is not set', async () => {
      const {lootBoxData, tokenSellerData} = await getLootBoxData();
      const {LootboxFactory, owner} = await setupNftGemGovernor();
      // Set MultiToken address to some dummy address
      lootBoxData[3] = ethers.constants.AddressZero;
      await expect(
        LootboxFactory.createLootbox(
          owner.address,
          lootBoxData,
          tokenSellerData
        )
      ).to.be.revertedWith('Multitoken address must be set');
    });
    it('Should revert if name or symbol is not set', async () => {
      const {lootBoxData, tokenSellerData} = await getLootBoxData();
      const {LootboxFactory, owner} = await setupNftGemGovernor();
      // Set name to empty string
      lootBoxData[6] = '';
      await expect(
        LootboxFactory.createLootbox(
          owner.address,
          lootBoxData,
          tokenSellerData
        )
      ).to.be.revertedWith('Name must be set');

      // Set symbol to empty string
      lootBoxData[5] = '';
      lootBoxData[6] = 'Lootbox1';
      await expect(
        LootboxFactory.createLootbox(
          owner.address,
          lootBoxData,
          tokenSellerData
        )
      ).to.be.revertedWith('Symbol must be set');
    });
    it('Should revert if min loot or max loot is not set', async () => {
      const {lootBoxData, tokenSellerData} = await getLootBoxData();
      const {LootboxFactory, owner} = await setupNftGemGovernor();
      // Set min loot to 0
      lootBoxData[8] = 0;
      await expect(
        LootboxFactory.createLootbox(
          owner.address,
          lootBoxData,
          tokenSellerData
        )
      ).to.be.revertedWith('Min loot must be set');

      // Set symbol to empty string
      lootBoxData[8] = 1;
      lootBoxData[9] = 0;
      await expect(
        LootboxFactory.createLootbox(
          owner.address,
          lootBoxData,
          tokenSellerData
        )
      ).to.be.revertedWith('Max loot must be set');
    });
    it('Should revert if multitoken address is not set in tokenseller', async () => {
      const {lootBoxData, tokenSellerData} = await getLootBoxData();
      const {LootboxFactory, owner} = await setupNftGemGovernor();
      // Set MultiToken address to some dummy address
      tokenSellerData[0] = ethers.constants.AddressZero;
      await expect(
        LootboxFactory.createLootbox(
          owner.address,
          lootBoxData,
          tokenSellerData
        )
      ).to.be.revertedWith('Multitoken address must be set');
    });
    it('Should revert if price is not set in tokenseller', async () => {
      const {lootBoxData, tokenSellerData} = await getLootBoxData();
      const {LootboxFactory, owner} = await setupNftGemGovernor();
      // Set price to 0
      tokenSellerData[4] = ethers.utils.parseEther('0');
      await expect(
        LootboxFactory.createLootbox(
          owner.address,
          lootBoxData,
          tokenSellerData
        )
      ).to.be.revertedWith('Price must be set');
    });
  });
  it('Mint Lootbox tokens', async () => {
    const {LootboxContract, NFTGemMultiToken, lootboxHash, owner} =
      await createLootbox();
    await LootboxContract.mintLootboxTokens(1000);
    expect(
      (await NFTGemMultiToken.balanceOf(owner.address, lootboxHash)).toNumber()
    ).to.be.equal(1000);
  });
  describe('Add Loot to Lootbox', () => {
    it('Should add Loot', async () => {
      const {LootboxContract} = await addLoot();
      const loot = await LootboxContract.getLoot(0);
      expect(loot.symbol).to.be.equal('SMBL');
      expect(loot.name).to.be.equal('Test Loot');
    });
    it('Should revert if symbol is not passed', async () => {
      const loot = await getLootData();
      const {LootboxContract} = await createLootbox();
      // set symbol to ''
      loot[3] = '';
      await expect(LootboxContract.addLoot(loot)).to.be.revertedWith(
        'Symbol must be set'
      );
    });
  });
  it('Mint Loot', async () => {
    const {LootboxContract} = await addLoot();
    const tx = await LootboxContract.mintLoot(0, 2);
    expect(tx).to.emit(LootboxContract, 'LootMinted');
  });
  //   it('open lootbox', async () => {
  //     const {LootboxContract, NFTGemMultiToken, lootboxHash, owner} =
  //       await addLoot();
  //     await LootboxContract.mintLootboxTokens(1000);
  //     const tx = await LootboxContract.openLootbox();
  //     expect(tx).to.emit(LootboxContract, 'LootboxOpened');
  //     expect(
  //       (await NFTGemMultiToken.balanceOf(owner.address, lootboxHash)).toNumber()
  //     ).to.be.equal(999);
  //   });
});
