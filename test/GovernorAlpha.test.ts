import {expect} from './chai-setup';
import {ethers} from 'hardhat';
import {
  setupGovernorAlpha,
  createProposal,
} from './fixtures/Governance.fixture';
import {SignerWithAddress} from 'hardhat-deploy-ethers/dist/src/signers';
import {Contract} from 'ethers';

const mineBlocks = async (num = 1) => {
  while (num > 0) {
    await ethers.provider.send('evm_mine', []);
    num -= 1;
  }
  return Promise.resolve();
};

describe('Governor Alpha Test Suite', function () {
  let proposer: SignerWithAddress, accounts: SignerWithAddress[];
  let GovernorAlpha: Contract;
  beforeEach(async () => {
    [proposer, ...accounts] = await ethers.getSigners();
    const {GovernorAlpha: alpha} =
      await setupGovernorAlpha();
    GovernorAlpha = alpha;
  });
  describe('Should initialize proposal properly', () => {
    it('Should create a new proposal', async () => {
      const {proposal} = await createProposal({proposer});

      const proposalId = await GovernorAlpha.latestProposalIds(
        proposer.address
      );
      expect(proposal.id).to.be.equal(proposalId);
      expect(await GovernorAlpha.state(proposalId)).to.be.equal(0);
    });

    it('Proposer is set to sender', async () => {
      const {proposal} = await createProposal({proposer});
      expect(proposal.proposer).to.be.equal(proposer.address);
    });

    it('Start block is set to the current block number plus vote delay', async () => {
      const {proposal} = await createProposal({proposer});
      const proposalBlock = await ethers.provider.getBlockNumber();
      expect(proposal.startBlock).to.be.equal(`${proposalBlock + 1}`);
    });

    it('End block is set to the current block number plus the sum of vote delay and vote period', async () => {
      const {proposal} = await createProposal({proposer});
      const proposalBlock = await ethers.provider.getBlockNumber();
      expect(proposal.endBlock).to.be.equal(`${proposalBlock + 1 + 17280}`);
    });

    it('ForVotes and AgainstVotes are initialized to zero', async () => {
      const {proposal} = await createProposal({proposer});
      expect(proposal.forVotes).to.be.equal('0');
      expect(proposal.againstVotes).to.be.equal('0');
    });

    it('Executed and Canceled flags are initialized to false', async () => {
      const {proposal} = await createProposal({proposer});
      expect(proposal.canceled).to.be.equal(false);
      expect(proposal.executed).to.be.equal(false);
    });

    it('ETA is initialized to zero', async () => {
      const {proposal} = await createProposal({proposer});
      expect(proposal.eta).to.be.equal('0');
    });
  });

  describe('Should be able to cast vote on proposal', () => {
    it('Should not cast if proposal is not in ACTIVE state', async () => {
      const {proposal} = await createProposal({proposer});
      await expect(
        GovernorAlpha.connect(proposer).castVote(proposal.id, true)
      ).to.be.revertedWith('GovernorAlpha::_castVote: voting is closed');
    });
    it('Should change the state to ACTIVE once appropriate blocks are mined', async () => {
      const {proposal} = await createProposal({proposer});
      await mineBlocks(2);
      expect(await GovernorAlpha.state(proposal.id)).to.be.equal(1);
    });
    it('Should be able to cast vote on proposal', async () => {
      const {proposal} = await createProposal({proposer});
      expect(
        (await GovernorAlpha.getReceipt(proposal.id, proposer.address)).hasVoted
      ).to.be.false;
      await mineBlocks(2);
      await GovernorAlpha.connect(proposer).castVote(proposal.id, true);
      expect(
        (await GovernorAlpha.getReceipt(proposal.id, proposer.address)).hasVoted
      ).to.be.true;
    });
    it('Should revert if voter has already voted', async () => {
      const {proposal} = await createProposal({proposer});
      await mineBlocks(2);
      await GovernorAlpha.connect(proposer).castVote(proposal.id, true);
      await expect(
        GovernorAlpha.connect(proposer).castVote(proposal.id, true)
      ).to.be.revertedWith('GovernorAlpha::_castVote: voter already voted');
    });
    it('Should add votes to forVotes', async () => {
      const actor: SignerWithAddress = accounts[6];
      const {proposal} = await createProposal({
        proposer: actor,
        transferAmount: '300000000000000000000001',
      });
      await mineBlocks(2);
      await GovernorAlpha.connect(actor).castVote(proposal.id, true);
      const forVotes = (await GovernorAlpha.proposals(proposal.id)).forVotes;
      expect(forVotes.toString()).to.be.equal('300000000000000000000001');
    });
    it('Should add votes to against votes', async () => {
      const actor: SignerWithAddress = accounts[6];
      const {proposal} = await createProposal({
        proposer: actor,
        transferAmount: '300000000000000000000001',
      });
      await mineBlocks(2);
      await GovernorAlpha.connect(actor).castVote(proposal.id, false);
      const againstVotes = (await GovernorAlpha.proposals(proposal.id))
        .againstVotes;
      expect(againstVotes.toString()).to.be.equal('300000000000000000000001');
    });
  });

  describe('Should be able to cast vote by signature', () => {
    it('reverts if the signatory is invalid', async () => {
      const actor: SignerWithAddress = accounts[6];
      const {proposal} = await createProposal({
        proposer: actor,
        transferAmount: '300000000000000000000001',
      });
      await mineBlocks(2);
      await expect(
        GovernorAlpha.castVoteBySig(proposal.id, true, 0, ethers.utils.randomBytes(32), ethers.utils.randomBytes(32))
      ).to.be.revertedWith('GovernorAlpha::castVoteBySig: invalid signature');
    });

    it('Cast vote on behalf of signatory', async () => {
      const actor: SignerWithAddress = accounts[6];
      const {proposal} = await createProposal({
        proposer: actor,
        transferAmount: '300000000000000000000001',
      });
      const {chainId} = await ethers.provider.getNetwork();
      const Domain = {
        name: 'Bitgem Governor Alpha',
        chainId,
        verifyingContract: GovernorAlpha.address,
      };
      const Types = {
        Ballot: [
          {name: 'proposalId', type: 'uint256'},
          {name: 'support', type: 'bool'},
        ],
      };
      const Message = {proposalId: proposal.id, support: true};
      const signature = await actor._signTypedData(Domain, Types, Message);
      const {v, r, s} = ethers.utils.splitSignature(signature);
      await mineBlocks(2);
      await GovernorAlpha.castVoteBySig(proposal.id, true, v, r, s);
      const forVotes = (await GovernorAlpha.proposals(proposal.id)).forVotes;
      expect(forVotes.toString()).to.be.equal('300000000000000000000001');
    });
  });

  describe('Should be able proposal state properly', () => {
    it('Pending state', async () => {
      const {proposal} = await createProposal({proposer});
      expect(await GovernorAlpha.state(proposal.id)).to.be.equal(0);
    });
    it('Active State', async () => {
      const {proposal} = await createProposal({proposer});
      await mineBlocks(2);
      expect(await GovernorAlpha.state(proposal.id)).to.be.equal(1);
    });
    it('Cancelled State', async () => {
      const {proposal} = await createProposal({
        proposer,
        transferAmount: ethers.BigNumber.from('400000').mul(
          ethers.constants.WeiPerEther
        ),
      });
      await GovernorAlpha.cancel(proposal.id);
      expect(await GovernorAlpha.state(proposal.id)).to.be.equal(2);
    });
    it('Defeated State', async () => {
      const actor: SignerWithAddress = accounts[6];
      const {proposal} = await createProposal({
        proposer: actor,
        transferAmount: ethers.BigNumber.from('400000').mul(
          ethers.constants.WeiPerEther
        ),
      });
      await mineBlocks(2);
      await GovernorAlpha.connect(actor).castVote(proposal.id, true);
      await mineBlocks(17281);
      expect(await GovernorAlpha.state(proposal.id)).to.be.equal(3);
    });
    it('Succeeded, Queued and Executed State', async () => {
      const {proposal} = await createProposal({
        proposer,
        transferAmount: ethers.BigNumber.from('1200000').mul(
          ethers.constants.WeiPerEther
        ),
      });
      await mineBlocks(2);
      await GovernorAlpha.castVote(proposal.id, true);
      await mineBlocks(17281);
      expect(await GovernorAlpha.state(proposal.id)).to.be.equal(4);
      await GovernorAlpha.queue(proposal.id);
      expect(await GovernorAlpha.state(proposal.id)).to.be.equal(5);
      await ethers.provider.send('evm_increaseTime', [(3600 * 24 * 2) + 3]);
      await GovernorAlpha.execute(proposal.id);
      expect(await GovernorAlpha.state(proposal.id)).to.be.equal(7);
    });
    it('Expired State', async () => {
        const {proposal} = await createProposal({
          proposer,
          transferAmount: ethers.BigNumber.from('1200000').mul(
            ethers.constants.WeiPerEther
          ),
        });
        await mineBlocks(2);
        await GovernorAlpha.castVote(proposal.id, true);
        await mineBlocks(17281);
        await GovernorAlpha.queue(proposal.id);
        await ethers.provider.send('evm_increaseTime', [3600 * 24 * 18]);
        await mineBlocks(1);
        expect(await GovernorAlpha.state(proposal.id)).to.be.equal(6);
      });
  });
});
