import {expect} from './chai-setup';
import {ethers, deployments} from 'hardhat';
import {SignerWithAddress} from 'hardhat-deploy-ethers/dist/src/signer-with-address';
import {Contract} from '@ethersproject/contracts';
import {createERC20Token} from './fixtures/ERC20Token.fixture';

const {utils} = ethers;

describe('NFTGemFeeManager contract', function () {
  let owner: SignerWithAddress;
  let sender: SignerWithAddress;
  let tokenAddress: SignerWithAddress;
  let payableAddress: SignerWithAddress;
  let NFTGemFeeManager: Contract;

  beforeEach(async () => {
    await deployments.fixture();
    [owner, sender, tokenAddress, payableAddress] = await ethers.getSigners();
    const NFTGemFeeManagerFactory = await ethers.getContractFactory(
      'NFTGemFeeManager',
      owner
    );
    NFTGemFeeManager = await NFTGemFeeManagerFactory.deploy();
    await NFTGemFeeManager.deployed();
    NFTGemFeeManager.setOperator(owner.address);
  });

  it('Should initialize NFTGemFeeManager contract ', async function () {
    const defaultFeeDivisor = await NFTGemFeeManager.defaultFeeDivisor();
    const defaultLiquidity = await NFTGemFeeManager.defaultLiquidity();
    expect(defaultFeeDivisor).to.equal(1000);
    expect(defaultLiquidity).to.equal(100);
  });
  describe('Default Liquidity', function () {
    it('Should set default liquidity', async function () {
      await NFTGemFeeManager.setDefaultLiquidity(99);
      const defaultLiquidity = await NFTGemFeeManager.defaultLiquidity();
      expect(defaultLiquidity).to.equal(99);
    });

    it('Should revert if invalid liquidity passed', async function () {
      await expect(NFTGemFeeManager.setDefaultLiquidity(0)).to.be.revertedWith(
        'INVALID'
      );
    });

    it('Should return liquidity', async function () {
      expect(
        (await NFTGemFeeManager.liquidity(tokenAddress.address)).toNumber()
      ).to.equal(100);
    });
  });

  describe('Default Fee Divisor', function () {
    it('Should set default fee divisor', async function () {
      await NFTGemFeeManager.setDefaultFeeDivisor(90);
      const defaultLiquidity = await NFTGemFeeManager.defaultFeeDivisor();
      expect(defaultLiquidity).to.equal(90);
    });

    it('Should revert if invalid liquidity passed', async function () {
      await expect(NFTGemFeeManager.setDefaultFeeDivisor(0)).to.be.revertedWith(
        'DIVISIONBYZERO'
      );
    });

    it('Should return fee divisor', async function () {
        expect(
          (await NFTGemFeeManager.feeDivisor(tokenAddress.address)).toNumber()
        ).to.equal(1000);
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

    it('Should revert if invalid liquidity passed', async function () {
      await expect(
        NFTGemFeeManager.setFeeDivisor(tokenAddress.address, 0)
      ).to.be.revertedWith('DIVISIONBYZERO');
    });
  });

  describe('Transfer', function () {
    it('Should return ETH balance of contract', async function () {
      await sender.sendTransaction({
        to: NFTGemFeeManager.address,
        value: utils.parseEther('10'),
      });
      expect(utils.formatEther(await NFTGemFeeManager.ethBalanceOf())).to.equal(
        '10.0'
      );
    });
    it('Should transfer ETH', async function () {
      // Transfer some amount to contract
      await sender.sendTransaction({
        to: NFTGemFeeManager.address,
        value: utils.parseEther('10'),
      });

      await NFTGemFeeManager.transferEth(
        payableAddress.address,
        utils.parseEther('1')
      );

      expect(utils.formatEther(await NFTGemFeeManager.ethBalanceOf())).to.equal(
        '9.0'
      );
    });
    it('Should revert Transfer ETH if there is not sufficient balance', async function () {
      await expect(
        NFTGemFeeManager.transferEth(
          payableAddress.address,
          utils.parseEther('1')
        )
      ).to.be.revertedWith('INSUFFICIENT_BALANCE');
    });
    it('Should transfer token', async function () {
      const {ERC20Token} = await createERC20Token({owner});
      // First send some tokens to contract
      await ERC20Token.transfer(NFTGemFeeManager.address, 100);

      expect(
        (await ERC20Token.balanceOf(NFTGemFeeManager.address)).toString()
      ).to.equal('100');

      await NFTGemFeeManager.transferToken(
        ERC20Token.address,
        sender.address,
        10
      );
      expect(
        (await NFTGemFeeManager.balanceOF(ERC20Token.address)).toString()
      ).to.equal('90');
      expect((await ERC20Token.balanceOf(sender.address)).toString()).to.equal(
        '10'
      );
    });
    it('Should revert if there is not enough balance', async function () {
      const {ERC20Token} = await createERC20Token({owner});
      await ERC20Token.transfer(NFTGemFeeManager.address, 10);
      await expect(
        NFTGemFeeManager.transferToken(ERC20Token.address, sender.address, 100)
      ).to.be.revertedWith('INSUFFICIENT_BALANCE');
    });
    it('should return the token balance', async function () {
      const {ERC20Token} = await createERC20Token({owner});
      await ERC20Token.transfer(NFTGemFeeManager.address, 10);
      expect(
        (await NFTGemFeeManager.balanceOF(ERC20Token.address)).toString()
      ).to.equal('10');
    });
  });
});
