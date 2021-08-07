import {expect} from './chai-setup';
import {ethers} from 'hardhat';
import {pack, keccak256} from '@ethersproject/solidity';
import {createNFTGemPool} from './fixtures/NFTGemPool.fixture';

describe('Flash Loan Test Suite', () => {
  const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
  const data = {
    poolData: {
      symbol: 'FTM',
      name: 'Fantom',
      ethPrice: ethers.utils.parseEther('1'),
      minTime: 86400,
      maxTime: 864000,
      diffStep: 1000,
      maxClaims: 0,
      allowedToken: ZERO_ADDRESS,
    },
    tokenData: {
      symbol: 'WFTM',
      name: 'Wrapped FTM',
      decimals: 8,
    },
  };
  describe('Flash Loan', () => {
    it('Should success flashloan', async () => {
      const {NFTComplexGemPool, ERC20WrappedGem} = await createNFTGemPool(data);
      const receiver = await (
        await ethers.getContractFactory('ERC3156FlashBorrowerMock')
      ).deploy(true, true);
      const totalSupply = (await ERC20WrappedGem.totalSupply()).toString();
      const tx = await NFTComplexGemPool.flashLoan(
        receiver.address,
        ERC20WrappedGem.address,
        1000,
        '0x'
      );
      expect(tx)
        .to.emit(receiver, 'BalanceOf')
        .withArgs(ERC20WrappedGem.address, receiver.address, 1000);
      expect(tx)
        .to.emit(receiver, 'TotalSupply')
        .withArgs(ERC20WrappedGem.address, totalSupply);
      // Transfer loan amount from contract to receiver
      expect(tx)
        .to.emit(ERC20WrappedGem, 'Transfer')
        .withArgs(NFTComplexGemPool.address, receiver.address, 1000);
      // Repayment of loan amount from receiver to contract
      expect(tx)
        .to.emit(ERC20WrappedGem, 'Transfer')
        .withArgs(receiver.address, NFTComplexGemPool.address, 1000);
    });
    it('Should revert flashloan if invalid success callback', async () => {
      const {NFTComplexGemPool, ERC20WrappedGem} = await createNFTGemPool(data);
      const receiver = await (
        await ethers.getContractFactory('ERC3156FlashBorrowerMock')
      ).deploy(false, true);
      await expect(
        NFTComplexGemPool.flashLoan(
          receiver.address,
          ERC20WrappedGem.address,
          1000,
          '0x'
        )
      ).to.be.revertedWith('FlashMinter: Callback failed');
    });
    it('Should revert flashloan if approval is missing', async () => {
      const {NFTComplexGemPool, ERC20WrappedGem} = await createNFTGemPool(data);
      const receiver = await (
        await ethers.getContractFactory('ERC3156FlashBorrowerMock')
      ).deploy(true, false);
      await expect(
        NFTComplexGemPool.flashLoan(
          receiver.address,
          ERC20WrappedGem.address,
          1000,
          '0x'
        )
      ).to.be.revertedWith('FlashMinter: Repay not approved');
    });
  });
  it('should get maxFlashLoan amount', async () => {
    const {NFTComplexGemPool, ERC20WrappedGem} = await createNFTGemPool(data);
    expect(
      (await NFTComplexGemPool.maxFlashLoan(ERC20WrappedGem.address)).toNumber()
    ).to.be.equal(1000000 - 1000000 / 10);
  });
  it('should get correct flashFee', async () => {
    const {NFTComplexGemPool, NFTGemFeeManager, ERC20WrappedGem} =
      await createNFTGemPool(data);
    const feeHash = keccak256(['bytes'], [pack(['string'], ['flash_loan'])]);
    const fd = (await NFTGemFeeManager.fee(feeHash)).toNumber();
    const amount = 10000;
    expect(
      (
        await NFTComplexGemPool.flashFee(ERC20WrappedGem.address, amount)
      ).toNumber()
    ).to.be.equal(amount / fd);
  });
});
