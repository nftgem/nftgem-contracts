import {Component, AfterViewInit} from '@angular/core';
import {BlockchainService} from '../..//blockchain.service';

@Component({
  selector: 'app-web3-connect-button',
  templateUrl: './web3-connect-button.component.html',
  styleUrls: ['./web3-connect-button.component.css']
})
export class Web3ConnectButtonComponent implements AfterViewInit {

  constructor(private blockchainService: BlockchainService) {}

  ngAfterViewInit(): void {
    this.blockchainService.reloadAccount();
  }

  connectWallet(): void {
    this.blockchainService.connectAccount();
  }

  get connected(): boolean {
    return this.blockchainService.account !== undefined;
  }

  get connectedAccount(): string | undefined {
    return this.blockchainService.account !== undefined
      ? this.blockchainService.account.substring(0, 4) +
          '...' +
          this.blockchainService.account.substring(
            this.blockchainService.account.length - 2,
            this.blockchainService.account.length
          )
      : undefined;
  }

  get buttonCaption(): string | undefined {
    return this.connected ? `${this.blockchainService.networkName}-${this.connectedAccount}` : 'connect';
  }

  get buttonColor(): string {
    return this.connected ? 'var(--bs-teal)' : 'var(--bs-red)';
  }
}
