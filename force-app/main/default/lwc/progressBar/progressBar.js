import { LightningElement } from 'lwc';

export default class ProgressBar extends LightningElement {
    progress = 0;

    get progressStyle() {
        return `width: ${this.progress}%`;
    }

    increaseProgress() {
        if (this.progress < 100) {
            this.progress += 10;
        }
    }
}