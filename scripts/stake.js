/* eslint-disable @typescript-eslint/no-var-requires */
require('dotenv').config();
const hre = require('hardhat');
require('@nomiclabs/hardhat-waffle');

async function main() {
  const [sender] = await hre.ethers.getSigners();
  const {ethers} = hre;
  const {BigNumber} = ethers;

  const addressStick = ethers.utils.getAddress(process.env.STICK_ADDRESS);
  const addressToken = ethers.utils.getAddress(process.env.TOKEN_ADDRESS);
  const addressFeeManager = ethers.utils.getAddress(
    process.env.FEE_MANAGER_ADDRESS
  );

  const myAddress = await sender.getAddress();
  const myBalance = await sender.getBalance();
  console.log(
    `myAddress=${myAddress}`,
    `myBalance=${hre.ethers.utils.formatEther(myBalance)}`
  );

  const [FeeManager, Token, Pool, Data] = await Promise.all([
    ethers.getContractFactory('NFTGemFeeManager'),
    ethers.getContractFactory('NFTGemMultiToken'),
    ethers.getContractFactory('NFTGemPool'),
    ethers.getContractFactory('NFTGemPoolData'),
  ]);

  // const gemPoolFactory = await GemPoolFactory.attach(aGemPoolFactory);

  const token = await Token.attach(addressToken);
  const pool = await Pool.attach(addressStick);
  const data = Data.attach(addressStick);
  const feeManager = await FeeManager.attach(addressFeeManager);

  const bitlootEarned = await
    feeManager.ethBalanceOf(),
;


  console.log(
    `bitloot feeManager=${addressFeeManager}`,
    `feeBalance=${hre.ethers.utils.formatEther(bitlootEarned)}`
  );

  async function cleanup() {
    const allLen = await pool.allTokenHashesLength();
    for (let i = allLen - 1; i >= 0; i -= 1) {
      const tokenHash = await pool.allTokenHashes(i);
      const [tokenType, ebal, mybal] = await Promise.all([
        pool.tokenType(tokenHash),
        token.balanceOf(myAddress, tokenHash),
        token.balanceOf(myAddress, BigNumber.from(0)),
      ]);
      console.log(`${i} of ${allLen}, balance=${ebal}, my balance=${mybal}`);
      if (!ebal.eq(0) && tokenType === 1) {
        await pool.collectClaim(tokenHash, {gasLimit: 4200000});
        console.log(`... attempted collection`);
      } else console.log(`... skipping`);
    }
  }

  async function claimStick(claimHash) {
    try {
      await pool.collectClaim(claimHash, {gasLimit: 4200000});
      const sticks = await token.balanceOf(myAddress, BigNumber.from(0));
      console.log(`${sticks} sticks, claim ${claimHash} collected`);
    } catch (e) {
      console.log(`error collecting claim - ${claimHash}`, e.message);
    }
  }

  let lastClaimHash = BigNumber.from(0);
  async function stakeStick() {
    try {
      const claimHash = await pool.nextClaimHash();
      // console.log(claimHash, String.valueOf(claimHash));
      if (!claimHash.eq(lastClaimHash)) {
        lastClaimHash = claimHash;
        const [ethPrice, minTime, difficultyStep, sticks] = await Promise.all([
          data.ethPrice(),
          data.minTime(),
          data.difficultyStep(),
          token.balanceOf(myAddress, BigNumber.from(0)),
        ]);

        // const time = await data.claimUnlockTime(claimHash);

        const addPercent = ethPrice
          .add(ethPrice.div(difficultyStep))
          .div(BigNumber.from(100 / 5));

        const purchasePrice = ethPrice
          .add(ethPrice.div(difficultyStep))
          .add(addPercent);

        console.log(
          `${sticks} sticks, stick ${claimHash} price is ${hre.ethers.utils.formatEther(
            purchasePrice
          )} ethPrice=${ethPrice} adj=${difficultyStep}`
        );
        // process.exit(0);

        const claim = await pool.createClaims(minTime.add(10), 1, {
          value: purchasePrice,
          gasLimit: 4200000,
        });
        console.log('claim', claim.nonce, claim.hash);

        const [myBalance, newSticks] = await Promise.all([
          sender.getBalance(),
          token.balanceOf(myAddress, BigNumber.from(0)),
        ]);
        console.log(
          `${newSticks} sticks, stick ${claimHash} purchased for ${hre.ethers.utils.formatEther(
            purchasePrice
          )}, myBalance=${hre.ethers.utils.formatEther(myBalance)}`
        );
        setTimeout(async () => {
          await claimStick(claimHash);
        }, 2000);
      } else {
        const sticks = await token.balanceOf(myAddress, BigNumber.from(0));
        console.log(`${sticks} sticks, stick ${claimHash} has not changed.`);
      }
    } catch (err) {
      console.log(`failed to stake claim`, err.message);
      // process.exit(1);
    }
  }

  //collectClaims().then(() => {});
  // await cleanup();
  setInterval(() => stakeStick(), 3000);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
