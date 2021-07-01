import {expect} from './chai-setup';
import {initializeNFTGemWrappedERC20Token} from './fixtures/ERC20GemToken.fixture';

describe('NFTGemWrappedERC20Fuel Contract', () => {
  it('Should initialize', async () => {
    const {NFTGemWrappedERC20Fuel} = await initializeNFTGemWrappedERC20Token();
    expect(NFTGemWrappedERC20Fuel).to.exist;
  });
  describe('Wrap tokens', () => {
    it('should wrap tokens', async () => {
      const {
        NFTGemWrappedERC20Fuel,
        NFTGemMultiToken,
        NFTGemFeeManager,
        sender,
      } = await initializeNFTGemWrappedERC20Token();
      const qty = 4000;
      await NFTGemWrappedERC20Fuel.connect(sender).wrap(qty);
      const fd = (await NFTGemFeeManager.defaultFeeDivisor()).toNumber();
      const fee = qty / fd;
      const userQty = qty - fee;
      expect(
        (
          await NFTGemMultiToken.balanceOf(NFTGemWrappedERC20Fuel.address, 1)
        ).toNumber()
      ).to.equal(qty);
      expect(
        (await NFTGemWrappedERC20Fuel.balanceOf(sender.address)).toNumber()
      ).to.equal(userQty);
      expect(
        (
          await NFTGemWrappedERC20Fuel.balanceOf(NFTGemFeeManager.address)
        ).toNumber()
      ).to.equal(fee);
    });
    it('Should revert if quantity is zero', async () => {
      const {
        NFTGemWrappedERC20Fuel,
        sender,
      } = await initializeNFTGemWrappedERC20Token();
      const qty = 0;
      await expect(
        NFTGemWrappedERC20Fuel.connect(sender).wrap(qty)
      ).to.be.revertedWith('ZERO_QUANTITY');
    });
    it('Should revert if there is insufficient balance', async () => {
      const {
        NFTGemWrappedERC20Fuel,
        sender,
      } = await initializeNFTGemWrappedERC20Token();
      const qty = 15000;
      await expect(
        NFTGemWrappedERC20Fuel.connect(sender).wrap(qty)
      ).to.be.revertedWith('INSUFFICIENT_ERC1155_BALANCE');
    });
  });
  describe('Unwrap tokens', () => {
    it('should unwrap tokens', async () => {
      const {
        NFTGemWrappedERC20Fuel,
        NFTGemMultiToken,
        sender,
      } = await initializeNFTGemWrappedERC20Token();
      const qty = 4000;
      await NFTGemWrappedERC20Fuel.connect(sender).wrap(qty);
      const tokensBefore = (
        await NFTGemMultiToken.balanceOf(sender.address, 1)
      ).toNumber();
      await NFTGemWrappedERC20Fuel.connect(sender).unwrap(2000);
      const tokensAfter = (
        await NFTGemMultiToken.balanceOf(sender.address, 1)
      ).toNumber();
      expect(tokensAfter - tokensBefore).to.equal(2000);
    });
    it('should revert if quantity is zero', async () => {
      const {
        NFTGemWrappedERC20Fuel,
        sender,
      } = await initializeNFTGemWrappedERC20Token();
      await NFTGemWrappedERC20Fuel.connect(sender).wrap(4000);
      await expect(
        NFTGemWrappedERC20Fuel.connect(sender).unwrap(0)
      ).to.be.revertedWith('ZERO_QUANTITY');
    });
    it('should revert if insufficient reserves', async () => {
      const {
        NFTGemWrappedERC20Fuel,
        sender,
      } = await initializeNFTGemWrappedERC20Token();
      await expect(
        NFTGemWrappedERC20Fuel.connect(sender).unwrap(1000)
      ).to.be.revertedWith('INSUFFICIENT_RESERVES');
    });
    it('should revert if insufficient erc20 reserves', async () => {
      const {
        NFTGemWrappedERC20Fuel,
        sender,
      } = await initializeNFTGemWrappedERC20Token();
      await NFTGemWrappedERC20Fuel.connect(sender).wrap(4000);
      await expect(
        NFTGemWrappedERC20Fuel.connect(sender).unwrap(3999)
      ).to.be.revertedWith('INSUFFICIENT_ERC20_BALANCE');
    });
  });
});
