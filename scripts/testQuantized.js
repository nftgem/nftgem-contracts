import hre from 'hardhat';

async (args, hre) => {
  const blockNumber = await hre.ethers.provider.getBlockNumber();
  console.log('Current block number: ' + blockNumber);

}

const setupContracts = async () => {
  const abis = require('./quantized.json').contracts;
  const [owner] = await hre.ethers.getSigners();
  const senderAddress = await owner.getAddress();
  const contracts = [];
  await Object.keys(abis).forEach(async abi => contracts[abi] = await hre.ethers.getContractAt(
    abis[abi].abi,
    abis[abi].address,
    owner
  ));
  return { owner, senderAddress, contracts }
};
const c = await setupContracts();
