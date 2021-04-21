import { Component, Input } from '@angular/core';
import { BigNumber } from 'ethers';
import { formatEther } from 'ethers/lib/utils';
import { BlockchainService } from 'src/app/blockchain.service';
import swal from 'sweetalert2';

@Component({
  selector: 'app-gem-claim',
  templateUrl: './gem-claim.component.html',
  styleUrls: ['./gem-claim.component.css']
})
export class GemClaimComponent {

  constructor(public blockchainService: BlockchainService) { }

  _mintedCount: any;
  _claimQuantity: any;
  _claim: any;
  _pool: any;
  @Input() set claim(p : any) {
    this._claim = p;
    this._pool = p.pool;
    this._claim.pool.contract
      .claimUnlockTime(this._claim.hash)
      .then((t: BigNumber) => (this.unlockTime = t.toNumber()));
    this._claim.pool.contract
      .claimAmount(this._claim.hash)
      .then((t: BigNumber) => (this._claimAmount = t));
    this.blockchainService.token
      .balanceOf(this.blockchainService.account, this._claim.hash)
      .then((t: BigNumber) => (this._mintedCount = t.toNumber()));
      this._claim.pool.contract
      .claimQuantity(this._claim.hash)
      .then((t: BigNumber) => (this._claimQuantity = t.toNumber()));


  }
  get claim(): any {
    return this._claim;
  }

  unlockTime: any;
  _claimAmount: any;

  handleCollectClaimClick(): void {
    if(!this._claim) {
      return;
    }

    const collectClaim = () => {
      this.blockchainService
      .collectClaim(this._claim.pool, this._claim.hash)
      .then(() => {
        this.blockchainService.showToast('collecting claim', `Submitted a transaction to collect claim`);
      });
    }

    if(this.isMature) {
      collectClaim();
    } else {
      swal.fire({
        title: 'Immature Claim!',
        text: 'You are about to collect on an immature claim, and will not receive a claim if you proceed. Do you wish you not receive a gem and collect your claim principal?',
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#3085d6',
        cancelButtonColor: '#d33',
        confirmButtonText: 'Yes, I want to collect!'
      }).then((result) => {
        if (result.isConfirmed) {
          collectClaim();
        }
      })
    }
  }

  makeCompact(s: string): string {
    return this.blockchainService.makeCompact(s);
  }

  makeColor(color1: string, color2: string, ratio: number): string {
    color1 = color1.substring(1, color1.length);
    color2 = color2.substring(1, color2.length);
    const hex = function(x:any) {
        x = x.toString(16);
        return (x.length == 1) ? '0' + x : x;
    };
    let r = Math.ceil(parseInt(color1.substring(0,2), 16) * ratio + parseInt(color2.substring(0,2), 16) * (1-ratio)  );
    let g = Math.ceil(parseInt(color1.substring(2,4), 16) * ratio + parseInt(color2.substring(2,4), 16) * (1-ratio) );
    let b = Math.ceil(parseInt(color1.substring(4,6), 16) * ratio + parseInt(color2.substring(4,6), 16) * (1-ratio) );

    r = r > 10 ? r - 20 : r;
    g = g > 10 ? g - 20 : g;
    b = b > 10 ? b - 20 : b;

    return '#' + hex(r) + hex(g) + hex(b);
  }

  get name(): string | undefined{
    return this._claim ? this._claim.name : undefined;
  }

  get gemId(): number{
    return this._claim ? this._claim.id : undefined;
  }

  get hashValue(): string | undefined{
    return this.makeCompact(this._claim.hash);
  }

  get claimAmount(): string | undefined{
    return this._claimAmount ? this.blockchainService.formatEther(this._claimAmount) : undefined;
  }

  get claimQuantity(): string | undefined{
    return this._claimQuantity
  }

  get claimColor(): string {
    const target = new Date((this.unlockTime * 1000)).getTime();
    const nowd = new Date().getTime();

    let claimDuration = parseFloat(formatEther(this._pool.ethPrice))
      * parseFloat(this._pool.minTime.toString())
      / parseFloat(formatEther(this._claim.amount.toString()))

    if(claimDuration === 0) {
      claimDuration = 0.001
    } else if (claimDuration === 1)  {
      claimDuration = 0.999
    }

    const lent = claimDuration / parseFloat(this._pool.maxTime.toString());
    return this.makeColor('#ff0000', '#00ff00', lent);
  }

  get symbol(): string {
    return this._claim.symbol;
  }

  get maturityDate(): string | undefined {
    return this._claim && this.unlockTime && this.unlockTime !== 0
      ? new Date((this.unlockTime * 1000)).toLocaleDateString()
      : undefined;
  }

  get maturityTime(): string | undefined {
    return this._claim && this.unlockTime && this.unlockTime !== 0
      ? new Date((this.unlockTime * 1000)).toLocaleTimeString()
      : undefined;
  }

  get isMature(): boolean {
    if(this._claim && this.unlockTime && this.unlockTime !== 0) {
      return ~~((Date.now() as number) / 1000) > this.claim.unlockTime;
    }  else return false;
  }

  get mintedCount(): string {
    return this._mintedCount;
  }

  get gemPic(): string {
    if(this.symbol=='DMND') return 'diamond.png';
    else if (this.symbol=='RUBY') return 'ruby.png';
    else if (this.symbol=='MRLD') return 'emerald.png';
    else if (this.symbol=='SPHR') return 'sapphire.png';
    else if (this.symbol=='JADE') return 'greengem2.png';
    else return 'diamond.png';
  }

}
