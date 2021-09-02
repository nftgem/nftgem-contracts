import { HardhatRuntimeEnvironment } from 'hardhat/types';

import { task } from 'hardhat/config';

import fs, { writeFileSync } from 'fs';

import 'dotenv/config';
import { HardhatUserConfig } from 'hardhat/types';

import 'hardhat-deploy';
import 'hardhat-deploy-ethers';
import 'hardhat-spdx-license-identifier';
import 'hardhat-contract-sizer';
import 'hardhat-abi-exporter';
import 'hardhat-gas-reporter';
import 'hardhat-typechain';
import 'hardhat-watcher';

import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-solhint';
import '@nomiclabs/hardhat-ganache';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-etherscan';

import { node_url, accounts } from './utils/network';
import { BigNumber } from 'ethers';
import { pack, keccak256 } from '@ethersproject/solidity';

import publish from './lib/publishLib';
import lootbox, { Lootbox, Loot } from './lib/lootboxLib';
import migrator from './lib/migrateLib';
import { formatEther, parseEther } from '@ethersproject/units';
import { info } from 'console';

//import * as NFTGemPoolFactory from './build/INFTGemPoolFactory.json';

task('check-fees', 'Check the fee manager balance').setAction(
  async (_, hre: HardhatRuntimeEnvironment) => {
    // get the fee manager contract
    const bitgemFeeManager = await hre.ethers.getContractAt(
      'NFTGemFeeManager',
      (
        await hre.deployments.get('NFTGemFeeManager')
      ).address
    );
    const bg = await bitgemFeeManager.ethBalanceOf();
    console.log(
      new Date().getTime(),
      `${bitgemFeeManager.address} = ${hre.ethers.utils.formatEther(bg)}`
    );
  }
);

task('held-tokens', 'Get a list of held tokens for the given address')
  .addParam('address', 'The token holder address')
  .setAction(async ({ address }, hre: HardhatRuntimeEnvironment) => {
    // get the fee manager contract
    const multitoken = await hre.ethers.getContractAt(
      'NFTGemMultiToken',
      (
        await hre.deployments.get('NFTGemMultiToken')
      ).address
    );
    const allTokens = await multitoken.heldTokens(address);
    for (let i = 0; i < allTokens.length; i++) {
      const val = allTokens[i];
      if (val.eq(0) || val.eq(1)) continue;
      console.log(val.toHexString());
    }
  });

task(
  'list-legacy-pools',
  'index all legacy pools for given factory and multitoken'
)
  .addParam('factory', 'The legacy factory address')
  .addParam('multitoken', 'The legacy multitoken address')
  .setAction(
    async ({ factory, multitoken }, hre: HardhatRuntimeEnvironment) => {
      // get all gempool contracts
      const factoryContract: any = await hre.ethers.getContractAt(
        'NFTGemPoolFactory',
        factory
      );

      // get length of all gempools, load gempool calls into array
      // use Promise.all to load all the addresses at once
      let poolsArray: any = [];
      const poolcount = await factoryContract.allNFTGemPoolsLength();
      for (let i = 0; i < poolcount.toNumber(); i++) {
        poolsArray.push(factoryContract.allNFTGemPools(i));
      }
      // get all gem pool data contracts
      poolsArray = await Promise.all(poolsArray);
      console.log(poolsArray);
    });

task(
  'token-holders',
  'Get a list of token holder addresses for the given token hash'
)
  .addParam('hash', 'The token hash')
  .setAction(async ({ hash }, hre: HardhatRuntimeEnvironment) => {
    // get the fee manager contract
    const multitoken = await hre.ethers.getContractAt(
      'NFTGemMultiToken',
      (
        await hre.deployments.get('NFTGemMultiToken')
      ).address
    );
    const allHodlers = await multitoken.tokenHolders(hash);
    for (let i = 0; i < allHodlers.length; i++) {
      const val = allHodlers[i];
      if (val.eq(0)) continue;
      console.log(val.toHexString());
    }
  });

task('list-gem-pools', 'Lists all current gem pools').setAction(
  async (args, hre: HardhatRuntimeEnvironment) => {
    // get the gem pool factory
    const gemPoolFactory = await hre.ethers.getContractAt(
      'NFTGemPoolFactory',
      (
        await hre.deployments.get('NFTGemPoolFactory')
      ).address
    );

    // get all gem pool addresses
    const gemPools = await gemPoolFactory.allNFTGemPoolsLength();
    // iterate through all contracts
    // and output symbol and address
    const out: any = [];
    for (let i = 0; i < gemPools.toNumber(); i++) {
      const gemPool = await gemPoolFactory.allNFTGemPools(i);
      const gemPoolO = await hre.ethers.getContractAt(
        'NFTComplexGemPool',
        gemPool
      );
      const sym = await gemPoolO.symbol();
      out.push([sym, gemPool]);
    }
    console.log(JSON.stringify(out, null, 4));
  }
);

// task('list-gem-pools-for', 'Lists all current gem pools')
//   .addParam('address', 'The gem pool address')
//   .setAction(async ({ address }, hre: HardhatRuntimeEnvironment) => {
//     // get the gem pool factory
//     const gemPoolFactory = await hre.ethers.getContractAt(
//       'NFTGemPoolFactory',
//       address
//     );

//     // get all gem pool addresses
//     const gemPools = await gemPoolFactory.allNFTGemPoolsLength();
//     const abi2 = require('./nftgem-ui/abis-legacy/INFTGemPoolData.json')
//     // iterate through all contracts
//     // and output symbol and address
//     const out: any = [];
//     for (let i = 0; i < gemPools.toNumber(); i++) {
//       const gemPool = await gemPoolFactory.allNFTGemPools(i);
//       const gemPoolO = await hre.ethers.getContractAt(
//         'NFTComplexGemPool',
//         gemPool
//       );
//       const sym = await gemPoolO.symbol();
//       out.push([sym, gemPool]);
//     }
//     console.log(JSON.stringify(out, null, 4));
//   }
//   );

task('pool-tokens', 'show pool tokens for given pool')
  .addParam('address', 'The pool address')
  .setAction(async ({ address }, hre: HardhatRuntimeEnvironment) => {
    // get all gempool contracts
    const poolContract: any = await hre.ethers.getContractAt(
      'NFTComplexGemPoolData',
      address
    );
    const symbol = await poolContract.symbol();
    let tokenHashes = await poolContract.tokenHashes();
    tokenHashes = tokenHashes.map((th: BigNumber) => th.toHexString());
    console.log(symbol, tokenHashes);
  });

task('pool-tokens-for', 'show pool tokens for given pool held by given address')
  .addParam('address', 'The pool address')
  .addParam('owner', 'The owner address')
  .setAction(async ({ address, owner }, hre: HardhatRuntimeEnvironment) => {
    // get all gempool contracts
    const poolContract: any = await hre.ethers.getContractAt(
      'NFTComplexGemPoolData',
      address
    );
    // get all gempool contracts
    const multitoken: any = await hre.ethers.getContractAt(
      'NFTGemMultiToken',
      (
        await hre.deployments.get('NFTGemMultiToken')
      ).address
    );
    // get the token symbol
    const symbol = await poolContract.symbol();
    // get all token hashes for pool
    const tokenHashes = await poolContract.tokenHashes();

    // get balance for given owner address fpr all tokens
    const tokenBalances = await Promise.all(
      tokenHashes.map((th: BigNumber) => multitoken.balanceOf(owner, th))
    );

    // get the token types for only non-zero balances
    let tokenTypes: any = [];
    const balances: any = [];
    const recipientTokens: BigNumber[] = [];
    tokenBalances.forEach((bal: any, i) => {
      if (!bal.eq(0)) {
        recipientTokens.push(tokenHashes[i]);
        tokenTypes.push(poolContract.tokenType(tokenHashes[i]));
        balances.push(bal);
      }
    });
    if (recipientTokens.length === 0) return;
    tokenTypes = await Promise.all(tokenTypes);
    // print to the console
    console.log(
      symbol,
      recipientTokens.map((rt, j) => ({
        hash: rt,
        type: tokenTypes[j],
        balance: balances[j],
      }))
    );
  });

task(
  'legacy-tokens-for',
  'show all legacy tokens for given pool symbol of given factory and multitoken held by given address'
)
  .addParam('owner', 'The owner address')
  .addParam('factory', 'The legacy factory address')
  .addParam('symbol', 'The legacy gem pool symbol')
  .addParam('multitoken', 'The legacy multitoken address')
  .setAction(
    async (
      { owner, factory, multitoken, symbol },
      hre: HardhatRuntimeEnvironment
    ) => {
      // get all gempool contracts
      const factoryContract: any = await hre.ethers.getContractAt(
        'NFTGemPoolFactory',
        factory
      );
      // get all gempool contracts
      const multitokenContract: any = await hre.ethers.getContractAt(
        'NFTGemMultiToken',
        multitoken
      );

      const salt = keccak256(['bytes'], [pack(['string'], [symbol])]);
      const poolAddress = await factoryContract.getNFTGemPool(salt);

      if (BigNumber.from(poolAddress).eq(0)) {
        console.log(`No pool found for ${symbol}`);
        return;
      }

      const poolContract = await hre.ethers.getContractAt(
        'NFTComplexGemPoolData',
        poolAddress
      );

      // get all token hashes for pool
      const tokenHashLen = await poolContract.allTokenHashesLength();
      for (let j = 0; j < tokenHashLen.toNumber(); j++) {
        const tokenHash = await poolContract.allTokenHashes(j);
        const tokenBalance = await multitokenContract.balanceOf(
          owner,
          tokenHash
        );
        if (!tokenBalance.eq(0)) {
          const tokenType = await poolContract.tokenType(tokenHash);
          console.log(symbol, {
            hash: tokenHash,
            type: tokenType,
            balance: tokenBalance.toString(),
          });
        }
      }
    }
  );

task(
  'all-legacy-tokens-for',
  'show all legacy tokens for all pools of given factory and multitoken held by given address'
)
  .addParam('owner', 'The owner address')
  .addParam('factory', 'The legacy factory address')
  .addParam('multitoken', 'The legacy multitoken address')
  .setAction(
    async ({ owner, factory, multitoken }, hre: HardhatRuntimeEnvironment) => {
      // get all gempool contracts
      const factoryContract: any = await hre.ethers.getContractAt(
        'NFTGemPoolFactory',
        factory
      );
      // get all gempool contracts
      const multitokenContract: any = await hre.ethers.getContractAt(
        'NFTGemMultiToken',
        multitoken
      );

      // get length of all gempools, load gempool calls into array
      // use Promise.all to load all the addresses at once
      let poolsArray: any = [];
      const poolcount = await factoryContract.allNFTGemPoolsLength();
      for (let i = 0; i < poolcount.toNumber(); i++) {
        poolsArray.push(factoryContract.allNFTGemPools(i));
      }
      // get all gem pool data contracts
      poolsArray = await Promise.all(poolsArray);
      poolsArray = poolsArray.map((pa: string) =>
        hre.ethers.getContractAt('NFTComplexGemPoolData', pa)
      );
      // load all gem pool addresses at once
      poolsArray = await Promise.all(poolsArray);

      // iterate through all gempools
      for (let i = 0; i < poolsArray.length; i++) {
        const poolContract: any = poolsArray[i];
        // get the token symbol
        const symbol = await poolContract.symbol();
        // get all token hashes for pool
        const tokenHashLen = await poolContract.allTokenHashesLength();
        for (let j = 0; j < tokenHashLen.toNumber(); j++) {
          const tokenHash = await poolContract.allTokenHashes(j);
          const tokenBalance = await multitokenContract.balanceOf(
            owner,
            tokenHash
          );
          if (!tokenBalance.eq(0)) {
            const tokenType = await poolContract.tokenType(tokenHash);
            console.log(symbol, {
              hash: tokenHash,
              type: tokenType,
              balance: tokenBalance.toString(),
            });
          }
        }
        // print to the console
      }
    }
  );

task(
  'index-legacy-pools',
  'index all legacy pools for given factory and multitoken'
)
  .addParam('factory', 'The legacy factory address')
  .addParam('multitoken', 'The legacy multitoken address')
  .setAction(
    async ({ factory, multitoken }, hre: HardhatRuntimeEnvironment) => {
      // get all gempool contracts
      const factoryContract: any = await hre.ethers.getContractAt(
        'NFTGemPoolFactory',
        factory
      );
      // get all gempool contracts
      const bitgemIndexer: any = await hre.ethers.getContractAt(
        'BitgemIndexer',
        multitoken
      );

      // get length of all gempools, load gempool calls into array
      // use Promise.all to load all the addresses at once
      let poolsArray: any = [];
      const poolcount = await factoryContract.allNFTGemPoolsLength();
      for (let i = 0; i < poolcount.toNumber(); i++) {
        poolsArray.push(factoryContract.allNFTGemPools(i));
      }
      // get all gem pool data contracts
      poolsArray = await Promise.all(poolsArray);
      poolsArray = poolsArray.map((pa: string) =>
        hre.ethers.getContractAt('NFTComplexGemPoolData', pa)
      );
      // load all gem pool addresses at once
      poolsArray = await Promise.all(poolsArray);

      // iterate through all gempools
      for (let i = 0; i < 1; i++) {  // 10,438(35 per)
        const poolContract: any = poolsArray[i];
        console.log(i, poolContract.address);
        const tokenHashLen = await poolContract.allTokenHashesLength();
        let tx;
        if (tokenHashLen.gt(25)) {
          for (let j = 0; j <= ~~(tokenHashLen.toNumber() / 25); j++) {
            tx = await bitgemIndexer.indexGemPool(poolContract.address, multitoken, j, 25, { gasLimit: 8000000 });
            await hre.ethers.provider.waitForTransaction(tx.hash, 1);
            console.log(j);
          }
        } else {
          tx = await bitgemIndexer.indexGemPool(poolContract.address, multitoken, 0, tokenHashLen.toNumber(), { gasLimit: 8000000 });
          //await hre.ethers.provider.waitForTransaction(tx.hash, 1);
          await tx.wait();
        }
      }
    }
  );

task('pool-settings', 'show pool settings for given pool address')
  .addParam('address', 'The pool address')
  .setAction(async ({ address }, hre: HardhatRuntimeEnvironment) => {
    // get all gempool contracts
    const poolContract: any = await hre.ethers.getContractAt(
      'NFTComplexGemPoolData',
      address
    );
    const settings = await poolContract.settings();
    const [
      symbol,
      name,
      description,
      category,
      ethPrice,
      minTime,
      maxTime,
      diffStep,
      maxClaims,
      maxQuantityPerClaim,
      maxClaimsPerAccount,
    ] = settings;
    console.log({
      symbol,
      name,
      description,
      category,
      ethPrice,
      minTime,
      maxTime,
      diffStep,
      maxClaims,
      maxQuantityPerClaim,
      maxClaimsPerAccount,
    });
  });

task('pool-stats', 'show pool stats for given pool address')
  .addParam('address', 'The pool address')
  .setAction(async ({ address }, hre: HardhatRuntimeEnvironment) => {
    // get all gempool contracts
    const poolContract: any = await hre.ethers.getContractAt(
      'NFTComplexGemPoolData',
      address
    );
    const symbol = await poolContract.symbol();
    const stats = await poolContract.stats();
    const [
      statsVisible,
      statsClaimedCount,
      statsMintedCount,
      statsTotalStakedEth,
      statsNextClaimHash,
      statsNextGemHash,
      statsNextClaimId,
      statsNextGemId,
    ] = stats;
    console.log(symbol, {
      statsVisible,
      statsClaimedCount,
      statsMintedCount,
      statsTotalStakedEth,
      statsNextClaimHash,
      statsNextGemHash,
      statsNextClaimId,
      statsNextGemId,
    });
  });

task('claim-details', 'show details for given claim in given pool')
  .addParam('claimHash', 'The claim hash')
  .addParam('address', 'The pool address')
  .setAction(async ({ address, claimHash }, hre: HardhatRuntimeEnvironment) => {
    // get all gempool contracts
    const poolContract: any = await hre.ethers.getContractAt(
      'NFTComplexGemPoolData',
      address
    );
    const symbol = await poolContract.symbol();
    const claim = await poolContract.claim(claimHash);
    const [
      claimAmount,
      claimQuantity,
      claimUnlockTime,
      claimTokenAmount,
      stakedToken,
      nextClaimId,
    ] = claim;
    console.log(symbol, claimHash, {
      claimAmount,
      claimQuantity,
      claimUnlockTime,
      claimTokenAmount,
      stakedToken,
      nextClaimId,
    });
  });

task('token-details', 'show details for given token in given pool')
  .addParam('tokenHash', 'The token hash')
  .addParam('address', 'The pool address')
  .setAction(async ({ address, tokenHash }, hre: HardhatRuntimeEnvironment) => {
    // get all gempool contracts
    const poolContract = await hre.ethers.getContractAt(
      'NFTComplexGemPoolData',
      address
    );
    const symbol = await poolContract.symbol();
    const claim = await poolContract.token(tokenHash);
    const [tokenType, tokenId, tokenSource] = claim;
    console.log(symbol, tokenHash, {
      tokenType,
      tokenId,
      tokenSource,
    });
  });

task('import-legacy-gem', 'Import a legacy gem into the given pool')
  .addParam('address', 'The pool address')
  .addParam('legacyAddress', 'The legacy pool address')
  .addParam('legacyToken', 'The legacy token address')
  .addParam('tokenHash', 'The legacy token hash')
  .addParam('recipient', 'The token import recipient')
  .setAction(
    async (
      { address, legacyAddress, legacyToken, tokenHash, recipient },
      hre: HardhatRuntimeEnvironment
    ) => {
      // get all gempool contracts
      const poolContract = await hre.ethers.getContractAt(
        'NFTComplexGemPoolData',
        address
      );
      const tx = await poolContract.importLegacyGem(
        legacyAddress,
        legacyToken,
        tokenHash,
        recipient
      );
      console.log(tx);
    }
  );

task(
  'mint-governance-to',
  'Mint an amount of governance tokens into an account'
)
  .addParam('address', 'The address')
  .addParam('amount', 'The amount to send to in whole units')
  .setAction(async ({ address, amount }, hre: HardhatRuntimeEnvironment) => {
    // get all gempool contracts
    const govToken: any = await hre.ethers.getContractAt(
      'GovernanceToken',
      address
    );
    const tx = await govToken.mint(address, parseEther(amount));
    await hre.ethers.provider.waitForTransaction(tx.hash, 1);
    console.log(tx);
  });

task(
  'add-allowed-token-source',
  'Add the given address as a valid legacy gem token source'
)
  .addParam('address', 'The pool address')
  .addParam('allowedAddress', 'The allowed source address')
  .setAction(
    async ({ address, allowedAddress }, hre: HardhatRuntimeEnvironment) => {
      // get all gempool contracts
      const poolContract: any = await hre.ethers.getContractAt(
        'NFTComplexGemPoolData',
        address
      );
      const tx = await poolContract.addAllowedTokenSource(allowedAddress);
      console.log(tx);
    }
  );

task(
  'deploy-pix',
  'Deploy the niftypix contract and associate it with the given symbol / token'
)
  .addParam('address', 'The pool address')
  .addParam('fee', 'The fee we are charging')
  .setAction(async ({ address, fee }, hre: HardhatRuntimeEnvironment) => {
    const [sender] = await hre.ethers.getSigners();
    const libDeployParams = {
      from: await sender.getAddress(),
      log: true,
    };
    await hre.deployments.deploy('NiftyPixContract', libDeployParams);
    const NiftyPixContract = await hre.ethers.getContractAt(
      'NiftyPixContract',
      (
        await hre.deployments.get('NiftyPixContract')
      ).address,
      sender
    );
    const tx = await NiftyPixContract.initialize(
      address,
      await hre.deployments.get('NFTGemMultiToken'),
      fee
    );
    console.log('NiftyPix', NiftyPixContract.address);
    await hre.ethers.provider.waitForTransaction(tx.hash, 10);
  });

task(
  'migrate',
  'Migrate the given legacy gem pool factory and multitoken. Creates new pools with settings same as legacy pool, migrates goverance tokens, and adds legacy pool to allowed pools list.'
)
  .addParam('factory', 'The legacy gem pool factory address')
  .addParam('multitoken', 'The legacy gem multitoken address')
  .addParam('governance', 'true or 1 to also migrate governance tokens')
  .setAction(
    async (
      { factory, multitoken, migrateGovernance },
      hre: HardhatRuntimeEnvironment
    ) => {
      await migrator(hre, factory, multitoken, migrateGovernance);
    }
  );

task('migrate-governance', 'Migrate the legacy governance token to erc20')
  .addParam('multitoken', 'The legacy gem multitoken address')
  .setAction(async ({ multitoken }, hre: HardhatRuntimeEnvironment) => {
    // get the signers
    const [sender] = await hre.ethers.getSigners();
    // get the old token
    const oldToken = await hre.ethers.getContractAt(
      'NFTGemMultiToken',
      multitoken,
      sender
    );
    // get the gov token minter
    const govToken: any = await hre.ethers.getContractAt(
      'GovernanceToken',
      (
        await hre.deployments.get('GovernanceToken')
      ).address
    );
    // get the length of old gov token hodlers
    const allGovTokenHolders = await oldToken.allTokenHoldersLength(0);
    console.log(`num holders: ${allGovTokenHolders.toNumber()}`);
    // process each gov token hodler
    for (let i = 1; i < allGovTokenHolders.toNumber(); i++) {
      if (i === 3 || i === 10) continue;
      const thAddr = await oldToken.allTokenHolders(0, i);
      if (BigNumber.from(thAddr).eq(0)) continue;
      let th0Bal = await oldToken.balanceOf(thAddr, 0);
      if (i === 0) {
        th0Bal = th0Bal.sub(500000);
      }
      const bo = await govToken.balanceOf(thAddr);
      if (!bo.eq(0)) {
        const tx = await govToken.mint(
          thAddr,
          parseEther(th0Bal.mul(30).toString())
        );
        await hre.ethers.provider.waitForTransaction(tx.hash, 1);
        // tx = await oldToken.burn(thAddr, 0, th0Bal);
        // await hre.ethers.provider.waitForTransaction(tx.hash, 1);
        console.log(`${i} ${thAddr} ${th0Bal.toString()}`);
      }
    }
  });

task('index-flat', 'Create easy to index events for gem create events')
  .addParam('multitoken', 'The legacy gem multitoken address')
  .addParam('factory', 'The legacy factory address')
  .setAction(async ({ multitoken, factory }, hre: HardhatRuntimeEnvironment) => {
    // get the signers
    const [sender] = await hre.ethers.getSigners();
    // get the old token
    const oldToken = await hre.ethers.getContractAt(
      'NFTGemMultiToken',
      multitoken,
      sender
    );

    const index: any = {
      pools: { },
      gems: { },
      users: { }
    };
    // get all gempool contracts
    const factoryContract: any = await hre.ethers.getContractAt(
      'NFTGemPoolFactory',
      factory
    );
    // get all gempool contracts
    const multitokenContract: any = await hre.ethers.getContractAt(
      'NFTGemMultiToken',
      multitoken
    );
    // get the gov token minter
    const bitgemIndexer: any = await hre.ethers.getContractAt(
      'BitgemIndexer',
      (
        await hre.deployments.get('BitgemIndexer')
      ).address
    );

    let cached = undefined;
    try {
      cached = fs.readFileSync('./token_' + oldToken.address + '.json', 'utf8');
      cached = JSON.parse(cached);
    } catch (e) { }
    cached.forEach((ci: any) => index.users[ci.address] = ci);

    let allTokenHodlers = [];
    const largeTokenHodlers = [];
    if (!cached) {
      // get the length of old gov token hodlers
      const allGovTokenHolders = await oldToken.allTokenHoldersLength(1);
      console.log(`num holders: ${allGovTokenHolders.toNumber()}`);
      // process each gov token hodler

      for (let i = 0; i < allGovTokenHolders.toNumber(); i++) {
        const thAddr = await oldToken.allTokenHolders(1, i);
        if (BigNumber.from(thAddr).eq(0) || BigNumber.from(thAddr).eq(1))
          continue;
        allTokenHodlers.push(thAddr);
        console.log(thAddr);
      }
      writeFileSync(
        './token_' + oldToken.address + '.json',
        JSON.stringify(allTokenHodlers)
      );
    }
    // allTokenHodlers.forEach(async (thAddr: string) => {
    //   index.users[thAddr] = [];
    // });

    // get length of all gempools, load gempool calls into array
    // use Promise.all to load all the addresses at once
    let poolsArray: any = [];
    const poolcount = await factoryContract.allNFTGemPoolsLength();
    for (let i = 0; i < poolcount.toNumber(); i++) {
      poolsArray.push(factoryContract.allNFTGemPools(i));
    }
    // get all gem pool data contracts
    poolsArray = await Promise.all(poolsArray);
    poolsArray = poolsArray.map((pa: string) =>
      hre.ethers.getContractAt('NFTComplexGemPoolData', pa)
    );
    // load all gem pool addresses at once
    poolsArray = await Promise.all(poolsArray);

    // iterate through all gempools
    for (let i = 0; i < poolsArray.length; i++) {
      let out = [];
      const poolContract: any = poolsArray[i];
      const tokenHashLen = await poolContract.allTokenHashesLength();
      // index.pools[poolContract.address] = [];

      // get all token hashes for this pool
      let allTokenHashes: any = [];
      try {
        allTokenHashes = fs.readFileSync('./pool_' + poolContract.address + '.json', 'utf8');
        allTokenHashes = JSON.parse(allTokenHashes);
      } catch (e) { }
      if (!allTokenHashes.length) {
        let allTokenHashesPromises = [];
        for (let j = 0; j <= ~~(tokenHashLen.toNumber() / 10); j++) {
          for (let k = (j * 10); k < (j * 10) + 10; k++) {
            if (k >= tokenHashLen.toNumber()) break;
            allTokenHashesPromises.push(poolContract.allTokenHashes(k));
          }
          allTokenHashes = allTokenHashes
            .concat(await Promise.all(allTokenHashesPromises))
            .filter((e: any) => !e.eq(0));
        }
        //index.pools[poolContract.address] = allTokenHashes;
        writeFileSync(
          './index.json',
          JSON.stringify(index));
        console.log('.');


        // save all token hashes for pool to file
        writeFileSync(
          './pool_' + poolContract.address + '.json',
          JSON.stringify(allTokenHashes));

        // index.pools[poolContract.address] = allTokenHashes;
      }

      writeFileSync(
        './index.json',
        JSON.stringify(index));
      console.log('.');

      // find the users tokens by finding nonzero balances
      let allMyTokens: any = [];
      let allMyTokenPromises = [];
      let senderAddress = await sender.getAddress();
      for (let j = 0; j <= ~~(allTokenHashes.length / 10); j++) {
        for (let k = j * 10; k < (j * 10) + 10; k++) {
          if (k >= tokenHashLen.toNumber()) break;
          const athl = allTokenHashes[k];
          allMyTokenPromises.push(multitokenContract.balanceOf(senderAddress, athl));
        }
        allMyTokens = allMyTokens
          .concat(await Promise.all(allMyTokenPromises))
          .filter((e: any) => !e.eq(0) && !e.eq(1));
      }
      writeFileSync(
        './user_' + senderAddress + '.json',
        JSON.stringify(allMyTokens));
    }

    writeFileSync(
      './index.json',
      JSON.stringify(index));

  });

task('index-bitgem', 'Create easy to index events for gem create events')
  .addParam('multitoken', 'The legacy gem multitoken address')
  .addParam('factory', 'The legacy factory address')
  .setAction(async ({ multitoken, factory }, hre: HardhatRuntimeEnvironment) => {
    // get the signers
    const [sender] = await hre.ethers.getSigners();
    // get the old token
    const oldToken = await hre.ethers.getContractAt(
      'NFTGemMultiToken',
      multitoken,
      sender
    );

    // get all gempool contracts
    const factoryContract: any = await hre.ethers.getContractAt(
      'NFTGemPoolFactory',
      factory
    );
    // get all gempool contracts
    const multitokenContract: any = await hre.ethers.getContractAt(
      'NFTGemMultiToken',
      multitoken
    );
    // get the gov token minter
    const bitgemIndexer: any = await hre.ethers.getContractAt(
      'BitgemIndexer',
      (
        await hre.deployments.get('BitgemIndexer')
      ).address
    );

    let cached = undefined;
    try {
      cached = fs.readFileSync('./token_' + oldToken.address + '.json', 'utf8');
    } catch (e) { }

    let allTokenHodlers = [];
    const largeTokenHodlers = [];
    if (!cached) {
      // get the length of old gov token hodlers
      const allGovTokenHolders = await oldToken.allTokenHoldersLength(1);
      console.log(`num holders: ${allGovTokenHolders.toNumber()}`);
      // process each gov token hodler

      for (let i = 0; i < allGovTokenHolders.toNumber(); i++) {
        const thAddr = await oldToken.allTokenHolders(1, i);
        if (BigNumber.from(thAddr).eq(0) || BigNumber.from(thAddr).eq(1))
          continue;
        allTokenHodlers.push(thAddr);
        console.log(thAddr);
      }
      writeFileSync(
        './token_' + oldToken.address + '.json',
        JSON.stringify(allTokenHodlers)
      );
    } else {
      allTokenHodlers = JSON.parse(cached);
    }

    // get length of all gempools, load gempool calls into array
    // use Promise.all to load all the addresses at once
    let poolsArray: any = [];
    const poolcount = await factoryContract.allNFTGemPoolsLength();
    for (let i = 0; i < poolcount.toNumber(); i++) {
      poolsArray.push(factoryContract.allNFTGemPools(i));
    }
    // get all gem pool data contracts
    poolsArray = await Promise.all(poolsArray);
    poolsArray = poolsArray.map((pa: string) =>
      hre.ethers.getContractAt('NFTComplexGemPoolData', pa)
    );
    // load all gem pool addresses at once
    poolsArray = await Promise.all(poolsArray);

    // write out pools data to file
    // const poolSettings = await Promise.all(poolsArray.map((pa: any) => pa.settings()))
    // writeFileSync(
    //   './pools.json',
    //   JSON.stringify(poolSettings));

    for (let u = 0; u < allTokenHodlers.length; u++) {
      const owner = allTokenHodlers[u];

      let ownedGems: any = [];
      try {
        ownedGems = fs.readFileSync('./user_' + owner + '.json', 'utf8');
      } catch (e) { }

      // iterate through all gempools
      for (let i = 0; i < poolsArray.length; i++) {
        let out = [];
        const poolContract: any = poolsArray[i];
        const tokenHashLen = await poolContract.allTokenHashesLength();

        // get all token hashes for this pool
        let allTokenHashes: any = [];
        try {
          allTokenHashes = fs.readFileSync('./pool_' + poolContract.address + '.json', 'utf8');
          allTokenHashes = JSON.parse(allTokenHashes);
        } catch (e) { }
        if (!allTokenHashes.length) {
          let allTokenHashesPromises = [];
          for (let j = 0; j <= ~~(tokenHashLen.toNumber() / 10); j++) {
            for (let k = (j * 10); k < (j * 10) + 10; k++) {
              if (k >= tokenHashLen.toNumber()) break;
              allTokenHashesPromises.push(poolContract.allTokenHashes(k));
            }
            allTokenHashes = allTokenHashes
              .concat(await Promise.all(allTokenHashesPromises))
              .filter((e: any) => !e.eq(0));
          }
          // save all token hashes for pool to file
          writeFileSync(
            './pool_' + poolContract.address + '.json',
            JSON.stringify(allTokenHashes));
        }

        // find the users tokens by finding nonzero balances
        let allMyTokens: any = [];
        let allMyTokenPromises = [];
        let senderAddress = await sender.getAddress();
        for (let j = 0; j <= ~~(allTokenHashes.length / 10); j++) {
          for (let k = j * 10; k < (j * 10) + 10; k++) {
            if (k >= tokenHashLen.toNumber()) break;
            const athl = allTokenHashes[k];
            allMyTokenPromises.push(multitokenContract.balanceOf(senderAddress, athl));
          }
          allMyTokens = allMyTokens
            .concat(await Promise.all(allMyTokenPromises))
        }

        // add the nonsero balance hashees to the ownedGems output array
        for (let j = 0; j <= allTokenHashes.length; j++) {
          if (!allMyTokens[j].eq(0)) {
            ownedGems.push(allTokenHashes[j]);
          }
        }

        // save the user file
        if (ownedGems.length) {
          writeFileSync(
            './user_' + owner + '.json',
            JSON.stringify(ownedGems, null, 4)
          );
        }
      }
      console.log('user', owner);

    }

  });

task('publish-gempool', 'Publish a new gem pool with the given parameters')
  .addParam('symbol', 'The gem pool symbol')
  .addParam('name', 'The gem pool name')
  .addParam('price', 'The gem pool starting price')
  .addParam('min', 'The gem pool minimum maturity time in seconds')
  .addParam('max', 'The gem pool maximum maturity time in seconds')
  .addParam('diff', 'The gem pool difficulty divisor')
  .addParam('maxClaims', 'The gem pool max number of claims')
  .addParam('allowedToken', 'An optional allowed token')
  .setAction(
    async (
      { symbol, name, price, min, max, diff, maxClaims, allowedToken },
      hre: HardhatRuntimeEnvironment
    ) => {
      const publisher = await publish(hre, false);
      const minionAddress = await publisher.createPool(
        symbol,
        name,
        hre.ethers.utils.parseEther(price),
        min,
        max,
        diff,
        maxClaims,
        allowedToken
      );
    }
  );

task(
  'mint-governance',
  'Mint governance tokens. Driven with a file input containing an array of address, quantity pairs'
)
  .addParam('file', 'The legacy gem pool factory address')
  .setAction(async ({ file }, hre: HardhatRuntimeEnvironment) => {
    const data = JSON.parse(fs.readFileSync(file).toString());
    // get the multitoken contract
    const signer = await hre.ethers.provider.getSigner();
    const govToken: any = await hre.ethers.getContractAt(
      'GovernanceToken',
      (
        await hre.deployments.get('GovernanceToken')
      ).address,
      signer
    );
    // get the signer

    for (let i = 0; i < data.length; i++) {
      const line: any = data[i];
      const k = line[0];
      const v = parseInt(line[1]) * 30;
      const b = await govToken.balanceOf(k);
      if (parseInt(formatEther(b)) !== v) {
        await govToken.mint(k, parseEther(v + ''));
        console.log(`${k} ${v}`);
      }
    }
  });

task(
  'withdraw-fees',
  'Withdraw fees from fee manager. Pushes a governance proposal through for a transfer to the specific individualThe.'
)
  .addParam('account', 'The legacy gem multitoken address')
  .setAction(async ({ account }, hre: HardhatRuntimeEnvironment) => {
    // get the signer
    const signer = await hre.ethers.provider.getSigner();

    // load the proposal factory contract
    const proposalFactory = await hre.ethers.getContractAt(
      'ProposalFactory',
      (
        await hre.deployments.get('ProposalFactory')
      ).address,
      signer
    );

    // load the nft gem governor contract
    const nftGemGovernor = await hre.ethers.getContractAt(
      'NFTGemGovernor',
      (
        await hre.deployments.get('NFTGemGovernor')
      ).address,
      signer
    );

    // create a new proposal that will transfer fees to the address
    // specified by the user

    // fund the proposal with 1 fantom

    // send vote tokens to the proposal address

    // execute the proposal
  });

task(
  'migrate-all-gems',
  'Migrate all the gem holdera from legacy gem pool factory and multitoken. Creates new gems for token holder from legacy token contents.'
)
  .addParam('factory', 'The legacy gem pool factory address')
  .addParam('multitoken', 'The legacy gem multitoken address')
  .setAction(
    async ({ factory, multitoken, account }, hre: HardhatRuntimeEnvironment) => {
      await migrator(hre, factory, multitoken, account);
    }
  );

task(
  'migrate-gems',
  'Migrate the given gem holder from legacy gem pool factory and multitoken. Creates new gems for token holder from legacy token contents.'
)
  .addParam('factory', 'The legacy gem pool factory address')
  .addParam('multitoken', 'The legacy gem multitoken address')
  .addParam('account', 'The target token holder account address')
  .setAction(
    async ({ factory, multitoken, account }, hre: HardhatRuntimeEnvironment) => {
      await migrator(hre, factory, multitoken, account);
    }
  );

task('send-token-to', 'Send the given claim or gem to the given address')
  .addParam('hash', 'The token hash')
  .addParam('recipient', 'The recipient address')
  .addParam('quantity', 'The recipient address')
  .setAction(
    async ({ hash, recipient, quantity }, hre: HardhatRuntimeEnvironment) => {
      // get the multitoken contract
      const multitoken: any = await hre.ethers.getContractAt(
        'NFTGemMultiToken',
        (
          await hre.deployments.get('NFTGemMultiToken')
        ).address
      );
      // get the signer
      const signer = await hre.ethers.provider.getSigner();
      // send the token
      const tx = await multitoken.safeTransferFrom(
        signer.getAddress(),
        recipient,
        hash,
        quantity,
        signer,
        0
      );
      // print to the console
      console.log(tx);
    }
  );

task(
  'publish-test-items',
  'Publish test suite items. Publishes a set of gem pools designed to test through all Bitgem functionality'
).setAction(async (_, hre: HardhatRuntimeEnvironment) => {
  // get all gempool contracts
  const publisher = await publish(hre, false);
  const deployedContracts = await publisher.getDeployedContracts();

  const metalAddress = await publisher.createPool(
    'METAL',
    'Metal',
    hre.ethers.utils.parseEther('1'),
    30,
    900,
    65536,
    0,
    '0x0000000000000000000000000000000000000000'
  );
  const woodAddress = await publisher.createPool(
    'WOOD',
    'Wood',
    hre.ethers.utils.parseEther('1'),
    30,
    900,
    65536,
    0,
    '0x0000000000000000000000000000000000000000'
  );
  const mana = await publisher.createPool(
    'MANA',
    'Mana',
    hre.ethers.utils.parseEther('1'),
    30,
    900,
    65536,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  // publish a minion - can be minted with no input requirements
  const blade = await publisher.createPool(
    'BLADE',
    'Metal Blade',
    hre.ethers.utils.parseEther('1'),
    30,
    900,
    65536,
    0,
    '0x0000000000000000000000000000000000000000',
    [
      [
        deployedContracts.NFTGemMultiToken.address,
        metalAddress,
        2,
        0,
        1,
        true,
        false,
        false,
      ],
    ]
  );

  // publish a minion - can be minted with no input requirements
  const hilt = await publisher.createPool(
    'HILT',
    'Wood Hilt',
    hre.ethers.utils.parseEther('1'),
    30,
    900,
    65536,
    0,
    '0x0000000000000000000000000000000000000000',
    [
      [
        deployedContracts.NFTGemMultiToken.address,
        woodAddress,
        2,
        0,
        1,
        true,
        false,
        false,
      ],
    ]
  );

  // publish a minion - can be minted with no input requirements
  const sword = await publisher.createPool(
    'SWORD',
    'Sword of Power',
    hre.ethers.utils.parseEther('1'),
    30,
    900,
    65536,
    0,
    '0x0000000000000000000000000000000000000000',
    [
      [
        deployedContracts.NFTGemMultiToken.address,
        blade,
        2,
        0,
        1,
        true,
        false,
        false,
      ],
      [
        deployedContracts.NFTGemMultiToken.address,
        hilt,
        2,
        0,
        1,
        true,
        false,
        false,
      ],
      [
        deployedContracts.NFTGemMultiToken.address,
        mana,
        2,
        0,
        1,
        true,
        false,
        false,
      ],
    ]
  );
});

task('publish-aquarium', 'Publish Aquarium and a fish').setAction(
  async (_, hre: HardhatRuntimeEnvironment) => {
    // get all gempool contracts
    const publisher = await publish(hre, false);
    const deployedContracts = await publisher.getDeployedContracts();

    // publish the aquarium
    const aquarium = await publisher.createPool(
      'AQRM',
      'BitNautica Aquarium',
      hre.ethers.utils.parseEther('500'),
      86400,
      86400 * 7,
      128,
      0,
      '0x0000000000000000000000000000000000000000'
    );

    // publish the fish
    const fish = await publisher.createPool(
      'FISH',
      'BitNautica Fish',
      hre.ethers.utils.parseEther('100'),
      86400,
      86400 * 7,
      65536,
      0,
      '0x0000000000000000000000000000000000000000',
      [
        [
          deployedContracts.NFTGemMultiToken.address,
          aquarium,
          2,
          0,
          1,
          false,
          false,
          false,
        ],
      ]
    );
  }
);

task('publish-test-lootbox', 'Publish Test Lootbox').setAction(
  async (_, hre: HardhatRuntimeEnvironment) => {
    // get all gempool contracts
    const publisher = await lootbox(hre);
    const deployedContracts = await publisher.getDeployedContracts();
    const [sender] = await hre.ethers.getSigners();
    const senderAddress = await sender.getAddress();
    // create a test lootbox
    const lootB = {
      owner: senderAddress,
      randomFarmer: deployedContracts.RandomFarmer.address,
      multitoken: deployedContracts.NFTGemMultiToken.address,
      lootboxHash: BigNumber.from(0),
      symbol: 'TEST6',
      name: 'Test Lootbox',
      description: 'Test Lootbox',
      minLootPerOpen: 1,
      maxLootPerOpen: 1,
      openPrice: hre.ethers.utils.parseEther('0.1'),
      maxOpens: hre.ethers.BigNumber.from('100'),
      openCount: hre.ethers.utils.parseEther('0'),
      totalLootGenerated: hre.ethers.utils.parseEther('0'),
      lootboxTokenSalePrice: hre.ethers.utils.parseEther('0.1'),
      probabilitiesSum: hre.ethers.utils.parseEther('0'),
      initialized: true,
      openedCount: hre.ethers.utils.parseEther('0'),
      lootIssuedCount: hre.ethers.utils.parseEther('0'),
    };
    const tokenSeller = [
      deployedContracts.NFTGemMultiToken.address,
      '0x0000000000000000000000000000000000000000',
      senderAddress,
      hre.ethers.utils.parseEther('0'),
      hre.ethers.utils.parseEther('1'),
      0,
      hre.ethers.utils.parseEther('0'),
      hre.ethers.utils.parseEther('0'),
      hre.ethers.utils.parseEther('0'),
      hre.ethers.utils.parseEther('0'),
      hre.ethers.utils.parseEther('0'),
      hre.ethers.utils.parseEther('0'),
      true,
      true,
      hre.ethers.utils.parseEther('0'),
    ];
    const loot = [
      [
        BigNumber.from(0),
        senderAddress as string,
        deployedContracts.NFTGemMultiToken.address,
        'SMBL',
        'Test Loot',
        hre.ethers.constants.MaxUint256.div(4).sub(1),
        BigNumber.from(0),
        BigNumber.from(0),
        BigNumber.from(0),
        BigNumber.from(0),
      ],
      [
        BigNumber.from(0),
        senderAddress as string,
        deployedContracts.NFTGemMultiToken.address,
        'ABC',
        'Another Name',
        hre.ethers.constants.MaxUint256.div(4).sub(1),
        BigNumber.from(0),
        BigNumber.from(0),
        BigNumber.from(0),
        BigNumber.from(0),
      ],
      [
        BigNumber.from(0),
        senderAddress as string,
        deployedContracts.NFTGemMultiToken.address,
        'DEZ',
        'Test Data',
        hre.ethers.constants.MaxUint256.div(4).sub(1),
        BigNumber.from(0),
        BigNumber.from(0),
        BigNumber.from(0),
        BigNumber.from(0),
      ],
      [
        BigNumber.from(0),
        senderAddress as string,
        deployedContracts.NFTGemMultiToken.address,
        'GEM',
        'Not Real but Fake',
        hre.ethers.constants.MaxUint256.div(4).sub(1),
        BigNumber.from(0),
        BigNumber.from(0),
        BigNumber.from(0),
        BigNumber.from(0),
      ],
    ];

    const result = await publisher.createLootbox(lootB, tokenSeller);
    const contract = await new hre.ethers.Contract(
      result,
      require('./build/LootboxContract.json'),
      sender
    );
    for (let j = 0; j < loot.length; j++) {
      const boob = {
        lootHash: loot[j][0],
        owner: loot[j][1],
        multitoken: loot[j][2],
        symbol: loot[j][3],
        name: loot[j][4],
        probability: loot[j][5],
        probabilityIndex: loot[j][6],
        probabilityRoll: loot[j][7],
        maxMint: loot[j][8],
        minted: loot[j][9],
      };
      await contract.addLoot(boob);
      console.log(loot[j]);
    }
  }
);

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: '0.8.0',
        settings: {
          optimizer: {
            enabled: true,
            runs: 2222,
          },
        },
      },
      {
        version: '0.6.6',
        settings: {
          optimizer: {
            enabled: true,
            runs: 2222,
          },
        },
      },
      {
        version: '0.5.16',
        settings: {
          optimizer: {
            enabled: true,
            runs: 2200,
          },
        },
      },
    ],
  },
  namedAccounts: {
    deployer: {
      default: 0,
      kovan: 0,
    },
  },

  networks: {
    hardhat: {
      chainId: 1337,
      accounts: accounts(),
    },
    localhost: {
      url: 'http://localhost:8545',
      accounts: accounts(),
      gasPrice: 'auto',
      gas: 'auto',
    },
    mainnet: {
      url: node_url('mainnet'),
      accounts: accounts('mainnet'),
      gasPrice: 'auto',
      gas: 'auto',
      gasMultiplier: 1.5,
    },
    rinkeby: {
      url: node_url('rinkeby'),
      accounts: accounts('rinkeby'),
      gasPrice: 'auto',
      gas: 'auto',
    },
    ropsten: {
      url: node_url('ropsten'),
      accounts: accounts('ropsten'),
      gasPrice: 'auto',
      gas: 'auto',
    },
    kovan: {
      url: node_url('kovan'),
      accounts: accounts('kovan'),
      gasPrice: 'auto',
      gas: 'auto',
    },
    staging: {
      url: node_url('kovan'),
      accounts: accounts('kovan'),
      gasPrice: 'auto',
      gas: 'auto',
    },
    ftmtest: {
      url: node_url('ftmtest'),
      accounts: accounts('ftmtest'),
      gasPrice: 'auto',
      gas: 'auto',
    },
    opera: {
      url: node_url('opera'),
      accounts: accounts('opera'),
      timeout: 30000,
    },
    sokol: {
      url: node_url('sokol'),
      accounts: accounts('sokol'),
      gasPrice: 'auto',
      gas: 'auto',
    },
    fuji: {
      url: node_url('fuji'),
      accounts: accounts('fuji'),
      gasPrice: 'auto',
      gas: 'auto',
    },
    avax: {
      url: node_url('avax'),
      accounts: accounts('avax'),
      gasPrice: 'auto',
      gas: 'auto',
    },
    binance: {
      url: node_url('binance'),
      accounts: accounts('binance'),
      gasPrice: 'auto',
      gas: 'auto',
    },
    bsctest: {
      url: node_url('bsctest'),
      accounts: accounts('bsctest'),
      gasPrice: 'auto',
      gas: 'auto',
    },
    poa: {
      url: node_url('poa'),
      accounts: accounts('poa'),
      gasPrice: 'auto',
      gas: 'auto',
    },
  },
  etherscan: {
    apiKey: '4QX1GGDD4FPPHK4DNTR3US6XJDFBUXG7WQ',
  },
  paths: {
    sources: 'src',
  },
  gasReporter: {
    currency: 'USD',
    gasPrice: 150,
    enabled: true,
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    maxMethodDiff: 10,
  },
  mocha: {
    timeout: 0,
  },
  abiExporter: {
    path: './build',
    clear: true,
    flat: true,
  },
  typechain: {
    outDir: './types',
    target: 'ethers-v5',
  },
};

export default config;
