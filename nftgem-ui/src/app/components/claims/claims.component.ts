import { Component, Input } from '@angular/core';
import { BigNumber } from 'ethers';
import { BlockchainService } from 'src/app/blockchain.service';

@Component({
  selector: 'app-claims',
  templateUrl: './claims.component.html',
  styleUrls: ['./claims.component.css']
})
export class ClaimsComponent {

  constructor(private blockchainService: BlockchainService) { }

}
