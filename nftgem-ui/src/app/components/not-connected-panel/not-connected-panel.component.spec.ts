import { ComponentFixture, TestBed } from '@angular/core/testing';

import { NotConnectedPanelComponent } from './not-connected-panel.component';

describe('NotConnectedPanelComponent', () => {
  let component: NotConnectedPanelComponent;
  let fixture: ComponentFixture<NotConnectedPanelComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ NotConnectedPanelComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(NotConnectedPanelComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
