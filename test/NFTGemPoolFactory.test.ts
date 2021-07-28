import {expect} from './chai-setup';
import {ethers} from 'hardhat';
import {setupNftGemGovernor} from './fixtures/Governance.fixture';
import {pack, keccak256} from '@ethersproject/solidity';

const {utils} = ethers;

describe('NFTGemPoolFactory contract', function () {
  const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

  it('Should create a new nft gem pool', async function () {
    const {NFTGemPoolFactory, owner} = await setupNftGemGovernor();
    await NFTGemPoolFactory.createNFTGemPool(
      owner.address,
      'TST',
      'Test Gem',
      utils.parseEther('1'),
      86400,
      864000,
      1000,
      0,
      ZERO_ADDRESS
    );
    const totalPools = (
      await NFTGemPoolFactory.allNFTGemPoolsLength()
    ).toNumber();
    const poolHash = keccak256(['bytes'], [pack(['string'], ['TST'])]);
    expect(totalPools).to.be.equal(1);
    expect(await NFTGemPoolFactory.getNFTGemPool(poolHash)).to.be.equal(
      await NFTGemPoolFactory.allNFTGemPools(totalPools - 1)
    );
  });
  it('Revert if Gempool already exists', async function () {
    const {NFTGemPoolFactory, owner} = await setupNftGemGovernor();
    await NFTGemPoolFactory.createNFTGemPool(
      owner.address,
      'TST',
      'Test Gem',
      utils.parseEther('1'),
      86400,
      864000,
      1000,
      0,
      ZERO_ADDRESS
    );
    await expect(
      NFTGemPoolFactory.createNFTGemPool(
        owner.address,
        'TST',
        'Test Gem',
        utils.parseEther('1'),
        86400,
        864000,
        1000,
        0,
        ZERO_ADDRESS
      )
    ).to.be.revertedWith('GEMPOOL_EXISTS');
  });
  it('Revert if ETH price is zero', async function () {
    const {NFTGemPoolFactory, owner} = await setupNftGemGovernor();
    await expect(
      NFTGemPoolFactory.createNFTGemPool(
        owner.address,
        'TST',
        'Test Gem',
        utils.parseEther('0'),
        86400,
        864000,
        1000,
        0,
        ZERO_ADDRESS
      )
    ).to.be.revertedWith('INVALID_PRICE');
  });
  it('Revert if minTime is zero', async function () {
    const {NFTGemPoolFactory, owner} = await setupNftGemGovernor();
    await expect(
      NFTGemPoolFactory.createNFTGemPool(
        owner.address,
        'TST',
        'Test Gem',
        utils.parseEther('1'),
        0,
        864000,
        1000,
        0,
        ZERO_ADDRESS
      )
    ).to.be.revertedWith('INVALID_MIN_TIME');
  });
  it('Revert if diffstep is zero', async function () {
    const {NFTGemPoolFactory, owner} = await setupNftGemGovernor();
    await expect(
      NFTGemPoolFactory.createNFTGemPool(
        owner.address,
        'TST',
        'Test Gem',
        utils.parseEther('1'),
        86400,
        1000,
        0,
        0,
        ZERO_ADDRESS
      )
    ).to.be.revertedWith('INVALID_DIFFICULTY_STEP');
  });
});
