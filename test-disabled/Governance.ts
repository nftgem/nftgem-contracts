import hre from 'hardhat';
import {expect} from 'chai';
import {assert} from '../test/chai-setup';
import {pack, keccak256} from '@ethersproject/solidity';

import func from "../deploy/deploy";

const {ethers, deployments, getUnnamedAccounts} = hre;
const {BigNumber, utils, provider, getContractAt} = ethers;
const {deploy, get} = deployments;

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

let sender: any;
let deployedContracts: any;

describe('Governance', function () {

  before(async function () {
    [sender] = await hre.ethers.getSigners();
    const dc = deployedContracts = await func(hre);
  });

  it('Should create', async function () {

    // deploy
    const dc = deployedContracts = await func(hre);

    dc.NFTGemGovernor.createNewPoolProposal(
      sender.address,
      'Proposal Title',
      'TST',
      'Test Gem',
      utils.parseEther('1'),
      86400,
      864000,
      1000,
      0,
      ZERO_ADDRESS
    );

    expect((await dc.ProposalFactory.allProposalsLength()).toNumber()).to.equal(
      1
    );

    const hash = keccak256(
      ['bytes'],
      [pack(['address', 'string'], [sender.address, 'Proposal Title'])]
    );

    const element = await dc.ProposalFactory.allProposals(0);
    const prophash = await dc.ProposalFactory.getProposal(hash);

    expect(element.toString()).to.equal(prophash.toString());

    const prop = (await getContractAt(
      'Proposal',
      prophash,
      sender
    ));
    deployedContracts.proposal = prop;

    expect(await prop.title()).to.equal('Proposal Title');
    expect(await prop.status()).to.equal(0);
  });

  it('Should reject less than 1 ETH funding for proposal', async function () {
    let didError = false;
    try {
      await deployedContracts.proposal.fund({value: utils.parseEther('0.9')});
    } catch (e) {
      didError = true;
    }
    expect(didError).to.equal(true);
  });

  it('Should reject executing proposal', async function () {
    let didError = false;
    try {
      await deployedContracts.proposal.execute();
    } catch (e) {
      didError = true;
    }
    expect(didError).to.equal(true);
  });

  it('Should reject closing proposal', async function () {
    let didError = false;
    try {
      await deployedContracts.proposal.close();
    } catch (e) {
      didError = true;
    }
    expect(didError).to.equal(true);
  });

  it('Should accept 1 ETH funding for proposal and move status to ACTIVE', async function () {
    await deployedContracts.proposal.fund({value: utils.parseEther('1')});
    expect(await deployedContracts.proposal.status()).to.equal(1);
  });

  it('Should reject more ETH', async function () {
    let error = false;
    try {
      await deployedContracts.proposal.fund({value: utils.parseEther('1')});
    } catch (e) {
      error = true;
    }
    expect(error).to.be.true;
  });

  it('Should reject executing proposal', async function () {
    let didError = false;
    try {
      await deployedContracts.proposal.execute();
    } catch (e) {
      didError = true;
    }
    expect(didError).to.equal(true);
  });

  it('Should reject closing proposal', async function () {
    let didError = false;
    try {
      await deployedContracts.proposal.close();
    } catch (e) {
      didError = true;
    }
    expect(didError).to.equal(true);
  });

  it('Should have generated and delivered vote tokens', async function () {
    const hash = keccak256(
      ['bytes'],
      [pack(['address', 'string'], [sender.address, 'Proposal Title'])]
    );
    const propAddress = await deployedContracts.ProposalFactory.getProposal(
      hash
    );
    console.log(propAddress);
    const tokenBalance = await deployedContracts.NFTGemMultiToken.balanceOf(
      sender.address,
      propAddress
    );
    expect(tokenBalance.toNumber()).to.not.equal(0);
  });

  it('Should change status of proposal to PASSED when vote tokens are delivered to proposal', async function () {
    const hash = keccak256(
      ['bytes'],
      [pack(['address', 'string'], [sender.address, 'Proposal Title'])]
    );
    const propAddress = await deployedContracts.ProposalFactory.getProposal(
      hash
    );
    const tokenBalance = await deployedContracts.NFTGemMultiToken.balanceOf(
      sender.address,
      propAddress
    );
    expect(tokenBalance.toNumber()).to.not.equal(0);
    await deployedContracts.NFTGemMultiToken.safeTransferFrom(
      sender.address,
      propAddress,
      BigNumber.from(propAddress),
      tokenBalance,
      0
    );
    const receiverBalance = await deployedContracts.NFTGemMultiToken.balanceOf(
      propAddress,
      propAddress
    );
    expect(receiverBalance.toNumber()).to.not.equal(0);
    expect(await deployedContracts.proposal.status()).to.equal(2);
  });

  it('Should successfully execute proposal and receive ETH back', async function () {
    const ap = await deployedContracts.NFTGemPoolFactory.allNFTGemPoolsLength();

    const bb = await provider.getBalance(sender.address);
    await deployedContracts.proposal.execute();
    const ba = await provider.getBalance(sender.address);

    expect(
      await deployedContracts.NFTGemPoolFactory.allNFTGemPoolsLength()
    ).to.equal(ap.add(1).toNumber());
    expect(await deployedContracts.proposal.status()).to.equal(4);
    expect(ba.gt(bb)).to.be.true;
  });

  it('Should not allow executing an executed proposal', async function () {
    let didError = false;
    try {
      await deployedContracts.proposal.execute();
    } catch (e) {
      didError = true;
    }
    expect(didError).to.be.true;
  });

  it('Should not allow closing an executed proposal', async function () {
    let didError = false;
    try {
      await deployedContracts.proposal.close();
    } catch (e) {
      didError = true;
    }
    expect(didError).to.be.true;
  });

  it('Should go through a successful change fee proposal creation', async function () {
    const dc = deployedContracts;

    const dlen = await deployedContracts.NFTGemPoolFactory.allNFTGemPoolsLength();
    const pool = await deployedContracts.NFTGemPoolFactory.allNFTGemPools(
      dlen.sub(1)
    );

    dc.NFTGemGovernor.createChangeFeeProposal(
      sender.address,
      'Please gimme me money - pleaese',
      '0x0000000000000000000000000000000000000000',
      pool,
      10
    );

    const hash = keccak256(
      ['bytes'],
      [
        pack(
          ['address', 'string'],
          [sender.address, 'Please gimme me money - pleaese']
        ),
      ]
    );

    const lpl = await dc.ProposalFactory.allProposalsLength();
    const element = await dc.ProposalFactory.allProposals(lpl.sub(1));
    const prophash = await dc.ProposalFactory.getProposal(hash);
    expect(element.toString()).to.equal(prophash.toString());
    const prop = await getContractAt('Proposal', element, sender);

    expect(await prop.title()).to.equal('Please gimme me money - pleaese');
    expect(await prop.status()).to.equal(0);

    await prop.fund({value: utils.parseEther('1')});
    expect(await prop.status()).to.equal(1);

    const tokenBalance = await deployedContracts.NFTGemMultiToken.balanceOf(
      sender.address,
      prop.address
    );
    await deployedContracts.NFTGemMultiToken.safeTransferFrom(
      sender.address,
      prop.address,
      BigNumber.from(prop.address),
      tokenBalance,
      0
    );

    expect(await prop.status()).to.equal(2);
    await prop.execute();
    expect(await prop.status()).to.equal(4);

    const fd = await deployedContracts.NFTGemFeeManager.feeDivisor(pool);
    expect(fd.toNumber()).to.equal(10);
  });

  it('Should go through a successful new project proposal creation', async function () {
    const dc = deployedContracts;

    dc.NFTGemGovernor.createFundProjectProposal(
      sender.address,
      'Give me money - pleaese',
      sender.address,
      'link',
      utils.parseEther('1')
    );

    const hash = keccak256(
      ['bytes'],
      [pack(['address', 'string'], [sender.address, 'Give me money - pleaese'])]
    );

    const feeManageAddress = dc.NFTGemFeeManager.address;
    const lpl = await dc.ProposalFactory.allProposalsLength();
    const element = await dc.ProposalFactory.allProposals(lpl.sub(1));
    const prophash = await dc.ProposalFactory.getProposal(hash);
    expect(element.toString()).to.equal(prophash.toString());
    const prop = (deployedContracts.proposal = await getContractAt(
      'Proposal',
      element,
      sender
    ));

    expect(await prop.title()).to.equal('Give me money - pleaese');
    expect(await prop.status()).to.equal(0);

    await sender.sendTransaction({ to: feeManageAddress,  value:utils.parseEther('1.1') });
    await prop.fund({value: utils.parseEther('1')});
    expect(await prop.status()).to.equal(1);

    const tokenBalance = await deployedContracts.NFTGemMultiToken.balanceOf(
      sender.address,
      prop.address
    );
    await deployedContracts.NFTGemMultiToken.safeTransferFrom(
      sender.address,
      prop.address,
      BigNumber.from(prop.address),
      tokenBalance,
      0
    );

    const bal = await provider.getBalance(sender.address);
    expect(await prop.status()).to.equal(2);
    await prop.execute();
    expect(await prop.status()).to.equal(4);
    const bal2 = await provider.getBalance(sender.address);
    expect(bal.lt(bal2)).to.be.true;
  });

  it('Should go through a successful modify allowlist proposal creation', async function () {
    const dc = deployedContracts;

    const lpla = await dc.NFTGemPoolFactory.allNFTGemPoolsLength();
    const poolEl = await dc.NFTGemPoolFactory.allNFTGemPools(lpla.sub(1));


    dc.NFTGemGovernor.createUpdateAllowlistProposal(
      sender.address,
      'Take me money - pleaese',
      '0x11111111aaaaaaaabbbbbbbb2222222200000000',
      poolEl,
      true
    );

    const hash = keccak256(
      ['bytes'],
      [pack(['address', 'string'], [sender.address, 'Take me money - pleaese'])]
    );

    const feeManageAddress = dc.NFTGemFeeManager.address;
    const lpl = await dc.ProposalFactory.allProposalsLength();
    const element = await dc.ProposalFactory.allProposals(lpl.sub(1));
    const prophash = await dc.ProposalFactory.getProposal(hash);
    expect(element.toString()).to.equal(prophash.toString());
    const prop = (deployedContracts.proposal = await getContractAt(
      'Proposal',
      element,
      sender
    ));

    expect(await prop.title()).to.equal('Take me money - pleaese');
    expect(await prop.status()).to.equal(0);

    await sender.sendTransaction({ to: feeManageAddress,  value:utils.parseEther('1.1') });
    await prop.fund({value: utils.parseEther('1')});
    expect(await prop.status()).to.equal(1);

    const tokenBalance = await deployedContracts.NFTGemMultiToken.balanceOf(
      sender.address,
      prop.address
    );
    await deployedContracts.NFTGemMultiToken.safeTransferFrom(
      sender.address,
      prop.address,
      BigNumber.from(prop.address),
      tokenBalance,
      0
    );

    const bal = await provider.getBalance(sender.address);
    expect(await prop.status()).to.equal(2);
    await prop.execute();
    expect(await prop.status()).to.equal(4);

    const bal2 = await provider.getBalance(sender.address);
    expect(bal.lt(bal2)).to.be.true;
  });

  it('Should create a Proposal', async function () {

    // deploy
    const dc = deployedContracts;

    dc.NFTGemGovernor.createNewPoolProposal(
      sender.address,
      'Proposal Title',
      'TST',
      'Test Gem',
      utils.parseEther('1'),
      86400,
      864000,
      1000,
      0,
      ZERO_ADDRESS
    );

    expect((await dc.ProposalFactory.allProposalsLength()).toNumber()).to.equal(
      1
    );

    const hash = keccak256(
      ['bytes'],
      [pack(['address', 'string'], [sender.address, 'Proposal Title'])]
    );

    const element = await dc.ProposalFactory.allProposals(0);
    const prophash = await dc.ProposalFactory.getProposal(hash);

    expect(element.toString()).to.equal(prophash.toString());

    const prop = (await getContractAt(
      'Proposal',
      prophash,
      sender
    ));
    deployedContracts.proposal = prop;

    expect(await prop.title()).to.equal('Proposal Title');
    expect(await prop.status()).to.equal(0);
  });

  it('Should reject less than 1 ETH funding for proposal', async function () {
    let didError = false;
    try {
      await deployedContracts.proposal.fund({value: utils.parseEther('0.9')});
    } catch (e) {
      didError = true;
    }
    expect(didError).to.equal(true);
  });

  it('Should reject executing proposal', async function () {
    let didError = false;
    try {
      await deployedContracts.proposal.execute();
    } catch (e) {
      didError = true;
    }
    expect(didError).to.equal(true);
  });

  it('Should reject closing proposal', async function () {
    let didError = false;
    try {
      await deployedContracts.proposal.close();
    } catch (e) {
      didError = true;
    }
    expect(didError).to.equal(true);
  });

  it('Should accept 1 ETH funding for proposal and move status to ACTIVE', async function () {
    await deployedContracts.proposal.fund({value: utils.parseEther('1')});
    expect(await deployedContracts.proposal.status()).to.equal(1);
  });

  it('Should reject more ETH', async function () {
    let error = false;
    try {
      await deployedContracts.proposal.fund({value: utils.parseEther('1')});
    } catch (e) {
      error = true;
    }
    expect(error).to.be.true;
  });

  it('Should reject executing proposal', async function () {
    let didError = false;
    try {
      await deployedContracts.proposal.execute();
    } catch (e) {
      didError = true;
    }
    expect(didError).to.equal(true);
  });

  it('Should reject closing proposal', async function () {
    let didError = false;
    try {
      await deployedContracts.proposal.close();
    } catch (e) {
      didError = true;
    }
    expect(didError).to.equal(true);
  });

  it('Should have generated and delivered vote tokens', async function () {
    const hash = keccak256(
      ['bytes'],
      [pack(['address', 'string'], [sender.address, 'Proposal Title'])]
    );
    const propAddress = await deployedContracts.ProposalFactory.getProposal(
      hash
    );
    console.log(propAddress);
    const tokenBalance = await deployedContracts.NFTGemMultiToken.balanceOf(
      sender.address,
      propAddress
    );
    expect(tokenBalance.toNumber()).to.not.equal(0);
  });

  it('Should change status of proposal to PASSED when vote tokens are delivered to proposal', async function () {
    const hash = keccak256(
      ['bytes'],
      [pack(['address', 'string'], [sender.address, 'Proposal Title'])]
    );
    const propAddress = await deployedContracts.ProposalFactory.getProposal(
      hash
    );
    const tokenBalance = await deployedContracts.NFTGemMultiToken.balanceOf(
      sender.address,
      propAddress
    );
    expect(tokenBalance.toNumber()).to.not.equal(0);
    await deployedContracts.NFTGemMultiToken.safeTransferFrom(
      sender.address,
      propAddress,
      BigNumber.from(propAddress),
      tokenBalance,
      0
    );
    const receiverBalance = await deployedContracts.NFTGemMultiToken.balanceOf(
      propAddress,
      propAddress
    );
    expect(receiverBalance.toNumber()).to.not.equal(0);
    expect(await deployedContracts.proposal.status()).to.equal(2);
  });

  it('Should successfully execute proposal and receive ETH back', async function () {
    const ap = await deployedContracts.NFTGemPoolFactory.allNFTGemPoolsLength();

    const bb = await provider.getBalance(sender.address);
    await deployedContracts.proposal.execute();
    const ba = await provider.getBalance(sender.address);

    expect(
      await deployedContracts.NFTGemPoolFactory.allNFTGemPoolsLength()
    ).to.equal(ap.add(1).toNumber());
    expect(await deployedContracts.proposal.status()).to.equal(4);
    expect(ba.gt(bb)).to.be.true;
  });

  it('Should not allow executing an executed proposal', async function () {
    let didError = false;
    try {
      await deployedContracts.proposal.execute();
    } catch (e) {
      didError = true;
    }
    expect(didError).to.be.true;
  });

  it('Should not allow closing an executed proposal', async function () {
    let didError = false;
    try {
      await deployedContracts.proposal.close();
    } catch (e) {
      didError = true;
    }
    expect(didError).to.be.true;
  });

  it('Should go through a successful change fee proposal creation', async function () {
    const dc = deployedContracts;

    const dlen = await deployedContracts.NFTGemPoolFactory.allNFTGemPoolsLength();
    const pool = await deployedContracts.NFTGemPoolFactory.allNFTGemPools(
      dlen.sub(1)
    );

    dc.NFTGemGovernor.createChangeFeeProposal(
      sender.address,
      'Please gimme me money - pleaese',
      '0x0000000000000000000000000000000000000000',
      pool,
      10
    );

    const hash = keccak256(
      ['bytes'],
      [
        pack(
          ['address', 'string'],
          [sender.address, 'Please gimme me money - pleaese']
        ),
      ]
    );

    const lpl = await dc.ProposalFactory.allProposalsLength();
    const element = await dc.ProposalFactory.allProposals(lpl.sub(1));
    const prophash = await dc.ProposalFactory.getProposal(hash);
    expect(element.toString()).to.equal(prophash.toString());
    const prop = await getContractAt('Proposal', element, sender);

    expect(await prop.title()).to.equal('Please gimme me money - pleaese');
    expect(await prop.status()).to.equal(0);

    await prop.fund({value: utils.parseEther('1')});
    expect(await prop.status()).to.equal(1);

    const tokenBalance = await deployedContracts.NFTGemMultiToken.balanceOf(
      sender.address,
      prop.address
    );
    await deployedContracts.NFTGemMultiToken.safeTransferFrom(
      sender.address,
      prop.address,
      BigNumber.from(prop.address),
      tokenBalance,
      0
    );

    expect(await prop.status()).to.equal(2);
    await prop.execute();
    expect(await prop.status()).to.equal(4);

    const fd = await deployedContracts.NFTGemFeeManager.feeDivisor(pool);
    expect(fd.toNumber()).to.equal(10);
  });

  it('Should go through a successful new project proposal creation', async function () {
    const dc = deployedContracts;

    dc.NFTGemGovernor.createFundProjectProposal(
      sender.address,
      'Give me money - pleaese',
      sender.address,
      'link',
      utils.parseEther('1')
    );

    const hash = keccak256(
      ['bytes'],
      [pack(['address', 'string'], [sender.address, 'Give me money - pleaese'])]
    );

    const feeManageAddress = dc.NFTGemFeeManager.address;
    const lpl = await dc.ProposalFactory.allProposalsLength();
    const element = await dc.ProposalFactory.allProposals(lpl.sub(1));
    const prophash = await dc.ProposalFactory.getProposal(hash);
    expect(element.toString()).to.equal(prophash.toString());
    const prop = (deployedContracts.proposal = await getContractAt(
      'Proposal',
      element,
      sender
    ));

    expect(await prop.title()).to.equal('Give me money - pleaese');
    expect(await prop.status()).to.equal(0);

    await sender.sendTransaction({ to: feeManageAddress,  value:utils.parseEther('1.1') });
    await prop.fund({value: utils.parseEther('1')});
    expect(await prop.status()).to.equal(1);

    const tokenBalance = await deployedContracts.NFTGemMultiToken.balanceOf(
      sender.address,
      prop.address
    );
    await deployedContracts.NFTGemMultiToken.safeTransferFrom(
      sender.address,
      prop.address,
      BigNumber.from(prop.address),
      tokenBalance,
      0
    );

    const bal = await provider.getBalance(sender.address);
    expect(await prop.status()).to.equal(2);
    await prop.execute();
    expect(await prop.status()).to.equal(4);
    const bal2 = await provider.getBalance(sender.address);
    expect(bal.lt(bal2)).to.be.true;
  });

  it('Should go through a successful modify allowlist proposal creation', async function () {
    const dc = deployedContracts;

    const lpla = await dc.NFTGemPoolFactory.allNFTGemPoolsLength();
    const poolEl = await dc.NFTGemPoolFactory.allNFTGemPools(lpla.sub(1));


    dc.NFTGemGovernor.createUpdateAllowlistProposal(
      sender.address,
      'Take me money - pleaese',
      '0x11111111aaaaaaaabbbbbbbb2222222200000000',
      poolEl,
      true
    );

    const hash = keccak256(
      ['bytes'],
      [pack(['address', 'string'], [sender.address, 'Take me money - pleaese'])]
    );

    const feeManageAddress = dc.NFTGemFeeManager.address;
    const lpl = await dc.ProposalFactory.allProposalsLength();
    const element = await dc.ProposalFactory.allProposals(lpl.sub(1));
    const prophash = await dc.ProposalFactory.getProposal(hash);
    expect(element.toString()).to.equal(prophash.toString());
    const prop = (deployedContracts.proposal = await getContractAt(
      'Proposal',
      element,
      sender
    ));

    expect(await prop.title()).to.equal('Take me money - pleaese');
    expect(await prop.status()).to.equal(0);

    await sender.sendTransaction({ to: feeManageAddress,  value:utils.parseEther('1.1') });
    await prop.fund({value: utils.parseEther('1')});
    expect(await prop.status()).to.equal(1);

    const tokenBalance = await deployedContracts.NFTGemMultiToken.balanceOf(
      sender.address,
      prop.address
    );
    await deployedContracts.NFTGemMultiToken.safeTransferFrom(
      sender.address,
      prop.address,
      BigNumber.from(prop.address),
      tokenBalance,
      0
    );

    const bal = await provider.getBalance(sender.address);
    expect(await prop.status()).to.equal(2);
    await prop.execute();
    expect(await prop.status()).to.equal(4);

    const bal2 = await provider.getBalance(sender.address);
    expect(bal.lt(bal2)).to.be.true;
  });

});
