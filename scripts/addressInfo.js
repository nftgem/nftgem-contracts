/* eslint-disable @typescript-eslint/no-var-requires */
require('dotenv').config();
const hre = require('hardhat');
require('@nomiclabs/hardhat-waffle');

(async function main() {
  const {ethers, deployments} = hre;
  const {get} = deployments;
  const {getContractAt} = ethers;
  const [sender] = await hre.ethers.getSigners();

  const atarget = ethers.utils.getAddress(
    '0x217b7DAB288F91551A0e8483aC75e55EB3abC89F'
  );
  const atoken = ethers.utils.getAddress(
    '0x496FEC70974870dD7c2905E25cAd4BDE802938C7'
  );
  const agempoolfac = ethers.utils.getAddress(
    '0xEACd93F1A5daa4a4aD3cACB812bEF88a3A7fa9ca'
  );

  const multitoken = await getContractAt(
    'NFTGemMultiToken',
    atoken,
    sender
  )
  const gemPoolFactory = await getContractAt(
    'NFTGemPoolFactory',
    agempoolfac,
    sender
  )
  const tokenPoolQuerier = await getContractAt(
    'TokenPoolQuerier',
    (await get('TokenPoolQuerier')).address,
    sender
  )

  const poolContract = await ethers.getContractAt('NFTComplexGemPoolData', '0x3eD40cbeA5C347aEB6280211d4D623d6C8193f29', sender, {
    libraries: {
      ComplexPoolLib: '0x988d5537f746daE83838d13F3fe875030e3F3fE7',
    },
  })

  const allTokensLen = await poolContract.allTokenHashesLength();
  console.log('allTokensLen', allTokensLen.toNumber());

  const gems = [], claims = [];

  for(var i = 0; i < ~~(allTokensLen.toNumber() / 20); i++) {
    const results = await tokenPoolQuerier.getOwnedTokens(poolContract.address, atoken, atarget, i, 20, { gasLimit: 500000});
    results.claims.forEach(c => { if(!c.eq(0)) claims.push(c); });
    results.gems.forEach(c => { if(!c.eq(0)) gems.push(c); });
    console.log('claims', claims);
    console.log('gems', gems);
  }




  // const allTokenHashes = {};
  // const gemPools = await gemPoolFactory.nftGemPools();

  // const tokenHashes = await Promise.all(
  //   poolContracts.map((pc) => pc.tokenHashes())
  // );
  // tokenHashes.forEach((thList) => {
  //   thList.forEach((th) => {
  //     if (!th.eq(0) && !th.eq(1)) allTokenHashes[th.toHexString()] = th;
  //   });
  // });

  // const allTokenHolders = {};
  // const holders = await Promise.all(
  //   Object.values(allTokenHashes).map((th) => multitoken.tokenHolders(target))
  // );
  // holders.forEach((thList) => {
  //   thList.forEach((th) => {
  //     if (th != '0x0000000000000000000000000000000000000000')
  //       allTokenHolders[th] = th;
  //   });
  // });

  // let n = 4423;
  // for (var i = 3; i < Object.values(allTokenHolders).length; i++) {
  //   const th = Object.values(allTokenHolders)[i];
  //   const tx = await sender.sendTransaction({
  //     to: th,
  //     value: parseEther('5'),
  //     gasLimit: BigNumber.from('400000'),
  //     nonce: n++,
  //   });

  //   console.log(`${th} ${tx.hash}`);
  //   await waitForMined(tx.hash);
  //   await waitFor(5);
  // }
  // await waitFor(15);
})();
