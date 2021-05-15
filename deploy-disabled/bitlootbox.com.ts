import { parseEther } from 'ethers/lib/utils';
import {HardhatRuntimeEnvironment} from 'hardhat/types';

const publishLib = require('../lib/publishLib');

const func: any = async function (hre: HardhatRuntimeEnvironment) {

  /**
   * @dev retrieve and display address, chain, balance
   */
  console.log('Bitgem deploy\n');

  const publisher = await publishLib(hre);
  const deployedContracts = publisher.deployedContracts;
  const getPoolAddress = publisher.getPoolAddress;

  await publisher.createPool(
    'APU',
    'BitRobots All-Purpose Unit',
    parseEther('100'),
    300,
    900,
    32,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await publisher.createPool(
    'SRR',
    'BitRobots Sentry Responder Unit',
    parseEther('100'),
    300,
    900,
    16,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await publisher.createPool(
    'RAU',
    'BitRobots Repair and Assist Unit',
    parseEther('100'),
    300,
    900,
    8,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await publisher.createPool(
    'PAU',
    'BitRobots Personal Assistant Unit',
    parseEther('100'),
    300,
    900,
    4,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await publisher.createPool(
    'PRC',
    'BitRobots Personal Robot Companion',
    parseEther('100'),
    300,
    900,
    3,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await publisher.createPool(
    'MCU',
    'BitRobots Master Control Unit',
    parseEther('100'),
    3600,
    14400,
    2,
    0,
    '0x0000000000000000000000000000000000000000',
    [
      [deployedContracts.NFTGemMultiToken.address, await getPoolAddress('APU'), 3, 0, 1, true, false],
      [deployedContracts.NFTGemMultiToken.address, await getPoolAddress('SRR'), 3, 0, 1, true, false],
      [deployedContracts.NFTGemMultiToken.address, await getPoolAddress('RAU'), 3, 0, 1, true, false],
      [deployedContracts.NFTGemMultiToken.address, await getPoolAddress('PAU'), 3, 0, 1, true, false],
      [deployedContracts.NFTGemMultiToken.address, await getPoolAddress('PRC'), 3, 0, 1, true, false],
    ]
  );

  await publisher.createPool(
    'AMBUS',
    'AssemblaMen Business Man',
    parseEther('100'),
    3600,
    3600,
    32,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await publisher.createPool(
    'AMPAR',
    'AssemblaMen Party Man',
    parseEther('100'),
    3600,
    3600,
    24,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await publisher.createPool(
    'AMCHF',
    'AssemblaMen Chef',
    parseEther('250'),
    3600,
    3600,
    12,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await publisher.createPool(
    'ASTRO',
    'AssemblaMen Astronaut',
    parseEther('500'),
    3600,
    3600,
    4,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await publisher.createPool(
    'BLHOP',
    'AssemblaMen Bellhop',
    parseEther('100'),
    3600,
    3600,
    32,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await publisher.createPool(
    'FRMAN',
    'AssemblaMen Foreman',
    parseEther('500'),
    3600,
    3600,
    16,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await publisher.createPool(
    'PIXEL1',
    'PixelPals: Antonio',
    parseEther('100'),
    300,
    2400,
    32,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await publisher.createPool(
    'PIXEL4',
    'PixelPals: Jax',
    parseEther('250'),
    300,
    1600,
    24,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await publisher.createPool(
    'PIXEL3',
    'PixelPals: Simone',
    parseEther('500'),
    300,
    1200,
    16,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await publisher.createPool(
    'PIXEL2',
    'PixelPals: Rongo',
    parseEther('1000'),
    300,
    900,
    12,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  // we are done!
  console.log('Deploy complete\n');
};

func.dependencies = ['Deploy'];
export default func;
