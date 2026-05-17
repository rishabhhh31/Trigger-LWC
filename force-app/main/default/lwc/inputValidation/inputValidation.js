import { LightningElement } from 'lwc';

export default class InputValidation extends LightningElement {
    email = '';
    showError = false;
    errorMessage = '';

    validateEmail(event) {
        this.email = event.target.value;

        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

        if (!emailRegex.test(this.email)) {
            this.showError = true;
            this.errorMessage = 'Please enter a valid email address';
        } else {
            this.showError = false;
            this.errorMessage = '';
        }
    }
}