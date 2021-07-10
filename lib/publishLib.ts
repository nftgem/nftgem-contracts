import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {pack, keccak256} from '@ethersproject/solidity';
import {formatEther} from 'ethers/lib/utils';
import {BigNumberish} from '@ethersproject/bignumber';

async function pub(
  hre: HardhatRuntimeEnvironment,
  deployAll: boolean
): Promise<any> {
  const networkId = await hre.getChainId();
  const sender = await hre.ethers.getSigners();
  class Publisher {
    ethers = hre.ethers;
    deployments = hre.deployments;
    getContractAt = hre.ethers.getContractAt;
    get = hre.deployments.get;
    deploy = hre.deployments.deploy;
    networkId = networkId;
    sender = sender;
  }
}

export default async function publisher(
  hre: HardhatRuntimeEnvironment,
  deployAll: boolean
): Promise<any> {
  const {ethers, deployments} = hre;
  const [sender] = await ethers.getSigners();
  const networkId = await hre.getChainId();
  const {getContractAt, BigNumber} = ethers;
  const chainId = (await ethers.provider.getNetwork()).chainId;
  const {get, deploy} = deployments;

  console.log(
    `${chainId} ${sender.address} ${formatEther(await sender.getBalance())}`
  );

  /**
   * @dev Deploy all libraries and contracts for the platform
   */
  this.deployContracts = async () => {
    const libDeployParams = {
      from: sender.address,
      log: true,
    };

    const [govLib, addressSet] = [
      await deploy('GovernanceLib', libDeployParams),
      await deploy('AddressSet', libDeployParams),
    ];

    const [
      strings,
      uint256Set,
      create2,
      wrappedTokenLib,
      proposalsLib,
      complexPoolLib,
    ] = await Promise.all([
      deploy('Strings', libDeployParams),
      deploy('UInt256Set', libDeployParams),
      deploy('Create2', libDeployParams),
      deploy('WrappedTokenLib', libDeployParams),
      deploy('ProposalsLib', {
        from: sender.address,
        log: true,
        libraries: {
          GovernanceLib: govLib.address,
        },
      }),
      deploy('ComplexPoolLib', {
        from: sender.address,
        log: true,
        libraries: {
          AddressSet: addressSet.address,
        },
      }),
    ]);

    const deployParams: any = {
      from: sender.address,
      log: true,
      libraries: {
        GovernanceLib: govLib.address,
        Strings: strings.address,
        AddressSet: addressSet.address,
        UInt256Set: uint256Set.address,
        Create2: create2.address,
        ProposalsLib: proposalsLib.address,
        ComplexPoolLib: complexPoolLib.address,
        WrappedTokenLib: wrappedTokenLib.address,
      },
    };

    await Promise.all([
      deploy('NFTGemGovernor', deployParams),
      deploy('NFTGemMultiToken', deployParams),
      deploy('NFTGemPoolFactory', deployParams),
      deploy('NFTGemFeeManager', deployParams),
      deploy('ProposalFactory', deployParams),
      deploy('MockProxyRegistry', deployParams),
      deploy('ERC20GemTokenFactory', deployParams),
      deploy('TokenPoolQuerier', deployParams),
      deploy('BulkTokenMinter', deployParams),
    ]);

    let SwapHelper = undefined;
    if (parseInt(networkId) === 1) {
      SwapHelper = 'UniSwap';
    } else if (parseInt(networkId) === 250) {
      SwapHelper = 'SushiSwap';
    } else if (parseInt(networkId) === 56) {
      SwapHelper = 'PancakeSwap';
    } else if (parseInt(networkId) === 43114) {
      SwapHelper = 'Pangolin';
    }
    if (!SwapHelper) {
      // mock helper for testing - returns 10x input
      SwapHelper = await deploy('MockQueryHelper', deployParams);
    } else {
      // deploy the appropriate helper given network
      const deployParams: any = {
        from: sender.address,
        log: true,
        libraries: {},
      };
      deployParams.libraries[`${SwapHelper}Lib`] = (
        await deploy(`${SwapHelper}Lib`, libDeployParams)
      ).address;
      SwapHelper = await deploy(`${SwapHelper}QueryHelper`, deployParams);
    }

    dc = await getDeployedContracts();

    const inited = await dc.NFTGemGovernor.initialized();

    if (!inited) {
      console.log('initializing governor...');

      let tx = await dc.NFTGemGovernor.initialize(
        dc.NFTGemMultiToken.address,
        dc.NFTGemPoolFactory.address,
        dc.NFTGemFeeManager.address,
        dc.ProposalFactory.address,
        dc.SwapHelper.address
      );
      await hre.ethers.provider.waitForTransaction(tx.hash, 1);

      console.log('propagating multitoken controller...');
      tx = await dc.NFTGemMultiToken.addController(dc.NFTGemGovernor.address, {
        gasLimit: 500000,
      });
      await hre.ethers.provider.waitForTransaction(tx.hash, 1);

      console.log('propagating fee manager controller...');
      tx = await dc.NFTGemFeeManager.addController(dc.NFTGemGovernor.address, {
        gasLimit: 500000,
      });
      await hre.ethers.provider.waitForTransaction(tx.hash, 1);

      console.log('minting initial governance tokens...');
      tx = await dc.NFTGemGovernor.issueInitialGovernanceTokens(
        sender.address,
        {
          gasLimit: 5000000,
        }
      );
      await hre.ethers.provider.waitForTransaction(tx.hash, 1);

      // deploy the governance token wrapper
      console.log('deploying wrapped governance token...');
      deployParams.args = [
        'NFTGem Governance',
        'NFTGG',
        dc.NFTGemMultiToken.address,
        dc.NFTGemFeeManager.address,
      ];
      await deploy('NFTGemWrappedERC20Governance', deployParams);

      // init governance token wrapper
      console.log('intializing wrapped governance token...');
      dc.NFTGemWrappedERC20Governance = await getContractAt(
        'NFTGemWrappedERC20Governance',
        (
          await get('NFTGemWrappedERC20Governance')
        ).address,
        sender
      );
      tx = await dc.NFTGemWrappedERC20Governance.initialize(
        '',
        '',
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000',
        0,
        dc.NFTGemFeeManager.address
      );
      await hre.ethers.provider.waitForTransaction(tx.hash, 1);

      // approve the wrappedgem contract
      console.log('approving wrapped governance token as operator...');
      tx = await dc.NFTGemMultiToken.setApprovalForAll(
        dc.NFTGemWrappedERC20Governance.address,
        true,
        {from: sender.address}
      );
      await hre.ethers.provider.waitForTransaction(tx.hash, 1);
    } else {
      console.log('contracts already deployed and initialized.');
    }

    return dc;
  };

  deployContracts.bind(self);

  const getDeployedContracts = async () => {
    const ret: any = {
      NFTGemGovernor: await getContractAt(
        'NFTGemGovernor',
        (
          await get('NFTGemGovernor')
        ).address,
        sender
      ),
      NFTGemMultiToken: await getContractAt(
        'NFTGemMultiToken',
        (
          await get('NFTGemMultiToken')
        ).address,
        sender
      ),
      NFTGemPoolFactory: await getContractAt(
        'NFTGemPoolFactory',
        (
          await get('NFTGemPoolFactory')
        ).address,
        sender
      ),
      NFTGemFeeManager: await getContractAt(
        'NFTGemFeeManager',
        (
          await get('NFTGemFeeManager')
        ).address,
        sender
      ),
      ProposalFactory: await getContractAt(
        'ProposalFactory',
        (
          await get('ProposalFactory')
        ).address,
        sender
      ),
      ERC20GemTokenFactory: await getContractAt(
        'ERC20GemTokenFactory',
        (
          await get('ERC20GemTokenFactory')
        ).address,
        sender
      ),
      MockProxyRegistry: await getContractAt(
        'MockProxyRegistry',
        (
          await get('MockProxyRegistry')
        ).address,
        sender
      ),
    };

    if (parseInt(networkId) === 1) {
      ret.SwapHelper = await getContractAt(
        'UniswapQueryHelper',
        (
          await get('UniswapQueryHelper')
        ).address,
        sender
      );
    } else if (parseInt(networkId) === 250) {
      ret.SwapHelper = await getContractAt(
        'SushiSwapQueryHelper',
        (
          await get('SushiSwapQueryHelper')
        ).address,
        sender
      );
    } else if (parseInt(networkId) === 43114) {
      ret.SwapHelper = await getContractAt(
        'PangolinQueryHelper',
        (
          await get('PangolinQueryHelper')
        ).address,
        sender
      );
    } else if (parseInt(networkId) === 56) {
      ret.SwapHelper = await getContractAt(
        'PancakeSwapQueryHelper',
        (
          await get('PancakeSwapQueryHelper')
        ).address,
        sender
      );
    } else {
      ret.SwapHelper = await getContractAt(
        'MockQueryHelper',
        (
          await get('MockQueryHelper')
        ).address,
        sender
      );
    }
    return ret;
  };

  let dc: any = deployAll
    ? await deployContracts()
    : await getDeployedContracts();

  const getGemPoolAddress = async (sym: string) => {
    return await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], [sym])])
    );
  };

  const getGemTokenAddress = async (sym: string) => {
    return await dc.ERC20GemTokenFactory.getItem(
      keccak256(['bytes'], [pack(['string'], [sym])])
    );
  };

  const getPoolContract = async (addr: string) => {
    return dc.NFTComplexGemPool.attach(addr);
  };

  /*
    await createPool(
    'MINF',
    'Minion 6',
    parseEther(itemPrice),
    30,
    90,
    12,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'UBOSSA',
    'Underboss 1',
    parseEther(itemPrice),
    30,
    90,
    4,
    0,
    '0x0000000000000000000000000000000000000000',
    [
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MINA'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MINB'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MINC'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MIND'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MINE'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MINF'), 3, 0, 1, true, false],
    ]
  );
  */
  const createPool = async (
    symbol: string,
    name: string,
    price: BigNumberish,
    min: number,
    max: number,
    diff: number,
    maxClaims: number,
    allowedToken: string,
    inputRequirements?: any[]
  ) => {
    let tx,
      created = false,
      nonce = BigNumber.from(0);
    let poolAddr = await getGemPoolAddress(symbol);
    if (BigNumber.from(poolAddr).eq(0)) {
      // create the gem pool
      console.log(`Creating ${name} (${symbol}) pool...`);
      tx = await dc.NFTGemGovernor.createSystemPool(
        symbol,
        name,
        price,
        min,
        max,
        diff,
        maxClaims,
        allowedToken,
        {gasLimit: 5000000}
      );
      await hre.ethers.provider.waitForTransaction(tx.hash, 1);
      nonce = BigNumber.from(tx.nonce).add(1);
      poolAddr = await getGemPoolAddress(symbol);
      console.log(`address: ${poolAddr}`);

      // create the wrapped erc20 gem contract
      console.log(`Creating wrapped ${name} (${symbol}) token...`);
      tx = await dc.ERC20GemTokenFactory.createItem(
        `W${symbol}`,
        `Wrapped ${name}`,
        poolAddr,
        dc.NFTGemMultiToken.address,
        18,
        dc.NFTGemFeeManager.address,
        {gasLimit: 5000000, nonce}
      );
      await hre.ethers.provider.waitForTransaction(tx.hash, 1);
      nonce = nonce.add(1);
      const gtAddr = await getGemTokenAddress(`W${symbol}`);
      console.log(`address: ${gtAddr}`);

      created = true;
    }
    const pc = await getPoolContract(poolAddr);
    const reqlen = created ? 0 : await pc.allInputRequirementsLength();
    if (
      inputRequirements &&
      inputRequirements.length &&
      inputRequirements.length > 0 &&
      inputRequirements.length > reqlen
    ) {
      for (
        let ii = 0;
        ii < inputRequirements.length;
        ii++, nonce = nonce.add(1)
      ) {
        if (ii < reqlen) {
          console.log(`updating complex requirements to ${name} (${symbol})`);
          if (nonce.eq(0)) {
            tx = await pc.updateInputRequirement(ii, ...inputRequirements[ii]);
            nonce = BigNumber.from(tx.nonce);
          } else {
            tx = await pc.updateInputRequirement(ii, ...inputRequirements[ii], {
              nonce,
            });
          }
        } else {
          console.log(`adding complex requirements to ${name} (${symbol})`);
          if (nonce.eq(0)) {
            tx = await pc.addInputRequirement(...inputRequirements[ii]);
            nonce = BigNumber.from(tx.nonce);
          } else {
            tx = await pc.addInputRequirement(...inputRequirements[ii], {
              nonce,
            });
          }
        }
        await hre.ethers.provider.waitForTransaction(tx.hash, 1);
      }
    }
    return await getGemPoolAddress(symbol);
  };

  return {
    deployContracts,
    deployedContracts: dc,
    getGemPoolAddress,
    getGemTokenAddress,
    getPoolContract,
    createPool,
  };
}
