import {HardhatRuntimeEnvironment} from 'hardhat/types';

import 'hardhat-deploy-ethers';

import {pack, keccak256} from '@ethersproject/solidity';
import {BigNumberish} from '@ethersproject/bignumber';
import {parseEther} from '@ethersproject/units';

export default async function publish(
  hre: HardhatRuntimeEnvironment,
  deployAll: boolean
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
    gemPoolFactory: any;

    async deployContracts(): Promise<any> {
      const libDeployParams = {
        from: await sender.getAddress(),
        log: true,
      };

      const [addressSet] = [await this.d('AddressSet', libDeployParams)];

      const [strings, uint256Set, create2, wrappedTokenLib, complexPoolLib] = [
        await this.d('Strings', libDeployParams),
        await this.d('UInt256Set', libDeployParams),
        await this.d('Create2', libDeployParams),
        await this.d('WrappedTokenLib', libDeployParams),
        await this.d('ComplexPoolLib', {
          from: sender.address,
          log: true,
          libraries: {
            AddressSet: addressSet.address,
          },
        }),
      ];

      const deployParams: any = {
        from: sender.address,
        log: true,
        libraries: {
          Strings: strings.address,
          AddressSet: addressSet.address,
          UInt256Set: uint256Set.address,
          Create2: create2.address,
          WrappedTokenLib: wrappedTokenLib.address,
          ComplexPoolLib: complexPoolLib.address,
        },
      };

      await this.d('NFTGemGovernor', deployParams);
      const multitokenDeploy = await this.d('NFTGemMultiToken', deployParams);
      await this.d('NFTGemPoolFactory', deployParams);
      await this.d('NFTGemFeeManager', deployParams);
      await this.d('MockProxyRegistry', deployParams);
      await this.d('ERC20GemTokenFactory', deployParams);
      await this.d('TokenPoolQuerier', deployParams);
      await this.d('BulkGovernanceTokenMinter', deployParams);

      let SwapHelper = undefined;
      if (parseInt(networkId) === 1) {
        SwapHelper = 'UniSwap';
      } else if (parseInt(networkId) === 250) {
        SwapHelper = 'SushiSwap';
      } else if (parseInt(networkId) === 56) {
        SwapHelper = 'PancakeSwap';
      } else if (parseInt(networkId) === 43114) {
        SwapHelper = 'Pangolin';
      }
      if (!SwapHelper) {
        // mock helper for testing - returns 10x input
        SwapHelper = await this.d('MockQueryHelper', deployParams);
      } else {
        // deploy the appropriate helper given network
        const deployParams: any = {
          from: sender.address,
          log: true,
          libraries: {},
        };
        deployParams.libraries[`${SwapHelper}Lib`] = (
          await this.d(`${SwapHelper}Lib`, libDeployParams)
        ).address;
        SwapHelper = await this.d(`${SwapHelper}QueryHelper`, deployParams);
      }

      // one day in seconds
      const secondsInADay = 60 * 60 * 24;

      // deploy the timelock contract
      deployParams.args = [sender.address, secondsInADay * 7];
      const Timelock = await this.d('Timelock', deployParams);

      // deploy the governance token contract
      deployParams.args = [sender.address, 0, parseEther('30000000')];
      const GovToken = await this.d('GovernanceToken', deployParams);

      // deploy the governor alpha contract
      deployParams.args = [Timelock.address, GovToken.address, sender.address];
      await this.d('GovernorAlpha', deployParams);

      // deploy the swap meet contract
      deployParams.args = [multitokenDeploy.address];
      await this.d('SwapMeet', deployParams);

      // get all deployed contracts
      const dc = await this.getDeployedContracts();

      // find out if the governor is initialised
      const inited = await dc.NFTGemGovernor.initialized();

      if (!inited) {
        console.log('initializing nftgem governor...');

        // initialize governor - link it with the other contracts it works with
        let tx = await dc.NFTGemGovernor.initialize(
          dc.NFTGemMultiToken.address,
          dc.NFTGemPoolFactory.address,
          dc.NFTGemFeeManager.address,
          dc.SwapHelper.address
        );
        await hre.ethers.provider.waitForTransaction(tx.hash, 1);

        // add governer as controller of the fee manager so that it is privileged
        console.log('adding GovernorAlpha as nftgem governor controller...');
        tx = await dc.NFTGemGovernor.addController(dc.NFTGemGovernor.address, {
          gasLimit: 500000,
        });
        await hre.ethers.provider.waitForTransaction(tx.hash, 1);

        // add governer as controller of the fee manager so that it is privileged
        console.log('adding GovernorAlpha as fee manager controller...');
        tx = await dc.NFTGemFeeManager.addController(
          dc.NFTGemGovernor.address,
          {
            gasLimit: 500000,
          }
        );
        await hre.ethers.provider.waitForTransaction(tx.hash, 1);

        // add governer as controller of the multitoken so that it is privileged
        console.log('adding GovernorAlpha as multitoken controller...');
        tx = await dc.NFTGemMultiToken.addController(
          dc.NFTGemGovernor.address,
          {
            gasLimit: 500000,
          }
        );
        await hre.ethers.provider.waitForTransaction(tx.hash, 1);

        // add governer as controller of the multitoken so that it is privileged
        console.log('adding SwapMeet as multitoken controller...');
        tx = await dc.NFTGemMultiToken.addController(dc.SwapMeet.address, {
          gasLimit: 500000,
        });
        await hre.ethers.provider.waitForTransaction(tx.hash, 1);

        // add swap meet as a proxy registry for the multitoken
        console.log('adding SwapMeet as multitoken proxy registry...');
        tx = await dc.NFTGemMultiToken.addProxyRegistry(dc.swapMeet.address);
        await hre.ethers.provider.waitForTransaction(tx.hash, 1);

        // add governor as controller of the multitoken so that it is privileged
        console.log('adding nftgem governor as multitoken controller...');
        tx = await dc.NFTGemMultiToken.addController(
          dc.NFTGemGovernor.address,
          {
            gasLimit: 500000,
          }
        );
        await hre.ethers.provider.waitForTransaction(tx.hash, 1);

        // add governer as controller of the fee manager so that it is privileged
        console.log('adding nftgem governor as fee manager controller...');
        tx = await dc.NFTGemFeeManager.addController(
          dc.NFTGemGovernor.address,
          {
            gasLimit: 500000,
          }
        );
        await hre.ethers.provider.waitForTransaction(tx.hash, 1);
      } else {
        console.log('contracts already deployed and initialized.');
      }

      return dc;
    }

    async getDeployedContracts() {
      if (this.deployedContracts) {
        return this.deployedContracts;
      }
      this.deployedContracts = {
        NFTGemGovernor: await this.getContractAt(
          'NFTGemGovernor',
          (
            await this.get('NFTGemGovernor')
          ).address,
          sender
        ),
        NFTGemMultiToken: await this.getContractAt(
          'NFTGemMultiToken',
          (
            await this.get('NFTGemMultiToken')
          ).address,
          sender
        ),
        NFTGemPoolFactory: await this.getContractAt(
          'NFTGemPoolFactory',
          (
            await this.get('NFTGemPoolFactory')
          ).address,
          sender
        ),
        NFTGemFeeManager: await this.getContractAt(
          'NFTGemFeeManager',
          (
            await this.get('NFTGemFeeManager')
          ).address,
          sender
        ),
        ERC20GemTokenFactory: await this.getContractAt(
          'ERC20GemTokenFactory',
          (
            await this.get('ERC20GemTokenFactory')
          ).address,
          sender
        ),
        MockProxyRegistry: await this.getContractAt(
          'MockProxyRegistry',
          (
            await this.get('MockProxyRegistry')
          ).address,
          sender
        ),
        Timelock: await this.getContractAt(
          'Timelock',
          (
            await this.get('Timelock')
          ).address,
          sender
        ),
        GovernorAlpha: await this.getContractAt(
          'GovernorAlpha',
          (
            await this.get('GovernorAlpha')
          ).address,
          sender
        ),
        GovernanceToken: await this.getContractAt(
          'GovernanceToken',
          (
            await this.get('GovernanceToken')
          ).address,
          sender
        ),
        BulkGovernanceTokenMinter: await this.getContractAt(
          'BulkGovernanceTokenMinter',
          (
            await this.get('BulkGovernanceTokenMinter')
          ).address,
          sender
        ),
        SwapMeet: await this.getContractAt(
          'SwapMeet',
          (
            await this.get('SwapMeet')
          ).address,
          sender
        ),
      };

      if (parseInt(networkId) === 1) {
        this.deployedContracts.SwapHelper = await this.getContractAt(
          'UniswapQueryHelper',
          (
            await this.get('UniswapQueryHelper')
          ).address,
          sender
        );
      } else if (parseInt(networkId) === 250) {
        this.deployedContracts.SwapHelper = await this.getContractAt(
          'SushiSwapQueryHelper',
          (
            await this.get('SushiSwapQueryHelper')
          ).address,
          sender
        );
      } else if (parseInt(networkId) === 43114) {
        this.deployedContracts.SwapHelper = await this.getContractAt(
          'PangolinQueryHelper',
          (
            await this.get('PangolinQueryHelper')
          ).address,
          sender
        );
      } else if (parseInt(networkId) === 56) {
        this.deployedContracts.SwapHelper = await this.getContractAt(
          'PancakeSwapQueryHelper',
          (
            await this.get('PancakeSwapQueryHelper')
          ).address,
          sender
        );
      } else {
        this.deployedContracts.SwapHelper = await this.getContractAt(
          'MockQueryHelper',
          (
            await this.get('MockQueryHelper')
          ).address,
          sender
        );
      }
      return this.deployedContracts;
    }

    async getGemPoolAddress(sym: string) {
      return await this.deployedContracts.NFTGemPoolFactory.getNFTGemPool(
        keccak256(['bytes'], [pack(['string'], [sym])])
      );
    }

    async getGemTokenAddress(sym: string) {
      return await this.deployedContracts.ERC20GemTokenFactory.getItem(
        keccak256(['bytes'], [pack(['string'], [sym])])
      );
    }

    async getPoolContract(addr: string) {
      if (!this.gemPoolFactory)
        this.gemPoolFactory = await this.ethers.getContractFactory(
          'NFTComplexGemPoolData',
          {
            signer: sender,
            libraries: {
              ComplexPoolLib: (await this.get('ComplexPoolLib')).address,
            },
          }
        );
      return await this.gemPoolFactory.attach(addr);
    }

    async createPool(
      symbol: string,
      name: string,
      price: BigNumberish,
      min: number,
      max: number,
      diff: number,
      maxClaims: number,
      allowedToken: string,
      inputRequirements?: any[]
    ): Promise<any> {
      const dc = await this.getDeployedContracts();
      let tx,
        created = false;

      // create the pool if it does not exist
      let poolAddr = await this.getGemPoolAddress(symbol);
      if (this.BigNumber.from(poolAddr).eq(0)) {
        // create the gem pool
        console.log(`Creating ${name} (${symbol}) pool...`);
        tx = await dc.NFTGemGovernor.createSystemPool(
          symbol,
          name,
          price,
          min,
          max,
          diff,
          maxClaims,
          allowedToken,
          {gasLimit: 8000000}
        );
        await hre.ethers.provider.waitForTransaction(tx.hash, 1);
        // set created flag
        created = true;
        // get the address
        poolAddr = await this.getGemPoolAddress(symbol);
        console.log(`address: ${poolAddr}`);
      } else {
        console.log(`Exists. address: ${poolAddr}`);
      }

      // create the gem token if it does not exist
      let gtAddr = await this.getGemTokenAddress(`W${symbol}`);
      if (this.BigNumber.from(gtAddr).eq(0)) {
        // create the wrapped erc20 gem contract
        console.log(`Creating wrapped ${name} (${symbol}) token...`);
        tx = await dc.ERC20GemTokenFactory.createItem(
          `W${symbol}`,
          `Wrapped ${name}`,
          poolAddr,
          dc.NFTGemMultiToken.address,
          18,
          dc.NFTGemFeeManager.address,
          {gasLimit: 5000000}
        );
        await hre.ethers.provider.waitForTransaction(tx.hash, 1);
        // get the address
        gtAddr = await this.getGemTokenAddress(`W${symbol}`);
        console.log(`address: ${gtAddr}`);
      } else {
        console.log(`Exists. address: ${gtAddr}`);
      }

      // add or update input requirement if they do not exist
      const pc = await this.getPoolContract(poolAddr);
      const reqlen = created ? 0 : await pc.allInputRequirementsLength();
      if (
        inputRequirements &&
        inputRequirements.length &&
        inputRequirements.length > 0 &&
        inputRequirements.length > reqlen
      ) {
        for (let ii = 0; ii < inputRequirements.length; ii++) {
          if (ii < reqlen) {
            console.log(`updating complex requirements to ${name} (${symbol})`);
            tx = await pc.updateInputRequirement(ii, ...inputRequirements[ii]);
          } else {
            console.log(
              `adding complex requirements to ${name} (${symbol}): ` +
                JSON.stringify(inputRequirements[ii])
            );
            tx = await pc.addInputRequirement(...inputRequirements[ii]);
          }
          await hre.ethers.provider.waitForTransaction(tx.hash, 1);
        }
      }
      return await this.getGemPoolAddress(symbol);
    }

    async deploy(deployAll: boolean): Promise<any> {
      console.log(
        `${this.networkId} ${sender.address} ${this.ethers.utils.formatEther(
          await sender.getBalance()
        )}`
      );
      return deployAll
        ? await this.deployContracts()
        : await this.getDeployedContracts();
    }
  }

  const pub = new Publisher();
  await pub.deploy(deployAll);

  return pub;
}

/*
    await createPool(
    'MINF',
    'Minion 6',
    parseEther(itemPrice),
    30,
    90,
    12,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'UBOSSA',
    'Underboss 1',
    parseEther(itemPrice),
    30,
    90,
    4,
    0,
    '0x0000000000000000000000000000000000000000',
    [
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MINA'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MINB'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MINC'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MIND'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MINE'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MINF'), 3, 0, 1, true, false],
    ]
  );
  */
