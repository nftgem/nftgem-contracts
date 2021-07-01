import {deployments} from 'hardhat';
import {pack, keccak256} from '@ethersproject/solidity';
import {setupNftGemGovernor} from './Governance.fixture';

export const setupERC20GemToken = deployments.createFixture(
  async ({ethers}) => {
    const {
      NFTGemGovernor,
      ProposalFactory,
      NFTGemMultiToken,
      NFTGemPoolFactory,
      NFTGemFeeManager,
      owner,
    } = await setupNftGemGovernor();
    const WrappedTokenLib = await (
      await ethers.getContractFactory('WrappedTokenLib')
    ).deploy();
    const ERC20GemTokenFactory = await (
      await ethers.getContractFactory('ERC20GemTokenFactory', {
        signer: owner,
        libraries: {
          WrappedTokenLib: WrappedTokenLib.address,
        },
      })
    ).deploy();
    return {
      NFTGemGovernor,
      ERC20GemTokenFactory,
      ProposalFactory,
      NFTGemPoolFactory,
      NFTGemMultiToken,
      NFTGemFeeManager,
    };
  }
);

export const createERC20Token = deployments.createFixture(
  async ({ethers}, data: any) => {
    const {
      NFTGemGovernor,
      ERC20GemTokenFactory,
      NFTGemPoolFactory,
      NFTGemMultiToken,
      NFTGemFeeManager,
    } = await setupERC20GemToken();

    const {poolData, tokenData} = data;

    await NFTGemGovernor.createSystemPool(
      poolData.symbol,
      poolData.name,
      poolData.ethPrice,
      poolData.minTime,
      poolData.maxTime,
      poolData.diffStep,
      poolData.maxClaims,
      poolData.allowedToken
    );
    const salt = keccak256(['bytes'], [pack(['string'], [poolData.symbol])]);
    const poolAddress = await NFTGemPoolFactory.getNFTGemPool(salt);

    await ERC20GemTokenFactory.createItem(
      tokenData.symbol,
      tokenData.name,
      poolAddress,
      NFTGemMultiToken.address,
      tokenData.decimals,
      NFTGemFeeManager.address
    );
    return {
      ERC20GemTokenFactory,
      NFTGemMultiToken,
      NFTGemFeeManager,
      poolAddress,
    };
  }
);

export const initializeERC20WrappedGem = deployments.createFixture(
  async ({ethers}, data: any) => {
    const {
      NFTGemGovernor,
      ProposalFactory,
      NFTGemMultiToken,
      NFTGemPoolFactory,
      NFTGemFeeManager,
      owner,
      sender,
    } = await setupNftGemGovernor();
    const WrappedTokenLib = await (
      await ethers.getContractFactory('WrappedTokenLib')
    ).deploy();
    const ERC20WrappedGem = await (
      await ethers.getContractFactory('ERC20WrappedGem', {
        signer: owner,
        libraries: {
          WrappedTokenLib: WrappedTokenLib.address,
        },
      })
    ).deploy();
    await NFTGemGovernor.createSystemPool(
      data.poolData.symbol,
      data.poolData.name,
      data.poolData.ethPrice,
      data.poolData.minTime,
      data.poolData.maxTime,
      data.poolData.diffStep,
      data.poolData.maxClaims,
      data.poolData.allowedToken
    );
    const salt = keccak256(
      ['bytes'],
      [pack(['string'], [data.poolData.symbol])]
    );
    const poolAddress = await NFTGemPoolFactory.getNFTGemPool(salt);

    await ERC20WrappedGem.initialize(
      data.tokenData.name,
      data.tokenData.symbol,
      poolAddress,
      NFTGemMultiToken.address,
      data.tokenData.decimals,
      NFTGemFeeManager.address
    );
    const tokenHash = keccak256(
      ['bytes'],
      [pack(['string'], [data.tokenData.symbol])]
    );

    // Mint some tokens to wrap gem tokens
    await NFTGemMultiToken.mint(sender.address, tokenHash, 100);
    await NFTGemMultiToken.setTokenData(tokenHash, 2, poolAddress);
    await NFTGemMultiToken.connect(sender).setApprovalForAll(
      ERC20WrappedGem.address,
      true
    );
    return {
      ERC20WrappedGem,
      NFTGemMultiToken,
      NFTGemFeeManager,
      poolAddress,
      owner,
      sender,
    };
  }
);

export const initializeNFTGemWrappedERC20Token = deployments.createFixture(
  async ({ethers}) => {
    const {
      NFTGemMultiToken,
      NFTGemFeeManager,
      owner,
      sender,
    } = await setupNftGemGovernor();
    const deployParams = [
      'NFTGem Fuel',
      'NFTGF',
      NFTGemMultiToken.address,
      NFTGemFeeManager.address,
    ];
    const NFTGemWrappedERC20Fuel = await (
      await ethers.getContractFactory('NFTGemWrappedERC20Fuel', owner)
    ).deploy(...deployParams);

    // Mint some tokens to wrap gem tokens
    await NFTGemMultiToken.mint(sender.address, 1, 10000);
    await NFTGemMultiToken.connect(sender).setApprovalForAll(
      NFTGemWrappedERC20Fuel.address,
      true
    );
    return {
      NFTGemWrappedERC20Fuel,
      NFTGemMultiToken,
      NFTGemFeeManager,
      sender,
    };
  }
);

export const initializeNFTGemERC20GovernanceToken = deployments.createFixture(
  async ({ethers}) => {
    const {
      NFTGemMultiToken,
      NFTGemFeeManager,
      owner,
      sender,
    } = await setupNftGemGovernor();
    const deployParams = [
      'NFTGem Governance',
      'NFTGG',
      NFTGemMultiToken.address,
      NFTGemFeeManager.address,
    ];
    const NFTGemERC20Governance = await (
      await ethers.getContractFactory('NFTGemWrappedERC20Governance', owner)
    ).deploy(...deployParams);

    // Mint some tokens to wrap gem tokens
    await NFTGemMultiToken.mint(sender.address, 0, 20000);
    await NFTGemMultiToken.connect(sender).setApprovalForAll(
      NFTGemERC20Governance.address,
      true
    );

    return {
      NFTGemERC20Governance,
      NFTGemMultiToken,
      NFTGemFeeManager,
      sender,
    }
  }
);
