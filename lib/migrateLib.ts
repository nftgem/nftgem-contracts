import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {pack, keccak256} from '@ethersproject/solidity';
import publisher from './publishLib';
import {BigNumber} from 'ethers';

export default async function migrator(
  hre: HardhatRuntimeEnvironment,
  factoryAddress: string,
  tokenAddress: string
): Promise<any> {
  const {ethers} = hre;
  const {getContractAt} = ethers;

  console.log('Bitgem migration\n');
  const [sender] = await hre.ethers.getSigners();

  // get published artifacts
  const publishItems = await publisher(hre, false);
  const {deployedContracts, waitForMined, createPool, getPoolContract} =
      publishItems,
    dc = deployedContracts;

  // factory and token addresses
  const afactory = ethers.utils.getAddress(factoryAddress);
  const alegacyToken = ethers.utils.getAddress(tokenAddress);

  // get contracts - tokens and factories old and new
  const oldFactory = await getContractAt('NFTGemPoolFactory', afactory, sender);
  const oldToken = await getContractAt(
    'NFTGemMultiToken',
    alegacyToken,
    sender
  );
  const newToken = await getContractAt(
    'NFTGemMultiToken',
    dc.NFTGemMultiToken.address,
    sender
  );
  const newFactory = dc.NFTGemPoolFactory;

  // add the bulk token minter as a minter
  const tx = await newToken.addController(dc.BulkTokenMinter.address);
  await waitForMined(tx.hash);

  // go through each published gem pool in old gem pool factory
  const gpLen = await oldFactory.allNFTGemPoolsLength();
  for (let gp = 0; gp < gpLen.toNumber(); gp++) {
    const gpAddr = await oldFactory.allNFTGemPools(gp);
    const oldData = await getContractAt('INFTGemPoolData', gpAddr, sender);
    const sym = await oldData.symbol();
    // these are ded
    if (sym === 'AMAST' || sym === 'MCU') {
      continue;
    }

    // create the new gem pool using the old pools
    // current settings
    console.log(`processing pool symbol ${sym}`);
    let newGpAddr = await newFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], [sym])])
    );
    if (BigNumber.from(newGpAddr).eq(0)) {
      newGpAddr = await createPool(
        sym,
        await oldData.name(),
        await oldData.ethPrice(),
        await oldData.minTime(),
        await oldData.maxTime(),
        await oldData.difficultyStep(),
        await oldData.maxClaims(),
        '0x0000000000000000000000000000000000000000'
      );
    }
    if (BigNumber.from(newGpAddr).eq(0)) {
      console.log(`cant create pool symbol ${sym}`);
      continue;
    }

    const pc = await getPoolContract(newGpAddr);
    const nextGemId = await oldData.mintedCount();
    const nextClaimId = await oldData.claimedCount();

    // set the next-ids (claim, gem) to set pools current
    let tx = await pc.setNextIds(nextClaimId, nextGemId);
    await waitForMined(tx.hash);
    console.log(
      `${sym} next claim ${nextClaimId.toString()} next gem ${nextGemId.toString()}`
    );

    // add the legacy token as an allowed token source
    tx = await pc.addAllowedTokenSource(alegacyToken);
    await waitForMined(tx.hash);
    console.log(`${sym} added token source ${alegacyToken.toString()}`);

    // set the categpry to the address of the new
    tx = await pc.setCategory(oldToken);
    await waitForMined(tx.hash);

    console.log(`${sym} set category -${oldToken}`);
  }

  // get the length of old gov token hodlers
  const allGovTokenHolders = await oldToken.allTokenHoldersLength(0);
  console.log(`num holders: ${allGovTokenHolders.toNumber()}`);

  let holders = [],
    govQuantities = [];

  // process each gov token hodler
  for (let i = 0; i < allGovTokenHolders.toNumber(); i++) {
    const thAddr = await oldToken.allTokenHolders(0, i);
    const th0Bal = await oldToken.balanceOf(thAddr, 0);

    holders.push(thAddr);
    govQuantities.push(th0Bal);
    console.log(`${i} ${thAddr} ${th0Bal.toString()}`);

    // mint governance tokens in batches of ten
    if (i % 10 === 0 && holders.length > 1) {
      const tx = await dc.BulkTokenMinter.bulkMintGov(
        newToken.address,
        holders,
        govQuantities,
        {gasLimit: 5000000}
      );
      await waitForMined(tx.hash);
      holders = [];
      govQuantities = [];
    }
  }

  // mint any tokens not processed above
  if (holders.length > 0) {
    const tx = await dc.BulkTokenMinter.bulkMintGov(
      newToken.address,
      holders,
      govQuantities,
      {gasLimit: 5000000}
    );
    await waitForMined(tx.hash);
  }

  // we are done!
  console.log('Migration complete\n');

  return publishItems.deployedContracts;
}
