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
  const waitForTime = 0;

  /**
   * @dev Wait for the given number of seconds and display balance
   */
  const waitFor = async (n: number) => {
    const nbal = await sender.getBalance();
    console.log(`${chainId} ${thisAddr} : spent ${formatEther(bal.sub(nbal))}`);
    return new Promise((resolve) => setTimeout(resolve, n * 1000));
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
      ERC20GemTokenFactory: await getContractAt(
        'ERC20GemTokenFactory',
        (await get('ERC20GemTokenFactory')).address,
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

  const deployedContracts = await getDeployedContracts(sender);
  const dc = deployedContracts;
  const gemTokens: any = {};

  const itemPrice = '0.01';

  /**
   * Create BitRobot APU Pool and Wrapped Token
   */
  console.log('Creating APU pool...');
  await dc.NFTGemGovernor.createSystemPool(
    'APU',
    'BitRobots All-Purpose Unit',
    parseEther(itemPrice),
    300,
    900,
    32,
    0,
    '0x0000000000000000000000000000000000000000',
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);
  console.log('Creating wrapped APU token...');
  gemTokens.Ruby = await dc.ERC20GemTokenFactory.createItem(
    'WAPU',
    'BitRobots All-Purpose Unit',
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['APU'])])
    ),
    dc.NFTGemMultiToken.address,
    8,
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);

  /**
   * Create BitRobot SRR Pool and Wrapped Token
   */
  console.log('Creating SRR pool...');
  await dc.NFTGemGovernor.createSystemPool(
    'SRR',
    'BitRobots Sentry Responder Unit',
    parseEther(itemPrice),
    300,
    900,
    16,
    0,
    '0x0000000000000000000000000000000000000000',
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);
  console.log('Creating wrapped SRR token...');
  gemTokens.Ruby = await dc.ERC20GemTokenFactory.createItem(
    'WSRR',
    'Wrapped BitRobots Sentry Responder Unit',
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['SRR'])])
    ),
    dc.NFTGemMultiToken.address,
    8,
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);

  /**
   * Create BitRobot RNA Pool and Wrapped Token
   */
  console.log('Creating RAU pool...');
  await dc.NFTGemGovernor.createSystemPool(
    'RAU',
    'BitRobots Repair and Assist Unit',
    parseEther(itemPrice),
    300,
    900,
    8,
    0,
    '0x0000000000000000000000000000000000000000',
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);
  console.log('Creating wrapped RAU token...');
  gemTokens.Ruby = await dc.ERC20GemTokenFactory.createItem(
    'WRAU',
    'Wrapped BitRobots Repair and Assist Unit',
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['RAU'])])
    ),
    dc.NFTGemMultiToken.address,
    8,
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);

  /**
   * Create BitRobot RNA Pool and Wrapped Token
   */
  console.log('Creating PAU pool...');
  await dc.NFTGemGovernor.createSystemPool(
    'PAU',
    'BitRobots Personal Assistant Unit',
    parseEther(itemPrice),
    300,
    900,
    4,
    0,
    '0x0000000000000000000000000000000000000000',
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);
  console.log('Creating wrapped PAU token...');
  gemTokens.Ruby = await dc.ERC20GemTokenFactory.createItem(
    'WPAU',
    'Wrapped BitRobots Personal Assistant Unit',
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['PAU'])])
    ),
    dc.NFTGemMultiToken.address,
    8,
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);

  /**
   * Create BitRobot RNA Pool and Wrapped Token
   */
  console.log('Creating PRC pool...');
  await dc.NFTGemGovernor.createSystemPool(
    'PRC',
    'BitRobots Personal Robot Companion',
    parseEther(itemPrice),
    300,
    900,
    3,
    0,
    '0x0000000000000000000000000000000000000000',
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);
  console.log('Creating wrapped PRC token...');
  gemTokens.Ruby = await dc.ERC20GemTokenFactory.createItem(
    'WPRC',
    'Wrapped BitRobots Personal Robot Companion',
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['PRC'])])
    ),
    dc.NFTGemMultiToken.address,
    8,
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);

  /**
   * build depoy params for the complex pool
   */
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

  await deploy('NFTComplexGemPool', deployParams);
  const NFTComplexGemPool = await ethers.getContractFactory(
    'NFTComplexGemPool'
  );
  const NFTComplexGemPoolABI = await get('NFTComplexGemPool');
  await dc.NFTGemPoolFactory.createCustomNFTGemPool(
    NFTComplexGemPoolABI.bytecode,
    'MCU',
    'BitRobots Master Control Unit'
  );
  const addr = await dc.NFTGemPoolFactory.getNFTGemPool(
    keccak256(['bytes'], [pack(['string'], ['MCU'])])
  );
  const customPool = await NFTComplexGemPool.attach(addr);
  await customPool.initialize(
    'MCU',
    'BitRobots Master Control Unit',
    parseEther(itemPrice),
    300,
    900,
    2,
    0,
    '0x0000000000000000000000000000000000000000'
  );
  await customPool.setMultiToken(dc.NFTGemMultiToken.address);
  await customPool.setGovernor(dc.NFTGemGovernor.address);
  await dc.NFTGemMultiToken.addProxyRegistry(addr);
  await dc.NFTGemMultiToken.addController(addr);
  await dc.NFTGemGovernor.addController(addr);
  await customPool.setVisible(false);
  await customPool.addInputRequirement(
    dc.NFTGemMultiToken.address,
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['APU'])])
    ),
    3,
    0,
    1,
    false
  );
  await customPool.addInputRequirement(
    dc.NFTGemMultiToken.address,
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['SRR'])])
    ),
    3,
    0,
    1,
    false
  );
  await customPool.addInputRequirement(
    dc.NFTGemMultiToken.address,
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['RAU'])])
    ),
    3,
    0,
    1,
    false
  );
  await customPool.addInputRequirement(
    dc.NFTGemMultiToken.address,
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['PAU'])])
    ),
    3,
    0,
    1,
    false
  );
  await customPool.addInputRequirement(
    dc.NFTGemMultiToken.address,
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['PRC'])])
    ),
    3,
    0,
    1,
    false
  );
  await waitFor(waitForTime);
  console.log('Creating wrapped MCU token...');
  gemTokens.Ruby = await dc.ERC20GemTokenFactory.createItem(
    'WMCU',
    'Wrapped BitRobots Master Control Unit',
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['MCU'])])
    ),
    dc.NFTGemMultiToken.address,
    8,
    {gasLimit: 5000000}
  );

  // const l = await dc.NFTGemPoolFactory.allNFTGemPoolsLength();
  // const p = await dc.NFTGemPoolFactory.allNFTGemPools(l.sub(1));
  // const aGemPool = ethers.utils.getAddress(p);
  // const GemPool = await ethers.getContractFactory('NFTGemPool');
  // const pool = await GemPool.attach(aGemPool);
  // await pool.setValidateErc20(false);

  // l = await dc.NFTGemPoolFactory.allNFTGemPoolsLength();
  // p = await dc.NFTGemPoolFactory.allNFTGemPools(l.sub(1));
  // aGemPool = ethers.utils.getAddress(p);
  // GemPool = await ethers.getContractFactory('NFTGemPool');
  // pool = await GemPool.attach(aGemPool);
  // await pool.setValidateErc20(false);

  // l = await dc.NFTGemPoolFactory.allNFTGemPoolsLength();
  // p = await dc.NFTGemPoolFactory.allNFTGemPools(l.sub(1));
  // aGemPool = ethers.utils.getAddress(p);
  // GemPool = await ethers.getContractFactory('NFTGemPool');
  // pool = await GemPool.attach(aGemPool);
  // await pool.setVisible(false);
  // await pool.setValidateErc20(false);

  console.log('Deploy complete\n');
  const nbal = await sender.getBalance();
  console.log(`${chainId} ${thisAddr} : ${formatEther(nbal)}`);
  console.log(`spent : ${formatEther(bal.sub(nbal))}`);

  return deployedContracts;
};

func.tags = ['Publish'];
func.dependencies = ['Deploy'];
export default func;
