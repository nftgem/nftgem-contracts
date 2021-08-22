import {ethers, deployments} from 'hardhat';
import {pack, keccak256} from '@ethersproject/solidity';
import {setupNftGemGovernor} from './Governance.fixture';
import {BigNumber} from 'ethers';

type PoolData = {
  symbol: string;
  name: string;
  ethPrice: BigNumber;
  minTime: number;
  maxTime: number;
  diffStep: number;
  maxClaims: number;
  allowedToken: string;
};

type TokenData = {
  symbol: string;
  name: string;
  decimals: number;
};
type Data = {
  poolData: PoolData;
  tokenData: TokenData;
};

export const setupNFTGemPool = deployments.createFixture(async () => {
  return await setupNftGemGovernor();
});

export const createPool = async (poolData: PoolData): Promise<string> => {
  const {NFTGemGovernor, NFTGemPoolFactory} = await setupNFTGemPool();
  const salt = keccak256(['bytes'], [pack(['string'], [poolData.symbol])]);
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
  const poolAddress = await NFTGemPoolFactory.getNFTGemPool(salt);
  return poolAddress;
};

export const createWrappedGemToken = deployments.createFixture(
  async ({ethers}, data: any) => {
    const {
      ERC20GemTokenFactory,
      NFTGemMultiToken,
      NFTGemFeeManager,
      NFTGemPoolFactory,
    } = await setupNFTGemPool();
    const {poolData, tokenData} = data;
    let poolAddress, tokenAddress;

    // try to find an existing pool with the given symbol
    const salt = keccak256(['bytes'], [pack(['string'], [poolData.symbol])]);
    poolAddress = await NFTGemPoolFactory.getNFTGemPool(salt);
    if (poolAddress === ethers.constants.AddressZero) {
      poolAddress = await createPool(poolData);
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
    return {poolAddress, tokenAddress};
  }
);

export const flashLoanSetup = deployments.createFixture(
  async ({ethers}, data: any) => {
    const {
      NFTGemGovernor,
      ERC20GemTokenFactory,
      NFTGemPoolFactory,
      NFTGemMultiToken,
      NFTGemFeeManager,
      owner,
    } = await setupNFTGemPool();
    const {poolAddress, tokenAddress} = await createWrappedGemToken(data);
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
      NFTGemGovernor,
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

export const getGemHash = (hash: number, poolAddress: string): string => {
  return ethers.utils.keccak256(
    ethers.utils.solidityPack(
      ['string', 'address', 'uint'],
      ['gem', poolAddress, hash]
    )
  );
};

export const createSwapMeetOffer = deployments.createFixture(
  async ({ethers}, data: any) => {
    const {SwapMeet, NFTGemMultiToken, owner, sender} = await setupNFTGemPool();
    const acceptAddr = sender;
    const {poolData} = data;
    const poolAddress = await createPool(poolData);
    // get a reference to the newly-created gem pool
    const NFTComplexGemPool = await ethers.getContractAt(
      'NFTComplexGemPool',
      poolAddress,
      owner
    );
    await NFTComplexGemPool.setAllowPurchase(true);
    // Purchase some gems
    await NFTComplexGemPool.connect(acceptAddr).purchaseGems(3, {
      value: ethers.utils.parseEther('4'),
    });
    const gemHash0 = getGemHash(0, poolAddress);
    const gemHash1 = getGemHash(1, poolAddress);
    const gemHash2 = getGemHash(2, poolAddress);
    // Create an offer
    await SwapMeet.registerOffer(
      poolAddress,
      gemHash0,
      1,
      [poolAddress],
      [gemHash2], // Allowed gems for swapping
      [1],
      1, // random
      {value: ethers.utils.parseEther('1')}
    );
    const offerId = (await SwapMeet.listOfferIds())[0].toString();
    // Approval for tranferring gems from offer acceptor to offer creator
    await NFTGemMultiToken.connect(acceptAddr).setApprovalForAll(SwapMeet.address, true);
    // Approval for tranferring gems from offer creator to offer acceptor
    await NFTGemMultiToken.connect(owner).setApprovalForAll(SwapMeet.address, true);
    return {
      SwapMeet,
      NFTComplexGemPool,
      poolAddress,
      offerId,
      gemHash0,
      gemHash1,
      gemHash2,
      owner,
      acceptAddr
    };
  }
);
