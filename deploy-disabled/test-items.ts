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

  const deployParams: any = {
    from: sender.address,
    log: true,
    libraries: {
      ComplexPoolLib: (await get('ComplexPoolLib')).address,
    },
  };

  /**
   * Create BitRobot TT1 Pool and Wrapped Token
   */
  console.log('Creating TT1 pool...');
  await dc.NFTGemGovernor.createSystemPool(
    'TT1',
    'Test Thing 1',
    parseEther(itemPrice),
    300,
    900,
    32,
    0,
    '0x0000000000000000000000000000000000000000',
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);
  console.log('Creating wrapped TT1 token...');
  gemTokens.Ruby = await dc.ERC20GemTokenFactory.createItem(
    'WTT1',
    'Test Thing 1',
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['TT1'])])
    ),
    dc.NFTGemMultiToken.address,
    18,
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);

  /**
   * Create BitRobot TT2 Pool and Wrapped Token
   */
  console.log('Creating TT2 pool...');
  await dc.NFTGemGovernor.createSystemPool(
    'TT2',
    'Test Thing 2',
    parseEther(itemPrice),
    300,
    900,
    16,
    0,
    '0x0000000000000000000000000000000000000000',
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);
  console.log('Creating wrapped TT2 token...');
  gemTokens.Ruby = await dc.ERC20GemTokenFactory.createItem(
    'WTT2',
    'Wrapped Test Thing 2',
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['TT2'])])
    ),
    dc.NFTGemMultiToken.address,
    18,
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);

  /**
   * Create BitRobot RNA Pool and Wrapped Token
   */
  console.log('Creating TT3 pool...');
  await dc.NFTGemGovernor.createSystemPool(
    'TT3',
    'Test Thing 3',
    parseEther(itemPrice),
    300,
    900,
    8,
    0,
    '0x0000000000000000000000000000000000000000',
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);
  console.log('Creating wrapped TT3 token...');
  gemTokens.Ruby = await dc.ERC20GemTokenFactory.createItem(
    'WTT3',
    'Wrapped Test Thing 3',
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['TT3'])])
    ),
    dc.NFTGemMultiToken.address,
    18,
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);

  /**
   * Create BitRobot RNA Pool and Wrapped Token
   */
  console.log('Creating TT4 pool...');
  await dc.NFTGemGovernor.createSystemPool(
    'TT4',
    'Test Thing 4',
    parseEther(itemPrice),
    300,
    900,
    4,
    0,
    '0x0000000000000000000000000000000000000000',
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);
  console.log('Creating wrapped TT4 token...');
  gemTokens.Ruby = await dc.ERC20GemTokenFactory.createItem(
    'WTT4',
    'Wrapped Test Thing 4',
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['TT4'])])
    ),
    dc.NFTGemMultiToken.address,
    18,
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);

  /**
   * Create BitRobot RNA Pool and Wrapped Token
   */
  console.log('Creating TT5 pool...');
  await dc.NFTGemGovernor.createSystemPool(
    'TT5',
    'Test Thing 5',
    parseEther(itemPrice),
    300,
    900,
    3,
    0,
    '0x0000000000000000000000000000000000000000',
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);
  console.log('Creating wrapped TT5 token...');
  gemTokens.Ruby = await dc.ERC20GemTokenFactory.createItem(
    'WTT5',
    'Wrapped Test Thing 5',
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['TT5'])])
    ),
    dc.NFTGemMultiToken.address,
    18,
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);

  /**
   * Create BitRobot Master Control Unit
   */
  await dc.NFTGemGovernor.createSystemPool(
    'CT1',
    'Complex Thing 1',
    parseEther(itemPrice),
    3600,
    14400,
    2,
    0,
    '0x0000000000000000000000000000000000000000',
    {gasLimit: 5000000}
  );

  // get the contract factory for the complex pool
  // and attach the newly-created pool address
  const NFTComplexGemPool = await ethers.getContractFactory(
    'NFTComplexGemPool',
    deployParams
  );
  let addr = await dc.NFTGemPoolFactory.getNFTGemPool(
    keccak256(['bytes'], [pack(['string'], ['CT1'])])
  );
  let customPool = await NFTComplexGemPool.attach(addr);

  // hide the pool
  console.log('visible false');
  await customPool.setVisible(true);

  // add input requirements
  await waitFor(waitForTime);
  await customPool.addInputRequirement(
    dc.NFTGemMultiToken.address,
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['TT1'])])
    ),
    3,
    0,
    1,
    false
  );
  await waitFor(waitForTime);
  await customPool.addInputRequirement(
    dc.NFTGemMultiToken.address,
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['TT2'])])
    ),
    3,
    0,
    1,
    false
  );
  await waitFor(waitForTime);
  await customPool.addInputRequirement(
    dc.NFTGemMultiToken.address,
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['TT3'])])
    ),
    3,
    0,
    1,
    false
  );
  await waitFor(waitForTime);
  await customPool.addInputRequirement(
    dc.NFTGemMultiToken.address,
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['TT4'])])
    ),
    3,
    0,
    1,
    false
  );
  await waitFor(waitForTime);
  await customPool.addInputRequirement(
    dc.NFTGemMultiToken.address,
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['TT5'])])
    ),
    3,
    0,
    1,
    false
  );
  await waitFor(waitForTime);
  console.log('Creating wrapped WCT1 token...');
  gemTokens.Ruby = await dc.ERC20GemTokenFactory.createItem(
    'WCT1',
    'Wrapped Complex Thing 1',
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['CT1'])])
    ),
    dc.NFTGemMultiToken.address,
    18,
    {gasLimit: 5000000}
  );

  /**
   * AssemblaMen - business man
   */
  console.log('Creating TT7 pool...');
  await dc.NFTGemGovernor.createSystemPool(
    'TT7',
    'Test Thing 7',
    parseEther(itemPrice),
    3600,
    3600,
    32,
    0,
    '0x0000000000000000000000000000000000000000',
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);
  console.log('Creating wrapped TT7 token...');
  gemTokens.Ruby = await dc.ERC20GemTokenFactory.createItem(
    'WTT7',
    'Wrapped Test Thing 7',
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['TT7'])])
    ),
    dc.NFTGemMultiToken.address,
    18,
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);

  /**
   * AssemblaMen - party man
   */
  console.log('Creating TT8 pool...');
  await dc.NFTGemGovernor.createSystemPool(
    'TT8',
    'Test Thing 8',
    parseEther(itemPrice),
    3600,
    3600,
    24,
    0,
    '0x0000000000000000000000000000000000000000',
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);
  console.log('Creating wrapped TT8 token...');
  gemTokens.Ruby = await dc.ERC20GemTokenFactory.createItem(
    'WTT8',
    'Wrapped Test Thing 8',
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['TT8'])])
    ),
    dc.NFTGemMultiToken.address,
    18,
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);

  /**
   * AssemblaMen - chef man
   */
  console.log('Creating TT9 pool...');
  await dc.NFTGemGovernor.createSystemPool(
    'TT9',
    'Test Thing 9',
    parseEther(itemPrice),
    3600,
    3600,
    12,
    0,
    '0x0000000000000000000000000000000000000000',
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);
  console.log('Creating wrapped TT9 token...');
  gemTokens.chef = await dc.ERC20GemTokenFactory.createItem(
    'WTT9',
    'Wrapped Test Thing 9',
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['TT9'])])
    ),
    dc.NFTGemMultiToken.address,
    18,
    {gasLimit: 5000000}
  );
  await waitFor(waitForTime);

  /**
   * AssemblaMen - Astronaut
   */
  let txn: any = await dc.NFTGemGovernor.createSystemPool(
    'CT2',
    'Complex Thing 2',
    parseEther(itemPrice),
    86400,
    86400,
    2,
    0,
    '0x0000000000000000000000000000000000000000',
    {gasLimit: 5000000}
  );

  const sp: any = sender.provider;
  //if(sp) sp.waitForTransaction(txn);

  // get the contract factory for the complex pool
  // and attach the newly-created pool address

  const pools: any = Promise.all([
    dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['CT2'])])
    ),
    dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['TT7'])])
    ),
    dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['TT8'])])
    ),
    dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['TT9'])])
    ),
  ]);

  customPool = await NFTComplexGemPool.attach(pools[0]);
  await customPool.setVisible(true);

  txn = await dc.ERC20GemTokenFactory.createItem(
    'WCT2',
    'Complex Thing 2',
    pools[0],
    dc.NFTGemMultiToken.address,
    18,
    {gasLimit: 5000000}
  );
  //sp.waitForTransaction(txn);

  txn = await customPool.addInputRequirement(
    dc.NFTGemMultiToken.address,
    pools[1],
    3,
    0,
    1,
    false,
    {gasLimit: 5000000}
  );
  //sp.waitForTransaction(txn);

  txn = await customPool.addInputRequirement(
    dc.NFTGemMultiToken.address,
    pools[2],
    3,
    0,
    1,
    false,
    {gasLimit: 5000000}
  );
  //sp.waitForTransaction(txn);

  txn = await customPool.addInputRequirement(
    dc.NFTGemMultiToken.address,
    pools[3],
    3,
    0,
    1,
    false,
    {gasLimit: 5000000}
  );
  //sp.waitForTransaction(txn);

  /**
   * Lint
   */
  console.log('Creating Lint pool...');
  await dc.NFTGemGovernor.createSystemPool(
    'LINT',
    'Lint',
    parseEther(itemPrice),
    1,
    1,
    65536 * 65536,
    0,
    '0x0000000000000000000000000000000000000000',
    {gasLimit: 5000000}
  );

  // get a reference to lint pool
  addr = await dc.NFTGemPoolFactory.getNFTGemPool(
    keccak256(['bytes'], [pack(['string'], ['LINT'])])
  );
  customPool = await NFTComplexGemPool.attach(addr);

  await waitFor(waitForTime);
  console.log('visible false');
  await customPool.setVisible(true);

  // mint some #2 - admin token
  await waitFor(waitForTime);
  await dc.NFTGemMultiToken.mint(sender.address, 2, 100);

  // require admin token to mint
  await waitFor(waitForTime);
  await customPool.addInputRequirement(
    dc.NFTGemMultiToken.address,
    '0x0000000000000000000000000000000000000000',
    2,
    2,
    1,
    false,
    {gasLimit: 5000000}
  );
  await customPool.setVisible(true);

  // we are done!
  console.log('Deploy complete\n');
  const nbal = await sender.getBalance();
  console.log(`${chainId} ${thisAddr} : ${formatEther(nbal)}`);
  console.log(`spent : ${formatEther(bal.sub(nbal))}`);

  // dc.NFTGemMultiToken.safeTransferFrom(
  //   sender.address,
  //   '0x217b7DAB288F91551A0e8483aC75e55EB3abC89F',
  //   2,
  //   1,
  //   0
  // );

  return deployedContracts;
};

func.dependencies = ['Deploy'];
export default func;
