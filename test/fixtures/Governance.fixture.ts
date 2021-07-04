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
      NFTGemMultiToken,
      NFTGemPoolFactory,
      ProposalFactory,
      NFTGemFeeManager,
      ERC20GemTokenFactory,
    } = deployedContracts;
    return {
      NFTGemGovernor,
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

export const createProposal = deployments.createFixture(
  async ({ethers}, ProposalData: any) => {
    const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

    const {deployedContracts} = await publisher(hre, false);
    const {
      NFTGemGovernor,
      NFTGemMultiToken,
      NFTGemPoolFactory,
      ProposalFactory,
      NFTGemFeeManager,
    } = deployedContracts;

    const [owner, sender] = await ethers.getSigners();

    const {
      ProposalType,
      ProposalSubmitter,
      ProposalTitle,
      FeeProposalTitle = 'Change Fee Title',
      FundProposalTitle = 'Fund Project Proposal',
      ListProposalTitle = 'Update allow list Proposal',
      ProposalPrice = ethers.utils.parseEther('1'),
      ProposalAllowedToken,
      ProposalFeeDivisor = 10,
      ProposalDescriptionUrl = 'http://dummy/url',
    } = ProposalData;
    let title = ProposalTitle;

    let poolIndex = await NFTGemPoolFactory.allNFTGemPoolsLength();
    if (poolIndex.eq(0)) {
      await NFTGemGovernor.createSystemPool(
        'TST',
        'Test Gem',
        ethers.utils.parseEther('1'),
        30,
        30,
        65536,
        0,
        ZERO_ADDRESS
      );
    } else poolIndex = (await NFTGemPoolFactory.allNFTGemPoolsLength()).sub(1);
    const poolAddress = await NFTGemPoolFactory.allNFTGemPools(poolIndex);

    switch (ProposalType) {
      case 0:
        await NFTGemGovernor.createFundProjectProposal(
          ProposalSubmitter,
          FundProposalTitle,
          ProposalAllowedToken,
          ProposalDescriptionUrl,
          ProposalPrice
        );
        title = FundProposalTitle;
        break;
      case 1:
        await NFTGemGovernor.createChangeFeeProposal(
          ProposalSubmitter,
          FeeProposalTitle,
          ProposalAllowedToken,
          poolAddress,
          ProposalFeeDivisor
        );
        title = FeeProposalTitle;
        break;
      case 2:
        await NFTGemGovernor.createUpdateAllowlistProposal(
          ProposalSubmitter,
          ListProposalTitle,
          ProposalAllowedToken,
          poolAddress,
          true
        );
        title = ListProposalTitle;
        break;
    }

    const salt = keccak256(
      ['bytes'],
      [pack(['address', 'string'], [ProposalSubmitter, title])]
    );
    const proposalAddress = await ProposalFactory.getProposal(salt);
    const ProposalContract = await ethers.getContractAt(
      'Proposal',
      proposalAddress
    );
    return {
      ProposalContract,
      NFTGemGovernor,
      NFTGemFeeManager,
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
      NFTGemFeeManager,
      owner,
    } = await createProposal(ProposalData);

    if (ProposalData.ProposalType === 0) {
      // send some tokens to the fee manager or the fund project call won't work
      await owner.sendTransaction({
        to: NFTGemFeeManager.address,
        value: ethers.utils.parseEther('1'),
      });
    }

    await ProposalContract.fund({
      from: owner.address,
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
    // execute the contract
    await ProposalContract.execute();
    const newTokenBalance = await NFTGemMultiToken.balanceOf(
      owner.address,
      ProposalContract.address
    );
    return {
      ProposalContract,
      NFTGemMultiToken,
      NFTGemPoolFactory,
      NFTGemFeeManager,
      oldTokenBalance,
      newTokenBalance,
      owner,
    };
  }
);
