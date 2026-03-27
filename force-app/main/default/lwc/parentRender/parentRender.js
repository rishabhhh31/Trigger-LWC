import { LightningElement, track } from 'lwc';

export default class ParentRender extends LightningElement {
    @track value = 0;

    handleValueChange(event) {
        const newValue = event.detail;

        // ✅ Guard: prevent redundant updates
        if (this.value !== newValue) {
            console.log('Parent updating:', newValue);
            this.value = newValue;
        }
    }
}