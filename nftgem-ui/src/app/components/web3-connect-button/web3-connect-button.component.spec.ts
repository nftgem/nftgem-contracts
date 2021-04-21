import { ComponentFixture, TestBed } from '@angular/core/testing';

import { Web3ConnectButtonComponent } from './web3-connect-button.component';

describe('Web3ConnectButtonComponent', () => {
  let component: Web3ConnectButtonComponent;
  let fixture: ComponentFixture<Web3ConnectButtonComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ Web3ConnectButtonComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(Web3ConnectButtonComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
