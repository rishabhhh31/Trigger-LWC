import { LightningElement, track } from 'lwc';
import startBulkInsert from '@salesforce/apex/BulkInsertService.startBulkInsert';
import checkJobStatus from '@salesforce/apex/BulkInsertService.checkJobStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BulkUploader extends LightningElement {

    @track jobId;
    @track jobStatus;

    handleInsert() {
        startBulkInsert()
            .then(result => {
                this.jobId = result;
                this.showToast('Success', 'Job Created: ' + result, 'success');
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    handleStatus() {
        checkJobStatus({ jobId: this.jobId })
            .then(result => {
                this.jobStatus = result;
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}