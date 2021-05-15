/* eslint-disable @typescript-eslint/no-var-requires */
require('dotenv').config();
const {BigNumber} = require('ethers');
const {parseEther} = require('ethers/lib/utils');
const hre = require('hardhat');
require('@nomiclabs/hardhat-waffle');

(async function main() {
  const {ethers} = hre;

  const [sender] = await hre.ethers.getSigners();

  // get multitoken
  const NFTGemMultiToken = await ethers.getContractFactory('NFTGemMultiToken');
  const multitoken = await NFTGemMultiToken.attach('0xf4899c94a0319825b341775e4387b1c5081b9d1b');
  const multitoken2 = await NFTGemMultiToken.attach('0x481d559466a04EB3744832e02a05aB1AE68fEb17');

  // target address
  const target = ethers.utils.getAddress(
    '0x391b80e88860bc715841568bc2c92dc3892360a6'
  );
  const target2 = ethers.utils.getAddress(
    '0x217b7DAB288F91551A0e8483aC75e55EB3abC89F'
  );
  // the target gem pool
  const agemPool = ethers.utils.getAddress(
    process.env.GEM_POOL || '0x3e15DCd222890C05828d5AC53aCe42C3d8495800'
  );
  const gemPool = await ethers.getContractAt('NFTGemPoolData', agemPool, sender, {})

  const symbol = await gemPool.symbol();
  console.log(symbol);

  let heldTokens = [];
  for(let i = 0; i < (await multitoken.allHeldTokensLength(target)).toNumber; i++) {
    heldTokens.push(await multitoken.allHeldTokens(target, i));
  }
  console.log(heldTokens);

  heldTokens = [];
  for(let i = 0; i < (await multitoken2.allHeldTokensLength(target)).toNumber; i++) {
    heldTokens.push(await multitoken2.allHeldTokens(target, i));
  }
  console.log(heldTokens);

  heldTokens = [];
  for(let i = 0; i < (await multitoken.allHeldTokensLength(target2)).toNumber; i++) {
    heldTokens.push(await multitoken.allHeldTokens(target2, i));
  }
  console.log(heldTokens);

  heldTokens = [];
  for(let i = 0; i < (await multitoken2.allHeldTokensLength(target2)).toNumber; i++) {
    heldTokens.push(await multitoken2.allHeldTokens(target2, i));
  }
  console.log(heldTokens);

})();
