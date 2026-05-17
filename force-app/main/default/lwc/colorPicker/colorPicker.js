import { LightningElement } from 'lwc';

export default class ColorPicker extends LightningElement {
    selectedColor = 'None';

    colors = [
        { name: 'Red', style: 'background-color: red;' },
        { name: 'Blue', style: 'background-color: blue;' },
        { name: 'Green', style: 'background-color: green;' }
    ];

    selectColor(event) {
        this.selectedColor = event.currentTarget.dataset.color;
    }
}