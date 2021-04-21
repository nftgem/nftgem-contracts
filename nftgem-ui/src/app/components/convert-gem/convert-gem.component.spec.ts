import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ConvertGemComponent } from './convert-gem.component';

describe('ConvertGemComponent', () => {
  let component: ConvertGemComponent;
  let fixture: ComponentFixture<ConvertGemComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ ConvertGemComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(ConvertGemComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
