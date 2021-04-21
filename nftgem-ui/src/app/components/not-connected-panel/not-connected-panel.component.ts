import { Component, OnInit } from '@angular/core';
import { BlockchainService } from 'src/app/blockchain.service';

@Component({
  selector: 'app-not-connected-panel',
  templateUrl: './not-connected-panel.component.html',
  styleUrls: ['./not-connected-panel.component.css']
})
export class NotConnectedPanelComponent implements OnInit {

  constructor(public blockchainService: BlockchainService) { }

  ngOnInit(): void {
  }

}
