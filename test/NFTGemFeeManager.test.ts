import {expect} from './chai-setup';
import {ethers, deployments} from 'hardhat';
import {SignerWithAddress} from 'hardhat-deploy-ethers/dist/src/signers';
import {Contract} from '@ethersproject/contracts';
import {createERC20Token} from './fixtures/ERC20Token.fixture';
import {pack, keccak256} from '@ethersproject/solidity';

const {utils} = ethers;

describe('NFTGemFeeManager contract', function () {
  let owner: SignerWithAddress;
  let sender: SignerWithAddress;
  let payableAddress: SignerWithAddress;
  let NFTGemFeeManager: Contract;
  const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

  beforeEach(async () => {
    await deployments.fixture();
    [owner, sender, payableAddress] = await ethers.getSigners();
    const NFTGemFeeManagerFactory = await ethers.getContractFactory(
      'NFTGemFeeManager',
      owner
    );
    NFTGemFeeManager = await NFTGemFeeManagerFactory.deploy();
    await NFTGemFeeManager.deployed();
  });

  it('Should get fee', async () => {
    const poolFeeHash = keccak256(['bytes'],[pack(['string'], ['pool_fee'])]);
    expect((await NFTGemFeeManager.fee(poolFeeHash)).toNumber()).to.be.equal(2000);
    const wrapGemHash = keccak256(['bytes'],[pack(['string'], ['wrap_gem'])]);
    expect((await NFTGemFeeManager.fee(wrapGemHash)).toNumber()).to.be.equal(2000);
    const flashLoanHash = keccak256(['bytes'],[pack(['string'], ['flash_loan'])]);
    expect((await NFTGemFeeManager.fee(flashLoanHash)).toNumber()).to.be.equal(10000);
  });

  it('should set fees', async () => {
    const poolFeeHash = keccak256(['bytes'],[pack(['string'], ['pool_fee'])]);
    await NFTGemFeeManager.setFee(poolFeeHash, 2000);
    expect((await NFTGemFeeManager.fee(poolFeeHash)).toNumber()).to.be.equal(2000);
  });

  describe('Transfer', function () {
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

      expect(utils.formatEther(await NFTGemFeeManager.balanceOf(ZERO_ADDRESS))).to.equal(
        '9.0'
      );
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
        (await NFTGemFeeManager.balanceOf(ERC20Token.address)).toString()
      ).to.equal('90');
      expect((await ERC20Token.balanceOf(sender.address)).toString()).to.equal(
        '10'
      );
    });
  });
});
