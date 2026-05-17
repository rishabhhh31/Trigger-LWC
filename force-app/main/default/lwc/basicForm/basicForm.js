import { LightningElement } from 'lwc';

export default class BasicForm extends LightningElement {
    userName = '';
    userEmail = '';
    showResult = false;

    handleNameChange(event) {
        this.userName = event.target.value;
        this.hideResult();
    }
    
    handleEmailChange(event) {
        this.userEmail = event.target.value;
        this.hideResult();
    }

    handleSubmit() {
        this.showResult = true;
    }

    hideResult(){
        this.showResult = false;
    }
}