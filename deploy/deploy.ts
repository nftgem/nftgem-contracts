import {formatEther, parseEther} from 'ethers/lib/utils';
import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {pack, keccak256} from '@ethersproject/solidity';
import {BigNumber} from 'ethers';
const func: any = async function (
  hre: HardhatRuntimeEnvironment,
  noDeploy?: boolean
) {
  const {ethers, deployments} = hre;
  const networkId = await hre.getChainId();
  const {utils, getContractAt} = ethers;
  const {deploy, get} = deployments;
  const [sender] = await hre.ethers.getSigners();
  const libDeployParams = {
    from: sender.address,
    log: true,
  };
  const waitForTime = 0;

  /**
   * @dev Wait for the given number of seconds and display balance
   */
  const waitFor = async (n: number) => {
    const nbal = await sender.getBalance();
    console.log(`${chainId} ${thisAddr} : spent ${formatEther(bal.sub(nbal))}`);
    return new Promise((resolve) => setTimeout(resolve, n * 1000));
  };

  const waitForMined = async (transactionHash: string) => {
    return new Promise((resolve) => {
      const _checkReceipt = async () => {
        const txReceipt = await await hre.ethers.provider.getTransactionReceipt(
          transactionHash
        );
        return txReceipt && txReceipt.blockNumber ? txReceipt : null;
      };
      const interval = setInterval(() => {
        _checkReceipt().then((r: any) => {
          if (r) {
            clearInterval(interval);
            resolve(true);
          }
        });
      }, 500);
    });
  };

  /**
   * @dev Load all deployed contracts
   */
  async function getDeployedContracts(sender: any) {
    const ret: any = {
      NFTGemGovernor: await getContractAt(
        'NFTGemGovernor',
        (await get('NFTGemGovernor')).address,
        sender
      ),
      NFTGemMultiToken: await getContractAt(
        'NFTGemMultiToken',
        (await get('NFTGemMultiToken')).address,
        sender
      ),
      NFTGemPoolFactory: await getContractAt(
        'NFTGemPoolFactory',
        (await get('NFTGemPoolFactory')).address,
        sender
      ),
      NFTGemFeeManager: await getContractAt(
        'NFTGemFeeManager',
        (await get('NFTGemFeeManager')).address,
        sender
      ),
      NFTGemWrapperFeeManager: await getContractAt(
        'NFTGemWrapperFeeManager',
        (await get('NFTGemWrapperFeeManager')).address,
        sender
      ),
      ProposalFactory: await getContractAt(
        'ProposalFactory',
        (await get('ProposalFactory')).address,
        sender
      ),
      ERC20GemTokenFactory: await getContractAt(
        'ERC20GemTokenFactory',
        (await get('ERC20GemTokenFactory')).address,
        sender
      ),
      Unigem1155Factory: await getContractAt(
        'Unigem1155Factory',
        (await get('Unigem1155Factory')).address,
        sender
      ),
      Unigem20Factory: await getContractAt(
        'Unigem20Factory',
        (await get('Unigem20Factory')).address,
        sender
      ),
      MockProxyRegistry: await getContractAt(
        'MockProxyRegistry',
        (await get('MockProxyRegistry')).address,
        sender
      ),
    };

    /**
     * @dev Load the network-specific DEX-adapters - Uniswap for ETH and FTM,
     * PancakeSwap for BNB, Pangolin for AVAX, or a Mock helper for testing
     */
    if (parseInt(networkId) === 1) {
      ret.SwapHelper = await getContractAt(
        'UniswapQueryHelper',
        (await get('UniswapQueryHelper')).address,
        sender
      );
    } else if (parseInt(networkId) === 250) {
      ret.SwapHelper = await getContractAt(
        'SushiSwapQueryHelper',
        (await get('SushiSwapQueryHelper')).address,
        sender
      );
    } else if (parseInt(networkId) === 43114) {
      ret.SwapHelper = await getContractAt(
        'PangolinQueryHelper',
        (await get('PangolinQueryHelper')).address,
        sender
      );
    } else if (parseInt(networkId) === 56) {
      ret.SwapHelper = await getContractAt(
        'PancakeSwapQueryHelper',
        (await get('PancakeSwapQueryHelper')).address,
        sender
      );
    } else {
      ret.SwapHelper = await getContractAt(
        'MockQueryHelper',
        (await get('MockQueryHelper')).address,
        sender
      );
    }
    return ret;
  }

  /**
   * @dev retrieve and display address, chain, balance
   */
  console.log('Bitgem deploy\n');
  const bal = await sender.getBalance();
  const thisAddr = await sender.getAddress();
  const chainId = (await ethers.provider.getNetwork()).chainId;
  console.log(`${chainId} ${thisAddr} : ${formatEther(bal)}`);

  /**
   * @dev adding a wait between contract calls is the only I have been able
   * to successfully deploy w/o issues 100% of the time
   */
  await waitFor(5);

  if (noDeploy) {
    console.log('Already deployed, returning references\n');
    return await getDeployedContracts(sender);
  }

  /**
   * @dev Deploy all llibraries that support the contract
   */
  console.log('deploying libraries...');
  const govLib = (await deploy('GovernanceLib', libDeployParams)).address;
  const strings = (await deploy('Strings', libDeployParams)).address;
  const safeMath = (await deploy('SafeMath', libDeployParams)).address;
  const addressSet = (await deploy('AddressSet', libDeployParams)).address;
  const uint256Set = (await deploy('UInt256Set', libDeployParams)).address;
  const deployParams: any = {
    from: sender.address,
    log: true,
    libraries: {
      GovernanceLib: govLib,
      Strings: strings,
      SafeMath: safeMath,
      AddressSet: addressSet,
      UInt256Set: uint256Set,
      Create2: (await deploy('Create2', libDeployParams)).address,
      ProposalsLib: (
        await deploy('ProposalsLib', {
          from: sender.address,
          log: true,
          libraries: {
            GovernanceLib: govLib,
          },
        })
      ).address,
      ComplexPoolLib: (
        await deploy('ComplexPoolLib', {
          from: sender.address,
          log: true,
          libraries: {
            AddressSet: addressSet,
            SafeMath: safeMath,
          },
        })
      ).address,
      WrappedTokenLib: (
        await deploy('WrappedTokenLib', {
          from: sender.address,
          log: true,
          libraries: {
            SafeMath: safeMath,
          },
        })
      ).address,
    },
  };

  /**
   * @dev Deploy all the contracts
   */
  console.log('deploying contracts...');
  const deploymentData: any = {
    SwapHelper: null,
    NFTGemGovernor: await deploy('NFTGemGovernor', deployParams),
    NFTGemMultiToken: await deploy('NFTGemMultiToken', deployParams),
    NFTGemPoolFactory: await deploy('NFTGemPoolFactory', deployParams),
    NFTGemFeeManager: await deploy('NFTGemFeeManager', deployParams),
    NFTGemWrapperFeeManager: await deploy(
      'NFTGemWrapperFeeManager',
      deployParams
    ),
    ProposalFactory: await deploy('ProposalFactory', deployParams),
    MockProxyRegistry: await deploy('MockProxyRegistry', deployParams),
    ERC20GemTokenFactory: await deploy('ERC20GemTokenFactory', deployParams),
    Unigem1155Factory: await deploy('Unigem1155Factory', deployParams),
    Unigem20Factory: await deploy('Unigem20Factory', deployParams),
    WETH9: await deploy('WETH9', deployParams),
  };

  /**
   * @dev Deploy the ETH mainnet / Fantom Uniswap adapter
   */
  if (parseInt(networkId) === 1) {
    /**
     * @dev Deploy the Uniswap adapter
     */
    deploymentData.SwapHelper = await deploy('UniswapQueryHelper', {
      from: sender.address,
      log: true,
      libraries: {
        UniswapLib: (await deploy('UniswapLib', libDeployParams)).address,
      },
    });
  } else if (parseInt(networkId) === 250) {
    /**
     * @dev Deploy the SushiSwap adapter
     */
    deploymentData.SwapHelper = await deploy('SushiSwapQueryHelper', {
      from: sender.address,
      log: true,
      libraries: {
        SushiSwapLib: (await deploy('SushiSwapLib', libDeployParams)).address,
      },
    });
  } else if (parseInt(networkId) === 56) {
    /**
     * @dev Deploy the PancakeSwap adapter
     */
    deploymentData.SwapHelper = await deploy('PancakeSwapQueryHelper', {
      from: sender.address,
      log: true,
      libraries: {
        PancakeSwapLib: (await deploy('PancakeSwapLib', libDeployParams))
          .address,
      },
    });
  } else if (parseInt(networkId) === 43114) {
    /**
     * @dev Deploy the Avanlanche Pangolin adapter
     */
    deploymentData.SwapHelper = await deploy('PangolinQueryHelper', {
      from: sender.address,
      log: true,
      libraries: {
        PangolinLib: (await deploy('PangolinLib', libDeployParams)).address,
      },
    });
  } else {
    /**
     * @dev Test adapter
     */
    deploymentData.SwapHelper = await deploy('MockQueryHelper', deployParams);
  }

  console.log('loading contracts...');
  await waitFor(waitForTime);

  const deployedContracts = await getDeployedContracts(sender);
  const dc = deployedContracts;
  const ds = 86400;
  const ms = ds * 30;

  console.log('initializing governor...');

  const inited = await dc.NFTGemGovernor.initialized();

  if (!inited) {
    let tx = await dc.NFTGemGovernor.initialize(
      dc.NFTGemMultiToken.address,
      dc.NFTGemPoolFactory.address,
      dc.NFTGemFeeManager.address,
      dc.ProposalFactory.address,
      dc.SwapHelper.address
    );
    await waitForMined(tx.hash);

    console.log('propagating multitoken controller...');
    tx = await dc.NFTGemMultiToken.addController(dc.NFTGemGovernor.address);
    await waitForMined(tx.hash);

    console.log('propagating pool factory  controller...');
    tx = await dc.NFTGemPoolFactory.addController(dc.NFTGemGovernor.address);
    await waitForMined(tx.hash);

    console.log('propagating proposal factory controller...');
    tx = await dc.ProposalFactory.addController(dc.NFTGemGovernor.address);
    await waitForMined(tx.hash);

    console.log('propagating fee manager controller...');
    tx = await dc.NFTGemFeeManager.addController(dc.NFTGemGovernor.address);
    await waitForMined(tx.hash);

    console.log('propagating wrapper fee manager controller...');
    tx = await dc.NFTGemWrapperFeeManager.addController(
      dc.NFTGemGovernor.address
    );
    await waitForMined(tx.hash);

    console.log('propagating gem token controller...');
    tx = await dc.ERC20GemTokenFactory.addController(dc.NFTGemGovernor.address);
    await waitForMined(tx.hash);

    console.log('minting initial governance tokens...');
    tx = await dc.NFTGemGovernor.issueInitialGovernanceTokens(sender.address, {
      gasLimit: 5000000,
    });
    await waitForMined(tx.hash);

    // deploy the governance token wrapper
    console.log('deploying wrapped governance token...');
    deployParams.args = [
      'Bitlootbox Governance',
      'BLBXG',
      dc.NFTGemMultiToken.address,
      dc.NFTGemWrapperFeeManager.address
    ];
    await deploy('NFTGemWrappedERC20Governance', deployParams);

    // init governance token wrapper
    console.log('intializing wrapped governance token...');
    await waitFor(1);
    dc.NFTGemWrappedERC20Governance = await getContractAt(
      'NFTGemWrappedERC20Governance',
      (await get('NFTGemWrappedERC20Governance')).address,
      sender
    );
    tx = await dc.NFTGemWrappedERC20Governance.initialize(
      '',
      '',
      '0x0000000000000000000000000000000000000000',
      '0x0000000000000000000000000000000000000000',
      0,
      dc.NFTGemWrapperFeeManager.address
    );
    await waitForMined(tx.hash);

    // approve the wrappedgem contract
    console.log('approving wrapped governance token as operator...');
    tx = await dc.NFTGemMultiToken.setApprovalForAll(
      dc.NFTGemWrappedERC20Governance.address,
      true,
      {from: sender.address}
    );
    await waitForMined(tx.hash);

    console.log('minting initial fuel tokens...');
    tx = await dc.NFTGemGovernor.issueInitialFuelTokens(sender.address, {
      gasLimit: 5000000,
    });
    await waitForMined(tx.hash);

    // deploy the fuel token wrapper
    console.log('deploying wrapped fuel token...');
    deployParams.args = [
      'Bitlootbox Fuel',
      'BLBXF',
      dc.NFTGemMultiToken.address,
      dc.NFTGemWrapperFeeManager.address
    ];
    await deploy('NFTGemWrappedERC20Fuel', deployParams);

    // init fuel token wrapper
    console.log('intializing wrapped fuel token...');
    await waitFor(1);
    dc.NFTGemWrappedERC20Fuel = await getContractAt(
      'NFTGemWrappedERC20Fuel',
      (await get('NFTGemWrappedERC20Fuel')).address,
      sender
    );
    tx = await dc.NFTGemWrappedERC20Fuel.initialize(
      '',
      '',
      '0x0000000000000000000000000000000000000000',
      '0x0000000000000000000000000000000000000000',
      0,
      dc.NFTGemWrapperFeeManager.address
    );
    await waitForMined(tx.hash);

    // approve the wrapped fuel contract
    console.log('approving wrapped fuel token as operator...');
    tx = await dc.NFTGemMultiToken.setApprovalForAll(
      dc.NFTGemWrappedERC20Fuel.address,
      true,
      {from: sender.address}
    );
    await waitForMined(tx.hash);

    // wrap 100k governance tokens
    console.log('wrapping 500k fuel tokens...');
    tx = await dc.NFTGemWrappedERC20Governance.wrap('100000', {
      from: sender.address,
      gasLimit: 5000000,
    });
    await waitForMined(tx.hash);

  }

  // we are done!
  console.log('Deploy complete\n');
  const nbal = await sender.getBalance();
  console.log(`${chainId} ${thisAddr} : ${formatEther(nbal)}`);
  console.log(`spent : ${formatEther(bal.sub(nbal))}`);

  return deployedContracts;
};

func.tags = ['Deploy'];
func.dependencies = [];
export default func;
