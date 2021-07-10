import {HardhatRuntimeEnvironment} from 'hardhat/types';

import 'hardhat-deploy-ethers';

import {pack, keccak256} from '@ethersproject/solidity';
import {BigNumberish} from '@ethersproject/bignumber';

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

    constructor() {
      this.deployContracts = this.deployContracts.bind(this);
      this.getDeployedContracts = this.getDeployedContracts.bind(this);
      this.getGemPoolAddress = this.getGemPoolAddress.bind(this);
      this.getGemTokenAddress = this.getGemTokenAddress.bind(this);
      this.getPoolContract = this.getPoolContract.bind(this);
      this.deploy = this.deploy.bind(this);
    }

    async deployContracts(): Promise<any> {
      const libDeployParams = {
        from: await sender.getAddress(),
        log: true,
      };

      const [govLib, addressSet] = [
        await this.d('GovernanceLib', libDeployParams),
        await this.d('AddressSet', libDeployParams),
      ];

      const [
        strings,
        uint256Set,
        create2,
        wrappedTokenLib,
        proposalsLib,
        complexPoolLib,
      ] = await Promise.all([
        this.d('Strings', libDeployParams),
        this.d('UInt256Set', libDeployParams),
        this.d('Create2', libDeployParams),
        this.d('WrappedTokenLib', libDeployParams),
        this.d('ProposalsLib', {
          from: sender.address,
          log: true,
          libraries: {
            GovernanceLib: govLib.address,
          },
        }),
        this.d('ComplexPoolLib', {
          from: sender.address,
          log: true,
          libraries: {
            AddressSet: addressSet.address,
          },
        }),
      ]);

      const deployParams: any = {
        from: sender.address,
        log: true,
        libraries: {
          GovernanceLib: govLib.address,
          Strings: strings.address,
          AddressSet: addressSet.address,
          UInt256Set: uint256Set.address,
          Create2: create2.address,
          ProposalsLib: proposalsLib.address,
          ComplexPoolLib: complexPoolLib.address,
          WrappedTokenLib: wrappedTokenLib.address,
        },
      };

      await Promise.all([
        this.d('NFTGemGovernor', deployParams),
        this.d('NFTGemMultiToken', deployParams),
        this.d('NFTGemPoolFactory', deployParams),
        this.d('NFTGemFeeManager', deployParams),
        this.d('ProposalFactory', deployParams),
        this.d('MockProxyRegistry', deployParams),
        this.d('ERC20GemTokenFactory', deployParams),
        this.d('TokenPoolQuerier', deployParams),
        this.d('BulkTokenMinter', deployParams),
      ]);

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

      const dc = await this.getDeployedContracts();

      const inited = await dc.NFTGemGovernor.initialized();

      if (!inited) {
        console.log('initializing governor...');

        let tx = await dc.NFTGemGovernor.initialize(
          dc.NFTGemMultiToken.address,
          dc.NFTGemPoolFactory.address,
          dc.NFTGemFeeManager.address,
          dc.ProposalFactory.address,
          dc.SwapHelper.address
        );
        await hre.ethers.provider.waitForTransaction(tx.hash, 1);

        console.log('propagating multitoken controller...');
        tx = await dc.NFTGemMultiToken.addController(
          dc.NFTGemGovernor.address,
          {
            gasLimit: 500000,
          }
        );
        await hre.ethers.provider.waitForTransaction(tx.hash, 1);

        console.log('propagating fee manager controller...');
        tx = await dc.NFTGemFeeManager.addController(
          dc.NFTGemGovernor.address,
          {
            gasLimit: 500000,
          }
        );
        await hre.ethers.provider.waitForTransaction(tx.hash, 1);

        console.log('minting initial governance tokens...');
        tx = await dc.NFTGemGovernor.issueInitialGovernanceTokens(
          sender.address,
          {
            gasLimit: 5000000,
          }
        );
        await hre.ethers.provider.waitForTransaction(tx.hash, 1);

        // deploy the governance token wrapper
        console.log('deploying wrapped governance token...');
        deployParams.args = [
          'NFTGem Governance',
          'NFTGG',
          dc.NFTGemMultiToken.address,
          dc.NFTGemFeeManager.address,
        ];
        await this.d('NFTGemWrappedERC20Governance', deployParams);

        // init governance token wrapper
        console.log('intializing wrapped governance token...');
        dc.NFTGemWrappedERC20Governance = await this.getContractAt(
          'NFTGemWrappedERC20Governance',
          (await this.get('NFTGemWrappedERC20Governance')).address,
          sender
        );
        tx = await dc.NFTGemWrappedERC20Governance.initialize(
          '',
          '',
          '0x0000000000000000000000000000000000000000',
          '0x0000000000000000000000000000000000000000',
          0,
          dc.NFTGemFeeManager.address
        );
        await hre.ethers.provider.waitForTransaction(tx.hash, 1);

        // approve the wrappedgem contract
        console.log('approving wrapped governance token as operator...');
        tx = await dc.NFTGemMultiToken.setApprovalForAll(
          dc.NFTGemWrappedERC20Governance.address,
          true,
          {from: sender.address}
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
          (await this.get('NFTGemGovernor')).address,
          sender
        ),
        NFTGemMultiToken: await this.getContractAt(
          'NFTGemMultiToken',
          (await this.get('NFTGemMultiToken')).address,
          sender
        ),
        NFTGemPoolFactory: await this.getContractAt(
          'NFTGemPoolFactory',
          (await this.get('NFTGemPoolFactory')).address,
          sender
        ),
        NFTGemFeeManager: await this.getContractAt(
          'NFTGemFeeManager',
          (await this.get('NFTGemFeeManager')).address,
          sender
        ),
        ProposalFactory: await this.getContractAt(
          'ProposalFactory',
          (await this.get('ProposalFactory')).address,
          sender
        ),
        ERC20GemTokenFactory: await this.getContractAt(
          'ERC20GemTokenFactory',
          (await this.get('ERC20GemTokenFactory')).address,
          sender
        ),
        MockProxyRegistry: await this.getContractAt(
          'MockProxyRegistry',
          (await this.get('MockProxyRegistry')).address,
          sender
        ),
      };

      if (parseInt(networkId) === 1) {
        this.deployedContracts.SwapHelper = await this.getContractAt(
          'UniswapQueryHelper',
          (await this.get('UniswapQueryHelper')).address,
          sender
        );
      } else if (parseInt(networkId) === 250) {
        this.deployedContracts.SwapHelper = await this.getContractAt(
          'SushiSwapQueryHelper',
          (await this.get('SushiSwapQueryHelper')).address,
          sender
        );
      } else if (parseInt(networkId) === 43114) {
        this.deployedContracts.SwapHelper = await this.getContractAt(
          'PangolinQueryHelper',
          (await this.get('PangolinQueryHelper')).address,
          sender
        );
      } else if (parseInt(networkId) === 56) {
        this.deployedContracts.SwapHelper = await this.getContractAt(
          'PancakeSwapQueryHelper',
          (await this.get('PancakeSwapQueryHelper')).address,
          sender
        );
      } else {
        this.deployedContracts.SwapHelper = await this.getContractAt(
          'MockQueryHelper',
          (await this.get('MockQueryHelper')).address,
          sender
        );
      }
      return this.deployedContracts;
    }

    async getGemPoolAddress(sym: string) {
      return await (
        await this.getDeployedContracts()
      ).NFTGemPoolFactory.getNFTGemPool(
        keccak256(['bytes'], [pack(['string'], [sym])])
      );
    }

    async getGemTokenAddress(sym: string) {
      return await (
        await this.getDeployedContracts()
      ).ERC20GemTokenFactory.getItem(
        keccak256(['bytes'], [pack(['string'], [sym])])
      );
    }

    async getPoolContract(addr: string) {
      return await (await this.getDeployedContracts()).NFTComplexGemPool.attach(
        addr
      );
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
        created = false,
        nonce = this.BigNumber.from(0);
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
          {gasLimit: 5000000}
        );
        await hre.ethers.provider.waitForTransaction(tx.hash, 1);
        nonce = this.BigNumber.from(tx.nonce).add(1);
        poolAddr = await this.getGemPoolAddress(symbol);
        console.log(`address: ${poolAddr}`);

        // create the wrapped erc20 gem contract
        console.log(`Creating wrapped ${name} (${symbol}) token...`);
        tx = await dc.ERC20GemTokenFactory.createItem(
          `W${symbol}`,
          `Wrapped ${name}`,
          poolAddr,
          dc.NFTGemMultiToken.address,
          18,
          dc.NFTGemFeeManager.address,
          {gasLimit: 5000000, nonce}
        );
        await hre.ethers.provider.waitForTransaction(tx.hash, 1);
        nonce = nonce.add(1);
        const gtAddr = await this.getGemTokenAddress(`W${symbol}`);
        console.log(`address: ${gtAddr}`);

        created = true;
      }
      const pc = await this.getPoolContract(poolAddr);
      const reqlen = created ? 0 : await pc.allInputRequirementsLength();
      if (
        inputRequirements &&
        inputRequirements.length &&
        inputRequirements.length > 0 &&
        inputRequirements.length > reqlen
      ) {
        for (
          let ii = 0;
          ii < inputRequirements.length;
          ii++, nonce = nonce.add(1)
        ) {
          if (ii < reqlen) {
            console.log(`updating complex requirements to ${name} (${symbol})`);
            if (nonce.eq(0)) {
              tx = await pc.updateInputRequirement(
                ii,
                ...inputRequirements[ii]
              );
              nonce = this.BigNumber.from(tx.nonce);
            } else {
              tx = await pc.updateInputRequirement(
                ii,
                ...inputRequirements[ii],
                {
                  nonce,
                }
              );
            }
          } else {
            console.log(`adding complex requirements to ${name} (${symbol})`);
            if (nonce.eq(0)) {
              tx = await pc.addInputRequirement(...inputRequirements[ii]);
              nonce = this.BigNumber.from(tx.nonce);
            } else {
              tx = await pc.addInputRequirement(...inputRequirements[ii], {
                nonce,
              });
            }
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
