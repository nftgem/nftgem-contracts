import { Component, OnInit } from '@angular/core';
import { BlockchainService } from 'src/app/blockchain.service';

@Component({
  selector: 'app-staking-pools',
  templateUrl: './staking-pools.component.html',
  styleUrls: ['./staking-pools.component.css']
})
export class StakingPoolsComponent implements OnInit {

  constructor(private blockchainService: BlockchainService) { }

  ngOnInit(): void {
  }

}
