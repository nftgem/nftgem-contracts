import {HardhatRuntimeEnvironment} from 'hardhat/types';
import publisher from '../lib/publishLib';

/**
 * @dev retrieve and display address, chain, balance
 */
const func: any = async function (hre: HardhatRuntimeEnvironment) {
  console.log('Bitgem deploy\n');

  const publishItems = await publisher(hre, true);

  // we are done!
  console.log('Deploy complete\n');

  return publishItems.deployedContracts;
};

func.tags = ['Deploy'];
func.dependencies = [];
export default func;
