import { Component, OnInit, Input } from '@angular/core';
import {Observable, OperatorFunction} from 'rxjs';
import {debounceTime, map} from 'rxjs/operators';
import { BlockchainService } from 'src/app/blockchain.service';
import {FormBuilder, FormGroup, Validators} from '@angular/forms';
import {BigNumberish, ethers} from 'ethers';
const {BigNumber} = ethers;

import tokenList from './tokens';

// import {
//   trigger,
//   state,
//   style,
//   animate,
//   transition,
// } from '@angular/animations';


@Component({
  selector: 'app-gem-pool',
  templateUrl: './gem-pool.component.html',
  styleUrls: ['./gem-pool.component.css']
})
export class GemPoolComponent implements OnInit {

  @Input() set pool(p : any) {
    this._pool = p;
    this.poolForm.patchValue({
      length: p.minTime.toNumber() / 86400.0,
      token: '',
      price: this.blockchainService.formatEther(
        p.ethPrice.toString()
      ),
      quantity: 1
    });
    this.valid = true;
  }
  get pool(): any {
    return this._pool || {};
  }

  allowed: any;
  timerRef: any;
  state: any;
  _pool: any;
  token: any;
  valid = false;
  showTokenInput = false;
  tokenButtonText = '';
  tokenConversionRate = 1;
  _tokenData: any;
  _badTokenSymbol = '';
  needsApproval = false;
  tokenContract: any;

  public poolForm: FormGroup;

  constructor(
    private formBuilder: FormBuilder,
    public blockchainService: BlockchainService,
  ) {
    this.state = 0;
    this.poolForm = this.formBuilder.group({
      length: [Validators.required, Validators.pattern('[0-9\\.]*')],
      price: [Validators.required, Validators.pattern('[0-9\\.]*')],
      quantity: [Validators.required, Validators.pattern('[0-9]*')],
      token: [Validators.required, Validators.pattern('[a-zA-Z0-9]*')]
    });
    this.tokenButtonText = blockchainService.COIN
  }

  get minDays(): any {
    return this.pool.minTime / 86400.0
  }

  get maxDays(): any {
    return this.pool.maxTime / 86400.0
  }


  search: OperatorFunction<string, readonly any[]> = (text$: Observable<string>) =>
  text$.pipe(
    debounceTime(200),
    map(term => {
      return term === '' ? []
      : tokenList.tokens.filter((v:any) => {
        return v.name.indexOf(term.toLowerCase()) > -1 ||
        v.symbol.indexOf(term.toLowerCase()) > -1
      }).slice(0, 20)
    })
  )

  formatter = (x: {name: string}): string => x.name;


  ngOnInit(): void {
    this.inputLengthChange = this.inputLengthChange.bind(this);
    this.handleActionClick = this.handleActionClick.bind(this);
    this.allowed = false;
  }

  get claimPrice(): string {
    return this._pool.ethPrice
      ? this.blockchainService.formatEther(
          this._pool.ethPrice
            .toString()
            .mul(this._pool.minTime)
            .div(this.poolForm.controls.length)
            .toString()
        )
      : '0';
  }

  get maxPrice(): string {
    return this._pool.ethPrice
      ? this.blockchainService.formatEther(this._pool.ethPrice.toString())
      : '0';
  }

  get minTime(): string {
    return this._pool.minTime;
  }

  get difficulty(): string {
    return this._pool.difficultyStep ? this.blockchainService.formatEther(this._pool.ethPrice.div(this._pool.difficultyStep).toString()) : '';
  }

  get maxTimeDays(): number {
    return this._pool.maxTime ? this._pool.maxTime.div('86400').toNumber() : undefined;
  }

  get minTimeDays(): number {
    return this._pool.minTime ? this._pool.minTime.div('86400').toNumber() : undefined;
  }

  get claimedCount(): string {
    return this._pool.claimedCount ? this._pool.claimedCount.toString() : '';
  }
  get mintedCount(): string {
    return this._pool.mintedCount ? this._pool.mintedCount.toString() : '';
  }

  get minPrice(): string {
    return this._pool.ethPrice &&
      this._pool.maxTime &&
      !this._pool.maxTime.eq(0)
      ? this.blockchainService.formatEther(
          this._pool.ethPrice
            .mul(this._pool.minTime)
            .div(this._pool.maxTime)
            .toString()
        )
      : '0';
  }

  handleActionClick(): void {
    this.state = 1;
    if(this.needsApproval) {
      return this.tokenContract
        .balanceOf(this.blockchainService.account)
        .then((b:any) => {
          if(b.eq(0)) b = this._pool.ethPrice.mul(100);
          return this.tokenContract.approve(this._pool.address, b);
        });
    }
    if(this._tokenData) {
      this.blockchainService
        .createERC20Claims(
          this._pool,
          this._tokenData.address,
          this.blockchainService.parseEther(
            this.poolForm.controls.price.value * this.poolForm.controls.quantity.value
          ),
          this.poolForm.controls.quantity.value
        )
        .then(() => {
          this.blockchainService.showToast('craeting new claim', `Submitted a transaction to create a new claim`);
        });
    } else {
      const claimTimeInSeconds = this.poolForm.controls.length.value * 86400.0;
      const ethCostWithTime = this._pool.ethPrice
        .mul(this._pool.minTime)
        .div(BigNumber.from(claimTimeInSeconds));
      this.blockchainService
        .createClaims(
          this._pool,
          this.poolForm.controls.quantity.value,
          claimTimeInSeconds,
          ethCostWithTime
        )
        .then(() => {
          this.blockchainService.showToast('craeting new claim', `Submitted a transaction to create a new claim`);
        });
    }
  }

  inputLengthChange(event:any): void {
    this.valid = false;
    if(isNaN(event.target.value)) {
      return;
    }
    const slen : number = parseFloat(event.target.value) * 86400.0;
    if(slen === 0) {
      return;
    }
    if(this._pool.minTime.lte(slen) && this._pool.maxTime.gte(slen)) {
      const ep = parseFloat(this.formatEth(this._pool.ethPrice));
      const price =
        ep
        * this._pool.minTime
        / slen
      if(price > ep || price < (ep / this._pool.maxTime.toNumber())) {
        event.stopPropagation();
        return;
      }
      this.poolForm.patchValue({price});
      this.valid = true;
    }
  }

  inputPriceChange(event:any): void {
    this.valid = false;
    if(isNaN(event.target.value)) {
      return;
    }
    const amt: number = event.target.value;
    if(amt === 0 || isNaN(amt)) {
      return;
    }
    const ep = parseFloat(this.formatEth(this._pool.ethPrice));
    let length : number =
      this._pool.minTime.toNumber()
      * ep
      / amt

    if(length < this._pool.minTime.toNumber() || length > this._pool.maxTime.toNumber()) {
      event.stopPropagation();
      return;
    }
    length = length / 86400.0;
    this.poolForm.patchValue({ length });
    this.valid = true;
  }

  tokenSelected(event:any) {
    this.tokenData = event.item;
    this.showTokenInput = false;
    this.tokenButtonText = this.tokenData.symbol;
  }

  resetComponentState() {
    this._tokenData = undefined;
    this.tokenConversionRate = 1;
    this.showTokenInput = false;
    this.tokenButtonText = this.blockchainService.COIN;
    this.needsApproval = false;

    this.poolForm.patchValue({
      length: this._pool.minTime.toNumber() / 86400.0,
      token: '',
      price: this.blockchainService.formatEther(
        this._pool.ethPrice.toString()
      ),
      quantity: 1
    });

  }

  tokenInputClicked():void {
    if(this.blockchainService.networkId == 56 || this.blockchainService.networkId == 43114) {
      alert('token staking within 24 hours');
      return;
    }
    if(this._tokenData) {
      this.resetComponentState();
    } else this.showTokenInput = !this.showTokenInput;
  }

  get tokenData(): any {
    return this._tokenData;
  }
  set tokenData(v:any) {
    this._tokenData = v;
    if(!this.blockchainService.queryHelper) return;
    if(!v) {
      this.resetComponentState();
      return;
    }
    this.blockchainService.queryHelper.coinQuote(this._tokenData.address, this._pool.ethPrice)
      .then((res:any) => {
        const { ethReserve, tokenReserve, ethereum } = res;
        const poolEthPrice = parseFloat(this.blockchainService.formatEther(this._pool.ethPrice));
        const tokenEthQuote = parseFloat(this.blockchainService.formatEther(ethereum));
        this.tokenConversionRate = poolEthPrice / tokenEthQuote;
        const tokenConvertedAmt = poolEthPrice * this.tokenConversionRate;
        this.poolForm.patchValue({ price: tokenConvertedAmt });
        return this.blockchainService.getTinyERC20(this._tokenData.address);
      })
      .then((res:any) => {
        this.tokenContract = res;
        if(!this.blockchainService.mockMode) {
          this.tokenContract.on('Approval', (owner:string, spender:string) => {
            if(owner === this.blockchainService.account && spender === this._pool.address) {
              this.needsApproval = false;
            }
          });
          return res.allowance(this.blockchainService.account, this._pool.address);
        } else {
          return Promise.resolve(BigNumber.from(this.blockchainService.parseEther('99999')))
        }
      })
      .then((res:any) => {
        if(res.lt(this._pool.ethPrice)) {
          this.needsApproval = true;
        }
      })
      .catch(() => {
        this.showTokenInput = false;
        this.tokenConversionRate = 1;
        this.tokenButtonText = this.blockchainService.COIN;
        this.badTokenSymbol = this._tokenData.symbol;
        this._tokenData = undefined;
        this.poolForm.patchValue({ token: ''});
      });
  }

  get badTokenSymbol(): string {
    return this._badTokenSymbol;
  }

  set badTokenSymbol(v: string) {
    this._badTokenSymbol = v;
    setTimeout(() => this._badTokenSymbol = '', 3000);
  }

  get symbol(): string {
    return this._pool ? this._pool.symbol : '';
  }

  get name(): string {
    return this._pool ? this._pool.name : '';
  }

  get priceColor(): string {
    return this.valid ? 'var(--bs-teal)' : 'var(--bs-red)';
  }

  get dayTerm(): string {
    return parseInt( this.poolForm.controls.length.value) > 1 ? 'days' : 'day';
  }

  formatEth(e:any):any {
    return this.blockchainService.formatEther(e);
  }
}
