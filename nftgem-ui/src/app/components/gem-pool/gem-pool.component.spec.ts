import { ComponentFixture, TestBed } from '@angular/core/testing';

import { GemPoolComponent } from './gem-pool.component';

describe('GemPoolComponent', () => {
  let component: GemPoolComponent;
  let fixture: ComponentFixture<GemPoolComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ GemPoolComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(GemPoolComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
