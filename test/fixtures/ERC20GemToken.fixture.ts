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
      poolAddress
    };
  }
);
