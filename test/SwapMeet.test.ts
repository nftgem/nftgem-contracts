import {ethers} from 'hardhat';
import {expect} from 'chai';
import {
  createSwapMeetOffer,
  setupNFTGemPool,
} from './fixtures/NFTGemPool.fixture';
import {Contract} from 'ethers';
import {SignerWithAddress} from 'hardhat-deploy-ethers/dist/src/signers';

describe('SwapMeet test suite', () => {
  const data = {
    poolData: {
      symbol: 'FTM',
      name: 'Fantom',
      ethPrice: ethers.utils.parseEther('1'),
      minTime: 86400,
      maxTime: 864000,
      diffStep: 1000,
      maxClaims: 0,
      allowedToken: ethers.constants.AddressZero,
    },
    tokenData: {
      symbol: 'WFTM',
      name: 'Wrapped FTM',
      decimals: 8,
    },
  };
  describe('Create Offer', () => {
    it('should create offer', async () => {
      const {SwapMeet, offerId} = await createSwapMeetOffer(data);
      expect(await SwapMeet.isOffer(offerId)).to.be.true;
    });
    it('should list all offer', async () => {
      const {SwapMeet} = await createSwapMeetOffer(data);
      const offers = await SwapMeet.listOffers();
      expect(offers.length).to.be.equal(1);
    });
    it('should list all offer by owner', async () => {
      const {SwapMeet, owner} = await createSwapMeetOffer(data);
      const offers = await SwapMeet.listOffersByOwner(owner.address);
      expect(offers.length).to.be.equal(1);
    });
    it('should get offer details', async () => {
      const {SwapMeet, offerId, poolAddress, owner} = await createSwapMeetOffer(
        data
      );
      const offerDetails = await SwapMeet.getOffer(offerId);
      expect(offerDetails.owner).to.be.equal(owner.address);
      expect(offerDetails.pool).to.be.equal(poolAddress);
    });
  });
  describe('Accept Offer', () => {
    let NFTGemMultiToken: Contract;
    let SwapMeet: Contract;
    let owner: SignerWithAddress;
    let acceptAddr: SignerWithAddress;
    let offerId: string;
    let gemHash0: string;
    let gemHash1: string;
    let gemHash2: string;
    beforeEach(async () => {
      const contracts = await setupNFTGemPool();
      NFTGemMultiToken = contracts.NFTGemMultiToken;
      const swapMeetOffer = await createSwapMeetOffer(data);
      SwapMeet = swapMeetOffer.SwapMeet;
      owner = swapMeetOffer.owner;
      acceptAddr = swapMeetOffer.acceptAddr;
      offerId = swapMeetOffer.offerId;
      gemHash0 = swapMeetOffer.gemHash0;
      gemHash1 = swapMeetOffer.gemHash1;
      gemHash2 = swapMeetOffer.gemHash2;
    });
    it('should accept the offer', async () => {
      /*  Gem count before swap
            Offer Creator(owner): gem0: 1, gem2: 0
            Offer Acceptor(acceptAddr): gem0: 0, gem2: 3
        */
      await SwapMeet.connect(acceptAddr).acceptOffer(offerId, [gemHash2], {
        value: ethers.utils.parseEther('1'),
      });
      /*  Gem count after swap
            Offer Creator(owner): gem0: 0, gem2: 1
            Offer Acceptor(acceptAddr): gem0: 1, gem2: 2
        */
      expect(
        (await NFTGemMultiToken.balanceOf(owner.address, gemHash0)).toNumber()
      ).to.be.equal(0);
      expect(
        (await NFTGemMultiToken.balanceOf(owner.address, gemHash2)).toNumber()
      ).to.be.equal(1);
      expect(
        (
          await NFTGemMultiToken.balanceOf(acceptAddr.address, gemHash0)
        ).toNumber()
      ).to.be.equal(1);
      expect(
        (
          await NFTGemMultiToken.balanceOf(acceptAddr.address, gemHash2)
        ).toNumber()
      ).to.be.equal(2);
    });
    it('Should revert if offer is not registered', async () => {
      await expect(
        SwapMeet.connect(acceptAddr).acceptOffer(gemHash1, [gemHash2], {
          value: ethers.utils.parseEther('1'),
        })
      ).to.be.revertedWith('offer not registered');
    });
    it('Should revert if gem mismatch', async () => {
      await expect(
        SwapMeet.connect(acceptAddr).acceptOffer(
          offerId,
          [gemHash1, gemHash2],
          {
            value: ethers.utils.parseEther('1'),
          }
        )
      ).to.be.revertedWith('gem mismatch');
    });
    it('Should revert if insufficient accept fees', async () => {
      await expect(
        SwapMeet.connect(acceptAddr).acceptOffer(offerId, [gemHash1])
      ).to.be.revertedWith('insufficient accept fee');
    });
    it('Should revert if sender does not have enough gems', async () => {
      await expect(
        SwapMeet.connect(owner).acceptOffer(offerId, [gemHash2], {
          value: ethers.utils.parseEther('1'),
        })
      ).to.be.revertedWith('Insufficient gem balance');
    });
    it('Should penalize if acceptor doesn not have enough gems to swap', async () => {
      await NFTGemMultiToken.safeTransferFrom(
        owner.address,
        acceptAddr.address,
        gemHash0,
        1,
        0x000
      );
      await SwapMeet.connect(acceptAddr).acceptOffer(offerId, [gemHash2], {
        value: ethers.utils.parseEther('1'),
      });
      const offerDetails = await SwapMeet.getOffer(offerId);
      expect(offerDetails.missingTokenPenalty).to.be.true;
      expect(
        (
          await NFTGemMultiToken.balanceOf(acceptAddr.address, gemHash2)
        ).toNumber()
      ).to.be.equal(3);
    });
  });
  describe('Unregister Offer', () => {
    it('should unregister the offer', async () => {
      const {SwapMeet, offerId} = await createSwapMeetOffer(data);
      await SwapMeet.unregisterOffer(offerId);
      expect(await SwapMeet.isOffer(offerId)).to.be.false;
    });
  });
});
