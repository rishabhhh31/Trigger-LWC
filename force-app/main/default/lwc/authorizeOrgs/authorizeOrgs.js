import { LightningElement, track } from 'lwc';
import updateAndDeployMetadata from '@salesforce/apex/CreateUpdateMetadataUtils.updateAndDeployMetadata';
import getDeploymentStatus from '@salesforce/apex/CreateUpdateMetadataUtils.getDeploymentStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AuthorizeOrgs extends LightningElement {
    isLoading = false;
    @track formData = {
        Label: '',
        Base_URL__c: '',
        Client_ID__c: '',
        Client_Secret__c: ''
    };

    // Handles all input changes dynamically
    handleChange(event) {
        const { name, value } = event.target;
        this.formData[name] = value;
    }

    // Reusable toast
    showToast({ title = '', message = '', variant = 'info', mode = 'dismissable' }) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant, mode }));
    }

    // Submit handler
    async handleSubmit() {
        // Validate all fields
        const allValid = [...this.template.querySelectorAll('lightning-input')].reduce(
            (validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            },
            true
        );

        if (!allValid) {
            this.showToast({
                title: 'Validation Error',
                message: 'Please fill all required fields correctly.',
                variant: 'warning'
            });
            return;
        }

        this.isLoading = true;

        try {
            // Call Apex to deploy metadata
            const jobId = await updateAndDeployMetadata({ metadataFields: this.formData, isUpdate: false });

            if (jobId) {
                // Poll deployment status every 5 seconds
                const result = await this.pollDeploymentStatus(jobId, 5000);

                if (result.success) {
                    this.showToast({
                        title: 'Success!',
                        message: 'Deployment completed successfully.',
                        variant: 'success'
                    });
                } else {
                    this.showToast({
                        title: 'Deployment Failed',
                        message: `Status: ${result.status}. Please check the deployment details.`,
                        variant: 'error'
                    });
                }

                // Clear form fields after successful attempt
                this.resetForm();
            }
        } catch (error) {
            this.showToast({
                title: 'Error!',
                message: error?.body?.message || error.message || 'An unexpected error occurred.',
                variant: 'error'
            });
        } finally {
            this.isLoading = false;
        }
    }

    // Poll deployment status until done
    async pollDeploymentStatus(deploymentId, intervalMs) {
        while (true) {
            const status = await getDeploymentStatus({ deploymentId });

            if (status?.done) {
                return status;
            }

            await new Promise((resolve) => setTimeout(resolve, intervalMs));
        }
    }

    // Reset form after submission
    resetForm() {
        this.formData = {
            Label: '',
            Base_URL__c: '',
            Client_ID__c: '',
            Client_Secret__c: ''
        };

        this.template.querySelectorAll('lightning-input').forEach((inputCmp) => {
            inputCmp.value = null;
        });
    }
}