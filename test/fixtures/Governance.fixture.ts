import {deployments} from 'hardhat';
import {pack, keccak256} from '@ethersproject/solidity';
import {FactoryOptions} from 'hardhat-deploy-ethers/dist/src/helpers';

export const setupNftGemGovernor = deployments.createFixture(
  async ({ethers}) => {
    await deployments.fixture();

    const [owner, sender] = await ethers.getSigners();
    // Deploy libraries
    const GovernanceLib = await (
      await ethers.getContractFactory('GovernanceLib')
    ).deploy();
    const ProposalsLib = await (
      await ethers.getContractFactory('ProposalsLib', {
        libraries: {GovernanceLib: GovernanceLib.address},
      })
    ).deploy();
    const ComplexPoolLib = await (
      await ethers.getContractFactory('ComplexPoolLib')
    ).deploy();

    const factoryOptions: FactoryOptions = {
      signer: owner,
      libraries: {
        GovernanceLib: GovernanceLib.address,
        ProposalsLib: ProposalsLib.address
      },
    };
    const factoryOptions1: FactoryOptions = {
      signer: owner,
      libraries: {
        ComplexPoolLib: ComplexPoolLib.address
      },
    };
    // deploy contracts
    const NFTGemGovernor = await (
      await ethers.getContractFactory('NFTGemGovernor', factoryOptions)
    ).deploy();
    const NFTGemMultiToken = await (
      await ethers.getContractFactory('NFTGemMultiToken', owner)
    ).deploy();
    const NFTGemPoolFactory = await (
      await ethers.getContractFactory('NFTGemPoolFactory', factoryOptions1)
    ).deploy();
    const NFTGemFeeManager = await (
      await ethers.getContractFactory('NFTGemFeeManager', owner)
    ).deploy();
    const ProposalFactory = await (
      await ethers.getContractFactory('ProposalFactory', owner)
    ).deploy();
    const SwapHelper = await (
      await ethers.getContractFactory('MockQueryHelper', owner)
    ).deploy();

    await NFTGemGovernor.deployed();
    await NFTGemMultiToken.deployed();
    await NFTGemPoolFactory.deployed();
    await NFTGemFeeManager.deployed();
    await ProposalFactory.deployed();
    await SwapHelper.deployed();

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

    return {
      NFTGemGovernor,
      NFTGemMultiToken,
      NFTGemPoolFactory,
      ProposalFactory,
      NFTGemFeeManager,
      owner,
      sender,
    };
  }
);

export const createProposal = deployments.createFixture(
  async ({ethers}, ProposalData: any) => {
    const {NFTGemGovernor, ProposalFactory, NFTGemMultiToken, owner, sender} = await setupNftGemGovernor();

    const {
      ProposalSubmitter,
      ProposalTitle,
      ProposalSymbol,
      ProposalName,
      ProposalPrice,
      ProposalMinTime,
      ProposalMaxTime,
      ProposalDiffStep,
      ProposalMaxClaims,
      ProposalAllowedToken
    } = ProposalData;
    await NFTGemGovernor.issueInitialGovernanceTokens(owner.address);
    await NFTGemGovernor.createNewPoolProposal(
      ProposalSubmitter,
      ProposalTitle,
      ProposalSymbol,
      ProposalName,
      ProposalPrice,
      ProposalMinTime,
      ProposalMaxTime,
      ProposalDiffStep,
      ProposalMaxClaims,
      ProposalAllowedToken
    );

    const salt = keccak256(
      ['bytes'],
      [pack(['address', 'string'], [ProposalSubmitter, ProposalTitle])]
    );
    const proposalAddress = await ProposalFactory.getProposal(salt);
    const ProposalContract = await ethers.getContractAt(
      'Proposal',
      proposalAddress,
      ProposalSubmitter
    );
    return {
        ProposalContract,
        NFTGemGovernor,
        ProposalFactory,
        NFTGemMultiToken,
        owner,
        sender
    };
  }
);
