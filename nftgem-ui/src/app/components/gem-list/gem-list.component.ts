import { Component, OnInit } from '@angular/core';
import { BlockchainService } from 'src/app/blockchain.service';

@Component({
  selector: 'app-gem-list',
  templateUrl: './gem-list.component.html',
  styleUrls: ['./gem-list.component.css']
})
export class GemListComponent implements OnInit {

  constructor(public blockchainService: BlockchainService) { }

  ngOnInit(): void {
  }

}
