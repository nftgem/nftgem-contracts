import {Injectable} from '@angular/core';
import Web3Modal from 'web3modal';

import {ToastrService} from 'ngx-toastr';

import {Contract, ethers} from 'ethers';
const {BigNumber, utils} = ethers;

import {NFTGemGovernor} from '../../types/NFTGemGovernor';
import {NFTGemMultiToken} from '../../types/NFTGemMultiToken';
import {NFTGemPoolFactory} from '../../types/NFTGemPoolFactory';

import swal from 'sweetalert2'

import * as iabis from '../../abis/abis.json'

import { CacheService } from './cache.service'

declare let confetti: any;

const pad = function (num: any, size: any) {
  let s = String(num);
  while (s.length < (size || 2)) {
    s = '0' + s;
  }
  return s;
};
@Injectable({
  providedIn: 'root',
})
export class BlockchainService {
  ethers: any;
  provider: any;
  accounts: any;
  account: any;
  signer: any;
  network: any;
  networkId: any;

  updateList: any;
  confettiOn: any;
  updatingNFTList: any;
  updatingBalances: any;
  providerOptions: any;
  contractData: any;

  public gemPools: any[];
  public gemPoolsByAddress: any;
  public balances: any;
  public nftItems: any;

  public claimsList: any;
  public gemsList: any;

  public governor: any;
  public factory: any;
  public token: any;
  public queryHelper: any;

  public lastGemMintedId: any;
  public lastClaimMintedId: any;
  public connected = false;

  public totalClaims = 0;
  public totalMinted = 0;
  public totalEthStaked = BigNumber.from(0);

  public isLoading = false;

  historicalEvents: any;

  web3Modal: any;

  maxUINT256: any;

  pepe: any

  mockMode = false;

  constructor(public toastr: ToastrService, private cache: CacheService) {
    this.governor = undefined;
    this.factory = undefined;
    this.token = undefined;

    this.createClaim = this.createClaim.bind(this);
    this.collectClaim = this.collectClaim.bind(this);
    this.connectAccount = this.connectAccount.bind(this);
    this.reloadAccount = this.reloadAccount.bind(this);
    this.resetApp = this.resetApp.bind(this);

    this.confettiOn = false;
    this.lastClaimMintedId = undefined;
    this.lastGemMintedId = undefined;

    this.updateList = [];
    this.claimsList = [];
    this.gemsList = [];
    this.gemPools = [];
    this.nftItems = [];

    this.balances = {
      governance: 0,
    };
  }

  get networkName(): string {
    const networks: any = {
      '1': 'Ethereum',
      '3': 'ropsten',
      '4': 'rinkeby',
      '5': 'goerli',
      '42': 'kovan',
      '56': 'Binance',
      '77': 'sokol',
      '97': 'bsc-testnet',
      '99': 'POA',
      '250': 'Opera',
      '1337': 'local',
      '4002': 'ftmtest',
      '43113': 'fuji',
      '43114': 'Avalanche',
    }
    return networks[`${this.networkId}`];
  }

  get COIN(): string {
    const networks: any = {
      '1': 'ETH',
      '3': 'rETH',
      '4': 'rETH',
      '5': 'kETH',
      '42': 'kETH',
      '56': 'BNB',
      '77': 'sPOS',
      '97': 'tBNB',
      '99': 'POA',
      '250': 'FTM',
      '1337': 'lETH',
      '4002': 'tFTM',
      '43113': 'tAVAX',
      '43114': 'AVAX',
    }
    return this.networkId ? networks[`${this.networkId}`] : 'ETH';
  }


  parseEther(n: any) {
    const pe = utils.parseEther(n ? n.toString() : '0');
    return pe ? pe.toString() : '0';
  }

  formatEther(n: any) {
    if (!n) return '0';
    const pe = utils.formatEther(n);
    return pe ? pe.toString() : '0';
  }

  async connectAccount():Promise<void> {
    if(!this.web3Modal)
      this.web3Modal = new Web3Modal({
        cacheProvider: false, // optional
        providerOptions: {},
        theme: {
          background: 'rgb(39, 49, 56)',
          main: 'rgb(199, 199, 199)',
          secondary: 'rgb(136, 136, 136)',
          border: 'rgba(195, 195, 195, 0.14)',
          hover: 'rgb(16, 26, 32)',
        }
      });

    this.resetApp();
    const p = await this.web3Modal.connect();
    if (p) {
      this.subscribeProvider(p);
      this.provider = new ethers.providers.Web3Provider(p);
      await window.ethereum.enable();
      await this.setupAccount();
    }
  }

  async reloadAccount():Promise<void> {
    if (this.web3Modal.cachedProvider) {
      const p = await this.web3Modal.connect();
      this.subscribeProvider(p);
      this.provider = new ethers.providers.Web3Provider(p);
      await this.setupAccount();
    }
  }

  async resetApp():Promise<void> {
    if (this.provider) {
      this.provider = null;
      await this.web3Modal.clearCachedProvider();
    }
  }

  subscribeProvider(provider: any): void {
    if (!provider.on) {
      return;
    }
    provider.on('close', async () => await this.resetApp());
    provider.on('accountsChanged', async (accounts: string[]) => {
      console.log('accountsChanged', accounts);
      await this.reloadAccount();
    });
    provider.on('chainChanged', async (chainId: number) => {
      console.log('chainChanged', chainId);
      await this.reloadAccount();
    });

    provider.on('networkChanged', async (networkId: number) => {
      console.log('networkChanged', networkId);
      await this.reloadAccount();
    });
  }

  async setupAccount(): Promise<void> {

    const invalidNetwork = () => {
      if (this.networkId !== 42) {
        swal.fire({
          title: 'Wrong Network',
          text:
            'Bitgems is not deployed on your selected network. Please select the Kovan network in Metamask and try again.',
          buttonsStyling: false,
          customClass: {
            confirmButton: 'btn btn-info retro-confirm',
          },
        });
      }
    }
    this.lastClaimMintedId = undefined;
    this.lastGemMintedId = undefined;

    this.updateList = [];
    this.claimsList = [];
    this.gemsList = [];
    this.gemPools = [];
    this.nftItems = [];

    this.totalMinted = 0;
    this.balances = {
      governance: 0,
    };
    this.totalClaims = 0;

    this.isLoading = true;
    this.ethers = new ethers.providers.Web3Provider(this.provider); // create ethers instance
    this.signer = this.provider.getSigner();
    this.account = await this.signer.getAddress();
    this.network = await this.provider.getNetwork();
    this.networkId = this.network.chainId;

    try {
      this.contractData = await import(
        `../../abis/${this.networkId}/bitgems.json`
      );
    } catch (e) {
      this.isLoading = false;
      return invalidNetwork();
    }

    this.confettiOn = false;

    this.balances = {
      governance: 0,
    };
    this.totalEthStaked = BigNumber.from(0);

    let queryHelperContract = '';
    if(this.networkId == 1) {
      queryHelperContract = 'UniswapQueryHelper'
    } else if(this.networkId == 43114) {
      queryHelperContract = 'PangolinQueryHelper'
    } else if(this.networkId == 56) {
      queryHelperContract = 'PancakeSwapQueryHelper'
    } else {
      queryHelperContract = 'MockQueryHelper'
      this.mockMode = true;
    }

    // the uniswap helper
    this.queryHelper = await this.getContractRef(
      queryHelperContract
    );

    // the primary bitgem multitoken
    this.token = (await this.getContractRef(
      'NFTGemMultiToken'
    )) as NFTGemMultiToken;

    // the bitgem pool factory
    this.factory = (await this.getContractRef(
      'NFTGemPoolFactory'
    )) as NFTGemPoolFactory;

    // governance
    this.governor = (await this.getContractRef(
      'NFTGemGovernor'
    )) as NFTGemGovernor;

    this.governor.on('GovernanceTokenIssued', (receiver: any, amount: any) => {
      if (receiver == this.account) {
        this.updateBalances();
        this.showToast(
          'Governance Token Received',
          `You just received a governance token`
        );
        this.confetti(2000);
        this.invokeUpdateList('GovernanceTokenIssued', {amount});
      }
    });


    this.connected = true;

    console.log('updating balance');
    await this.updateBalances();

    // load all gem pools from contracts
    this.gemPoolsByAddress = {};
    const allPoolsCount = await this.factory.allNFTGemPoolsLength();
    const tmpPools: any[] = [];
    this.gemPools = []; // CacheService.get(`pool_list_${this.networkId}`) || [];
    if(this.gemPools) {
      this.gemPools.forEach((e: any) => this.gemPoolsByAddress[e.address] = e);
    }
    console.log('getting pool list addresses');
    for(let i = 0;i < allPoolsCount; i++) {
      tmpPools.push((async (i:any) => {
        const address = await this.factory.allNFTGemPools(i)
        let res: any = {
          address,
          contract: new ethers.Contract(
            address,
            iabis.NFTGemPool,
            this.signer)
        }
        this.attachPoolEvents(res.contract);

        const o = await this.getPoolDetails(res);
        res = Object.assign(res, o);

        if(res.symbol === 'PEPE') {
          this.pepe = res;
          return;
        }

        if(this.gemPools.length > i && this.gemPools[i].address === address) {
          this.gemPools[i] = res;
          this.gemPoolsByAddress[address] = this.gemPools[i] ;
        } else {
          this.gemPools.push(res);
          this.gemPoolsByAddress[address] = res;
        }
        console.log(res);
      })(i));
    }
    await Promise.all(tmpPools);
    //CacheService.put(outCache, `pool_list_${this.networkId}`);

    console.log('updating gem list');
    const promisesList = [];
    const tokensHeldCount = await this.token.allHeldTokensLength(this.account);
    for (let ndx = 0; ndx < tokensHeldCount.toNumber(); ndx++) {
      promisesList.push((async (n:any) => {
        const tokenIndex = await this.token.allHeldTokens(this.account, n);
        const hashString = tokenIndex.toHexString();
        const b = await this.token.balanceOf(this.account, hashString);
        //console.log(tokenIndex, b.toString());
        if (hashString == '0x00') { return };
        let tokenType = 0, tokenPool;
        for(let i=0;i<this.gemPools.length;i++) {
          tokenType = await this.gemPools[i].contract.tokenType(hashString);
          if(tokenType !== 0) {
            tokenPool = this.gemPools[i];
            break;
          }
        }
        if(tokenType === 1 || tokenType === 2) {
          this.addTokenOfPool(tokenType, hashString, tokenPool.contract.address);
        } else {
          //console.log('not found', hashString);
        }
        // HERE get the token type and id
      })(ndx));
    }
    await Promise.all(promisesList);
    this.isLoading = false;
    this.invokeUpdateList('nftlist', this.nftItems);
  }

  async addTokenOfPool(tokenType: number, hashString: string, poolAddress: string): Promise<void> {
    const tokenPool = this.gemPoolsByAddress[poolAddress];
    const claimUnlockTime = await tokenPool.contract.claimUnlockTime(hashString);
    const claimAmount = await tokenPool.contract.claimAmount(hashString);
    const claimQuantity =  await tokenPool.contract.claimQuantity(hashString);
    const gemQuantity = await this.token.balanceOf(this.account, hashString);
    const claimTokenAmount = await tokenPool.contract.claimTokenAmount(hashString);
    const stakedToken = await tokenPool.contract.stakedToken(hashString);
    const tokenId = await tokenPool.contract.tokenId(hashString);
    const item = {
      type: tokenType,
      id: tokenId,
      hash: hashString,
      name: tokenPool.name,
      symbol: tokenPool.symbol,
      unlockTime: claimUnlockTime,
      amount: claimAmount,
      tokenAmount: claimTokenAmount,
      quantity: claimQuantity,
      gemQuantity: gemQuantity,
      token: stakedToken,
      pool: tokenPool
    };
    if(tokenType === 1)  {
      this.claimsList.push(item);
      //console.log('claim', this.claimsList[this.claimsList.length - 1]);
    }
    else if(tokenType === 2) {
      this.gemsList.push(item);
      //console.log('gem', this.gemsList[this.gemsList.length - 1]);
    }
  }

  async getPoolDetails(p: any): Promise<any> {
    if(!p.contract) {
      return;
    }
    if(!p.name) p.name = await p.contract.name();
    if(!p.symbol) p.symbol = await p.contract.symbol();
    p.ethPrice = await p.contract.ethPrice();
    if(!p.minTime) p.minTime = await p.contract.minTime();
    if(!p.maxTime) p.maxTime = await p.contract.maxTime();
    if(!p.difficultyStep) p.difficultyStep = await p.contract.difficultyStep();
    if(!p.claimedCount) {
      p.claimedCount = await p.contract.claimedCount();
      this.totalClaims = this.totalClaims +  p.claimedCount.toNumber();

    }
    if(!p.mintedCount) {
      p.mintedCount = await p.contract.mintedCount();
      this.totalMinted = this.totalMinted +  p.mintedCount.toNumber();
    }
    const poolTotalEth = await p.contract.totalStakedEth();
    p.totalEthStaked = poolTotalEth;
    this.totalEthStaked = this.totalEthStaked.add(poolTotalEth);
    // ret.maxClaims = await p.maxClaims();
    return p;
  }

  async getContractRef(contract: any, address?: any): Promise<any> {
    const tokenData = this.contractData.contracts[contract];
    if (tokenData) {
      return new ethers.Contract(address ? address : tokenData.address, tokenData.abi, this.signer);
    }
  }

  async updateBalances(): Promise<any> {
    this.balances.governance = await this.token.balanceOf(this.account, 0);
    this.invokeUpdateList('balances', this.balances);
  }

  makeCompact(s: string): string {
    const sLen = s.length;
    if (sLen <= 18) {
      return s;
    }
    return s.substring(0, 6) + '--' + s.substring(sLen - 6, sLen);
  }

  invokeUpdateList(tag: any, vals: any): void {
    this.updateList.forEach((el: any) => el(tag, vals));
  }

  addToUpdateList(el: any):void {
    if (this.updateList.push) {
      this.updateList.push(el);
    }
  }

  removeFromUpdateList(el: any): void {
    if (this.updateList.remove) {
      this.updateList.remove(el);
    }
  }

  async showToast(title: string, body: string): Promise<void> {
    //console.log(title, body);
    this.showSidebarMessage(body);
  }

  showSidebarMessage(message: string):void {
    this.toastr.show(
      ``,
      message,
      {
        timeOut: 4000,
        closeButton: true,
        enableHtml: true,
        toastClass: 'toast-info2 ngx-toastr',
        positionClass: 'toast-top-right',
      }
    );
  }

  attachPoolEvents(c: Contract): void {
    c.on(
      'NFTGemClaimCreated', (account: any, pool: any, claimHash: any, length: any, quantity: any, amountPaid: any) => {
        if (account == this.account) {
          this.nftItems.push(claimHash.toHexString());
          this.showToast(
            'Claim created',
            `You created a claim valued at ${parseFloat(this.formatEther(amountPaid)).toFixed(4)} ${this.COIN} to redeem on ${new Date(
              Date.now() + length * 1000
            ).toLocaleString()}`
          );
          this.invokeUpdateList('NFTGemClaimCreated', {
            account,
            pool,
            claimHash,
            length,
            amountPaid,
          });
          this.addTokenOfPool(1, claimHash.toHexString(), pool);
        }
        this.totalEthStaked = this.totalEthStaked.add(amountPaid);
        this.gemPoolsByAddress[pool].totalEthStaked = this.gemPoolsByAddress[pool].totalEthStaked.add(amountPaid);
        this.gemPoolsByAddress[pool].claimedCount = this.gemPoolsByAddress[pool].claimedCount.add(1);
        this.totalClaims = this.totalClaims + 1;
      }
    );
    c.on(
      'NFTGemERC20ClaimCreated',
      async (account: any, pool: any, claimHash: any, length: any, quantity: any, amountPaid: any) => {
        if (account == this.account) {
          this.nftItems.push(claimHash.toHexString());
          this.showToast(
            'Claim created',
            `You created a claim valued at ${this.formatEther(
              amountPaid
            ).toString()} to redeem on ${new Date(
              Date.now() + length * 1000
            ).toString()}`
          );
          this.invokeUpdateList('NFTGemERC20ClaimCreated', {
            account,
            pool,
            claimHash,
            length,
            amountPaid,
          });
          this.addTokenOfPool(1, claimHash.toHexString(), pool);
        }
        this.totalEthStaked = this.totalEthStaked.add(amountPaid);
        this.gemPoolsByAddress[pool].totalEthStaked = this.gemPoolsByAddress[pool].totalEthStaked.add(amountPaid);
        this.gemPoolsByAddress[pool].claimedCount = this.gemPoolsByAddress[pool].claimedCount.add(1);
        this.totalClaims = this.totalClaims + 1;
      }
    );
    c.on('NFTGemClaimRedeemed', (account: any, pool: any, claimHash: any, amountPaid: any) => {
        if (account == this.account) {
          this.nftItems = this.nftItems.filter((e:any) => e.hash !== claimHash);
          this.claimsList = this.claimsList.filter((e:any) => !claimHash.eq(e.hash));
          this.showToast(
            'Claim Redeemed',
            `You redeemed a claim valued at ${this.formatEther(
              amountPaid
            ).toString()}`
          );
          this.invokeUpdateList('NFTGemClaimRedeemed', {
            account,
            pool,
            claimHash,
            amountPaid,
          });
        }
        this.totalEthStaked = this.totalEthStaked.sub(amountPaid);
        this.gemPoolsByAddress[pool].totalEthStaked = this.gemPoolsByAddress[pool].totalEthStaked.sub(amountPaid);
        this.gemPoolsByAddress[pool].claimedCount = this.gemPoolsByAddress[pool].claimedCount.sub(1);
        this.totalClaims = this.totalClaims - 1;
      }
    );
    c.on('NFTGemCreated', async (account: any, pool: any, claimHash: any, gemHash: any, gemCount: any) => {
        if (account == this.account) {
          this.nftItems.push(gemHash.toHexString());
          this.showToast(`${this.gemPoolsByAddress[pool].name} Received`, `You received a newly-minted ${this.gemPoolsByAddress[pool].name}!`);
          this.invokeUpdateList('NFTGemCreated', {
            account,
            pool,
            claimHash,
            gemHash,
          });
          this.confetti(5000);
        }
        this.totalMinted = this.totalMinted + 1;
        this.gemPoolsByAddress[pool].mintedCount = this.gemPoolsByAddress[pool].mintedCount.add(1);
        this.gemPoolsByAddress[pool].ethPrice = this.gemPoolsByAddress[pool].ethPrice.add(
          this.gemPoolsByAddress[pool].ethPrice.div(this.gemPoolsByAddress[pool].difficultyStep)
        );
      }
    );
  }

  async createClaim(pool: any, length: any, price?: any): Promise<any> {
    const bnLength = BigNumber.from(length);
    const ethPrice = BigNumber.from(price) || pool.ethPrice;
    const myPrice = ethPrice.mul(pool.minTime).div(bnLength);
    if (bnLength.gt(pool.maxTime) || myPrice.gt(ethPrice)) {
      return;
    }
    return pool.contract.createClaim(bnLength, {value: ethPrice.toHexString() });
  }

  async createERC20Claims(pool: any, token: string, price: any, amount: any): Promise<any> {
    return await pool.contract.createERC20Claims(token, price, amount);
  }

  async createClaims(pool: any, qty:number, length: any, price?: any): Promise<any> {
    const bnLength = BigNumber.from(length);
    const ethPrice = BigNumber.from(price) || pool.ethPrice;
    const myPrice = ethPrice.mul(pool.minTime).div(bnLength);
    if (bnLength.gt(pool.maxTime) || myPrice.gt(ethPrice)) {
      return;
    }
    return pool.contract.createClaims(bnLength, qty, {value: ethPrice.mul(qty).toHexString() });
  }

  async approve20(contract: any, owner: any, spender: any, amount: any): Promise<any> {
    return contract.approve(owner, spender, amount);
  }

  async approve1155(owner: any, spender: any): Promise<any> {
    const c = await new Contract(this.token.address, iabis.IERC1155, this.signer);
    return c.setApprovalForAll(owner, spender, true);
  }

  async isApproved1155(owner: any, spender: any): Promise<any> {
    const c = await new Contract(this.token.address, iabis.IERC1155, this.signer);
    return c.isApprovedForAll(owner, spender);
  }

  async allowance20(contract: any, owner: any, spender: any): Promise<any> {
    return contract.allowance(owner, spender);
  }

  async collectClaim(pool: any, claimId: any): Promise<any> {
    return pool.contract.collectClaim(claimId);
  }

  public gems = [
    {
      address: '0xD14781B2e59F594A53aB360FeaACACf32184C280',
      name: 'ruby'
    },
    {
      address: '0x812D3E21bb9Cd18518FB70764b70B89Fd583B81c',
      name: 'opal'
    },
    {
      address: '0xe3f91f3289D3D5B105aF6183d6dBCfAA11cb7928',
      name: 'emerald'
    },
    {
      address: '0x5A3a17Fe585561341bAfF5C6b574844c20Fb987F',
      name: 'sapphire'
    },
    {
      address: '0x2767f7b33A14d96B53e194D19c8d827FcFCA1b78',
      name: 'diamond'
    },
    {
      address: '0xEa60902f3c60819Fe644AD4B72e22d9c00Dc1aAA',
      name: 'jade'
    },
    {
      address: '0x7b801494B65F5eeC79E7807bd771b7F981713928',
      name: 'topaz'
    },
    {
      address: '0x5256EF83a3Aaf3bd1300fC1c9BFf5629e2170d00',
      name: 'pearl'
    }
  ];

  async convertGemsToERC20(address: any, quantity: number): Promise<any> {
    const c = await new Contract(address, iabis.IERC20, this.signer);
    return await c.wrap(quantity.toString());
  }

  async convertGemsFromERC20(address: any, quantity: number): Promise<any> {
    const c = await new Contract(address, iabis.IERC20, this.signer);
    return await c.unwrap(quantity.toString());
  }


  gemPic(symbol:string): string {
    if(symbol=='DMND') return 'white2.png';
    else if (symbol=='RUBY') return 'red2.png';
    else if (symbol=='MRLD') return 'greengem2.png';
    else if (symbol=='SPHR') return 'blue2.png';
    else if (symbol=='JADE') return 'dkgreengem2.png';
    else if (symbol=='TPAZ') return 'orange2.png';
    else if (symbol=='OPAL') return 'opal.png';
    else if (symbol=='PERL') return 'pearl.png';
    else if (symbol=='CHRY') return 'cherry.png';
    else if (symbol=='BERY') return 'strawberry.png';
    else if (symbol=='PEPE') return 'pepe.png';
    else return 'white2.png';
  }

  confetti(time: number): void {
    if (this.confettiOn) {
      return;
    }
    this.confettiOn = true;
    confetti.start();
    setTimeout(() => {
      confetti.stop();
      this.confettiOn = false;
    }, time);
  }

  async getGemERC20Contract(address:string):Promise<Contract> {
    return new ethers.Contract(
      address,
      iabis.IERC20WrappedGem);
  }

  async getTinyERC20(address:string):Promise<Contract> {
    return new ethers.Contract(
      address,
      [
        {
          anonymous: false,
          inputs: [
            {
              indexed: true,
              name: 'owner',
              type: 'address',
            },
            {
              indexed: true,
              name: 'spender',
              type: 'address',
            },
            {
              indexed: false,
              name: 'value',
              type: 'uint256',
            },
          ],
          name: 'Approval',
          type: 'event',
        },
        {
          inputs: [
            {
              name: 'spender',
              type: 'address',
            },
            {
              name: 'amount',
              type: 'uint256',
            },
          ],
          name: 'approve',
          outputs: [
            {
              name: '',
              type: 'bool',
            },
          ],
          stateMutability: 'nonpayable',
          type: 'function',
        },
        {
          inputs: [
            {
              name: 'account',
              type: 'address',
            },
          ],
          name: 'balanceOf',
          outputs: [
            {
              name: '',
              type: 'uint256',
            },
          ],
          stateMutability: 'view',
          type: 'function',
        },
        {
          inputs: [],
          name: 'decimals',
          outputs: [
            {
              name: '',
              type: 'uint8',
            },
          ],
          stateMutability: 'view',
          type: 'function',
        },
        {
          inputs: [
            {
              name: 'owner',
              type: 'address',
            },
            {
              name: 'spender',
              type: 'address',
            },
          ],
          name: 'allowance',
          outputs: [
            {
              name: '',
              type: 'uint256',
            },
          ],
          stateMutability: 'view',
          type: 'function',
        },
      ],
      this.signer
    );
  }

//   async getUniswapPrice


// const uniswapUsdcAddress = "0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc";
// const uniswapAbi =

// const getUniswapContract = async address => await new ethers.Contract(address, uniswapAbi, provider);

// const getEthUsdPrice = async () => await getUniswapContract(uniswapUsdcAddress)
//     .then(contract => contract.getReserves())
//     .then(reserves => Number(reserves._reserve0) / Number(reserves._reserve1) * 1e12); // times 10^12 because usdc only has 6 decimals



}
