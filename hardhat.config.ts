import {HardhatRuntimeEnvironment} from 'hardhat/types';

import {task} from 'hardhat/config';

import 'dotenv/config';
import {HardhatUserConfig} from 'hardhat/types';

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

import {node_url, accounts} from './utils/network';
import {BigNumber} from 'ethers';

import publisher from './lib/publishLib';
import migrator from './lib/migrateLib';

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
  .setAction(async ({address}, hre: HardhatRuntimeEnvironment) => {
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
  'token-holders',
  'Get a list of token holder addresses for the given token hash'
)
  .addParam('hash', 'The token hash')
  .setAction(async ({hash}, hre: HardhatRuntimeEnvironment) => {
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
    const gemPools = await gemPoolFactory.nftGemPools();

    // get all gempool contracts
    const poolContracts: any = await Promise.all(
      gemPools.map(async (gp: string) =>
        hre.ethers.getContractAt('NFTComplexGemPoolData', gp)
      )
    );

    // iterate through all contracts
    // and output symbol and address
    for (let i = 0; i < poolContracts.length; i++) {
      const symbol = await poolContracts[i].symbol();
      console.log(symbol, poolContracts[i].address);
    }
  }
);

task('pool-tokens', 'show pool tokens for given pool')
  .addParam('address', 'The pool address')
  .setAction(async ({address}, hre: HardhatRuntimeEnvironment) => {
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
  .setAction(async ({address, owner}, hre: HardhatRuntimeEnvironment) => {
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

task('pool-settings', 'show pool settings for given pool address')
  .addParam('address', 'The pool address')
  .setAction(async ({address}, hre: HardhatRuntimeEnvironment) => {
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
  .setAction(async ({address}, hre: HardhatRuntimeEnvironment) => {
    // get all gempool contracts
    const poolContract: any = await hre.ethers.getContractAt(
      'NFTComplexGemPoolData',
      address
    );
    const symbol = await poolContract.symbol();
    const stats = await poolContract.stats();
    const [
      visible,
      claimedCount,
      mintedCount,
      totalStakedEth,
      nextClaimHash,
      nextGemHash,
      nextClaimIdVal,
      nextGemIdVal,
    ] = stats;
    console.log(symbol, {
      visible,
      claimedCount,
      mintedCount,
      totalStakedEth,
      nextClaimHash,
      nextGemHash,
      nextClaimIdVal,
      nextGemIdVal,
    });
  });

task('claim-details', 'show details for given claim in given pool')
  .addParam('claimHash', 'The claim hash')
  .addParam('address', 'The pool address')
  .setAction(async ({address, claimHash}, hre: HardhatRuntimeEnvironment) => {
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
  .setAction(async ({address, tokenHash}, hre: HardhatRuntimeEnvironment) => {
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
      {address, legacyAddress, legacyToken, tokenHash, recipient},
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
  'add-allowed-token-source',
  'Add the given address as a valid legacy gem token source'
)
  .addParam('address', 'The pool address')
  .addParam('allowedAddress', 'The allowed source address')
  .setAction(
    async ({address, allowedAddress}, hre: HardhatRuntimeEnvironment) => {
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
  'migrate',
  'Migrate the given legacy gem pool factory and multitoken. Creates new pools with settings same as legacy pool, migrates goverance tokens, and adds legacy pool to allowed pools list.'
)
  .addParam('factory', 'The legacy gem pool factory address')
  .addParam('multitoken', 'The legacy gem multitoken address')
  .setAction(async ({factory, multitoken}, hre: HardhatRuntimeEnvironment) => {
    await migrator(hre, factory, multitoken);
  });

task(
  'migrate-gems',
  'Migrate the given gem holder from legacy gem pool factory and multitoken. Creates new gems for token holder from legacy token contents.'
)
  .addParam('factory', 'The legacy gem pool factory address')
  .addParam('multitoken', 'The legacy gem multitoken address')
  .addParam('account', 'The target token holder account address')
  .setAction(
    async ({factory, multitoken, account}, hre: HardhatRuntimeEnvironment) => {
      await migrator(hre, factory, multitoken, account);
    }
  );

task('send-token-to', 'Send the given claim or gem to the given address')
  .addParam('hash', 'The token hash')
  .addParam('recipient', 'The recipient address')
  .addParam('quantity', 'The recipient address')
  .setAction(
    async ({hash, recipient, quantity}, hre: HardhatRuntimeEnvironment) => {
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
  const {createPool, deployedContracts} = await publisher(hre, false);

  // publish a minion - can be minted with no input requirements
  const minionAddress = await createPool(
    'TEST1',
    'Test Minion',
    hre.ethers.utils.parseEther('1'),
    30,
    900,
    65536,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  // publish an underboss - must have a minion to mint
  const underBossAddress = await createPool(
    'TEST2',
    'Test Underboss',
    hre.ethers.utils.parseEther('1'),
    30,
    900,
    65536,
    0,
    '0x0000000000000000000000000000000000000000',
    [
      [
        deployedContracts.NFTGemMultiToken.address,
        minionAddress,
        3,
        0,
        1,
        true,
        false,
      ],
    ]
  );

  // publish a level boss - must have a minion and underboss to mint
  const levelBossAddress = await createPool(
    'TEST3',
    'Test Level Boss',
    hre.ethers.utils.parseEther('1'),
    30,
    900,
    65536,
    0,
    '0x0000000000000000000000000000000000000000',
    [
      [
        deployedContracts.NFTGemMultiToken.address,
        minionAddress,
        3,
        0,
        1,
        true,
        false,
      ],
      [
        deployedContracts.NFTGemMultiToken.address,
        underBossAddress,
        3,
        0,
        1,
        true,
        false,
      ],
    ]
  );

  // publish a big boss - requires minion, underboss
  // and level boss and keeps all of them
  await createPool(
    'TEST4',
    'Test Big Boss',
    hre.ethers.utils.parseEther('1'),
    30,
    900,
    65536,
    0,
    '0x0000000000000000000000000000000000000000',
    [
      [
        deployedContracts.NFTGemMultiToken.address,
        minionAddress,
        3,
        0,
        1,
        true,
        true,
      ],
      [
        deployedContracts.NFTGemMultiToken.address,
        underBossAddress,
        3,
        0,
        1,
        true,
        true,
      ],
      [
        deployedContracts.NFTGemMultiToken.address,
        levelBossAddress,
        3,
        0,
        1,
        true,
        true,
      ],
    ]
  );
});

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: '0.8.0',
        settings: {
          optimizer: {
            enabled: true,
            runs: 2000,
          },
        },
      },
      {
        version: '0.6.6',
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
      {
        version: '0.5.3',
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
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
      gasPrice: 'auto',
      gas: 'auto',
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
