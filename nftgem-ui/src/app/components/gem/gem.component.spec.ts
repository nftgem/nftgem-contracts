import { ComponentFixture, TestBed } from '@angular/core/testing';

import { GemComponent } from './gem.component';

describe('GemComponent', () => {
  let component: GemComponent;
  let fixture: ComponentFixture<GemComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ GemComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(GemComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
