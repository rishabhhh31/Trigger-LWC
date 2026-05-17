import { LightningElement } from 'lwc';

export default class ButtonGroup extends LightningElement {
    lastAction = 'None';

    handleAction1() {
        this.lastAction = 'Action 1 performed';
    }

    handleAction2() {
        this.lastAction = 'Action 2 performed';
    }

    handleAction3() {
        this.lastAction = 'Action 3 performed';
    }
}