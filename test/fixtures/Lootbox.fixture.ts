import {deployments} from 'hardhat';
import {BigNumber} from 'ethers';
import {setupNftGemGovernor} from './Governance.fixture';

export const getLootBoxData = deployments.createFixture(async ({ethers}) => {
  const {RandomFarmer, NFTGemMultiToken, owner} = await setupNftGemGovernor();
  const lootBoxData = [
    owner.address,
    owner.address,
    RandomFarmer.address,
    NFTGemMultiToken.address,
    BigNumber.from(0),
    'TEST1',
    'Test Lootbox',
    'Test Lootbox',
    1,
    1,
    ethers.utils.parseEther('0.1'),
    BigNumber.from('100'),
    ethers.utils.parseEther('0'),
    ethers.utils.parseEther('0'),
    ethers.utils.parseEther('0.1'),
    ethers.utils.parseEther('0'),
    true,
    ethers.utils.parseEther('0'),
    ethers.utils.parseEther('0'),
  ];
  const tokenSellerData = [
    NFTGemMultiToken.address,
    ethers.constants.AddressZero,
    owner.address,
    ethers.utils.parseEther('0'),
    ethers.utils.parseEther('1'),
    0,
    ethers.utils.parseEther('0'),
    ethers.utils.parseEther('0'),
    ethers.utils.parseEther('0'),
    ethers.utils.parseEther('0'),
    ethers.utils.parseEther('0'),
    ethers.utils.parseEther('0'),
    true,
    true,
    ethers.utils.parseEther('0'),
  ];
  return {
    lootBoxData,
    tokenSellerData,
  };
});

export const getLootData = deployments.createFixture(async ({ethers}) => {
  const {NFTGemMultiToken, owner} = await setupNftGemGovernor();
  const loot = [
    BigNumber.from(0),
    owner.address,
    NFTGemMultiToken.address,
    'SMBL',
    'Test Loot',
    ethers.constants.MaxUint256.div(4).sub(1),
    BigNumber.from(0),
    BigNumber.from(0),
    BigNumber.from(0),
    BigNumber.from(0),
  ];
  return loot;
});

export const createLootbox = deployments.createFixture(async ({ethers}) => {
  const {LootboxFactory, LootboxData, NFTGemMultiToken, owner, sender} =
    await setupNftGemGovernor();

  const {lootBoxData, tokenSellerData} = await getLootBoxData();

  await LootboxFactory.createLootbox(
    owner.address,
    lootBoxData,
    tokenSellerData
  );
  const lootboxHash = ethers.utils.keccak256(
    ethers.utils.solidityPack(['string'], ['TEST1'])
  );
  const lootBox = await LootboxFactory.getLootbox(lootboxHash);
  const LootboxContract = await ethers.getContractAt(
    'LootboxContract',
    lootBox.contractAddress,
    owner
  );
  await NFTGemMultiToken.addController(LootboxContract.address);
  return {
    LootboxContract,
    LootboxFactory,
    LootboxData,
    NFTGemMultiToken,
    lootBox,
    lootboxHash,
    lootBoxData,
    tokenSellerData,
    owner,
    sender,
  };
});

export const addLoot = deployments.createFixture(async ({ethers}) => {
  const {LootboxContract, NFTGemMultiToken, owner, lootboxHash} =
    await createLootbox();
  const loot = [
    BigNumber.from(0),
    owner.address,
    NFTGemMultiToken.address,
    'SMBL',
    'Test Loot',
    ethers.constants.MaxUint256.div(4).sub(1),
    BigNumber.from(0),
    BigNumber.from(0),
    BigNumber.from(0),
    BigNumber.from(0),
  ];
  await LootboxContract.addLoot(loot);
  return {
    LootboxContract,
    NFTGemMultiToken,
    lootboxHash,
    owner,
  };
});
