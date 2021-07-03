import {expect} from './chai-setup';
import {ethers, deployments} from 'hardhat';
import {Contract} from 'ethers';

const {utils} = ethers;

describe('NFTGemPoolFactory contract', function () {
  const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
  let NFTGemPoolFactory: Contract;

  beforeEach(async () => {
    await deployments.fixture();
    NFTGemPoolFactory = await (
      await ethers.getContractFactory('NFTGemPoolFactory')
    ).deploy();
  });

  it('Should create a new nft gem pool', async function () {
    await expect(
      NFTGemPoolFactory.createNFTGemPool(
        'TST',
        'Test Gem',
        utils.parseEther('1'),
        86400,
        864000,
        1000,
        0,
        ZERO_ADDRESS
      )
    )
      .to.emit(NFTGemPoolFactory, 'NFTGemPoolCreated')
      .withArgs(
        'TST',
        'Test Gem',
        utils.parseEther('1'),
        86400,
        864000,
        1000,
        0,
        ZERO_ADDRESS
      );
  });
  it('Revert if Gempool already exists', async function () {
    await expect(
      NFTGemPoolFactory.createNFTGemPool(
        'TST',
        'Test Gem',
        utils.parseEther('1'),
        86400,
        864000,
        1000,
        0,
        ZERO_ADDRESS
      )
    );
    await expect(
      NFTGemPoolFactory.createNFTGemPool(
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
    await expect(
      NFTGemPoolFactory.createNFTGemPool(
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
    await expect(
      NFTGemPoolFactory.createNFTGemPool(
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
    await expect(
      NFTGemPoolFactory.createNFTGemPool(
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
