import { LightningElement } from 'lwc';

export default class ToggleComponent extends LightningElement {
    toggleState = false;

    get toggleClass() {
        return `toggle-switch ${this.toggleState ? 'active' : ''}`;
    }

    toggleSwitch() {
        this.toggleState = !this.toggleState;
    }
}