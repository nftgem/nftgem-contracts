import {expect} from './chai-setup';
import {ethers} from 'hardhat';
import {pack, keccak256} from '@ethersproject/solidity';
import {
  setupNftGemGovernor,
  createProposal,
} from './fixtures/Governance.fixture';
const {BigNumber, utils} = ethers;

describe('NFTGemGovernance contract', async function () {
  const [sender] = await ethers.getSigners();
  const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
  const ProposalData = {
    ProposalSubmitter: sender.address,
    ProposalTitle: 'Proposal Title',
    ProposalType: 0,
    ProposalSymbol: 'TST',
    ProposalName: 'Test Gem',
    ProposalPrice: utils.parseEther('1'),
    ProposalMinTime: 86400,
    ProposalMaxTime: 864000,
    ProposalDiffStep: 1000,
    ProposalMaxClaims: 0,
    ProposalAllowedToken: ZERO_ADDRESS,
  };
  it('Should create Proposal Vote tokens ', async function () {
    const {
      NFTGemGovernor,
      NFTGemMultiToken,
      owner,
    } = await setupNftGemGovernor();
    // issue initial supply
    await NFTGemGovernor.issueInitialGovernanceTokens(owner.address);
    const tokensBeforeCreating = (
      await NFTGemMultiToken.balanceOf(owner.address, 0)
    ).toNumber();
    await NFTGemGovernor.createProposalVoteTokens(0);
    const tokensAfterCreating = (
      await NFTGemMultiToken.balanceOf(owner.address, 0)
    ).toNumber();
    // we will mint new tokens equals to the tokens user is currently helding
    expect(tokensAfterCreating).to.equal(tokensBeforeCreating * 2);
  });
  it('Should destroy Proposal Vote tokens ', async function () {
    const {
      NFTGemGovernor,
      NFTGemMultiToken,
      owner,
    } = await setupNftGemGovernor();
    // issue initial supply and create some proposal tokens
    await NFTGemGovernor.issueInitialGovernanceTokens(owner.address);
    await NFTGemGovernor.createProposalVoteTokens(0);

    // Burn tokens
    await NFTGemGovernor.destroyProposalVoteTokens(0);
    const tokensAfterBurning = (
      await NFTGemMultiToken.balanceOf(owner.address, 0)
    ).toNumber();
    expect(tokensAfterBurning).to.equal(0);
  });

  describe('Proposal Test Suite', function () {
    it('Should create new pool proposal ', async function () {
      const {ProposalContract, ProposalFactory} = await createProposal(ProposalData);
      expect((await ProposalFactory.allProposalsLength()).toNumber()).to.equal(
        1
      );
      expect(await ProposalContract.title()).to.equal(ProposalData.ProposalTitle);
      expect(await ProposalContract.status()).to.equal(0);
      expect(await ProposalContract.proposalType()).to.equal(0);
      expect(await ProposalContract.creator()).to.equal(sender.address);
      expect(await ProposalContract.funder()).to.equal(sender.address);
    });
    it('should fund a proposal', async function () {
      const {ProposalContract, NFTGemMultiToken, owner} = await createProposal(ProposalData);
      await ProposalContract.fund({from: sender.address, value: utils.parseEther('1')});
      const tokenBalance = await NFTGemMultiToken.balanceOf(
        owner.address,
        ProposalContract.address
      );
      expect(tokenBalance).to.equal(500000);
      expect(await ProposalContract.funder()).to.equal(sender.address);
    });
    it('should revert if the proposal is already funded', async function () {
      const {ProposalContract} = await createProposal(ProposalData);
      await ProposalContract.fund({from: sender.address, value: utils.parseEther('1')});
      await expect(
        ProposalContract.fund({from: sender.address, value: utils.parseEther('1')})
      ).to.be.revertedWith('ALREADY_FUNDED');
    });
    it('should revert if fee is less than the proposal cost', async function () {
      const {
        NFTGemGovernor,
        ProposalFactory,
        owner,
        sender,
      } = await setupNftGemGovernor();
      await NFTGemGovernor.issueInitialGovernanceTokens(owner.address);
      await NFTGemGovernor.createNewPoolProposal(
        sender.address,
        'Proposal Title 1',
        'TST1',
        'Test Gem 1',
        utils.parseEther('1'),
        86400,
        864000,
        1000,
        0,
        ZERO_ADDRESS
      );
      const ProposalAddress = await ProposalFactory.allProposals(0);
      const Proposal = await ethers.getContractAt(
        'Proposal',
        ProposalAddress,
        sender
      );
      await expect(
        Proposal.fund({from: sender.address, value: utils.parseEther('0.1')})
      ).to.be.revertedWith('MISSING_FEE');
    });
    it('Should execute pool proposal ', async function () {
      const {
        NFTGemGovernor,
        NFTGemMultiToken,
        NFTGemPoolFactory,
        ProposalFactory,
        owner,
        sender,
      } = await setupNftGemGovernor();
      await NFTGemGovernor.issueInitialGovernanceTokens(owner.address);
      await NFTGemGovernor.createNewPoolProposal(
        sender.address,
        'Proposal Title 1',
        'TST1',
        'Test Gem 1',
        utils.parseEther('1'),
        86400,
        864000,
        1000,
        0,
        ZERO_ADDRESS
      );
      const poolProposalAddress = await ProposalFactory.allProposals(0);
      const Proposal = await ethers.getContractAt(
        'Proposal',
        poolProposalAddress,
        sender
      );
      await Proposal.fund({from: sender.address, value: utils.parseEther('1')});
      const tokenBalance = await NFTGemMultiToken.balanceOf(
        owner.address,
        poolProposalAddress
      );
      await NFTGemMultiToken.safeTransferFrom(
        owner.address,
        poolProposalAddress,
        BigNumber.from(poolProposalAddress),
        tokenBalance,
        0
      );
      expect(await Proposal.status()).to.equal(2);
      // This method will internally call NFTGemGovernor.executeProposal()
      await Proposal.execute();
      expect(await Proposal.status()).to.equal(4);
      // Check whether 2 genesis gems are minted or not.
      expect(
        (await NFTGemPoolFactory.allNFTGemPoolsLength()).toNumber()
      ).to.equal(1);
      const gemPoolAddress = await NFTGemPoolFactory.allNFTGemPools(0);
      const gemHash0 = keccak256(
        ['bytes'],
        [pack(['string', 'address', 'uint'], ['gem', gemPoolAddress, 0])]
      );
      const gemHash1 = keccak256(
        ['bytes'],
        [pack(['string', 'address', 'uint'], ['gem', gemPoolAddress, 1])]
      );
      expect(
        (await NFTGemMultiToken.balanceOf(sender.address, gemHash0)).toNumber()
      ).to.equal(1);
      expect(
        (await NFTGemMultiToken.balanceOf(sender.address, gemHash1)).toNumber()
      ).to.equal(1);
    });
    it('Should revert if proposal is already executed', async function () {
      const {
        NFTGemGovernor,
        NFTGemMultiToken,
        ProposalFactory,
        owner,
        sender,
      } = await setupNftGemGovernor();
      await NFTGemGovernor.issueInitialGovernanceTokens(owner.address);
      await NFTGemGovernor.createNewPoolProposal(
        sender.address,
        'Proposal Title 1',
        'TST1',
        'Test Gem 1',
        utils.parseEther('1'),
        86400,
        864000,
        1000,
        0,
        ZERO_ADDRESS
      );
      const poolProposalAddress = await ProposalFactory.allProposals(0);
      const Proposal = await ethers.getContractAt(
        'Proposal',
        poolProposalAddress,
        sender
      );
      await Proposal.fund({from: sender.address, value: utils.parseEther('1')});
      const tokenBalance = await NFTGemMultiToken.balanceOf(
        owner.address,
        poolProposalAddress
      );
      await NFTGemMultiToken.safeTransferFrom(
        owner.address,
        poolProposalAddress,
        BigNumber.from(poolProposalAddress),
        tokenBalance,
        0
      );
      expect(await Proposal.status()).to.equal(2);
      // This method will internally call NFTGemGovernor.executeProposal()
      await Proposal.execute();
      expect(await Proposal.status()).to.equal(4);
    });
    it('Should create Change Fee proposal', async function () {
      const {
        NFTGemGovernor,
        ProposalFactory,
        sender,
      } = await setupNftGemGovernor();
      await NFTGemGovernor.createNewPoolProposal(
        sender.address,
        'Proposal Title 1',
        'TST1',
        'Test Gem 1',
        utils.parseEther('1'),
        86400,
        864000,
        1000,
        0,
        ZERO_ADDRESS
      );
      const poolAddress = await ProposalFactory.allProposals(0);
      await NFTGemGovernor.createChangeFeeProposal(
        sender.address,
        'Change Fee Title',
        ZERO_ADDRESS,
        poolAddress,
        10
      );
      const noOfPools = (await ProposalFactory.allProposalsLength()).toNumber();
      expect(noOfPools).to.equal(2);
      const poolProposalAddress = await ProposalFactory.allProposals(
        noOfPools - 1
      );
      const Proposal = await ethers.getContractAt(
        'Proposal',
        poolProposalAddress,
        sender
      );
      expect(await Proposal.title()).to.equal('Change Fee Title');
      expect(await Proposal.status()).to.equal(0);
    });

    it('Should create Fund Project proposal', async function () {
      const {
        NFTGemGovernor,
        ProposalFactory,
        sender,
      } = await setupNftGemGovernor();
      await NFTGemGovernor.createFundProjectProposal(
        sender.address,
        'Fund Project Proposal',
        ZERO_ADDRESS,
        'dummy/url',
        utils.parseEther('1')
      );
      const noOfPools = (await ProposalFactory.allProposalsLength()).toNumber();
      expect(noOfPools).to.equal(1);
      const poolProposalAddress = await ProposalFactory.allProposals(
        noOfPools - 1
      );
      const Proposal = await ethers.getContractAt(
        'Proposal',
        poolProposalAddress,
        sender
      );
      expect(await Proposal.title()).to.equal('Fund Project Proposal');
      expect(await Proposal.status()).to.equal(0);
    });
    it('Should create update allow list proposal', async function () {
      const {
        NFTGemGovernor,
        ProposalFactory,
        sender,
      } = await setupNftGemGovernor();
      await NFTGemGovernor.createNewPoolProposal(
        sender.address,
        'Proposal Title 1',
        'TST1',
        'Test Gem 1',
        utils.parseEther('1'),
        86400,
        864000,
        1000,
        0,
        ZERO_ADDRESS
      );
      const poolAddress = await ProposalFactory.allProposals(0);
      await NFTGemGovernor.createUpdateAllowlistProposal(
        sender.address,
        'Update allow list Proposal',
        ZERO_ADDRESS,
        poolAddress,
        true
      );
      const noOfPools = (await ProposalFactory.allProposalsLength()).toNumber();
      expect(noOfPools).to.equal(2);
      const poolProposalAddress = await ProposalFactory.allProposals(
        noOfPools - 1
      );
      const Proposal = await ethers.getContractAt(
        'Proposal',
        poolProposalAddress,
        sender
      );
      expect(await Proposal.title()).to.equal('Update allow list Proposal');
      expect(await Proposal.status()).to.equal(0);
    });
  });
  it('Should issue initial governance tokens', async function () {
    const {
      NFTGemGovernor,
      NFTGemMultiToken,
      owner,
    } = await setupNftGemGovernor();
    await NFTGemGovernor.issueInitialGovernanceTokens(owner.address);
    const ownerBalance = await NFTGemMultiToken.balanceOf(owner.address, 0);
    expect(ownerBalance.toNumber()).to.equal(500000);
  });
  it('Should revert issuing initial governance tokens if already issued', async function () {
    const {NFTGemGovernor, owner} = await setupNftGemGovernor();
    await NFTGemGovernor.issueInitialGovernanceTokens(owner.address);
    await expect(
      NFTGemGovernor.issueInitialGovernanceTokens(owner.address)
    ).to.be.revertedWith('ALREADY_ISSUED');
  });
  it('Should issue fuel tokens', async function () {
    const {
      NFTGemGovernor,
      NFTGemMultiToken,
      owner,
    } = await setupNftGemGovernor();
    await NFTGemGovernor.issueFuelToken(owner.address, 10);
    const ownerBalance = await NFTGemMultiToken.balanceOf(owner.address, 1);
    expect(ownerBalance.toNumber()).to.equal(10);
  });
  it('Maybe issue governance tokens', async function () {
    const {
      NFTGemGovernor,
      NFTGemMultiToken,
      owner,
    } = await setupNftGemGovernor();
    await NFTGemGovernor.maybeIssueGovernanceToken(owner.address);
    const ownerBalance = await NFTGemMultiToken.balanceOf(owner.address, 0);
    expect(ownerBalance.toNumber()).to.equal(1);
    await expect(NFTGemGovernor.maybeIssueGovernanceToken(owner.address))
      .to.emit(NFTGemGovernor, 'GovernanceTokenIssued')
      .withArgs(owner.address, 1);
  });
  it('Should create and associate system pool', async function () {
    const {
      NFTGemGovernor,
      NFTGemMultiToken,
      NFTGemPoolFactory,
      owner,
    } = await setupNftGemGovernor();
    await NFTGemGovernor.createSystemPool(
      'TST',
      'TEST Pool Name',
      ethers.utils.parseEther('1'),
      86400,
      864000,
      1000,
      0,
      ZERO_ADDRESS
    );
    expect(
      (await NFTGemPoolFactory.allNFTGemPoolsLength()).toNumber()
    ).to.equal(1);
    const gemPoolAddress = await NFTGemPoolFactory.allNFTGemPools(0);
    const gemHash0 = keccak256(
      ['bytes'],
      [pack(['string', 'address', 'uint'], ['gem', gemPoolAddress, 0])]
    );
    const gemHash1 = keccak256(
      ['bytes'],
      [pack(['string', 'address', 'uint'], ['gem', gemPoolAddress, 1])]
    );
    expect(
      (await NFTGemMultiToken.balanceOf(owner.address, gemHash0)).toNumber()
    ).to.equal(1);
    expect(
      (await NFTGemMultiToken.balanceOf(owner.address, gemHash1)).toNumber()
    ).to.equal(1);
  });
});
