import {expect} from './chai-setup';
import {ethers} from 'hardhat';
import {pack, keccak256} from '@ethersproject/solidity';
import {
  setupNftGemGovernor
} from './fixtures/Governance.fixture';

const {utils} = ethers;
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

describe('NFTGemGovernance contract', async function () {
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
  let NFTGemGovernor: any,
    NFTGemMultiToken: any,
    NFTGemPoolFactory: any,
    owner: any,
    sender: any;

  beforeEach(async function () {
    const signers = await ethers.getSigners();
    owner = signers[0];
    sender = signers[0];
    const setupNftGemGovernorResult = await setupNftGemGovernor();
    NFTGemGovernor = setupNftGemGovernorResult.NFTGemGovernor;
    NFTGemMultiToken = setupNftGemGovernorResult.NFTGemMultiToken;
    NFTGemPoolFactory = setupNftGemGovernorResult.NFTGemPoolFactory;
    ProposalData.ProposalSubmitter = sender.address;
  });

  it('Should initialize Governor contract', async () => {
    expect(await NFTGemGovernor.initialized()).to.be.true;
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
