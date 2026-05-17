import { LightningElement } from 'lwc';

export default class SimpleCounter extends LightningElement {
    count = 0;

    increase() {
        this.count++;
    }

    decrease() {
        this.count--;
    }
}