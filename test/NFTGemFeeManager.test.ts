import {expect} from './chai-setup';
import {ethers, deployments} from 'hardhat';
import {SignerWithAddress} from 'hardhat-deploy-ethers/dist/src/signer-with-address';
import {Contract} from '@ethersproject/contracts';

const {utils} = ethers;

describe('NFTGemFeeManager contract', function () {
  let operator: SignerWithAddress;
  let address1: SignerWithAddress;
  let tokenAddress: SignerWithAddress;
  let payableAddress: SignerWithAddress;
  let NFTGemFeeManager: Contract;
  let NFTGemFeeManagerTest: Contract;

  beforeEach(async () => {
    await deployments.fixture();
    [
      operator,
      address1,
      tokenAddress,
      payableAddress,
    ] = await ethers.getSigners();
    // Make a fresh deployment so we will have access to operator address
    const NFTGemFeeManagerFactory = await ethers.getContractFactory(
      'NFTGemFeeManager'
    );
    NFTGemFeeManager = await NFTGemFeeManagerFactory.deploy();
    await NFTGemFeeManager.deployed();
    NFTGemFeeManager.setOperator(operator.address);
    // Get instance of NFTGemFeeManager using any other address
    NFTGemFeeManagerTest = NFTGemFeeManager.connect(
      await ethers.getSigner(address1.address)
    );
  });

  it('Should initialize NFTGemFeeManager contract ', async function () {
    const defaultFeeDivisor = await NFTGemFeeManager.defaultFeeDivisor();
    const defaultLiquidity = await NFTGemFeeManager.defaultLiquidity();
    expect(defaultFeeDivisor).to.equal(1000);
    expect(defaultLiquidity).to.equal(100);
  });

  it('Should not allow to set operator', async function () {
    await expect(
      NFTGemFeeManager.setOperator(operator.address)
    ).to.be.revertedWith('IMMUTABLE');
    await expect(
      NFTGemFeeManagerTest.setOperator(operator.address)
    ).to.be.revertedWith('IMMUTABLE');
  });

  describe('Default Liquidity', function () {
    it('Should set default liquidity', async function () {
      await NFTGemFeeManager.setDefaultLiquidity(99);
      const defaultLiquidity = await NFTGemFeeManager.defaultLiquidity();
      expect(defaultLiquidity).to.equal(99);
    });
    it('Should revert if called by anyone other than owner', async function () {
      await expect(
        NFTGemFeeManagerTest.setDefaultLiquidity(99)
      ).to.be.revertedWith('UNAUTHORIZED');
    });

    it('Should revert if invalid liquidity passed', async function () {
      await expect(NFTGemFeeManager.setDefaultLiquidity(0)).to.be.revertedWith(
        'INVALID'
      );
    });
  });

  describe('Default Fee Divisor', function () {
    it('Should set default fee divisor', async function () {
      await NFTGemFeeManager.setDefaultFeeDivisor(90);
      const defaultLiquidity = await NFTGemFeeManager.defaultFeeDivisor();
      expect(defaultLiquidity).to.equal(90);
    });

    it('Should revert if called by anyone other than owner', async function () {
      await expect(
        NFTGemFeeManagerTest.setDefaultFeeDivisor(99)
      ).to.be.revertedWith('UNAUTHORIZED');
    });

    it('Should revert if invalid liquidity passed', async function () {
      await expect(NFTGemFeeManager.setDefaultFeeDivisor(0)).to.be.revertedWith(
        'DIVISIONBYZERO'
      );
    });
  });

  describe('Fee Divisor for a token', function () {
    it('Should set Fee Divisior for given token', async function () {
      await NFTGemFeeManager.setFeeDivisor(tokenAddress.address, 102);
      const feeDivisor = await NFTGemFeeManager.feeDivisor(
        tokenAddress.address
      );
      expect(feeDivisor).to.equal(102);
    });

    it('Should revert if called by anyone other than owner', async function () {
      await expect(
        NFTGemFeeManagerTest.setFeeDivisor(tokenAddress.address, 99)
      ).to.be.revertedWith('UNAUTHORIZED');
    });

    it('Should revert if invalid liquidity passed', async function () {
      await expect(
        NFTGemFeeManager.setFeeDivisor(tokenAddress.address, 0)
      ).to.be.revertedWith('DIVISIONBYZERO');
    });
  });

  describe('Transfer', function () {
    it('Should Transfer ETH', async function () {
      // Transfer some amount to contract
      await operator.sendTransaction({
        to: NFTGemFeeManager.address,
        value: utils.parseEther('10'),
      });

      await NFTGemFeeManager.transferEth(
        payableAddress.address,
        utils.parseEther('1')
      );
      const afterEthAmount = utils.formatEther(
        await NFTGemFeeManager.ethBalanceOf()
      );
      expect(parseInt(afterEthAmount)).to.be.equal(9);
    });

    it('Should revert Transfer ETH if unauthorized', async function () {
      await expect(
        NFTGemFeeManagerTest.transferEth(
          payableAddress.address,
          utils.parseEther('1')
        )
      ).to.be.revertedWith('UNAUTHORIZED');
    });

    it('Should revert Transfer ETH if there is not sufficient balance', async function () {
      await expect(
        NFTGemFeeManager.transferEth(
          payableAddress.address,
          utils.parseEther('1')
        )
      ).to.be.revertedWith('INSUFFICIENT_BALANCE');
    });
  });
});
