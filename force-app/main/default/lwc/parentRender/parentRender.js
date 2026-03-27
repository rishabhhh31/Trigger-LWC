import { LightningElement, track } from 'lwc';

export default class ParentRender extends LightningElement {
    @track value = 0;

    handleValueChange(event) {
        console.log('Parent received:', event.detail);
        this.value = event.detail; // updates child again
    }
}