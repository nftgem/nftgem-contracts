const hre = require('hardhat');
require('@nomiclabs/hardhat-waffle');

async function main() {
  const [sender] = await hre.ethers.getSigners();
  const {ethers} = hre;

  const stick = ethers.utils.getAddress(
    '0x6A7a28fD9B590ad24be7B3830b10d8990Fad849d'
  );
  const myAddress = await sender.getAddress();
  console.log(myAddress);

  const Pool = await ethers.getContractFactory('NFTGemPool');
  const Data = await ethers.getContractFactory('NFTGemPoolData');

  const pool = await Pool.attach(stick);
  const data = await Data.attach(stick);
  let i;

  for (i = 1; i < 2500; i++) {
    const min = await data.minTime();
    const max = await data.maxTime();
    const price = await data.ethPrice();
    const final = (price * min) / max;
    let overrides = {value: Math.ceil(final) * 2};
    await pool.createClaim(85400, overrides);
    console.log(`stick purchased for ${final.toString()}`);
    console.log(`total spent: ${(final * i).toString()}`);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
