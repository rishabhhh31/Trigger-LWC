import { LightningElement, api } from 'lwc';

export default class ChildRender extends LightningElement {
    _value;
    isInternalUpdate = false; // ✅ key flag

    @api
    get value() {
        return this._value;
    }

    set value(newValue) {
        // ✅ Ignore if same value
        if (this._value === newValue) {
            return;
        }

        console.log('Child received:', newValue);
        this._value = newValue;

        // ✅ Prevent loop: only emit if NOT internal update
        if (!this.isInternalUpdate) {
            this.isInternalUpdate = true;

            // simulate auto update logic
            const updatedValue = newValue + 1;

            this.dispatchEvent(
                new CustomEvent('valuechange', {
                    detail: updatedValue
                })
            );

            // reset flag after microtask
            Promise.resolve().then(() => {
                this.isInternalUpdate = false;
            });
        }
    }
}