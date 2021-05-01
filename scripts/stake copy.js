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
  const aFeeManager = ethers.utils.getAddress(
    '0x70EC520bC874750815a1CD5109F6dF9A971AcF2A'
  );
  const aGemPoolFactory = ethers.utils.getAddress(
    '0x70EC520bC874750815a1CD5109F6dF9A971AcF2A'
  );

  const myAddress = await sender.getAddress();
  console.log(myAddress);

  const GemPoolFactory = await ethers.getContractFactory('NFTGemPoolFactory');
  const FeeManager = await ethers.getContractFactory('NFTGemFeeManager');
  const Token = await ethers.getContractFactory('NFTGemMultiToken');
  const Pool = await ethers.getContractFactory('NFTGemPool');
  const Data = await ethers.getContractFactory('NFTGemPoolData');

  const token = await Token.attach(atoken);
  const gemPoolFactory = await GemPoolFactory.attach(aGemPoolFactory);

  const pool = await Pool.attach(stick);
  const data = await Data.attach(stick);
  const min = await data.minTime();

  const feeManager = await FeeManager.attach(aFeeManager);
  const earned = await feeManager.ethBalanceOf();
  const fmt = hre.ethers.utils.formatEther(earned);
  console.log(fmt);

  async function getFeesTotal() {
    const length = await gemPoolFactory.allNFTGemPoolsLength();
    for (let i = 0; i < length.toNumber(); i++) {
      const addr = await gemPoolFactory.allNFTGemPools(i);
    }
  }

  async function collectClaims() {
    const allLen = await pool.allTokenHashesLength();
    for (let i = allLen - 1; i >= 0; i--) {
      const tokenHash = await pool.allTokenHashes(i);
      const tokenType = await pool.tokenType(tokenHash);
      const ebal = await token.balanceOf(myAddress, tokenHash);
      if (!ebal.eq(0)) {
        if (tokenType === 1) {
          await pool.collectClaim(tokenHash, {gasLimit: 4200000});
          const abal = await token.balanceOf(myAddress, BigNumber.from(0));
          console.log(`${abal}`);
        } else console.log(`.`);
      }
    }
  }

  async function stakeStick() {
    const claimHash = await pool.nextClaimHash();
    const value = await data.ethPrice();
    const abal = await token.balanceOf(myAddress, BigNumber.from(0));
    await pool.createClaims(min.add(10), 1, {
      value: value.add(10),
      gasLimit: 4200000,
    });
    console.log(`${abal} stick ${claimHash} purchased for ${value}`);
    setTimeout(() => {
      try {
        pool
          .collectClaim(claimHash, {gasLimit: 4200000})
          .then(() => console.log(`claim ${claimHash} collected`));
      } catch (e) {
        /** */
      }
    }, 35000);
  }

  //collectClaims().then(() => {});
  setInterval(() => stakeStick(), 8000);

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
