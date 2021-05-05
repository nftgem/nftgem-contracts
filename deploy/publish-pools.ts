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

  // /**
  //  * Create BitRobot APU Pool and Wrapped Token
  //  */
  // console.log('Creating APU pool...');
  // await dc.NFTGemGovernor.createSystemPool(
  //   'APU',
  //   'BitRobots All-Purpose Unit',
  //   parseEther(itemPrice),
  //   300,
  //   900,
  //   32,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 5000000}
  // );
  // await waitFor(waitForTime);
  // console.log('Creating wrapped APU token...');
  // gemTokens.Ruby = await dc.ERC20GemTokenFactory.createItem(
  //   'WAPU',
  //   'BitRobots All-Purpose Unit',
  //   await dc.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['APU'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   18,
  //   {gasLimit: 5000000}
  // );
  // await waitFor(waitForTime);

  // /**
  //  * Create BitRobot SRR Pool and Wrapped Token
  //  */
  // console.log('Creating SRR pool...');
  // await dc.NFTGemGovernor.createSystemPool(
  //   'SRR',
  //   'BitRobots Sentry Responder Unit',
  //   parseEther(itemPrice),
  //   300,
  //   900,
  //   16,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 5000000}
  // );
  // await waitFor(waitForTime);
  // console.log('Creating wrapped SRR token...');
  // gemTokens.Ruby = await dc.ERC20GemTokenFactory.createItem(
  //   'WSRR',
  //   'Wrapped BitRobots Sentry Responder Unit',
  //   await dc.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['SRR'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   18,
  //   {gasLimit: 5000000}
  // );
  // await waitFor(waitForTime);

  // /**
  //  * Create BitRobot RNA Pool and Wrapped Token
  //  */
  // console.log('Creating RAU pool...');
  // await dc.NFTGemGovernor.createSystemPool(
  //   'RAU',
  //   'BitRobots Repair and Assist Unit',
  //   parseEther(itemPrice),
  //   300,
  //   900,
  //   8,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 5000000}
  // );
  // await waitFor(waitForTime);
  // console.log('Creating wrapped RAU token...');
  // gemTokens.Ruby = await dc.ERC20GemTokenFactory.createItem(
  //   'WRAU',
  //   'Wrapped BitRobots Repair and Assist Unit',
  //   await dc.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['RAU'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   18,
  //   {gasLimit: 5000000}
  // );
  // await waitFor(waitForTime);

  // /**
  //  * Create BitRobot RNA Pool and Wrapped Token
  //  */
  // console.log('Creating PAU pool...');
  // await dc.NFTGemGovernor.createSystemPool(
  //   'PAU',
  //   'BitRobots Personal Assistant Unit',
  //   parseEther(itemPrice),
  //   300,
  //   900,
  //   4,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 5000000}
  // );
  // await waitFor(waitForTime);
  // console.log('Creating wrapped PAU token...');
  // gemTokens.Ruby = await dc.ERC20GemTokenFactory.createItem(
  //   'WPAU',
  //   'Wrapped BitRobots Personal Assistant Unit',
  //   await dc.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['PAU'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   18,
  //   {gasLimit: 5000000}
  // );
  // await waitFor(waitForTime);

  // /**
  //  * Create BitRobot RNA Pool and Wrapped Token
  //  */
  // console.log('Creating PRC pool...');
  // await dc.NFTGemGovernor.createSystemPool(
  //   'PRC',
  //   'BitRobots Personal Robot Companion',
  //   parseEther(itemPrice),
  //   300,
  //   900,
  //   3,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 5000000}
  // );
  // await waitFor(waitForTime);
  // console.log('Creating wrapped PRC token...');
  // gemTokens.Ruby = await dc.ERC20GemTokenFactory.createItem(
  //   'WPRC',
  //   'Wrapped BitRobots Personal Robot Companion',
  //   await dc.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['PRC'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   18,
  //   {gasLimit: 5000000}
  // );
  // await waitFor(waitForTime);

  // /**
  //  * Create BitRobot Master Control Unit
  //  */
  // await dc.NFTGemGovernor.createSystemPool(
  //   'MCU',
  //   'BitRobots Master Control Unit',
  //   parseEther(itemPrice),
  //   3600,
  //   14400,
  //   2,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 5000000}
  // );

  // get the contract factory for the complex pool
  // and attach the newly-created pool address
  // const NFTComplexGemPool = await ethers.getContractFactory(
  //   'NFTComplexGemPool',
  //   deployParams
  // );
  // let addr = await dc.NFTGemPoolFactory.getNFTGemPool(
  //   keccak256(['bytes'], [pack(['string'], ['MCU'])])
  // );
  // let customPool = await NFTComplexGemPool.attach(addr);

  // // hide the pool
  // console.log('visible false');
  // await customPool.setVisible(true);

  // // add input requirements
  // await waitFor(waitForTime);
  // await customPool.addInputRequirement(
  //   dc.NFTGemMultiToken.address,
  //   await dc.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['APU'])])
  //   ),
  //   3,
  //   0,
  //   1,
  //   false
  // );
  // await waitFor(waitForTime);
  // await customPool.addInputRequirement(
  //   dc.NFTGemMultiToken.address,
  //   await dc.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['SRR'])])
  //   ),
  //   3,
  //   0,
  //   1,
  //   false
  // );
  // await waitFor(waitForTime);
  // await customPool.addInputRequirement(
  //   dc.NFTGemMultiToken.address,
  //   await dc.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['RAU'])])
  //   ),
  //   3,
  //   0,
  //   1,
  //   false
  // );
  // await waitFor(waitForTime);
  // await customPool.addInputRequirement(
  //   dc.NFTGemMultiToken.address,
  //   await dc.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['PAU'])])
  //   ),
  //   3,
  //   0,
  //   1,
  //   false
  // );
  // await waitFor(waitForTime);
  // await customPool.addInputRequirement(
  //   dc.NFTGemMultiToken.address,
  //   await dc.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['PRC'])])
  //   ),
  //   3,
  //   0,
  //   1,
  //   false
  // );
  // await waitFor(waitForTime);
  // console.log('Creating wrapped MCU token...');
  // gemTokens.Ruby = await dc.ERC20GemTokenFactory.createItem(
  //   'WMCU',
  //   'Wrapped BitRobots Master Control Unit',
  //   await dc.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['MCU'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   18,
  //   {gasLimit: 5000000}
  // );

  // /**
  //  * AssemblaMen - business man
  //  */
  // console.log('Creating AMBUS pool...');
  // await dc.NFTGemGovernor.createSystemPool(
  //   'AMBUS',
  //   'AssemblaMen Business Man',
  //   parseEther('100'),
  //   3600,
  //   3600,
  //   32,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 5000000}
  // );
  // await waitFor(waitForTime);
  // console.log('Creating wrapped AMBUS token...');
  // gemTokens.Ruby = await dc.ERC20GemTokenFactory.createItem(
  //   'WAMBUS',
  //   'Wrapped AssemblaMen Business Man',
  //   await dc.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['AMBUS'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   18,
  //   {gasLimit: 5000000}
  // );
  // await waitFor(waitForTime);

  // /**
  //  * AssemblaMen - party man
  //  */
  // console.log('Creating AMPAR pool...');
  // await dc.NFTGemGovernor.createSystemPool(
  //   'AMPAR',
  //   'AssemblaMen Party Man',
  //   parseEther('100'),
  //   3600,
  //   3600,
  //   24,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 5000000}
  // );
  // await waitFor(waitForTime);
  // console.log('Creating wrapped AMPAR token...');
  // gemTokens.Ruby = await dc.ERC20GemTokenFactory.createItem(
  //   'WAMPAR',
  //   'Wrapped AssemblaMen Party Man',
  //   await dc.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['AMPAR'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   18,
  //   {gasLimit: 5000000}
  // );
  // await waitFor(waitForTime);

  // /**
  //  * AssemblaMen - chef man
  //  */
  // console.log('Creating AMCHF pool...');
  // await dc.NFTGemGovernor.createSystemPool(
  //   'AMCHF',
  //   'AssemblaMen Chef',
  //   parseEther('250'),
  //   3600,
  //   3600,
  //   12,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 5000000}
  // );
  // await waitFor(waitForTime);
  // console.log('Creating wrapped AMCHF token...');
  // gemTokens.chef = await dc.ERC20GemTokenFactory.createItem(
  //   'WAMCHF',
  //   'Wrapped AssemblaMen Chef',
  //   await dc.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['AMCHF'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   18,
  //   {gasLimit: 5000000}
  // );
  // await waitFor(waitForTime);

  /**
   * AssemblaMen - Astronaut
   */
  await dc.NFTGemGovernor.createSystemPool(
    'ASTRO',
    'AssemblaMen Astronaut',
    parseEther('500'),
    3600,
    3600,
    4,
    0,
    '0x0000000000000000000000000000000000000000',
    {gasLimit: 5000000}
  );
  await waitFor(2);
  console.log('Creating wrapped ASTRO token...');
  gemTokens.chef = await dc.ERC20GemTokenFactory.createItem(
    'WASTRO',
    'Wrapped AssemblaMen Astronaut',
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['ASTRO'])])
    ),
    dc.NFTGemMultiToken.address,
    18,
    {gasLimit: 5000000}
  );

  await waitFor(2);

  await dc.NFTGemGovernor.createSystemPool(
    'BLHOP',
    'AssemblaMen Bellhop',
    parseEther('100'),
    3600,
    3600,
    32,
    0,
    '0x0000000000000000000000000000000000000000',
    {gasLimit: 5000000}
  );
  await waitFor(2);
  console.log('Creating wrapped BLHOP token...');
  gemTokens.chef = await dc.ERC20GemTokenFactory.createItem(
    'WBLHOP',
    'Wrapped AssemblaMen Bellhop',
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['BLHOP'])])
    ),
    dc.NFTGemMultiToken.address,
    18,
    {gasLimit: 5000000}
  );

  await dc.NFTGemGovernor.createSystemPool(
    'FRMAN',
    'AssemblaMen Foreman',
    parseEther('250'),
    3600,
    3600,
    16,
    0,
    '0x0000000000000000000000000000000000000000',
    {gasLimit: 5000000}
  );
  await waitFor(2);
  console.log('Creating wrapped FRMAN token...');
  gemTokens.chef = await dc.ERC20GemTokenFactory.createItem(
    'WFRMAN',
    'Wrapped AssemblaMen Foreman',
    await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], ['FRMAN'])])
    ),
    dc.NFTGemMultiToken.address,
    18,
    {gasLimit: 5000000}
  );

  // // get the contract factory for the complex pool
  // // and attach the newly-created pool address
  // addr = await dc.NFTGemPoolFactory.getNFTGemPool(
  //   keccak256(['bytes'], [pack(['string'], ['ASTRO'])])
  // );
  // customPool = await NFTComplexGemPool.attach(addr);

  // // hide the pool
  // await waitFor(waitForTime);
  // console.log('visible false');
  // await customPool.setVisible(true);

  // // add input requirements
  // await waitFor(waitForTime);
  // await customPool.addInputRequirement(
  //   dc.NFTGemMultiToken.address,
  //   await dc.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['AMBUS'])])
  //   ),
  //   3,
  //   0,
  //   1,
  //   false,
  //   {gasLimit: 5000000}
  // );
  // await waitFor(waitForTime);
  // await customPool.addInputRequirement(
  //   dc.NFTGemMultiToken.address,
  //   await dc.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['AMPAR'])])
  //   ),
  //   3,
  //   0,
  //   1,
  //   false,
  //   {gasLimit: 5000000}
  // );
  // await waitFor(waitForTime);
  // await customPool.addInputRequirement(
  //   dc.NFTGemMultiToken.address,
  //   await dc.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['AMCHF'])])
  //   ),
  //   3,
  //   0,
  //   1,
  //   false,
  //   {gasLimit: 5000000}
  // );
  // await waitFor(waitForTime);
  // console.log('Creating wrapped AMAST token...');
  // gemTokens.chef = await dc.ERC20GemTokenFactory.createItem(
  //   'WAMAST',
  //   'Wrapped AssemblaMen Astronaut',
  //   await dc.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['AMAST'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   18,
  //   {gasLimit: 5000000}
  // );

  // /**
  //  * Lint
  //  */
  // console.log('Creating Lint pool...');
  // await dc.NFTGemGovernor.createSystemPool(
  //   'LINT',
  //   'Lint',
  //   parseEther('0.01'),
  //   1,
  //   1,
  //   65536 * 65536,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 5000000}
  // );

  // // get a reference to lint pool
  // addr = await dc.NFTGemPoolFactory.getNFTGemPool(
  //   keccak256(['bytes'], [pack(['string'], ['LINT'])])
  // );
  // customPool = await NFTComplexGemPool.attach(addr);

  // await waitFor(waitForTime);
  // console.log('visible false');
  // await customPool.setVisible(true);

  // // mint some #2 - admin token
  // await waitFor(waitForTime);
  // await dc.NFTGemMultiToken.mint(sender.address, 2, 100);

  // // require admin token to mint
  // await waitFor(waitForTime);
  // await customPool.addInputRequirement(
  //   dc.NFTGemMultiToken.address,
  //   '0x0000000000000000000000000000000000000000',
  //   2,
  //   2,
  //   1,
  //   false,
  //   {gasLimit: 5000000}
  // );
  // await customPool.setVisible(true);

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

func.tags = ['Publish'];
func.dependencies = ['Deploy'];
export default func;
