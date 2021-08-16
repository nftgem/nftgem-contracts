import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { pack, keccak256 } from '@ethersproject/solidity';
import publisher from './publishLib';
import { BigNumber, Contract } from 'ethers';
import { formatEther } from '@ethersproject/units';

export default async function migrator(
  hre: HardhatRuntimeEnvironment,
  factoryAddress: string,
  tokenAddress: string,
  accountAddress?: string | boolean,
  migrateGovernance?: boolean,
  migrateGems?: boolean
): Promise<any> {
  const { ethers } = hre;
  const { getContractAt } = ethers;

  console.log('Bitgem migration\n');
  const [sender] = await hre.ethers.getSigners();

  // get published artifacts
  const publishItems = await publisher(hre, false);
  const { deployedContracts } = publishItems,
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

  // if an account address was given then migrate the accounts gems
  if (accountAddress) {
    const migrateOne = async (accountAddress: string) => {
      // get all nft gem pool addresses
      const gemPoolsLen = await oldFactory.allNFTGemPoolsLength();
      let gemPools = [];
      for (let i = 0; i < gemPoolsLen.toNumber(); i++) {
        gemPools.push(oldFactory.allNFTGemPools(i));
      }
      gemPools = await Promise.all(gemPools);
      (
        await Promise.all(
          gemPools.map(async (gp: string) =>
            hre.ethers.getContractAt('NFTComplexGemPoolData', gp)
          )
        )
      ).forEach(async (poolContract: any) => {
        const symbol = await poolContract.symbol();
        const poolHash = keccak256(['bytes'], [pack(['string'], [symbol])]);
        const newPoolAddress = await newFactory.getNFTGemPool(poolHash);
        if (newPoolAddress.eq(0)) {
          console.log(`Could not find NFTGemPool for ${symbol}`);
          return;
        }
        const newPoolContract = await hre.ethers.getContractAt(
          'NFTComplexGemPoolData',
          newPoolAddress
        );

        // get all token hashes for pool
        const tokenHashesLen = await poolContract.allTokenHashesLength();
        let allTokenHashes: any = [];
        for (let i = 0; i < tokenHashesLen.toNumber(); i++) {
          allTokenHashes.push(poolContract.allTokenHashes(i));
        }
        allTokenHashes = await Promise.all(allTokenHashes);
        // get balance for given owner address fpr all tokens
        const tokenBalances = await Promise.all(
          allTokenHashes.map((th: BigNumber) =>
            oldToken.balanceOf(accountAddress, th)
          )
        );

        // get the token types for only non-zero balances
        let tokenTypes: any = [];
        const balances: any = [];
        let recipientTokens: any = [];
        tokenBalances.forEach((bal: any, i) => {
          if (!bal.eq(0)) {
            recipientTokens.push(allTokenHashes[i]);
            tokenTypes.push(poolContract.tokenType(allTokenHashes[i]));
            balances.push(bal);
          }
        });
        if (recipientTokens.length === 0) return;
        tokenTypes = await Promise.all(tokenTypes);

        recipientTokens = recipientTokens
          .filter((rt: any, j: any) => tokenTypes[j] === 2)
          .forEach(async (hash: any) => {
            const tx = await newPoolContract.importLegacyGem(
              poolContract.address,
              alegacyToken,
              hash,
              accountAddress
            );
            console.log(tx);
          });
      });
    };
    if (typeof accountAddress === 'string') {
      await migrateOne(accountAddress);
    }
  } else {
    // go through each published gem pool in old gem pool factory
    const gpLen = await oldFactory.allNFTGemPoolsLength();
    for (let gp = 0; gp < gpLen.toNumber(); gp++) {
      const gpAddr = await oldFactory.allNFTGemPools(gp);
      const oldData = await getContractAt('INFTGemPoolData', gpAddr, sender);
      const sym = await oldData.symbol();
      // these are ded
      if (
        sym === 'AMAST' ||
        sym === 'MCU' ||
        sym === 'STIK' ||
        sym === 'ROCK'
      ) {
        continue;
      }

      // create the new gem pool using the old pools
      // current settings
      console.log(`processing pool symbol ${sym}`);
      let newGpAddr = await newFactory.getNFTGemPool(
        keccak256(['bytes'], [pack(['string'], [sym])])
      );
      if (BigNumber.from(newGpAddr).eq(0)) {


        const oldName = (await oldData.name()).replace('BoujaBonga', 'Boojabaunga');

        newGpAddr = await publishItems.createPool(
          sym,
          oldName,
          await oldData.ethPrice(),
          await oldData.minTime(),
          await oldData.maxTime(),
          await oldData.difficultyStep(),
          await oldData.maxClaims(),
          '0x0000000000000000000000000000000000000000',
          { gasLimit: 8000000 }
        );
      }
      if (BigNumber.from(newGpAddr).eq(0)) {
        console.log(`cant create pool symbol ${sym}`);
        continue;
      }

      const pc = await publishItems.getPoolContract(newGpAddr);
      const nextGemId = await oldData.mintedCount();
      const nextClaimId = await oldData.claimedCount();

      // set the next-ids (claim, gem) to set pools current
      let tx = await pc.setNextIds(nextClaimId, nextGemId);
      await hre.ethers.provider.waitForTransaction(tx.hash, 1);
      console.log(
        `${sym} next claim ${nextClaimId.toString()} next gem ${nextGemId.toString()}`
      );

      // add the legacy token as an allowed token source
      tx = await pc.addAllowedTokenSource(alegacyToken);
      await hre.ethers.provider.waitForTransaction(tx.hash, 1);
      // add the new gem pool as a controller of old
      // token so that it can burn imported gems
      tx = await oldToken.addController(newGpAddr);
      await hre.ethers.provider.waitForTransaction(tx.hash, 1);
      console.log(`${sym} added token source ${alegacyToken.toString()}`);

      // set the categpry to the address of the new
      tx = await pc.setCategory(oldToken.address);
      await hre.ethers.provider.waitForTransaction(tx.hash, 1);

      console.log(`${sym} set category: ${oldToken.address}`);

      if (migrateGems) {
        // get all token hashes for pool
        console.log(`get all token hashes`);
        const tokenHashesLen = await oldData.allTokenHashesLength();
        let allTokenHashes: any = [];
        for (let i = 0; i < tokenHashesLen.toNumber(); i++) {
          allTokenHashes.push(oldData.allTokenHashes(i));
        }
        allTokenHashes = await Promise.all(allTokenHashes);

        // now get the token types for those token hashes
        console.log(`get all token types`);
        let allTokenTypes: any = [];
        for (let i = 0; i < allTokenHashes.length; i++) {
          allTokenTypes.push(oldData.tokenType(allTokenHashes[i]));
        }
        allTokenTypes = await Promise.all(allTokenTypes);

        // get just the gems for the pool
        console.log(`keep just the gems`);
        const allGems: any = [];
        allTokenTypes.forEach((type: any, i: any) => {
          if (type === 2) {
            allGems.push(allTokenHashes[i]);
          }
        });

        // iterate through all gems and import them
        console.log(`go through each gem`);
        for (let jj = 0; jj < allGems.length; jj++) {
          const hash = allGems[jj];
          console.log(`gem ${hash}`);

          // get the token hodlers for the gem
          console.log(`gem ${hash} get all toekn hodlers`);
          const tokenHoldersLen = await oldToken.allTokenHoldersLength(hash);
          let allTokenHolders: any = [];
          for (let i = 0; i < tokenHoldersLen.toNumber(); i++) {
            allTokenHolders.push(oldToken.allTokenHolders(hash, i));
          }
          allTokenHolders = (await Promise.all(allTokenHolders)).reduce(
            (acc: any, cur: any) => acc.concat(cur),
            []
          );
          console.log(`gem ${hash} for each hodler`);
          for (let kk = 0; kk < allTokenHolders.length; kk++) {
            const holder = allTokenHolders[kk];
            console.log(`gem ${hash} hodler ${holder}`);
            const tx = await pc.importLegacyGem(
              pc.address,
              alegacyToken,
              hash,
              holder,
              false,
              { gasLimit: 5000000 }
            );
            await hre.ethers.provider.waitForTransaction(tx.hash, 1);
          }
        }
      }
    }

    if (migrateGovernance) {
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

        // send governance tokens in batches of ten
        if (i % 10 === 0 && holders.length > 1) {
          const tx = await dc.BulkGovernanceTokenMinter.bulkMint(
            newToken.address,
            holders,
            govQuantities,
            { gasLimit: 5000000 }
          );
          await hre.ethers.provider.waitForTransaction(tx.hash, 1);
          holders = [];
          govQuantities = [];
        }
      }

      // mint any tokens not processed above
      if (holders.length > 0) {
        const tx = await dc.BulkGovernanceTokenMinter.bulkMint(
          newToken.address,
          holders,
          govQuantities,
          { gasLimit: 5000000 }
        );
        await hre.ethers.provider.waitForTransaction(tx.hash, 1);

      }

      for (let i = 0; i < allGovTokenHolders.toNumber(); i++) {
        const thAddr = await oldToken.allTokenHolders(0, i);
        const th0Bal = await oldToken.balanceOf(thAddr, 0);
        const tx = await oldToken.burn(
          thAddr,
          0,
          th0Bal,
          { gasLimit: 5000000 }
        );
        await hre.ethers.provider.waitForTransaction(tx.hash, 1);
      }
    }
  }
  // we are done!
  console.log('Migration complete\n');

  return publishItems.deployedContracts;
}
