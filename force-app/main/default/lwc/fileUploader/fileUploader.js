import { LightningElement, api, track } from 'lwc';
import getContentDistributionData from '@salesforce/apex/ContentVersionTriggerHandler.getContentDistribution';

export default class FileUploader extends LightningElement {

    // Record ID of the parent record
    @api recordId;

    // Stores distribution info returned from Apex
    @track contentDistributions;

    // Stores the name of the uploaded file
    uploadedFileName;

    // Restrict allowed file formats
    get acceptedFormats() {
        return ['.pdf', '.jpg', '.png'];
    }

    /**
     * Called when a file upload finishes
     */
    async handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;

        // Extract uploaded file details
        const { contentVersionId, name: fileName } = uploadedFiles[0];
        this.uploadedFileName = fileName;

        // Call Apex to fetch public URL, password, and expiry
        const response = await getContentDistributionData({ contentVersionId });
        this.contentDistributions = response;
    }

    /**
     * Copies password to clipboard
     */
    copyPassword(event) {
        const passwordValue = event.target.dataset.password;
        navigator.clipboard.writeText(passwordValue);
    }
}