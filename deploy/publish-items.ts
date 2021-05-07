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
    };

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

  const nonce = BigNumber.from(0);

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
    allowedToken: string
  ) => {
    const poolAddr = await getGPA(symbol);
    if (BigNumber.from(poolAddr).eq(0)) {
      console.log(`Creating ${name} (${symbol}) pool...`);
      await dc.NFTGemGovernor.createSystemPool(
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
    }
    return await getGPA(symbol);
  };

  /**
   ******************************************************************************
   */
  // await createPool(
  //   'BOSS',
  //   'Command Node',
  //   parseEther('1'),
  //   60,
  //   60,
  //   1,
  //   0,
  //   '0x0000000000000000000000000000000000000000'
  // );

  // await createPool(
  //   '1UP',
  //   'Extra Life',
  //   parseEther('1'),
  //   60,
  //   60,
  //   1,
  //   0,
  //   '0x0000000000000000000000000000000000000000'
  // );

  await createPool(
    'PEPE',
    'Pepe',
    parseEther('1'),
    86400,
    86400 * 30,
    4,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'RUBY',
    'Ruby',
    parseEther('1'),
    86400,
    86400 * 30,
    32,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'OPAL',
    'Opal',
    parseEther('1'),
    86400,
    86400 * 30,
    64,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'MRLD',
    'Emerald',
    parseEther('1'),
    86400,
    86400 * 30,
    128,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'SPHR',
    'Sapphire',
    parseEther('1'),
    86400,
    86400 * 30,
    256,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'DNMD',
    'Diamond',
    parseEther('1'),
    86400,
    86400 * 30,
    512,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'JADE',
    'Jade',
    parseEther('1'),
    86400,
    86400 * 30,
    1024,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'TPAZ',
    'Topaz',
    parseEther('1'),
    86400,
    86400 * 30,
    2048,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'PERL',
    'Pearl',
    parseEther('1'),
    86400,
    86400 * 30,
    4096,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'ROCK',
    'Rock',
    parseEther('0.01'),
    60,
    86400,
    65536,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'STIK',
    'Stick',
    parseEther('0.01'),
    30,
    86400,
    65536,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'MEAT',
    'Meat',
    parseEther('1'),
    300,
    86400,
    65536,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'FIRE',
    'Fire',
    parseEther('0.25'),
    10,
    60,
    1073741824,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'LAND',
    'Land',
    parseEther('0.005'),
    60,
    31104000,
    1073741824,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'IRON',
    'Iron',
    parseEther('0.1'),
    60,
    31104000,
    1048576,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'WATR',
    'Water',
    parseEther('0.002'),
    60,
    31104000,
    16777216,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'SEED',
    'Seed',
    parseEther('0.25'),
    86400 * 7,
    86400 * 30,
    65536 * 2,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'GOLD',
    'Gold',
    parseEther('2.82'),
    86400,
    86400,
    65536 * 4,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'SLVR',
    'Silver',
    parseEther('0.04'),
    86400,
    86400,
    65536 * 4,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'MANA',
    'Mana',
    parseEther('0.15'),
    3600,
    7200,
    65536,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'RED',
    'Red',
    parseEther('0.01'),
    3600,
    7200,
    16384,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'GREN',
    'Green',
    parseEther('0.01'),
    3600,
    7200,
    16384,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'BLUE',
    'Blue',
    parseEther('0.01'),
    3600,
    7200,
    16384,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  // we are done!
  console.log('Deploy complete\n');
  const nbal = await sender.getBalance();
  console.log(`${chainId} ${thisAddr} : ${formatEther(nbal)}`);
  console.log(`spent : ${formatEther(bal.sub(nbal))}`);

  // await dc.NFTGemWrappedERC20Governance.wrap('1000');

  // dc.NFTGemMultiToken.safeTransferFrom(
  //   sender.address,
  //   '0x217b7DAB288F91551A0e8483aC75e55EB3abC89F',
  //   2,
  //   1,
  //   0
  // );

  await waitFor(18);

  return dc;
};

func.dependencies = ['Deploy'];
export default func;
