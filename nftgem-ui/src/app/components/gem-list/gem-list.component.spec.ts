import { ComponentFixture, TestBed } from '@angular/core/testing';

import { GemListComponent } from './gem-list.component';

describe('GemListComponent', () => {
  let component: GemListComponent;
  let fixture: ComponentFixture<GemListComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ GemListComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(GemListComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
