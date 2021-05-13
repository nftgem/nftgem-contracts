const hre = require('hardhat');
require('@nomiclabs/hardhat-waffle');

async function main() {
  const [sender] = await hre.ethers.getSigners();
  const myAddress = await sender.getAddress();
  console.log(myAddress);
  const {ethers} = hre;
  const {BigNumber} = ethers;

  const aGemPoolFactory = ethers.utils.getAddress(
    '0xaEA74b36Bc9B0FdC7429127f9A49BAE9edea898D'
  );

  const GemPoolFactory = await ethers.getContractFactory('NFTGemPoolFactory');
  const gemPoolFactory = await GemPoolFactory.attach(aGemPoolFactory);

  async function getTransactionsTotal() {
    let result = 0;
    const length = await gemPoolFactory.allNFTGemPoolsLength();
    for (let i = 0; i < length.toNumber(); i++) {
      const addr = await gemPoolFactory.allNFTGemPools(i);
      const cnt = await ethers.provider.getTransactionCount(addr);
      console.log(addr, cnt);
      result = result + cnt;
    }
    return result;
  }

  const total = await getTransactionsTotal();
  console.log(total);

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
