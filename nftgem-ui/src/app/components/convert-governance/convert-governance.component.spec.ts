import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ConvertGovernanceComponent } from './convert-governance.component';

describe('ConvertGovernanceComponent', () => {
  let component: ConvertGovernanceComponent;
  let fixture: ComponentFixture<ConvertGovernanceComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ ConvertGovernanceComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(ConvertGovernanceComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
