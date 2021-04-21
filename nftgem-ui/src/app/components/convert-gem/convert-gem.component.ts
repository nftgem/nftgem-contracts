import { Component, Input } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { formatEther } from 'ethers/lib/utils';
import { BlockchainService } from 'src/app/blockchain.service';

@Component({
  selector: 'app-convert-gem',
  templateUrl: './convert-gem.component.html',
  styleUrls: ['./convert-gem.component.css']
})
export class ConvertGemComponent {

  @Input()
  type: 'wrap' | 'unwrap';

  convertGemForm: FormGroup;
  approvederc1155 = false;
  approvederc20 = false;
  erc20contract: any;

  _selectedAddress = '';
  quantity = 0;
  erc20balance: any;
  allowance: any;

  get selectedAddress(): string {
    return this._selectedAddress;
  }
  set selectedAddress(s: string) {
    this._selectedAddress = s;
    if(!s || !this.blockchainService || this.blockchainService.isLoading) return;

    this.blockchainService.isApproved1155(this.blockchainService.account, this.selectedAddress)
    .then((approved:boolean) => this.approvederc1155 = approved);

    this.blockchainService.getGemERC20Contract(this.selectedAddress)
    .then(erc20contract => {
      this.erc20contract = erc20contract;
      return this.erc20contract.balanceOf(this.blockchainService.account);
    })
    .then((bal: any) => {
      this.erc20balance = bal
      return this.erc20contract.allowance(this.blockchainService.account, this.selectedAddress)
    })
    .then((all: any) => {
      this.allowance = all
      this.erc20contract.on('Approval', (owner: any, spender: any, amount: any) => {
        if(this.blockchainService.account === owner && spender === this.selectedAddress) {
          this.blockchainService.showSidebarMessage(`Approved`);
          this.approvederc20 = true;
        }
      })
      this.erc20contract.on('Wrap', (owner: any, amount: any) => {
        if(this.blockchainService.account === owner) {
          this.blockchainService.showSidebarMessage(`Succesfully wrapped ${amount} gems`);
          this.erc20contract.balanceOf(this.blockchainService.account).then((b:any) => this.erc20balance = b);
          this.approvederc20 = true;
        }
      })
      this.erc20contract.on('Unwrap', (owner: any, amount: any) => {
        if(this.blockchainService.account === owner) {
          this.blockchainService.showSidebarMessage(`Succesfully unwrapped ${amount} gems`);
          this.erc20contract.balanceOf(this.blockchainService.account).then((b:any) => this.erc20balance = b);
          this.approvederc20 = true;
        }
      })
      this.blockchainService.token.on('ApprovalForAll', (account: any, operator: any, approval: any) => {
        if(this.blockchainService.account === account && operator === this.selectedAddress && approval === true) {
          this.blockchainService.showSidebarMessage(`Approved`);
          this.approvederc1155 = true;
        }
      })
    })
  }

  gems: any[];

  text2 = 'into ERC20';

  constructor(private formBuilder: FormBuilder,
    public blockchainService: BlockchainService) {

    this.convertGemForm = formBuilder.group({
      quantity: [Validators.pattern('[0-9\\.]*')]
    });

    this.gems = this.blockchainService.gems;

    this.type = 'wrap';
  }

  get intoText(): string {
    if(!this.erc20balance) return '';
    const bal = parseFloat(formatEther(this.erc20balance)).toFixed(4);
    const balString = bal !== '' ? `(${bal})` : '';
    return this.type === 'wrap' ? `into ERC20 ${balString}` : 'ERC20 into native Gems';
  }

  get actionEnabled(): boolean {
    return this.selectedAddress !== '' && this.quantity != 0;
  }

  get buttonCaption(): string {
    return (this.approvederc20 && this.type === 'unwrap')
    || (this.approvederc1155 && this.type === 'wrap')
    ? ( this.type === 'wrap' ? 'Wrap' : 'Unwrap' )
    : 'Approve'
  }

  onConvertButtonClicked(): void {
    if(this.type === 'wrap') {
      if(!this.approvederc1155) return this.blockchainService.token.setApprovalForAll(this.selectedAddress, true);
      else {
        this.approvederc1155 = true;
        this.blockchainService.convertGemsToERC20(
          this.selectedAddress,
          this.quantity
        );
      }
    } else {
      if(!this.approvederc20) return  this.erc20contract.approve(this.selectedAddress, this.erc20balance);
      this.blockchainService.convertGemsFromERC20(
        this.selectedAddress,
        this.quantity
      );
    }
  }

}
