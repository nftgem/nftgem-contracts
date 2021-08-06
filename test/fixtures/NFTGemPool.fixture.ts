import {deployments} from 'hardhat';
import {pack, keccak256} from '@ethersproject/solidity';
import {setupNftGemGovernor} from './Governance.fixture';

export const setupNFTGemPool = deployments.createFixture(async () => {
  return await setupNftGemGovernor();
});

export const createNFTGemPool = deployments.createFixture(
  async ({ethers}, data: any) => {
    // get the NFT gem pool contracts
    const {
      NFTGemGovernor,
      ERC20GemTokenFactory,
      NFTGemPoolFactory,
      NFTGemMultiToken,
      NFTGemFeeManager,
      owner
    } = await setupNFTGemPool();

    const {poolData, tokenData} = data;
    let tokenAddress;

    // try to find an existing pool with the given symbol
    const salt = keccak256(['bytes'], [pack(['string'], [poolData.symbol])]);
    let poolAddress = await NFTGemPoolFactory.getNFTGemPool(salt);
    if (poolAddress === ethers.constants.AddressZero) {
      // if one is not found then create it
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
      // get the new gem pool address
      poolAddress = await NFTGemPoolFactory.getNFTGemPool(salt);
      // create a wrapped gem token
      await ERC20GemTokenFactory.createItem(
        tokenData.symbol,
        tokenData.name,
        poolAddress,
        NFTGemMultiToken.address,
        tokenData.decimals,
        NFTGemFeeManager.address
      );
      // get the wrapped token address
      const tokenIndex = await ERC20GemTokenFactory.allItemsLength();
      tokenAddress = await ERC20GemTokenFactory.allItems(tokenIndex.sub(1));
    } else {
      // get the wrapped token address
      const salt = keccak256(['bytes'], [pack(['string'], [tokenData.symbol])]);
      tokenAddress = await ERC20GemTokenFactory.getItem(salt);
    }
    // get a reference to the newly-created gem pool
    const NFTComplexGemPool = await ethers.getContractAt(
      'NFTComplexGemPool',
      poolAddress,
      owner
    );

    const ERC20WrappedGem = await ethers.getContractAt(
      'ERC20WrappedGem',
      tokenAddress,
      owner
    );
    
    // Wrap some gems to get ERC20 tokens
    await NFTGemMultiToken.setApprovalForAll(tokenAddress, true);
    await ERC20WrappedGem.wrap(2);
    // Transfer some ERC20 tokens to the gempool contract
    await ERC20WrappedGem.transfer(NFTComplexGemPool.address, 1000000);
    return {
      NFTGemPoolFactory,
      ERC20GemTokenFactory,
      NFTGemMultiToken,
      NFTGemFeeManager,
      NFTComplexGemPool,
      ERC20WrappedGem,
      poolAddress,
      tokenAddress,
      owner,
    };
  }
);

export const createNFTGemClaim = deployments.createFixture(
  async ({ethers}, data: any) => {
    const {
      NFTGemPoolFactory,
      ERC20GemTokenFactory,
      NFTGemMultiToken,
      NFTGemFeeManager,
      NFTComplexGemPool,
      poolAddress,
      tokenAddress,
      owner,
    } = await createNFTGemPool();

    return new ethers.Contract(poolAddress, []);
  }
);

export const createNFTGem = deployments.createFixture(
  async ({ethers}, data: any) => {}
);
