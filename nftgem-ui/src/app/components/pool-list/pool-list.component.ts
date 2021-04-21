import { ThisReceiver } from '@angular/compiler';
import { Component, Input } from '@angular/core';
import { isMainThread } from 'node:worker_threads';
import { BlockchainService } from '../../blockchain.service';
@Component({
  selector: 'app-pool-list',
  templateUrl: './pool-list.component.html',
  styleUrls: ['./pool-list.component.css']
})
export class PoolListComponent {

  @Input()
  limit: number;

  constructor(public blockchainService: BlockchainService) {
    this.limit = -1;
  }

}
