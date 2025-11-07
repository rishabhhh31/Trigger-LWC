import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getSupportedObjectOptions from '@salesforce/apex/DynamicRecordCreation.getSupportedObjectOptions';

export default class AccountCreator extends NavigationMixin(LightningElement) {
    // Stores list of available SObjects for record creation
    availableObjects = [];

    // Currently selected object API name
    selectedObjectApiName;

    // Controls record form visibility
    showRecordForm = false;

    // Controls loading spinner visibility
    isLoading = false;

    // Fetch the object list when the component is initialized
    connectedCallback() {
        this.loadSupportedObjects();
    }

    /**
     * Fetches a list of supported objects from Apex
     */
    async loadSupportedObjects() {
        try {
            this.isLoading = true; // show spinner
            this.availableObjects = await getSupportedObjectOptions(); // call Apex method
        } catch (error) {
            this.showToast('Error', 'Failed to load supported objects.', 'error');
            console.error('Error fetching object list:', error);
        } finally {
            this.isLoading = false; // hide spinner
        }
    }

    /**
     * Handles combobox value change event
     * Resets and re-renders the record form for the selected object
     */
    handleObjectSelection(event) {
        this.showRecordForm = false; // hide form before re-render
        this.selectedObjectApiName = event.detail.value; // update selected object

        // Slight delay ensures form resets properly
        setTimeout(() => {
            this.showRecordForm = true;
        }, 0);
    }

    /**
     * Handles success event from lightning-record-form
     * Displays a success toast and navigates to the newly created record page
     */
    handleRecordSuccess(event) {
        const { id: recordId } = event.detail;

        // Show success toast
        this.showToast('Success', `${this.selectedObjectApiName} created successfully!`, 'success');

        // Navigate to the newly created record page
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: this.selectedObjectApiName,
                actionName: 'view'
            }
        });
    }

    /**
     * Handles error events from the lightning-record-form
     * Extracts a readable message and displays it as a toast
     */
    handleRecordError(event) {
        const errorMessage = this.extractErrorMessage(event.detail);
        this.showToast('Error', errorMessage, 'error');
    }

    /**
     * Extracts meaningful error messages from Salesforce error objects
     */
    extractErrorMessage(error) {
        try {
            // Handle field-level validation errors
            const fieldErrors = error?.output?.fieldErrors;
            if (fieldErrors && Object.keys(fieldErrors).length > 0) {
                const messages = Object.values(fieldErrors)
                    .flat()
                    .map(e => e.message)
                    .filter(Boolean);
                if (messages.length > 0) return messages.join(', ');
            }

            // Handle general validation or DML errors
            const generalErrors = error?.output?.errors;
            if (generalErrors && generalErrors.length > 0) {
                const messages = generalErrors.map(e => e.message).filter(Boolean);
                if (messages.length > 0) return messages.join(', ');
            }

            // Fallback to top-level message
            if (error?.message) return error.message;

            // Generic fallback
            return 'An unknown error occurred.';
        } catch (parseError) {
            console.error('Error parsing error object:', parseError);
            return 'An error occurred while processing the error.';
        }
    }

    /**
     * Utility method to show toast notifications
     */
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
                mode: 'dismissable'
            })
        );
    }
}