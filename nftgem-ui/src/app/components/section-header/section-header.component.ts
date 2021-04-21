import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-section-header',
  templateUrl: './section-header.component.html',
  styleUrls: ['./section-header.component.css']
})
export class SectionHeaderComponent {

  @Input()
  title: string;

  @Input()
  image: string;

  @Input()
  imageWidth: string;

  constructor() {
    this.title = '';
    this.image = '';
    this.imageWidth = '';
  }

}
