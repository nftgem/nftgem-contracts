import { ComponentFixture, TestBed } from '@angular/core/testing';

import { GemClaimComponent } from './gem-claim.component';

describe('GemClaimComponent', () => {
  let component: GemClaimComponent;
  let fixture: ComponentFixture<GemClaimComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ GemClaimComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(GemClaimComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
