import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import publisher from '../lib/publishLib';
import { parseEther } from '@ethersproject/units';

/**
 * @dev retrieve and display address, chain, balance
 */
const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  console.log('Bitgem deploy\n');

  const publishItems = await publisher(hre, true);

  // npx hardhat --network opera publish-gempool --symbol PIXEL16 --name “Yoshi” --price 25 --min 3600 --max 21600 --diff 132 --maxclaims 0 --allowedtoken 0x0000000000000000000000000000000000000000
  await publishItems.createPool(
    'PIXEL16',
    'Yoshi',
    parseEther('25'),
    3600,
    21600,
    132,
    0,
    '0x0000000000000000000000000000000000000000',
    []
  );
  // -symbol PIXEL14 --name “Yuno” --price 100 --min 21600 --max 86400 --diff 69 --
  await publishItems.createPool(
    'PIXEL14',
    'Yuno',
    parseEther('100'),
    21600,
    86400,
    69,
    0,
    '0x0000000000000000000000000000000000000000',
    []
  );
  //  --symbol PIXEL15 --name “Diggory” --price 50 --min 10800 --max 43200 --diff 92 -
  await publishItems.createPool(
    'PIXEL15',
    'Diggory',
    parseEther('50'),
    10800,
    43200,
    92,
    0,
    '0x0000000000000000000000000000000000000000',
    []
  );
  //  --symbol PIXEL13 --name “Bozo” --price 75 --min 7200 --max 43200 --diff 116
  await publishItems.createPool(
    'PIXEL13',
    'Bozo',
    parseEther('75'),
    7200,
    43200,
    116,
    0,
    '0x0000000000000000000000000000000000000000',
    []
  );


  // const poolAddress = await publishItems.getGemPoolAddress('TST1');

  // console.log('Pool address:', poolAddress);
  // await publishItems.createPool(
  //   'BOB',
  //   'Miner Bob',
  //   parseEther('0.01'),
  //   30,
  //   90,
  //   4,
  //   0,
  //   '0x0000000000000000000000000000000000000000',
  //   [
  //     [
  //       publishItems.deployedContracts.NFTGemMultiToken.address,
  //       poolAddress,
  //       3,
  //       0,
  //       1,
  //       true,
  //       false,
  //       false
  //     ],
  //   ]
  // );




  return publishItems.deployedContracts;
};

func.tags = ['Pub'];
func.dependencies = ['Deploy'];
export default func;
