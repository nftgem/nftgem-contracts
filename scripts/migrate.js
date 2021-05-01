const hre = require('hardhat');
require('@nomiclabs/hardhat-waffle');

async function main() {
  const [sender] = await hre.ethers.getSigners();
  const {ethers} = hre;
  const {getContractAt} = ethers;

  const {BigNumber} = ethers;

  const bitbean = ethers.utils.getAddress(
    '0x89dA0A11CB88a217C1cDEa0eb7731EaD12219D35'
  );
  const superbitbean = ethers.utils.getAddress(
    '0x47523D669971fa81b2374cA62a5Cd3B860435605'
  );
  // const oldToken = ethers.utils.getAddress(
  //   '0xD1e52814f0d7951DAECb3eEc67ADF1074F6a5148'
  // );
  // const anewToken = ethers.utils.getAddress(
  //   '0xe2A220DCE7E75E3025AEfb944f473fF2be5F77C9'
  // );

  const oldToken = ethers.utils.getAddress(
    '0xe2A220DCE7E75E3025AEfb944f473fF2be5F77C9'
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

  const bitbeanPool = await Pool.attach(bitbean);
  const sbitbeanPool = await Pool.attach(superbitbean);
  const bitbeanData = await Data.attach(bitbean);
  const sbitbeanData = await Data.attach(superbitbean);

  const token = await getContractAt('NFTGemMultiToken', oldToken, sender);
  const newToken = await getContractAt('NFTGemMultiToken', anewToken, sender);
  const governor = await getContractAt('NFTGemGovernor', agovernor, sender);
  const factory = await getContractAt('NFTGemPoolFactory', afactory, sender);

  const gpLen = await factory.allNFTGemPoolsLength();
  for (let gp = 0; gp < gpLen.toNumber(); gp++) {
    const gpAddr = await factory.allNFTGemPools(gp);
    if (
      gpAddr === '0x89dA0A11CB88a217C1cDEa0eb7731EaD12219D35' ||
      gpAddr === '0x47523D669971fa81b2374cA62a5Cd3B860435605'
    ) {
      continue;
    }
    const pool = await Pool.attach(gpAddr);
    const data = await Data.attach(gpAddr);

    let thLen = await data.allTokenHashesLength();
    console.log(`processing ${thLen.toNumber()} hashes`);
    for (let i = 0; i < thLen.toNumber(); i++) {
      const tHash = await data.allTokenHashes(BigNumber.from(i), {
        gasLimit: 5000000,
      });
      const ath = await token.allTokenHoldersLength(tHash, {gasLimit: 5000000});
      if (
        ath.gt(1) &&
        !BigNumber.from(tHash).eq(0) &&
        !BigNumber.from(tHash).eq(1)
      ) {
        console.log('broken', tHash.toHexString());
        continue;
      }
      for (let j = 0; j < ath.toNumber(); j++) {
        const atha = await token.allTokenHolders(tHash, BigNumber.from(j), {
          gasLimit: 5000000,
        });
        if (BigNumber.from(atha).eq(0)) continue;
        const abal = await token.balanceOf(atha, tHash);
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
