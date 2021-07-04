import {expect} from './chai-setup';
import hre, {ethers, deployments} from 'hardhat';
import {pack, keccak256} from '@ethersproject/solidity';
import {SignerWithAddress} from 'hardhat-deploy-ethers/dist/src/signer-with-address';
import {Contract} from 'ethers';

describe('ProposalFactory contract', function () {
  const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
  let ProposalFactory: Contract;
  let sender: SignerWithAddress;
  beforeEach(async () => {
    await deployments.fixture();
    ProposalFactory = await(
      await ethers.getContractFactory('ProposalFactory')
    ).deploy();
  });

  it('Should create a new proposal', async function () {
    [sender] = await hre.ethers.getSigners();
    await ProposalFactory.createProposal(
      sender.address,
      'New Proposal',
      ZERO_ADDRESS,
      0
    );
    expect((await ProposalFactory.allProposalsLength()).toNumber()).to.equal(1);

    const salt = keccak256(
      ['bytes'],
      [pack(['address', 'string'], [sender.address, 'New Proposal'])]
    );
    const firstProposal = await ProposalFactory.allProposals(0);
    const hashProposal = await ProposalFactory.getProposal(salt);
    expect(hashProposal).to.equal(firstProposal);

    // Test the newly created contract
    const proposalContract = await ethers.getContractAt(
      'Proposal',
      hashProposal
    );
    expect(await proposalContract.title()).to.equal('New Proposal');
    expect(await proposalContract.proposalData()).to.equal(ZERO_ADDRESS);
    expect(await proposalContract.status()).to.equal(0);
  });

  it('Revert if the proposal already exists', async function () {
    [sender] = await hre.ethers.getSigners();
    await ProposalFactory.createProposal(
      sender.address,
      'New Proposal',
      ZERO_ADDRESS,
      0
    );
    await expect(
      ProposalFactory.createProposal(
        sender.address,
        'New Proposal',
        ZERO_ADDRESS,
        0
      )
    ).to.be.revertedWith('PROPOSAL_EXISTS');
  });
});
