import {HardhatRuntimeEnvironment} from 'hardhat/types';
import migrator from '../lib/migrateLib';

/**
 * @dev retrieve and display address, chain, balance
 */
const func: any = async function (hre: HardhatRuntimeEnvironment) {
  // bitlootbox.com
  const afactory = '0x9c393955D39c3C7A80Fe6A11B0e4B834a2c5301e';
  const alegacyToken = '0x481d559466a04EB3744832e02a05aB1AE68fEb17';

  // const migrateItemns = await migrator(hre, afactory, alegacyToken);

  console.log('Migration complete\n');

  //return migrateItemns.deployedContracts;
};

func.tags = ['Deploy'];
func.dependencies = [];
export default func;
