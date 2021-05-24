import {formatEther, parseEther} from 'ethers/lib/utils';
import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {pack, keccak256} from '@ethersproject/solidity';
import {BigNumber, BigNumberish} from '@ethersproject/bignumber';
const func: any = async function (hre: HardhatRuntimeEnvironment) {
  const {ethers, deployments} = hre;
  const networkId = await hre.getChainId();
  const {getContractAt} = ethers;
  const {get} = deployments;
  const [sender] = await hre.ethers.getSigners();

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
      ERC20GemTokenFactory: await getContractAt(
        'ERC20GemTokenFactory',
        (await get('ERC20GemTokenFactory')).address,
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
  const dc = await getDeployedContracts(sender);

  const itemPrice = '1000';

  const deployParams = {
    from: sender.address,
    log: true,
    libraries: {
      ComplexPoolLib: (await get('ComplexPoolLib')).address,
    },
  };
  const NFTComplexGemPool = await ethers.getContractFactory(
    'NFTComplexGemPool',
    deployParams
  );

  const getGPA = async (sym: string) => {
    return await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], [sym])])
    );
  };

  const getPoolContract = async (addr: string) => {
    return NFTComplexGemPool.attach(addr);
  };

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
    let poolAddr = await getGPA(symbol);
    if (BigNumber.from(poolAddr).eq(0)) {
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
      await waitForMined(tx.hash);
      nonce = BigNumber.from(tx.nonce).add(1);
      const gpAddr = await getGPA(symbol);
      console.log(`Creating wrapped ${name} (${symbol}) token...`);
      tx = await dc.ERC20GemTokenFactory.createItem(
        `W${symbol}`,
        `Wrapped ${name}`,
        gpAddr,
        dc.NFTGemMultiToken.address,
        18,
        dc.NFTGemWrapperFeeManager.address,
        {gasLimit: 5000000, nonce}
      );
      await waitForMined(tx.hash);
      nonce = nonce.add(1);
      poolAddr = await getGPA(symbol);
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
        await waitForMined(tx.hash);
      }
    }
    return await getGPA(symbol);
  };

  /**
   ******************************************************************************
   */

  await createPool(
    'APU',
    'BitRobots All-Purpose Unit',
    parseEther('1000'),
    300,
    900,
    32,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'SRR',
    'BitRobots Sentry Responder Unit',
    parseEther('1000'),
    300,
    900,
    16,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'RAU',
    'BitRobots Repair and Assist Unit',
    parseEther('1000'),
    300,
    900,
    8,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'PAU',
    'BitRobots Personal Assistant Unit',
    parseEther('1000'),
    300,
    900,
    4,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'PRC',
    'BitRobots Personal Robot Companion',
    parseEther('1000'),
    300,
    900,
    3,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'MCU',
    'BitRobots Master Control Unit',
    parseEther('5000'),
    3600,
    14400,
    2,
    0,
    '0x0000000000000000000000000000000000000000',
    [
      [dc.NFTGemMultiToken.address, await getGPA('APU'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGPA('SRR'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGPA('RAU'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGPA('PAU'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGPA('PRC'), 3, 0, 1, true, false],
    ]
  );

  await createPool(
    'AMBUS',
    'AssemblaMen Business Man',
    parseEther('1000'),
    3600,
    3600,
    32,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'AMPAR',
    'AssemblaMen Party Man',
    parseEther('1000'),
    3600,
    3600,
    24,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'AMCHF',
    'AssemblaMen Chef',
    parseEther('2500'),
    3600,
    3600,
    12,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'ASTRO',
    'AssemblaMen Astronaut',
    parseEther('5000'),
    3600,
    3600,
    4,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'BLHOP',
    'AssemblaMen Bellhop',
    parseEther('1000'),
    3600,
    3600,
    32,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'PIXEL1',
    'PixelPals: Antonio',
    parseEther('1000'),
    300,
    2400,
    32,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'PIXEL4',
    'PixelPals: Jax',
    parseEther('2500'),
    300,
    1600,
    24,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'PIXEL3',
    'PixelPals: Simone',
    parseEther('5000'),
    300,
    1200,
    16,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'PIXEL2',
    'PixelPals: Rongo',
    parseEther('10000'),
    300,
    900,
    12,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'PIXEL5',
    'PixelPals: Steve',
    parseEther('10000'),
    86400,
    86400 * 10,
    32,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'PIXEL6',
    'PixelPals: Shelly',
    parseEther('25000'),
    86400,
    86400 * 10,
    24,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'PIXEL7',
    'PixelPals: Splat',
    parseEther('50000'),
    86400,
    86400 * 10,
    16,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'PIXEL8',
    'PixelPals: Drago',
    parseEther('100000'),
    86400,
    86400 * 10,
    12,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'PIXEL10',
    'PixelPals: Ninja',
    parseEther('2500'),
    300,
    900,
    32,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'PIXEL11',
    'PixelPals: Crabby',
    parseEther('5000'),
    300,
    900,
    24,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'PIXEL12',
    'PixelPals: Bongo',
    parseEther('10000'),
    300,
    900,
    16,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'PIXEL9',
    'PixelPals: Princess',
    parseEther('50000'),
    300,
    900,
    12,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'BB1',
    'BoujaBonga: Ninja',
    parseEther('5000'),
    300,
    900,
    10,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'BB2',
    'BoujaBonga: Spank',
    parseEther('1000'),
    300,
    900,
    10,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'BB3',
    'BoujaBonga: Alien',
    parseEther('2500'),
    86400,
    86400 * 3,
    4,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'BB4',
    'BoujaBonga: Einstein',
    parseEther('10000'),
    86400,
    86400 * 3,
    4,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  // we are done!
  console.log('Deploy complete\n');
  const nbal = await sender.getBalance();
  console.log(`${chainId} ${thisAddr} : ${formatEther(nbal)}`);
  console.log(`spent : ${formatEther(bal.sub(nbal))}`);

  await waitFor(3);

  return dc;
};

func.dependencies = ['Deploy'];
export default func;
