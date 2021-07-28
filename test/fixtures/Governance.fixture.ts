import {pack, keccak256} from '@ethersproject/solidity';
import hre from 'hardhat';

const {deployments} = hre;

import publisher from '../../lib/publishLib';

export const setupNftGemGovernor = deployments.createFixture(
  async ({ethers}) => {
    await deployments.fixture();

    const [owner, sender] = await ethers.getSigners();

    // Deploy libraries
    const {deployedContracts} = await publisher(hre, false);
    const {
      NFTGemGovernor,
      GovernorAlpha,
      GovernanceToken,
      NFTGemMultiToken,
      NFTGemPoolFactory,
      ProposalFactory,
      NFTGemFeeManager,
      ERC20GemTokenFactory,
    } = deployedContracts;
    return {
      NFTGemGovernor,
      GovernorAlpha,
      GovernanceToken,
      NFTGemMultiToken,
      NFTGemPoolFactory,
      ProposalFactory,
      NFTGemFeeManager,
      ERC20GemTokenFactory,
      owner,
      sender,
    };
  }
);

export const setupGovernorAlpha = deployments.createFixture(
  async ({ethers}) => {
    const [owner] = await ethers.getSigners();
    
    const TimelockHarness = await (
      await ethers.getContractFactory('TimelockHarness')
    ).deploy(owner.address, 3600 * 24 * 2);

    const GovernanceToken = await (
      await ethers.getContractFactory('GovernanceToken', owner)
    ).deploy(owner.address);

    const GovernorAlpha = await (
      await ethers.getContractFactory('GovernorAlpha', owner)
    ).deploy(TimelockHarness.address, GovernanceToken.address, owner.address);

    await TimelockHarness.deployed();
    await GovernanceToken.deployed();
    await GovernorAlpha.deployed();

    TimelockHarness.harnessSetAdmin(GovernorAlpha.address);
    
    return {
      GovernorAlpha,
      GovernanceToken,
      TimelockHarness,
    };
  }
);

export const createProposal = deployments.createFixture(
  async ({ethers}, params: any) => {
    const {GovernorAlpha, GovernanceToken} = await setupGovernorAlpha();
    const proposer = params.proposer;
    const amount = params.transferAmount;
    const [...accounts] = await ethers.getSigners();
    const targets = [accounts[4].address];
    const values = ['0'];
    const signatures = ['getBalanceOf(address)'];
    const callDatas = [
      keccak256(['bytes'], [pack(['address'], [accounts[4].address])]),
    ];
    if(amount) {
      await GovernanceToken.transfer(proposer.address, amount);
    }
    await GovernanceToken.connect(proposer).delegate(proposer.address);
    await GovernorAlpha.connect(proposer).propose(
      targets,
      values,
      signatures,
      callDatas,
      'test proposal'
    );
    const proposalId = await GovernorAlpha.latestProposalIds(proposer.address);
    const proposal = await GovernorAlpha.proposals(proposalId);
    return {proposal};
  }
);
