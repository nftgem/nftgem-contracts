/* eslint-disable @typescript-eslint/no-var-requires */
require('dotenv').config();
const hre = require('hardhat');
require('@nomiclabs/hardhat-waffle');

(async function main() {
  const {ethers} = hre;
  const addressBitLootFeeManager = ethers.utils.getAddress(
    process.env.FEE_MANAGER_ADDRESS ||
      '0xFF32E5Db9Eb8b4b546EC8Dc968795654f414f87c'
  );

  const addressBitgemFeeManager = ethers.utils.getAddress(
    process.env.BG_FEE_MANAGER_ADDRESS ||
      '0x00ffE2dadbBD172e3EfE1a33FCa8dE77F11A472F'
  );

  const FeeManager = await ethers.getContractFactory('NFTGemFeeManager');
  const bitlootFeeManager = await FeeManager.attach(addressBitLootFeeManager);
  const bitgemFeeManager = await FeeManager.attach(addressBitgemFeeManager);
  setInterval(async () => {
    const bg = await bitgemFeeManager.ethBalanceOf();
    const bl = await bitlootFeeManager.ethBalanceOf();
    console.log(
      new Date(),
      `totalBalance=${hre.ethers.utils.formatEther(bg.add(bl), {
        commify: true,
        pad: true,
      })}`,
      `bitgem=${addressBitgemFeeManager}=${hre.ethers.utils.formatEther(bg, {
        commify: true,
        pad: true,
      })}`,
      `bitloot=${addressBitLootFeeManager}=${hre.ethers.utils.formatEther(bl, {
        commify: true,
        pad: true,
      })}`
    );
  }, 30000);
})();
