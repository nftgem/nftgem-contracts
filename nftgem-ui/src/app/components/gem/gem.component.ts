import { Component, Input } from '@angular/core';
import { BigNumber } from 'ethers';
import { BlockchainService } from 'src/app/blockchain.service';

@Component({
  selector: 'app-gem',
  templateUrl: './gem.component.html',
  styleUrls: ['./gem.component.css']
})
export class GemComponent {

  _gem: any;
  @Input() set gem(p : any) {
    this._gem = p;
    this._gem.pool.contract
      .claimUnlockTime(this._gem.id)
      .then((t: BigNumber) => (this._unlockTime = t.toNumber()));
    this._gem.pool.contract
      .claimAmount(this._gem.hash)
      .then((t: BigNumber) => (this._claimAmount = t));
  }

  _unlockTime: any;
  _claimAmount: any;

  constructor(public blockchainService: BlockchainService) { }

  makeCompact(s: string): string {
    return this.blockchainService.makeCompact(s);
  }

  get name(): string | undefined{
    return this._gem ? this._gem.name : undefined;
  }

  get gemId(): number{
    return this._gem ? this._gem.id : undefined;
  }

  get quantity(): number{
    return this._gem ? this._gem.gemQuantity : undefined;
  }

  get hashValue(): string | undefined{
    return this._gem ? this.makeCompact(this._gem.hash) : '';
  }

  get symbol(): string {
    return this._gem.symbol ;
  }

  get unlockTime(): number {
    return this._unlockTime ? this._unlockTime.div('86400').toNumber() : 0;
  }

  get claimAmount(): string {
    return this.blockchainService.formatEther(this._claimAmount);
  }

}
