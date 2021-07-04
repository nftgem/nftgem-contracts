import {BigNumber} from 'ethers';
import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {pack, keccak256} from '@ethersproject/solidity';
import publisher from '../lib/publishLib';
import {formatEther} from 'ethers/lib/utils';

/**
 * @dev retrieve and display address, chain, balance
 */
const func: any = async function (hre: HardhatRuntimeEnvironment) {
  const {ethers} = hre;
  const {getContractAt} = ethers;

  console.log('Bitgem migration\n');
  const networkId = await hre.getChainId();
  const [sender] = await hre.ethers.getSigners();

  if (
    BigNumber.from(networkId).eq(1337) ||
    BigNumber.from(networkId).eq(4002)
  ) {
    console.log(`test deploy. No migration.`);
    return;
  }

  const publishItems = await publisher(hre, false);
  const {dc, waitForMined, createPool, getPoolContract} = publishItems;

  // bitlootbox.com
  const afactory = ethers.utils.getAddress(
    '0x9c393955D39c3C7A80Fe6A11B0e4B834a2c5301e'
  );
  const alegacyToken = ethers.utils.getAddress(
    '0x481d559466a04EB3744832e02a05aB1AE68fEb17'
  );

  const oldFactory = await getContractAt('NFTGemPoolFactory', afactory, sender);
  const oldToken = await getContractAt(
    'NFTGemMultiToken',
    alegacyToken,
    sender
  );
  const newToken = await getContractAt(
    'NFTGemMultiToken',
    dc.NFTGemMultiToken.address,
    sender
  );
  const newFactory = dc.NFTGemPoolFactory;

  const tx = await newToken.addController(dc.BulkTokenMinter.address);
  await waitForMined(tx.hash);

  const gpLen = await oldFactory.allNFTGemPoolsLength();
  for (let gp = 0; gp < gpLen.toNumber(); gp++) {
    const gpAddr = await oldFactory.allNFTGemPools(gp);
    const oldData = await getContractAt('INFTGemPoolData', gpAddr, sender);
    const sym = await oldData.symbol();
    if (sym === 'ASTRO' || sym === 'MCU') {
      continue;
    }
    console.log(`processing pool symbol ${sym}`);
    let newGpAddr = await newFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], [sym])])
    );
    if (BigNumber.from(newGpAddr).eq(0)) {
      newGpAddr = await createPool(
        sym,
        await oldData.name(),
        await oldData.ethPrice(),
        await oldData.minTime(),
        await oldData.maxTime(),
        await oldData.difficultyStep(),
        await oldData.maxClaims(),
        '0x0000000000000000000000000000000000000000'
      );
    }
    if (BigNumber.from(newGpAddr).eq(0)) {
      console.log(`cant create pool symbol ${sym}`);
      continue;
    }

    const pc = await getPoolContract(newGpAddr);
    const nextGemId = await oldData.mintedCount();
    const nextClaimId = await oldData.claimedCount();

    let tx = await pc.setNextIds(nextClaimId, nextGemId);
    await waitForMined(tx.hash);
    console.log(
      `${sym} next claim ${nextClaimId.toString()} next gem ${nextGemId.toString()}`
    );

    tx = await pc.addAllowedTokenSource(alegacyToken);
    await waitForMined(tx.hash);
    console.log(`${sym} added token source ${alegacyToken.toString()}`);

    //tx = await pc.setCategory(1);
    //  await waitForMined(tx.hash);
    console.log(`${sym} set category - 0`);
  }

  const allGovTokenHolders = await oldToken.allTokenHoldersLength(0);
  console.log(`num holders: ${allGovTokenHolders.toNumber()}`);

  let holders = [],
    govQuantities = [],
    fuelQuantities = [];

  for (let i = 0; i < allGovTokenHolders.toNumber(); i++) {
    const thAddr = await oldToken.allTokenHolders(0, i);

    const th0Bal = await oldToken.balanceOf(thAddr, 0);
    const th1Bal = await oldToken.balanceOf(thAddr, 1);

    holders.push(thAddr);
    govQuantities.push(th0Bal);
    fuelQuantities.push(th1Bal);
    console.log(
      `${i} ${thAddr} ${th0Bal.toString()} ${formatEther(th1Bal.toString())}`
    );

    if (i % 10 === 0 && holders.length > 1) {
      const tx = await dc.BulkTokenMinter.bulkMintGovFuel(
        newToken.address,
        holders,
        govQuantities,
        fuelQuantities,
        {gasLimit: 5000000}
      );
      await waitForMined(tx.hash);
      holders = [];
      govQuantities = [];
      fuelQuantities = [];
    }
  }

  if (holders.length > 0) {
    const tx = await dc.BulkTokenMinter.bulkMintGovFuel(
      newToken.address,
      holders,
      govQuantities,
      fuelQuantities,
      {gasLimit: 5000000}
    );
    await waitForMined(tx.hash);
  }

  // we are done!
  console.log('Migration complete\n');

  return publishItems.deployedContracts;
};

func.tags = ['Deploy'];
func.dependencies = [];
export default func;
