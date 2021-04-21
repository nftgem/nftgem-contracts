import { Component, OnInit } from '@angular/core';
import { BlockchainService } from 'src/app/blockchain.service';

@Component({
  selector: 'app-home',
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.css']
})
export class HomeComponent implements OnInit {

  poolIndex = 0;

  constructor(public blockchainService: BlockchainService) { }

  ngOnInit(): void {
  }

}
