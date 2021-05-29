/* eslint-disable @typescript-eslint/no-var-requires */
require('dotenv').config();
const hre = require('hardhat');
require('@nomiclabs/hardhat-waffle');

(async function main() {
  const {ethers} = hre;
  const addressBitLootFeeManager = ethers.utils.getAddress(
    process.env.FEE_MANAGER_ADDRESS ||
      '0x7Fd79a2E4421A2b16b007375985C3B13E16F660F'
  );

  const addressBitgemFeeManager = ethers.utils.getAddress(
    process.env.BG_FEE_MANAGER_ADDRESS ||
      '0x70EC520bC874750815a1CD5109F6dF9A971AcF2A'
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
