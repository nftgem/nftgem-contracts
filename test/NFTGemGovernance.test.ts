import {expect} from './chai-setup';
import {ethers, deployments} from 'hardhat';
import {pack, keccak256} from '@ethersproject/solidity';
import {SignerWithAddress} from 'hardhat-deploy-ethers/dist/src/signer-with-address';
import {Contract} from '@ethersproject/contracts';
import {FactoryOptions} from 'hardhat-deploy-ethers/dist/src/helpers';

const {getContractFactory, BigNumber, utils} = ethers;
describe('NFTGemGovernance contract', function () {
  let owner: SignerWithAddress;
  let sender: SignerWithAddress;
  let NFTGemGovernor: Contract;
  let NFTGemMultiToken: Contract;
  let NFTGemPoolFactory: Contract;
  let NFTGemFeeManager: Contract;
  let ProposalFactory: Contract;
  let SwapHelper: Contract;
  const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

  beforeEach(async () => {
    await deployments.fixture();
    [owner, sender] = await ethers.getSigners();
    // Deploy libraries
    const GovernanceLib = await (
      await getContractFactory('GovernanceLib')
    ).deploy();
    const ProposalsLib = await (
      await getContractFactory('ProposalsLib', {
        libraries: {GovernanceLib: GovernanceLib.address},
      })
    ).deploy();
    const factoryOptions: FactoryOptions = {
      signer: owner,
      libraries: {
        GovernanceLib: GovernanceLib.address,
        ProposalsLib: ProposalsLib.address,
      },
    };
    // deploy contracts
    NFTGemGovernor = await (
      await getContractFactory('NFTGemGovernor', factoryOptions)
    ).deploy();
    NFTGemMultiToken = await (
      await getContractFactory('NFTGemMultiToken', owner)
    ).deploy();
    NFTGemPoolFactory = await (
      await getContractFactory('NFTGemPoolFactory', owner)
    ).deploy();
    NFTGemFeeManager = await (
      await getContractFactory('NFTGemFeeManager', owner)
    ).deploy();
    ProposalFactory = await (
      await getContractFactory('ProposalFactory', owner)
    ).deploy();
    SwapHelper = await (
      await getContractFactory('MockQueryHelper', owner)
    ).deploy();

    await NFTGemGovernor.deployed();
    await NFTGemMultiToken.deployed();
    await NFTGemPoolFactory.deployed();
    await NFTGemFeeManager.deployed();
    await ProposalFactory.deployed();
    await SwapHelper.deployed();

    await NFTGemMultiToken.removeProxyRegistryAt(0);
    // initialize NFTGemGovernance contract
    await NFTGemGovernor.initialize(
      NFTGemMultiToken.address,
      NFTGemPoolFactory.address,
      NFTGemFeeManager.address,
      ProposalFactory.address,
      SwapHelper.address
    );
    await NFTGemMultiToken.addController(NFTGemGovernor.address);
    await ProposalFactory.addController(NFTGemGovernor.address);
    await NFTGemPoolFactory.addController(NFTGemGovernor.address);
  });
  it('Should create Proposal Vote tokens ', async function () {
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

  it('Should create new pool proposal ', async function () {
    await NFTGemGovernor.createNewPoolProposal(
      sender.address,
      'Proposal Title',
      'TST',
      'Test Gem',
      ethers.utils.parseEther('1'),
      86400,
      864000,
      1000,
      0,
      ZERO_ADDRESS
    );
    expect((await ProposalFactory.allProposalsLength()).toNumber()).to.equal(1);

    const salt = keccak256(
      ['bytes'],
      [pack(['address', 'string'], [sender.address, 'Proposal Title'])]
    );
    const proposalAddress = await ProposalFactory.getProposal(salt);
    const ProposalContract = await ethers.getContractAt(
      'Proposal',
      proposalAddress,
      sender
    );
    expect(await ProposalContract.title()).to.equal('Proposal Title');
    expect(await ProposalContract.status()).to.equal(0);
  });
  it('Should execute pool proposal ', async function () {
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
  it('Should create Change Fee proposal', async function () {
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
  it('Should issue initial governance tokens', async function () {
    await NFTGemGovernor.issueInitialGovernanceTokens(owner.address);
    const ownerBalance = await NFTGemMultiToken.balanceOf(owner.address, 0);
    expect(ownerBalance.toNumber()).to.equal(500000);
  });
  it('Should revert issuing initial governance tokens if already issued', async function () {
    await NFTGemGovernor.issueInitialGovernanceTokens(owner.address);
    await expect(
      NFTGemGovernor.issueInitialGovernanceTokens(owner.address)
    ).to.be.revertedWith('ALREADY_ISSUED');
  });
  it('Should issue fuel tokens', async function () {
    await NFTGemGovernor.issueFuelToken(owner.address, 10);
    const ownerBalance = await NFTGemMultiToken.balanceOf(owner.address, 1);
    expect(ownerBalance.toNumber()).to.equal(10);
  });
  it('Maybe issue governance tokens', async function () {
    await NFTGemGovernor.maybeIssueGovernanceToken(owner.address);
    const ownerBalance = await NFTGemMultiToken.balanceOf(owner.address, 0);
    expect(ownerBalance.toNumber()).to.equal(1);
    await expect(NFTGemGovernor.maybeIssueGovernanceToken(owner.address))
      .to.emit(NFTGemGovernor, 'GovernanceTokenIssued')
      .withArgs(owner.address, 1);
  });
  it('Should create and associate system pool', async function () {
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
