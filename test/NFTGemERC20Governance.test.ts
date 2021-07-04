import {expect} from './chai-setup';
import {initializeNFTGemERC20GovernanceToken} from './fixtures/ERC20GemToken.fixture';

describe('NFTGemERC20Governance Contract', () => {
  it('Should initialize', async () => {
    const {
      NFTGemERC20Governance,
    } = await initializeNFTGemERC20GovernanceToken();
    expect(NFTGemERC20Governance).to.exist;
  });
  describe('Wrap tokens', () => {
    it('Should wrap governance tokens', async () => {
      const {
        NFTGemERC20Governance,
        NFTGemMultiToken,
        NFTGemFeeManager,
        sender,
      } = await initializeNFTGemERC20GovernanceToken();
      const qty = 4000;
      await NFTGemERC20Governance.connect(sender).wrap(qty);
      const fd = (await NFTGemFeeManager.defaultFeeDivisor()).toNumber();
      const rate = 1;
      const decimals = 18;
      const tq = qty * rate * 10 ** decimals;
      const fee = tq / fd;
      const userQty = tq - fee;
      expect(
        (
          await NFTGemMultiToken.balanceOf(NFTGemERC20Governance.address, 0)
        ).toNumber()
      ).to.equal(qty);
      expect(
        Number(
          (await NFTGemERC20Governance.balanceOf(sender.address)).toString()
        )
      ).to.equal(userQty);
      expect(
        (
          await NFTGemERC20Governance.balanceOf(NFTGemFeeManager.address)
        ).toString()
      ).to.equal(fee.toString());
    });
  });
});
