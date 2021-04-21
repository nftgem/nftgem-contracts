import { ComponentFixture, TestBed } from '@angular/core/testing';

import { StakingPoolsComponent } from './staking-pools.component';

describe('StakingPoolsComponent', () => {
  let component: StakingPoolsComponent;
  let fixture: ComponentFixture<StakingPoolsComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ StakingPoolsComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(StakingPoolsComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
