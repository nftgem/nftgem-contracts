// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import hre from 'hardhat';
import BigNumber from 'ethers';
const { ethers, deployments } = hre;
const { get } = deployments;
const { Contract } = ethers;
import { createClient } from 'redis';

import { pack, keccak256 } from '@ethersproject/solidity';

let sender: any = undefined;

const config = {
  networks: [
    {
      url: '',
      networkId: 25,
      gatewayContractAddress: ''
    },
    {
      url: '',
      networkId: 4002,
      gatewayContractAddress: ''
    }
  ]
}

function getConfig() {

  config.networks.forEach((net: any) => {
    if (!net.url || !net.networkId || !net.gatewayContractAddress) {
      throw new Error('Invalid configuration');
    }
  });

  return config;
}

async function configureNetwork(config: any) {
  const result: any = { };

  const gatewayContract = await hre.ethers.getContractAt(
    'ERC1155TokenBridge',
    (
      await hre.deployments.get('ERC1155TokenBridge')
    ).address
  );
  if (!await gatewayContract.isValidator(await sender.getAddress())) {
    throw new Error('You are not a validator');
  }
  // hook up event handler

  // each network will be named like 'network_<networkId>'

  // this is the dvent handler that listens to messages and forwards to the correct queue
  gatewayContract.on('NetworkTransfer', async (
    tokenAddress: string,
    receiptId: BigNumber,
    fromNetworkId: BigNumber,
    _from: string,
    toNetworkId: number,
    _to: string,
    _id: BigNumber[],
    _value: BigNumber[],
    isBatch: boolean) => {
    // create an object (for easy transport) with all the values in event
    // read the array of message from the destination queue
    // append the message to the queue
    // write the message array to the dest netwok
    const theMEssage = { };

    let arr = await gatewayContract.client.get(`network_${toNetworkId}`);
    if (!arr) {
      arr = [theMessage];
    } else arr.push(theMEssage);

    await gatewayContract.client.set(`network_${toNetworkId}`, arr);
  });

  result.client = createClient();

  result.client.on('error', (err: any) => console.log('Redis Client Error', err));

  await result.client.connect();

  result.gatewayContract = gatewayContract;

  return result;
}

async function main() {

  // We get the signer
  [sender] = await hre.ethers.getSigners();

  const config = getConfig();

  const configuredNetworks = await Promise.all(config.networks.map((config: any) => configureNetwork(config)));




}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
