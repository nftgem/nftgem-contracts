import hre from 'hardhat';
import {expect} from 'chai';
import {pack, keccak256} from '@ethersproject/solidity';

const {ethers, deployments, getUnnamedAccounts} = hre;
const {BigNumber, utils, provider, getContractAt} = ethers;
const {deploy, get} = deployments;
let sender: any;
let deploymentData: any,
  libDeployParams: any,
  deployParams: any,
  libs: any,
  deployedContracts: any;

describe('Proposal Factory Extended', function () {
  before(async function () {
    [sender] = await hre.ethers.getSigners();
    libDeployParams = {
      from: sender.address,
      log: true,
    };
    deployParams = {
      from: sender.address,
      log: true,
      libraries: {
        Strings: (await deploy('Strings', libDeployParams)).address,
        SafeMath: (await deploy('SafeMath', libDeployParams)).address,
        NFTGemLib: (await deploy('NFTGemLib', libDeployParams)).address,
        GovernanceLib: (await deploy('GovernanceLib', libDeployParams)).address,
        UniswapLib: (await deploy('UniswapLib', libDeployParams)).address,
        Create2: (await deploy('Create2', libDeployParams)).address,
      },
    };
    deploymentData = {
      NFTGemGovernor: await deploy('NFTGemGovernor', deployParams),
      NFTGemMultiToken: await deploy('NFTGemMultiToken', deployParams),
      NFTGemPoolFactory: await deploy('NFTGemPoolFactory', deployParams),
      NFTGemFeeManager: await deploy('NFTGemFeeManager', deployParams),
      ProposalFactory: await deploy('ProposalFactory', deployParams),
      //NFTGemPool: await deploy('NFTGemPool', deployParams),
    };
    deployedContracts = {
      NFTGemGovernor: await getContractAt(
        'NFTGemGovernor',
        deploymentData.NFTGemGovernor.address,
        sender
      ),
      NFTGemMultiToken: await getContractAt(
        'NFTGemMultiToken',
        deploymentData.NFTGemMultiToken.address,
        sender
      ),
      NFTGemPoolFactory: await getContractAt(
        'NFTGemPoolFactory',
        deploymentData.NFTGemPoolFactory.address,
        sender
      ),
      NFTGemFeeManager: await getContractAt(
        'NFTGemFeeManager',
        deploymentData.NFTGemFeeManager.address,
        sender
      ),
      ProposalFactory: await getContractAt(
        'ProposalFactory',
        deploymentData.ProposalFactory.address,
        sender
      ),
    };
  });

  it('Should create', async function () {
    const dc = deployedContracts;
    await dc.NFTGemGovernor.initialize(
      dc.NFTGemMultiToken.address,
      dc.NFTGemPoolFactory.address,
      dc.NFTGemFeeManager.address,
      dc.ProposalFactory.address
    );
    await dc.NFTGemMultiToken.addController(dc.NFTGemGovernor.address);
    await dc.NFTGemPoolFactory.addController(dc.NFTGemGovernor.address);
    await dc.ProposalFactory.addController(dc.NFTGemGovernor.address);
    await dc.NFTGemFeeManager.setOperator(dc.NFTGemGovernor.address);
    await dc.NFTGemGovernor.issueInitialGovernanceTokens(sender.address);
    const sa = sender.address;
    const ip = utils.parseEther('1');
    const ds = 86400;
    const ms = ds * 30;
    await dc.NFTGemGovernor.createPool(
      sa,
      sa,
      'BERY',
      'Berry',
      ip,
      ds,
      ms,
      8,
      0
    );

    await dc.NFTGemMultiToken.relinquishControl();
    await dc.NFTGemPoolFactory.relinquishControl();
    await dc.NFTGemGovernor.relinquishControl();
    await dc.ProposalFactory.relinquishControl();
  });

  it('Should reject less than 1 ETH funding for proposal', async function () {

    for (let i = 0; i < 1000; i++) {
      const h = BigNumber.from(keccak256(
        ['bytes'],
        [pack(['string'], [`Thisi${i-3}s is a sample${i+7} sting seed fdasln ${i}`])]
      ))
      deployedContracts.NFTGemGovernor.checkHash(
        h
      );
    }

  });
});
