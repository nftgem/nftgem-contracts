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
  const waitForTime = BigNumber.from(networkId).eq(1337) ? 0 : 11;

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
      setInterval(() => {
        _checkReceipt().then((r: any) => {
          if (r) {
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
  const dc = await getDeployedContracts(sender);

  const itemPrice = '0.0001';

  const getGPA = async (sym: string) => {
    return await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], [sym])])
    );
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
      nonce = BigNumber.from(0);
    const poolAddr = await getGPA(symbol);
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
      nonce = BigNumber.from(tx.nonce).add(1);
      await waitForMined(tx.hash);
      const gpAddr = await getGPA(symbol);
      console.log(`Creating wrapped ${name} (${symbol}) token...`);
      tx = await dc.ERC20GemTokenFactory.createItem(
        `W${symbol}`,
        `Wrapped ${name}`,
        gpAddr,
        dc.NFTGemMultiToken.address,
        18,
        {gasLimit: 5000000, nonce}
      );
      nonce = nonce.add(1);
      await waitForMined(tx.hash);
    }
    return await getGPA(symbol);
  };

  /**
   ******************************************************************************
   */

  await createPool(
    'AMBUS',
    'AssemblaMen Businessman',
    parseEther('0.25'),
    300,
    900,
    32,
    0,
    '0x0000000000000000000000000000000000000000'
  );
  await createPool(
    'AMCHF',
    'AssemblaMen Chef',
    parseEther('0.5'),
    300,
    900,
    12,
    0,
    '0x0000000000000000000000000000000000000000'
  );
  await createPool(
    'ASTRO',
    'AssemblaMen Astronaut',
    parseEther('1'),
    300,
    900,
    4,
    0,
    '0x0000000000000000000000000000000000000000'
  );
  await createPool(
    'AMPAR',
    'AssemblaMen Party Man',
    parseEther('0.25'),
    300,
    900,
    24,
    0,
    '0x0000000000000000000000000000000000000000'
  );
  await createPool(
    'FRMAN',
    'AssemblaMen Foreman',
    parseEther('0.5'),
    300,
    900,
    16,
    0,
    '0x0000000000000000000000000000000000000000'
  );
  await createPool(
    'AMOFW',
    'AssemblaMen Office Worker',
    parseEther('0.25'),
    300,
    900,
    32,
    0,
    '0x0000000000000000000000000000000000000000'
  );
  await createPool(
    'BLHOP',
    'AssemblaMen Bellhop',
    parseEther('0.25'),
    300,
    900,
    32,
    0,
    '0x0000000000000000000000000000000000000000'
  );
  await createPool(
    'SECGD',
    'AssemblaMen Security Guard',
    parseEther('0.5'),
    300,
    900,
    16,
    0,
    '0x0000000000000000000000000000000000000000'
  );
  await createPool(
    'AMUMP',
    'AssemblaMen Umpire',
    parseEther('0.5'),
    300,
    900,
    16,
    0,
    '0x0000000000000000000000000000000000000000'
  );
  await createPool(
    'FIRMN',
    'AssemblaMen Fireman',
    parseEther('1'),
    300,
    900,
    12,
    0,
    '0x0000000000000000000000000000000000000000'
  );
  // await createPool(
  //   'BASBL',
  //   'AssemblaMen Baseball',
  //   parseEther('1'),
  //   300,
  //   900,
  //   12,
  //   0,
  //   '0x0000000000000000000000000000000000000000'
  // );

  await createPool(
    'NVDRZ1',
    'Invaderz Light Drone 1',
    parseEther('50'),
    300,
    900,
    36,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'NVDRZ2',
    'Invaderz Drone 1',
    parseEther('100'),
    300,
    900,
    24,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'NVDRZ3',
    'Invaderz Heavy Drone 1',
    parseEther('250'),
    300,
    900,
    12,
    0,
    '0x0000000000000000000000000000000000000000'
  );
  // we are done!
  console.log('Deploy complete\n');
  const nbal = await sender.getBalance();
  console.log(`${chainId} ${thisAddr} : ${formatEther(nbal)}`);
  console.log(`spent : ${formatEther(bal.sub(nbal))}`);

  await waitFor(18);

  return dc;
};

func.dependencies = ['Deploy'];
export default func;
