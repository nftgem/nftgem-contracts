const hre = require('hardhat');
require('@nomiclabs/hardhat-waffle');

async function main() {
  const [sender] = await hre.ethers.getSigners();
  const {ethers} = hre;
  const {getContractAt} = ethers;

  const {BigNumber} = ethers;

  const aoldToken = ethers.utils.getAddress(
    '0x496FEC70974870dD7c2905E25cAd4BDE802938C7'
  );
  const anewToken = ethers.utils.getAddress(
    '0x8948bCfd1c1A6916c64538981e44E329BF381a59'
  );

  const agovernor = ethers.utils.getAddress(
    '0x5f8ccfdeb0c8170433bd8571da9abdc7b12776d5'
  );

  const afactory = ethers.utils.getAddress(
    '0xaEA74b36Bc9B0FdC7429127f9A49BAE9edea898D'
  );

  const myAddress = await sender.getAddress();
  console.log(myAddress);

  const Data = await ethers.getContractFactory('NFTGemPoolData');
  const Pool = await ethers.getContractFactory('NFTGemPool');

  const oldToken = await getContractAt('NFTGemMultiToken', aoldToken, sender);
  const newToken = await getContractAt('NFTGemMultiToken', anewToken, sender);
  const governor = await getContractAt('NFTGemGovernor', agovernor, sender);
  const factory = await getContractAt('NFTGemPoolFactory', afactory, sender);

  const gpLen = await factory.allNFTGemPoolsLength();
  for (let gp = 0; gp < gpLen.toNumber(); gp++) {
    const gpAddr = await factory.allNFTGemPools(gp);

    const pool = await Pool.attach(gpAddr);
    const data = await Data.attach(gpAddr);

    let thLen = await data.allTokenHashesLength();
    console.log(`processing ${thLen.toNumber()} hashes`);
    for (let i = 0; i < thLen.toNumber(); i++) {
      const tHash = await data.allTokenHashes(BigNumber.from(i), {
        gasLimit: 5000000,
      });
      const ath = await oldToken.allTokenHoldersLength(tHash, {
        gasLimit: 5000000,
      });
      if (
        ath.gt(1) &&
        !BigNumber.from(tHash).eq(0) &&
        !BigNumber.from(tHash).eq(1)
      ) {
        console.log('broken', tHash.toHexString());
        continue;
      }
      for (let j = 0; j < ath.toNumber(); j++) {
        const atha = await oldToken.allTokenHolders(tHash, BigNumber.from(j), {
          gasLimit: 5000000,
        });
        if (BigNumber.from(atha).eq(0)) continue;
        const abal = await oldToken.balanceOf(atha, tHash);
        if (!abal.eq(0)) {
          const nbal = await newToken.balanceOf(atha, tHash);
          if (!abal.eq(nbal)) {
            await newToken.mint(atha, tHash, abal, {gasLimit: 5000000});
            console.log(
              `${atha} ${tHash.toHexString()} ${abal.toNumber()} minted`
            );
          } else {
            console.log(`${atha} ${tHash.toHexString()} ${abal.toNumber()}`);
          }
        }
      }
    }
    await pool.setMultiToken(newToken.address);
    await newToken.addController(pool.address);
  }

  await governor.setMultitoken('0x8948bCfd1c1A6916c64538981e44E329BF381a59');
}
function stall() {
  setTimeout(() => stall());
}

main()
  .then(() => {
    //stall();
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
