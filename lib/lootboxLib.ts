import { HardhatRuntimeEnvironment } from 'hardhat/types';

import 'hardhat-deploy-ethers';

import { pack, keccak256 } from '@ethersproject/solidity';
import { BigNumber, Contract } from 'ethers';

export type Loot = {
  owner: string;
  lootHash: BigNumber;
  multitoken: string;
  symbol: string;
  name: string;
  probability: BigNumber;
  probabilityIndex: BigNumber;
  probabilityRoll: BigNumber;
  maxMint: BigNumber;
  minted: BigNumber;
};


export type Lootbox = {
  owner: string;
  contractAddress: string;
  contract: Contract;
  randomFarmer: string;
  multitoken: string;
  lootboxHash: BigNumber; // identifier and lootbox token hash for the lootbox
  symbol: string;
  name: string;
  description: string;
  minLootPerOpen: number;
  maxLootPerOpen: number;
  openPrice: BigNumber;
  maxOpens: BigNumber;
  openCount: BigNumber;
  totalLootGenerated: BigNumber;
  lootboxTokenSalePrice: BigNumber;
  probabilitiesSum: BigNumber;
  initialized: boolean;
  loot?: Loot[];
  openedCount: BigNumber;
  lootIssuedCount: BigNumber;
};


export default async function publish(
  hre: HardhatRuntimeEnvironment
): Promise<any> {
  const networkId = await hre.getChainId();
  const [sender] = await hre.ethers.getSigners();
  class Publisher {
    BigNumber = hre.ethers.BigNumber;
    ethers = hre.ethers;
    deployments = hre.deployments;
    getContractAt = hre.ethers.getContractAt;
    get = hre.deployments.get;
    d = hre.deployments.deploy;
    networkId = networkId;
    deployedContracts: any;
    lootboxFactory: any;

    async getDeployedContracts() {
      if (this.deployedContracts) {
        return this.deployedContracts;
      }
      this.deployedContracts = {
        NFTGemMultiToken: await this.getContractAt(
          'NFTGemMultiToken',
          (
            await this.get('NFTGemMultiToken')
          ).address,
          sender
        ),
        LootboxData: await this.getContractAt(
          'LootboxData',
          (
            await this.get('LootboxData')
          ).address,
          sender
        ),
        LootboxFactory: await this.getContractAt(
          'LootboxFactory',
          (
            await this.get('LootboxFactory')
          ).address,
          sender
        ),
        RandomFarm: await this.getContractAt(
          'RandomFarm',
          (
            await this.get('RandomFarm')
          ).address,
          sender
        ),
        RandomFarmer: await this.getContractAt(
          'RandomFarmer',
          (
            await this.get('RandomFarmer')
          ).address,
          sender
        )
      };
      return this.deployedContracts;
    }

    async getLootboxAddress(sym: string) {
      return await this.deployedContracts.LootboxFactory.getLootbox(
        keccak256(['bytes'], [pack(['string'], [sym])])
      );
    }

    async getLootboxContract(addr: string) {
      this.lootboxFactory = await this.ethers.getContractFactory(
        'LootboxContract',
        {
          signer: sender,
          libraries: {
            'LootboxLib': (
              await this.get('LootboxLib')
            ).address,
          }
        }
      );
      return await this.lootboxFactory.attach(addr);
    }

    async createLootbox(
      lootbox: Lootbox,
      tokenSeller: any
    ): Promise<any> {
      const dc = await this.getDeployedContracts();
      let tx,
        created = false;

      // create the lootbox if it does not exist
      let lootboxAddr = await this.getLootboxAddress(lootbox.symbol);
      if (this.BigNumber.from(lootboxAddr.contractAddress).eq(0)) {
        // create the gem pool
        const lootboxArray = [
          lootbox.owner,
          lootbox.owner,
          lootbox.randomFarmer,
          lootbox.multitoken,
          lootbox.lootboxHash, // identifier and lootbox token hash for the lootbox
          lootbox.symbol,
          lootbox.name,
          lootbox.description,
          lootbox.minLootPerOpen,
          lootbox.maxLootPerOpen,
          lootbox.openPrice,
          lootbox.maxOpens,
          lootbox.openCount,
          lootbox.totalLootGenerated,
          lootbox.lootboxTokenSalePrice,
          lootbox.probabilitiesSum,
          lootbox.initialized,
          lootbox.openedCount,
          lootbox.lootIssuedCount,
        ];
        //lootboxArray = Object.assign(lootboxArray, lootbox);
        console.log(`Creating lootbox: `, lootboxArray);
        tx = await dc.LootboxFactory.createLootbox(
          lootbox.owner,
          lootboxArray,
          tokenSeller,
          { gasLimit: 8000000 }
        );
      }

      // get the lootbox contract addres
      if (this.BigNumber.from(lootboxAddr.contractAddress).eq(0)) {
        await hre.ethers.provider.waitForTransaction(tx.hash, 1);
        // set created flag
        created = true;
        // get the address
        lootboxAddr = await this.getLootboxAddress(lootbox.symbol);
        console.log(`address: ${lootboxAddr.contractAddress}`);
      } else {
        console.log(`Exists. address: ${lootboxAddr.contractAddress}`);
      }

      return lootboxAddr;
    }

    async init(): Promise<any> {
      console.log(
        `${this.networkId} ${sender.address} ${this.ethers.utils.formatEther(
          await sender.getBalance()
        )}`
      );
      return await this.getDeployedContracts();
    }
  }

  const pub = new Publisher();
  await pub.init();

  return pub;
}

