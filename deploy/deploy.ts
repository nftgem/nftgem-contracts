import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';
import publisher from '../lib/publishLib';

/**
 * @dev retrieve and display address, chain, balance
 */
const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  console.log('Bitgem deploy\n');

  const publishItems = await publisher(hre, true);

  // we are done!
  console.log('Deploy complete\n');

  return publishItems.deployedContracts;
};

func.tags = ['Deploy'];
func.dependencies = [];
export default func;
