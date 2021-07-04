import {expect} from './chai-setup';
import {ethers} from 'hardhat';
import {pack, keccak256} from '@ethersproject/solidity';
import {
  setupNftGemGovernor,
  createProposal,
  executeProposal,
} from './fixtures/Governance.fixture';
import {SignerWithAddress} from 'hardhat-deploy-ethers/dist/src/signer-with-address';
const {utils} = ethers;
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

describe('NFTGemGovernance contract', function () {
  let sender: SignerWithAddress;
  const ProposalData = {
    ProposalSubmitter: '',
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
  beforeEach(async function () {
    [sender] = await ethers.getSigners();
    ProposalData.ProposalSubmitter = sender.address;
  });
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
  describe('Proposal Test Suite', function () {
    describe('Create Proposal', function () {
      it('Should create new pool proposal ', async function () {
        const {ProposalContract, ProposalFactory} = await createProposal(
          ProposalData
        );
        expect(
          (await ProposalFactory.allProposalsLength()).toNumber()
        ).to.equal(1);
        expect(await ProposalContract.title()).to.equal(
          ProposalData.ProposalTitle
        );
        expect(await ProposalContract.status()).to.equal(0);
        expect(await ProposalContract.proposalType()).to.equal(0);
        expect(await ProposalContract.creator()).to.equal(sender.address);
        expect(await ProposalContract.funder()).to.equal(sender.address);
      });
      it('Should create Fund Project proposal', async function () {
        const {ProposalContract, ProposalFactory} = await createProposal({
          ...ProposalData,
          ProposalType: 1,
        });
        const noOfPools = (
          await ProposalFactory.allProposalsLength()
        ).toNumber();
        expect(noOfPools).to.equal(2);
        expect(await ProposalContract.title()).to.equal(
          'Fund Project Proposal'
        );
        expect(await ProposalContract.status()).to.equal(0);
      });
      it('Should create Change Fee proposal', async function () {
        const {ProposalContract, ProposalFactory} = await createProposal({
          ...ProposalData,
          ProposalType: 2,
        });
        const noOfPools = (
          await ProposalFactory.allProposalsLength()
        ).toNumber();
        expect(noOfPools).to.equal(2);
        expect(await ProposalContract.title()).to.equal('Change Fee Title');
        expect(await ProposalContract.status()).to.equal(0);
      });
      it('Should create update allow list proposal', async function () {
        const {ProposalContract, ProposalFactory} = await createProposal({
          ...ProposalData,
          ProposalType: 3,
        });
        const noOfPools = (
          await ProposalFactory.allProposalsLength()
        ).toNumber();
        expect(noOfPools).to.equal(2);
        expect(await ProposalContract.title()).to.equal(
          'Update allow list Proposal'
        );
        expect(await ProposalContract.status()).to.equal(0);
      });
    });
    describe('Fund Proposal', function () {
      it('should revert if the proposal is already funded', async function () {
        const {ProposalContract} = await createProposal(ProposalData);
        await ProposalContract.fund({
          from: sender.address,
          value: utils.parseEther('1'),
        });
        await expect(
          ProposalContract.fund({
            from: sender.address,
            value: utils.parseEther('1'),
          })
        ).to.be.revertedWith('ALREADY_FUNDED');
      });
      it('should revert if fee is less than the proposal cost', async function () {
        const {ProposalContract} = await createProposal(ProposalData);
        await expect(
          ProposalContract.fund({
            from: sender.address,
            value: utils.parseEther('0.1'),
          })
        ).to.be.revertedWith('MISSING_FEE');
      });
      it('should fund a proposal', async function () {
        const {
          ProposalContract,
          NFTGemMultiToken,
          owner,
        } = await createProposal(ProposalData);
        await ProposalContract.fund({
          from: sender.address,
          value: utils.parseEther('1'),
        });
        const tokenBalance = await NFTGemMultiToken.balanceOf(
          owner.address,
          ProposalContract.address
        );
        expect(tokenBalance).to.equal(500000);
        expect(await ProposalContract.funder()).to.equal(sender.address);
      });
      it('Should return the excess amount back to funder', async function () {
        const {ProposalContract} = await createProposal(ProposalData);
        const senderBalanceBefore = parseInt(
          utils.formatEther(await sender.getBalance())
        );
        await ProposalContract.fund({
          from: sender.address,
          value: utils.parseEther('2'),
        });
        const senderBalanceAfter = parseInt(
          utils.formatEther(await sender.getBalance())
        );
        expect(senderBalanceBefore - senderBalanceAfter).to.equal(1);
      });
    });
    describe('Execute Proposal', function () {
      it('Should revert execution if proposal is not funded', async function () {
        const {ProposalContract} = await createProposal(ProposalData);
        await expect(ProposalContract.execute()).to.be.revertedWith(
          'NOT_FUNDED'
        );
      });
      it('Should revert execution if proposal is not passed', async function () {
        const {ProposalContract} = await createProposal(ProposalData);
        await ProposalContract.fund({
          from: sender.address,
          value: utils.parseEther('1'),
        });
        await expect(ProposalContract.execute()).to.be.revertedWith(
          'IS_FAILED'
        );
      });
      it('Should revert execution if proposal is already executed', async function () {
        const {ProposalContract} = await executeProposal(ProposalData);
        await expect(ProposalContract.execute()).to.be.revertedWith(
          'IS_EXECUTED'
        );
      });
      it('Should execute pool proposal ', async function () {
        const {
          ProposalContract,
          NFTGemMultiToken,
          NFTGemPoolFactory,
        } = await executeProposal(ProposalData);
        expect(await ProposalContract.status()).to.equal(4);
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
          (
            await NFTGemMultiToken.balanceOf(sender.address, gemHash0)
          ).toNumber()
        ).to.equal(1);
        expect(
          (
            await NFTGemMultiToken.balanceOf(sender.address, gemHash1)
          ).toNumber()
        ).to.equal(1);
      });
      it('Should destroy proposal vote tokens after successful execution', async function () {
        const {newTokenBalance} = await executeProposal(ProposalData);
        expect(newTokenBalance.toNumber()).to.equal(0);
      });
      it('Should return the filing fees to funder after execution', async function () {
        const funderBalanceBefore = parseInt(
          utils.formatEther(await sender.getBalance())
        );
        await executeProposal(ProposalData);
        const funderBalanceAfter = parseInt(
          utils.formatEther(await sender.getBalance())
        );
        expect(funderBalanceBefore).to.equal(funderBalanceAfter);
      });
    });
    describe('Close Proposal', function () {
      it('Should revert close operation if proposal is not funded', async function () {
        const {ProposalContract} = await createProposal(ProposalData);
        await expect(ProposalContract.close()).to.be.revertedWith('NOT_FUNDED');
      });
      it('Should revert close operation if proposal is executed', async function () {
        const {ProposalContract} = await executeProposal(ProposalData);
        await expect(ProposalContract.close()).to.be.revertedWith(
          'IS_EXECUTED'
        );
      });
      it('Should revert close operation if proposal is active', async function () {
        const {ProposalContract} = await createProposal(ProposalData);
        await ProposalContract.fund({
          from: sender.address,
          value: utils.parseEther('1'),
        });
        await expect(ProposalContract.close()).to.be.revertedWith('IS_ACTIVE');
      });
      it('Should revert close operation if proposal is already passed', async function () {
        const {
          ProposalContract,
          NFTGemMultiToken,
          owner,
        } = await createProposal(ProposalData);
        await ProposalContract.fund({
          from: sender.address,
          value: utils.parseEther('1'),
        });
        await ethers.provider.send('evm_increaseTime', [3600000]);
        await ethers.provider.send('evm_mine', []);
        const tokenBalance = await NFTGemMultiToken.balanceOf(
          owner.address,
          ProposalContract.address
        );
        await NFTGemMultiToken.safeTransferFrom(
          owner.address,
          ProposalContract.address,
          ethers.BigNumber.from(ProposalContract.address),
          tokenBalance,
          0
        );
        await expect(ProposalContract.close()).to.be.revertedWith('IS_PASSED');
      });
      it('Should close the proposal', async function () {
        const {ProposalContract} = await createProposal(ProposalData);
        await ProposalContract.fund({
          from: sender.address,
          value: utils.parseEther('1'),
        });
        await ethers.provider.send('evm_increaseTime', [3600000]);
        await ethers.provider.send('evm_mine', []);
        await ProposalContract.close();
        expect(await ProposalContract.status()).to.equal(5);
      });
      it('Should revert close operation if the proposal is already closed', async function () {
        const {ProposalContract} = await createProposal(ProposalData);
        await ProposalContract.fund({
          from: sender.address,
          value: utils.parseEther('1'),
        });
        await ethers.provider.send('evm_increaseTime', [3600000]);
        await ethers.provider.send('evm_mine', []);
        await ProposalContract.close();
        await expect(ProposalContract.close()).to.be.revertedWith('IS_CLOSED');
      });
    });
  });
});
