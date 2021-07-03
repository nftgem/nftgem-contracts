import {formatEther, parseEther} from 'ethers/lib/utils';
import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {pack, keccak256} from '@ethersproject/solidity';
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
      ProposalFactory: await getContractAt(
        'ProposalFactory',
        (await get('ProposalFactory')).address,
        sender
      ),
    };

    /**
     * @dev Load the network-specific DEX-adapters - Uniswap for ETH and FTM,
     * PancakeSwap for BNB, Pangolin for AVAX, or a Mock helper for testing
     */
    if (parseInt(networkId) === 1 || parseInt(networkId) === 250) {
      ret.SwapHelper = await getContractAt(
        'UniswapQueryHelper',
        (await get('UniswapQueryHelper')).address,
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

  if (noDeploy) {
    console.log('Already deployed, returning references\n');
    return await getDeployedContracts(sender);
  }

  /**
   * @dev Deploy all llibraries that support the contract
   */
  console.log('deploying libraries...');
  const govLib = (await deploy('GovernanceLib', libDeployParams)).address;
  const deployParams: any = {
    from: sender.address,
    log: true,
    libraries: {
      GovernanceLib: govLib,
      Strings: (await deploy('Strings', libDeployParams)).address,
      SafeMath: (await deploy('SafeMath', libDeployParams)).address,
      ProposalsLib: (
        await deploy('ProposalsLib', {
          from: sender.address,
          log: true,
          libraries: {
            GovernanceLib: govLib,
          },
        })
      ).address,
      Create2: (await deploy('Create2', libDeployParams)).address,
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
    ProposalFactory: await deploy('ProposalFactory', deployParams),
    ERC20GemTokenFactory: await deploy('ERC20GemTokenFactory', deployParams),
  };

  let ip = utils.parseEther('0.1'),
    pepe = utils.parseEther('10');

  /**
   * @dev Deploy the ETH mainnet / Fantom Uniswap adapter
   */
  if (parseInt(networkId) === 1 || parseInt(networkId) === 250) {
    deploymentData.SwapHelper = await deploy('UniswapQueryHelper', {
      from: sender.address,
      log: true,
      libraries: {
        UniswapLib: (await deploy('UniswapLib', libDeployParams)).address,
      },
    });
  } else if (parseInt(networkId) === 56) {
    /**
     * @dev Deploy the ETH mainnet / Fantom Uniswap adapter
     */
    ip = utils.parseEther('0.05');
    pepe = utils.parseEther('1');

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
    ip = utils.parseEther('1');
    pepe = utils.parseEther('10');

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
    ip = utils.parseEther('0.1');
    pepe = utils.parseEther('1');
    deploymentData.SwapHelper = await deploy('MockQueryHelper', deployParams);
  }

  console.log('loading contracts...');

  const deployedContracts = await getDeployedContracts(sender);
  const dc = deployedContracts;
  let inited = false;

  console.log('initializing governor...');
  try {
    const t = await dc.NFTGemGovernor.initialize(
      dc.NFTGemMultiToken.address,
      dc.NFTGemPoolFactory.address,
      dc.NFTGemFeeManager.address,
      dc.ProposalFactory.address,
      dc.SwapHelper.address
    );
    await waitForMined(t.hash);
  } catch (e) {
    console.log('already inited');
    inited = true;
  }

  if (!inited) {
    try {
      console.log('propagating governor controller...');
      const t = await dc.NFTGemMultiToken.addController(dc.NFTGemGovernor.address);
      await waitForMined(t.hash);
    } catch (e) {
      console.log('already inited');
    }
    try {
      console.log('propagating governor controller...');
      const t = await dc.NFTGemPoolFactory.addController(dc.NFTGemGovernor.address);
      await waitForMined(t.hash);
    } catch (e) {
      console.log('already inited');
    }
    try {
      console.log('propagating governor controller...');
      const t = await dc.ProposalFactory.addController(dc.NFTGemGovernor.address);
      await waitForMined(t.hash);
    } catch (e) {
      console.log('already inited');
    }
    try {
      console.log('propagating governor controller...');
      const t = await dc.NFTGemFeeManager.setOperator(dc.NFTGemGovernor.address);
      await waitForMined(t.hash);
    } catch (e) {
      console.log('already inited');
    }
    try {
      console.log('propagating governor controller...');
      const t = await dc.ERC20GemTokenFactory.setOperator(dc.NFTGemGovernor.address);
      await waitForMined(t.hash);
    } catch (e) {
      console.log('already inited');
    }
  }

  console.log('Deploy complete\n');
  const nbal = await sender.getBalance();
  console.log(`${chainId} ${thisAddr} : ${formatEther(nbal)}`);
  console.log(`spent : ${formatEther(bal.sub(nbal))}`);

  return deployedContracts;
};

func.tags = ['Deploy'];
func.dependencies = [];
export default func;
