import {expect} from './chai-setup';
import {ethers} from 'hardhat';
import {pack, keccak256} from '@ethersproject/solidity';
import {setupNftGemGovernor} from './fixtures/Governance.fixture';

describe('ProposalFactory contract', function () {
  const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

  it('Should create a new proposal', async function () {
    const {ProposalFactory, sender} = await setupNftGemGovernor();
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
    const {ProposalFactory, sender} = await setupNftGemGovernor();

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
