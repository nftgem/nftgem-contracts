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
  const waitForTime = 5;

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
    // NFTGemGovernor: await deploy('NFTGemGovernor', deployParams),
    // NFTGemMultiToken: await deploy('NFTGemMultiToken', deployParams),
    // NFTGemPoolFactory: await deploy('NFTGemPoolFactory', deployParams),
    // NFTGemFeeManager: await deploy('NFTGemFeeManager', deployParams),
    // ProposalFactory: await deploy('ProposalFactory', deployParams),
    // ERC20GemTokenFactory: await deploy('ERC20GemTokenFactory', deployParams),
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

  if (parseInt(networkId) === 250) {
    ip = utils.parseEther('100');
    pepe = utils.parseEther('10000');
  }

  console.log('loading contracts...');
  await waitFor(5);

  const deployedContracts = await getDeployedContracts(sender);
  const dc = deployedContracts;
  const ds = 86400;
  const ms = ds * 30;

  // await dc.NFTGemMultiToken.removeProxyRegistryAt(0);

  // console.log('initializing governor...');
  // try {
  //   await dc.NFTGemGovernor.initialize(
  //     dc.NFTGemMultiToken.address,
  //     dc.NFTGemPoolFactory.address,
  //     dc.NFTGemFeeManager.address,
  //     dc.ProposalFactory.address,
  //     dc.SwapHelper.address
  //   );
  // } catch (e) {
  //   console.log('already inited');
  // }
  // await waitFor(waitForTime);
  // try {
  //   console.log('propagating governor controller...');
  //   await dc.NFTGemMultiToken.addController(dc.NFTGemGovernor.address);
  //   await waitFor(waitForTime);
  // } catch (e) {
  //   console.log('already inited');
  // }
  // try {
  //   console.log('propagating governor controller...');
  //   await dc.NFTGemPoolFactory.addController(dc.NFTGemGovernor.address);
  //   await waitFor(waitForTime);
  // } catch (e) {
  //   console.log('already inited');
  // }
  // try {
  //   console.log('propagating governor controller...');
  //   await dc.ProposalFactory.addController(dc.NFTGemGovernor.address);
  //   await waitFor(waitForTime);
  // } catch (e) {
  //   console.log('already inited');
  // }
  // try {
  //   console.log('propagating governor controller...');
  //   await dc.NFTGemFeeManager.setOperator(dc.NFTGemGovernor.address);
  //   await waitFor(waitForTime);
  // } catch (e) {
  //   console.log('already inited');
  // }
  // try {
  //   console.log('propagating governor controller...');
  //   await dc.ERC20GemTokenFactory.setOperator(dc.NFTGemGovernor.address);
  //   await waitFor(waitForTime);
  // } catch (e) {
  //   console.log('already inited');
  // }

  // await waitFor(waitForTime);
  // try {
  //   console.log('minting initial governance tokens...');
  //   await dc.NFTGemGovernor.issueInitialGovernanceTokens(sender.address);
  // } catch (e) {
  //   console.log('already inited');
  // }

  // await waitFor(waitForTime);

  const gemTokens: any = {};

  // console.log('Creating Pepe pool...');
  // await dc.NFTGemGovernor.createSystemPool(
  //   'PEPE',
  //   'Pepe',
  //   parseEther('10'),
  //   86400,
  //   86400 * 30,
  //   4,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 4200000}
  // );
  // await waitFor(waitForTime);
  // console.log('Creating wrapped Pepe token...');
  // gemTokens.Ruby = await dc.ERC20GemTokenFactory.createItem(
  //   'WPEPE',
  //   'Wrapped Pepe',
  //   await dc.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['PEPE'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   8,
  //   {gasLimit: 4200000}
  // );
  // await waitFor(waitForTime);

  // console.log('Creating Ruby pool...');
  // await dc.NFTGemGovernor.createSystemPool(
  //   'RUBY',
  //   'Ruby',
  //   parseEther('0.1'),
  //   86400,
  //   86400 * 30,
  //   32,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 4200000}
  // );
  // await waitFor(waitForTime);
  // console.log('Creating wrapped Ruby token...');
  // gemTokens.Ruby = await dc.ERC20GemTokenFactory.createItem(
  //   'WRUBY',
  //   'Wrapped Ruby',
  //   await dc.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['RUBY'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   8,
  //   {gasLimit: 4200000}
  // );
  // await waitFor(waitForTime);

  // console.log('Creating Opal pool...');
  // await dc.NFTGemGovernor.createSystemPool(
  //   'OPAL',
  //   'Opal',
  //   parseEther('0.1'),
  //   86400,
  //   86400 * 30,
  //   64,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 4200000}
  // );
  // await waitFor(waitForTime);
  // console.log('Creating wrapped Opal token...');
  // gemTokens.Ruby = await dc.ERC20GemTokenFactory.createItem(
  //   'WOPAL',
  //   'Wrapped Opal',
  //   await dc.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['RUBY'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   8,
  //   {gasLimit: 4200000}
  // );
  // await waitFor(waitForTime);

  // console.log('Creating Land pool...');
  // await dc.NFTGemGovernor.createSystemPool(
  //   'LAND',
  //   'Land',
  //   parseEther('0.00001'),
  //   60,
  //   31104000,
  //   1073741824,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 4200000}
  // );
  // console.log('Creating wrapped Land token...');
  // gemTokens.Jade = await dc.ERC20GemTokenFactory.createItem(
  //   'WLAND',
  //   'Wrapped Land',
  //   await deployedContracts.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['LAND'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   8,
  //   {gasLimit: 4200000}
  // );
  // await waitFor(waitForTime);

  // emerald
  // console.log('Creating Emerald pool...');
  // await dc.NFTGemGovernor.createSystemPool(
  //   'MRLD',
  //   'Emerald',
  //   parseEther('0.1'),
  //   86400,
  //   86400 * 30,
  //   128,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 4200000}
  // );
  // await waitFor(waitForTime);
  // console.log('Creating wrapped Emerald token...');
  // gemTokens.Emerald = await dc.ERC20GemTokenFactory.createItem(
  //   'WMRLD',
  //   'Wrapped Emerald',
  //   await deployedContracts.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['MRLD'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   8,
  //   {gasLimit: 4200000}
  // );
  // await waitFor(waitForTime);

  // sapphire
  // console.log('Creating Sapphire pool...');
  // await dc.NFTGemGovernor.createSystemPool(
  //   'SPHR',
  //   'Sapphire',
  //   parseEther('0.1'),
  //   86400,
  //   86400 * 30,
  //   256,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 4200000}
  // );
  // console.log('Creating wrapped Sapphire token...');
  // gemTokens.Sapphire = await dc.ERC20GemTokenFactory.createItem(
  //   'WSPHR',
  //   'Wrapped Sapphire',
  //   await deployedContracts.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['SPHR'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   8,
  //   {gasLimit: 4200000}
  // );
  // await waitFor(waitForTime);

  // diamond
  // console.log('Creating Diamond pool...');
  // await dc.NFTGemGovernor.createSystemPool(
  //   'DNMD',
  //   'Diamond',
  //   parseEther('0.1'),
  //   86400,
  //   86400 * 30,
  //   512,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 4200000}
  // );
  // console.log('Creating wrapped Diamond token...');
  // gemTokens.Diamond = await dc.ERC20GemTokenFactory.createItem(
  //   'WDNMD',
  //   'Wrapped Diamond',
  //   await deployedContracts.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['DNMD'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   8,
  //   {gasLimit: 4200000}
  // );
  //await waitFor(waitForTime);

  // jade
  // console.log('Creating Jade pool...');
  // await dc.NFTGemGovernor.createSystemPool(
  //   'JADE',
  //   'Jade',
  //   parseEther('0.1'),
  //   86400,
  //   86400 * 30,
  //   1024,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 4200000}
  // );
  // console.log('Creating wrapped Jade token...');
  // gemTokens.Jade = await dc.ERC20GemTokenFactory.createItem(
  //   'WJADE',
  //   'Wrapped Jade',
  //   await deployedContracts.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['JADE'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   8,
  //   {gasLimit: 4200000}
  // );
  // await waitFor(waitForTime);

  // // topaz
  // console.log('Creating Topaz pool...');
  // await dc.NFTGemGovernor.createSystemPool(
  //   'TPAZ',
  //   'Topaz',
  //   parseEther('0.1'),
  //   86400,
  //   86400 * 30,
  //   2048,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 4200000}
  // );
  // console.log('Creating wrapped Topaz token...');
  // gemTokens.Jade = await dc.ERC20GemTokenFactory.createItem(
  //   'WTPAZ',
  //   'Wrapped Topaz',
  //   await deployedContracts.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['TPAZ'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   8,
  //   {gasLimit: 4200000}
  // );
  // await waitFor(waitForTime);

  // // pearl
  // console.log('Creating Pearl pool...');
  // await dc.NFTGemGovernor.createSystemPool(
  //   'PERL',
  //   'Pearl',
  //   parseEther('0.1'),
  //   86400,
  //   86400 * 30,
  //   4096,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 4200000}
  // );
  // console.log('Creating wrapped Pearl token...');
  // gemTokens.Jade = await dc.ERC20GemTokenFactory.createItem(
  //   'WPERL',
  //   'Wrapped Pearl',
  //   await deployedContracts.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['PERL'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   8,
  //   {gasLimit: 4200000}
  // );
  // await waitFor(waitForTime);

  // a rock
  // console.log('Creating Rock pool...');
  // await dc.NFTGemGovernor.createSystemPool(
  //   'ROCK',
  //   'Rock',
  //   utils.parseEther('0.0001'),
  //   60,
  //   86400,
  //   65536,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 4200000}
  // );
  // console.log('Creating wrapped Rock token...');
  // gemTokens.Jade = await dc.ERC20GemTokenFactory.createItem(
  //   'WROCK',
  //   'Wrapped Rock',
  //   await deployedContracts.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['ROCK'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   8,
  //   {gasLimit: 4200000}
  // );
  // await waitFor(waitForTime);

  // // a rock
  // console.log('Creating Stick pool...');
  // await dc.NFTGemGovernor.createSystemPool(
  //   'STIK',
  //   'Stick',
  //   utils.parseEther('0.0001'),
  //   30,
  //   86400,
  //   65536,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 4200000}
  // );
  // await waitFor(waitForTime);
  // console.log('Creating wrapped Stick token...');
  // gemTokens.Stick = await dc.ERC20GemTokenFactory.createItem(
  //   'WSTIK',
  //   'Wrapped Stick',
  //   await deployedContracts.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['STIK'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   8,
  //   {gasLimit: 4200000}
  // );
  // await waitFor(waitForTime);

  // // meat
  // console.log('Creating Meat pool...');
  // await dc.NFTGemGovernor.createSystemPool(
  //   'MEAT',
  //   'Meat',
  //   utils.parseEther('0.0005'),
  //   300,
  //   86400,
  //   65536,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 4200000}
  // );
  // await waitFor(waitForTime);
  // console.log('Creating wrapped Meat token...');
  // gemTokens.Meat = await dc.ERC20GemTokenFactory.createItem(
  //   'WMEAT',
  //   'Wrapped Meat',
  //   await deployedContracts.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['MEAT'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   8,
  //   {gasLimit: 4200000}
  // );
  // await waitFor(waitForTime);

  // // shroom
  // console.log('Creating Shroom pool...');
  // await dc.NFTGemGovernor.createSystemPool(
  //   'SHRM',
  //   'Shroom',
  //   utils.parseEther('0.01'),
  //   600,
  //   86400,
  //   32768,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 4200000}
  // );
  // await waitFor(waitForTime);
  // console.log('Creating wrapped Shroom token...');
  // gemTokens.Shroom = await dc.ERC20GemTokenFactory.createItem(
  //   'WSHRM',
  //   'Wrapped Shroom',
  //   await deployedContracts.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['SHRM'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   8,
  //   {gasLimit: 4200000}
  // );
  // await waitFor(waitForTime);

  // pearl
  // console.log('Creating Land pool...');
  // await dc.NFTGemGovernor.createSystemPool(
  //   'LAND',
  //   'Land',
  //   parseEther('0.00001'),
  //   60,
  //   31104000,
  //   1073741824,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 4200000}
  // );
  // console.log('Creating wrapped Land token...');
  // gemTokens.Jade = await dc.ERC20GemTokenFactory.createItem(
  //   'WLAND',
  //   'Wrapped Land',
  //   await deployedContracts.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['LAND'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   8,
  //   {gasLimit: 4200000}
  // );
  // await waitFor(waitForTime);

  await dc.NFTGemGovernor.createSystemPool(
    'PLSM',
    'Plasma',
    utils.parseEther('10'),
    60,
    60,
    1073741824,
    0,
    '0x0000000000000000000000000000000000000000',
    {gasLimit: 4200000}
  );

  await dc.NFTGemGovernor.createSystemPool(
    'COAL',
    'Coal',
    utils.parseEther('1'),
    86400 * 180,
    86400 * 360,
    1073741824,
    0,
    '0x0000000000000000000000000000000000000000',
    {gasLimit: 4200000}
  );

  await dc.NFTGemGovernor.createSystemPool(
    'MAGIC',
    'Philosophers Stone',
    utils.parseEther('500'),
    86400,
    86400,
    2,
    0,
    '0x0000000000000000000000000000000000000000',
    {gasLimit: 4200000}
  );

  // // shroom
  // console.log('Creating Fire pool...');
  // await dc.NFTGemGovernor.createSystemPool(
  //   'FIRE',
  //   'Fire',
  //   utils.parseEther('0.1'),
  //   10,
  //   60,
  //   1073741824,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   {gasLimit: 4200000}
  // );
  // await waitFor(waitForTime);
  // console.log('Creating wrapped Fire token...');
  // gemTokens.Land = await dc.ERC20GemTokenFactory.createItem(
  //   'WFIRE',
  //   'Wrapped Fire',
  //   await deployedContracts.NFTGemPoolFactory.getNFTGemPool(
  //     keccak256(['bytes'], [pack(['string'], ['FIRE'])])
  //   ),
  //   dc.NFTGemMultiToken.address,
  //   4
  // );
  // await waitFor(waitForTime);

  // // relinquish control
  // console.log('Relinquishing control of multitoken, factory, and governor');
  // await dc.NFTGemMultiToken.relinquishControl();await waitFor(waitForTime);
  // await dc.NFTGemPoolFactory.relinquishControl();await waitFor(waitForTime);
  // await dc.NFTGemGovernor.relinquishControl();await waitFor(waitForTime);
  // await dc.ProposalFactory.relinquishControl();await waitFor(waitForTime);

  // // lock owned governance tokens from moving for one year
  // console.log('Locking initial governance token issuance for one year');
  // const lockTil = ~~(Date.now() / 1000) + 31536000;
  // await dc.NFTGemMultiToken.lock(0, lockTil);

  // // init code hash for nft gem pool
  // const NFTGemPoolABI = await get('NFTGemPool');
  // const NFTGEMPOOL_INIT_CODE_HASH = keccak256(
  //   ['bytes'],
  //   [`${NFTGemPoolABI.bytecode}`]
  // );
  // console.log('NFTGemPool', NFTGEMPOOL_INIT_CODE_HASH);

  // // init code hash for proposal
  // const ProposalABI = await get('Proposal');
  // const PROPOSAL_INIT_CODE_HASH = keccak256(
  //   ['bytes'],
  //   [`${ProposalABI.bytecode}`]
  // );
  // console.log('Proposal', PROPOSAL_INIT_CODE_HASH);

  console.log('Deploy complete\n');
  const nbal = await sender.getBalance();
  console.log(`${chainId} ${thisAddr} : ${formatEther(nbal)}`);
  console.log(`spent : ${formatEther(bal.sub(nbal))}`);

  return deployedContracts;
};

func.tags = ['Deploy'];
func.dependencies = [];
export default func;
