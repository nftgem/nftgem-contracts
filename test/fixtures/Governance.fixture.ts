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


    const factoryOptions: FactoryOptions = {
      signer: owner,
      libraries: {
        GovernanceLib: GovernanceLib.address,
        ProposalsLib: ProposalsLib.address,
      },
    };
    const factoryOptions1: FactoryOptions = {
      signer: owner,
      libraries: {
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
      await ethers.getContractFactory('NFTGemFeeManager',  owner)
    ).deploy();
    const ProposalFactory = await (
      await ethers.getContractFactory('ProposalFactory',  owner)
    ).deploy();
    const SwapHelper = await (
      await ethers.getContractFactory('MockQueryHelper',  owner)
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
    await NFTGemFeeManager.setOperator(NFTGemGovernor.address);

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
    const {
      NFTGemGovernor,
      ProposalFactory,
      NFTGemMultiToken,
      NFTGemPoolFactory,
      owner,
      sender,
    } = await setupNftGemGovernor();

    const {
      ProposalType,
      ProposalSubmitter,
      ProposalTitle,
      FeeProposalTitle = 'Change Fee Title',
      FundProposalTitle = 'Fund Project Proposal',
      ListProposalTitle = 'Update allow list Proposal',
      ProposalSymbol,
      ProposalName,
      ProposalPrice,
      ProposalMinTime,
      ProposalMaxTime,
      ProposalDiffStep,
      ProposalMaxClaims,
      ProposalAllowedToken,
      ProposalFeeDivisor = 10,
      ProposalDescriptionUrl = 'http://dummy/url'
    } = ProposalData;
    let title = ProposalTitle;

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
    const poolAddress = await ProposalFactory.allProposals(0);

    switch (ProposalType) {
      case 1:
        await NFTGemGovernor.createFundProjectProposal(
          ProposalSubmitter,
          FundProposalTitle,
          ProposalAllowedToken,
          ProposalDescriptionUrl,
          ProposalPrice
        );
        title = FundProposalTitle;
        break;
      case 2:
        await NFTGemGovernor.createChangeFeeProposal(
          ProposalSubmitter,
          FeeProposalTitle,
          ProposalAllowedToken,
          poolAddress,
          ProposalFeeDivisor
        );
        title = FeeProposalTitle
        break;
      case 3:
        await NFTGemGovernor.createUpdateAllowlistProposal(
          ProposalSubmitter,
          ListProposalTitle,
          ProposalAllowedToken,
          poolAddress,
          true
        );
        title = ListProposalTitle
        break;
    }

    const salt = keccak256(
      ['bytes'],
      [pack(['address', 'string'], [ProposalSubmitter, title])]
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
      NFTGemPoolFactory,
      owner,
      sender,
    };
  }
);

export const executeProposal = deployments.createFixture(
  async ({ethers}, ProposalData: any) => {
    const {
      ProposalContract,
      NFTGemMultiToken,
      NFTGemPoolFactory,
      owner,
    } = await createProposal(ProposalData);
    await ProposalContract.fund({
      from: ProposalData.ProposalSubmitter.address,
      value: ethers.utils.parseEther('1'),
    });
    const oldTokenBalance = await NFTGemMultiToken.balanceOf(
      owner.address,
      ProposalContract.address
    );
    await NFTGemMultiToken.safeTransferFrom(
      owner.address,
      ProposalContract.address,
      ethers.BigNumber.from(ProposalContract.address),
      oldTokenBalance,
      0
    );
    await ProposalContract.execute();
    const newTokenBalance = await NFTGemMultiToken.balanceOf(
      owner.address,
      ProposalContract.address
    );
    return {
      ProposalContract,
      NFTGemMultiToken,
      NFTGemPoolFactory,
      oldTokenBalance,
      newTokenBalance,
      owner,
    };
  }
);
