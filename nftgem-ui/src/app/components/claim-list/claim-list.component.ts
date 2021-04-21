import { Component } from '@angular/core';
import { BlockchainService } from 'src/app/blockchain.service';

@Component({
  selector: 'app-claim-list',
  templateUrl: './claim-list.component.html',
  styleUrls: ['./claim-list.component.css']
})
export class ClaimListComponent {

  constructor(public blockchainService: BlockchainService) { }

  get hasClaims(): boolean {
    return this.blockchainService.claimsList && this.blockchainService.claimsList.length
      ? this.blockchainService.claimsList.length > 0
      : false;
  }

}
