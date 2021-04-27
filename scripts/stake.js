const hre = require('hardhat');
require('@nomiclabs/hardhat-waffle');

async function main() {
  const [sender] = await hre.ethers.getSigners();
  const {ethers} = hre;
  const {BigNumber} = ethers;

  const stick = ethers.utils.getAddress(
    '0x6A7a28fD9B590ad24be7B3830b10d8990Fad849d'
  );
  const atoken = ethers.utils.getAddress(
    '0x496FEC70974870dD7c2905E25cAd4BDE802938C7'
  );

  const myAddress = await sender.getAddress();
  console.log(myAddress);

  const Token = await ethers.getContractFactory('NFTGemMultiToken');
  const Pool = await ethers.getContractFactory('NFTGemPool');
  const Data = await ethers.getContractFactory('NFTGemPoolData');

  const token = await Token.attach(atoken);
  const pool = await Pool.attach(stick);
  const data = await Data.attach(stick);
  const min = await data.minTime();

  async function stakeStick() {
    const claimHash = await pool.nextClaimHash();
    const value = await data.ethPrice();
    const abal = await token.balanceOf(myAddress, BigNumber.from(0));
    await pool.createClaims(min, 1, {value, gasLimit: 4200000});
    console.log(`${abal} stick ${claimHash} purchased for ${value}`);
    setTimeout(
      () =>
        pool
          .collectClaim(claimHash, {gasLimit: 4200000})
          .then(() => console.log(`claim ${claimHash} collected`)),
      35000
    );
    setTimeout(() => stakeStick(), 5000);
  }

  stakeStick();

  stall();
}
function stall() {
  setTimeout(() => stall());
}

main()
  .then(() => {
    stall();
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
