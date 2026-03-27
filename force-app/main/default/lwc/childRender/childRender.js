import { LightningElement, api } from 'lwc';

export default class ChildRender extends LightningElement {
    _value;

    @api
    get value() {
        return this._value;
    }

    set value(newValue) {
        console.log('Child received:', newValue);
        this._value = newValue;

        // 🔥 Trigger update back to parent -> causes loop
        this.dispatchEvent(
            new CustomEvent('valuechange', {
                detail: newValue + 1
            })
        );
    }
}