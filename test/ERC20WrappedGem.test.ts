import {expect} from './chai-setup';
import {ethers} from 'hardhat';
import {initializeERC20WrappedGem} from './fixtures/ERC20GemToken.fixture';

const {utils} = ethers;
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
const data = {
  poolData: {
    symbol: 'RUBY',
    name: 'Ruby',
    ethPrice: utils.parseEther('1'),
    minTime: 86400,
    maxTime: 864000,
    diffStep: 1000,
    maxClaims: 0,
    allowedToken: ZERO_ADDRESS,
  },
  tokenData: {
    symbol: 'WRUBY',
    name: 'Wrapped Ruby',
    decimals: 8,
  },
};

const calculateQty = (fd: number) => {
  const tq = 20 * 10 ** 8;
  const fee = tq / fd;
  const qty = tq - fee;
  return qty;
};

describe('ERC20WrappedGem contract', function () {
  it('Should initialize', async () => {
    const {ERC20WrappedGem, NFTGemMultiToken} = await initializeERC20WrappedGem(
      data
    );
    expect(await ERC20WrappedGem.getTokenAddress()).to.equal(
      NFTGemMultiToken.address
    );
    expect(await ERC20WrappedGem.getTokenId()).to.equal(0);
  });
  describe('Wrap', () => {
    it('should revert if quantity is zero', async () => {
      const {ERC20WrappedGem, sender} = await initializeERC20WrappedGem(data);
      await expect(ERC20WrappedGem.connect(sender).wrap(0)).to.be.revertedWith(
        'ZERO_QUANTITY'
      );
    });
    it('should revert if balance is insufficient', async () => {
      const {ERC20WrappedGem, sender} = await initializeERC20WrappedGem(data);
      await expect(
        ERC20WrappedGem.connect(sender).wrap(200)
      ).to.be.revertedWith('INSUFFICIENT_QUANTITY');
    });
    it('should wrap gems to erc20', async () => {
      const {
        ERC20WrappedGem,
        NFTGemFeeManager,
        sender,
      } = await initializeERC20WrappedGem(data);
      await expect(ERC20WrappedGem.connect(sender).wrap(20))
        .to.emit(ERC20WrappedGem, 'Wrap')
        .withArgs(sender.address, 20);
      const qty = calculateQty(
        (await NFTGemFeeManager.defaultFeeDivisor()).toNumber()
      );
      expect(
        (await ERC20WrappedGem.balanceOf(sender.address)).toNumber()
      ).to.equal(qty);
    });
  });

  describe('Unwrap', () => {
    it('should revert if quantity is zero', async () => {
      const {ERC20WrappedGem, sender} = await initializeERC20WrappedGem(data);
      await ERC20WrappedGem.connect(sender).wrap(20);
      await expect(
        ERC20WrappedGem.connect(sender).unwrap(0)
      ).to.be.revertedWith('ZERO_QUANTITY');
    });
    it('should revert if gems balance is insufficient', async () => {
      const {ERC20WrappedGem, sender} = await initializeERC20WrappedGem(data);
      await ERC20WrappedGem.connect(sender).wrap(20);
      await expect(
        ERC20WrappedGem.connect(sender).unwrap(21)
      ).to.be.revertedWith('INSUFFICIENT_GEMS');
    });
    // TODO: Add test for INSUFFICIENT_QUANTITY check
    it('Should unwrap gems', async () => {
      const {ERC20WrappedGem, sender} = await initializeERC20WrappedGem(data);
      await ERC20WrappedGem.connect(sender).wrap(20);
      const beforeBalance = (
        await ERC20WrappedGem.balanceOf(sender.address)
      ).toNumber();
      await expect(ERC20WrappedGem.connect(sender).unwrap(10))
        .to.emit(ERC20WrappedGem, 'Unwrap')
        .withArgs(sender.address, 10);
      const afterBalance = (
        await ERC20WrappedGem.balanceOf(sender.address)
      ).toNumber();
      const decimals = await ERC20WrappedGem.decimals();
      expect(afterBalance).to.equal(beforeBalance - 10 * 10 ** decimals);
    });
  });
});
