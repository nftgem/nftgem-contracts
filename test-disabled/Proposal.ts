import hre from 'hardhat';
import {expect} from 'chai';
import {pack, keccak256} from '@ethersproject/solidity';

describe('Proposal Factory Core', function () {
  const {ethers} = hre;
  const {utils} = ethers;
  const getContractAt = ethers.getContractAt;

  let GovernanceLib: any;
  let factory: any;
  let propContract: any;

  before(async function () {
    GovernanceLib = await (
      await ethers.getContractFactory('GovernanceLib')
    ).deploy();
    await GovernanceLib.deployed();

    const ProposalFactory = await ethers.getContractFactory(
      'ProposalFactory',
      {
        libraries: {
          GovernanceLib: GovernanceLib.address,
        },
      }
    );
    factory = await ProposalFactory.deploy();
    factory.deployed();
  });

  it('Should create', async function () {
    expect((await factory.allProposalsLength()).toNumber()).to.equal(0);
  });

  it('Should allow for adding a new proposal', async function () {
    const [sender] = await ethers.getSigners();

    const CreatePoolProposalData = await ethers.getContractFactory(
      'CreatePoolProposalData',
      {}
    );
    const proposal = await CreatePoolProposalData.deploy(
      'TEST',
      'Test Item',
      utils.parseEther('1'),
      86400,
      864000,
      100000,
      0
    );
    proposal.deployed();

    await factory.createProposal('SAMPLE TITLE', proposal.address, 1);
    expect((await factory.allProposalsLength()).toNumber()).to.equal(1);

    const hash = keccak256(
      ['bytes'],
      [pack(['address', 'string'], [sender.address, 'SAMPLE TITLE'])]
    );

    const element = await factory.allProposals(0);
    const prophash = await factory.getProposal(hash);

    expect(element.toString()).to.equal(prophash.toString());

    propContract = await getContractAt('Proposal', prophash, sender);

    expect(await propContract.title()).to.equal('SAMPLE TITLE');
    expect(await propContract.proposalData()).to.equal(proposal.address);
    expect(await propContract.status()).to.equal(0);
  });

  it('Should reject less than 1 ETH funding for proposal', async function () {
    let didError = false;
    try {
      await propContract.fund({value: utils.parseEther('0.9')});
    } catch (e) {
      didError = true;
    }
    expect(didError).to.equal(true);
  });

  it('Should reject executing proposal', async function () {
    let didError = false;
    try {
      await propContract.execute();
    } catch (e) {
      didError = true;
    }
    expect(didError).to.equal(true);
  });

  it('Should reject closing proposal', async function () {
    let didError = false;
    try {
      await propContract.close();
    } catch (e) {
      didError = true;
    }
    expect(didError).to.equal(true);
  });

  // it('Should accept 1 ETH funding for proposal and move status to ACTIVE', async function () {
  //   await propContract.fund({value:utils.parseEther('1')})
  //   expect(await propContract.status()).to.equal(1);
  // })
});
