import { LightningElement, track, wire, api } from 'lwc';
import createLead from '@salesforce/apex/LeadModalController.createLead';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues, getObjectInfo } from "lightning/uiObjectInfoApi";
import LEAD_OBJECT from "@salesforce/schema/Lead";
import LEAD_SOURCE from "@salesforce/schema/Lead.LeadSource";
export default class LeadModal extends LightningElement {
    @api showModal = false;
    @track formData = {};
    leadRecordTypeId;
    leadSourceOptions = [];

    @wire(getObjectInfo, { objectApiName: LEAD_OBJECT })
    leadObjectResult({ error, data }) {
        if (data) {
            this.leadRecordTypeId = data.defaultRecordTypeId;
        } else if (error) {
            console.log(error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: "$leadRecordTypeId", fieldApiName: LEAD_SOURCE })
    picklistResults({ error, data }) {
        if (data) {
            this.leadSourceOptions = data.values;
        } else if (error) {
            console.log(error);
        }
    }

    handleInputChange(event) {
        const { name, value } = event.target;
        this.formData[name] = value;
    }

    showAddModal() {
        this.showModal = true;
        this.resetForm();
    }

    closeModal() {
        this.showModal = false;
        this.resetForm();
        this.dispatchEvent(new CustomEvent('close'));
    }

    resetForm() {
        this.formData = {};
        this.template.querySelectorAll('lightning-input, lightning-combobox').forEach(input => {
            input.value = '';
        });
    }

    validateForm() {
        const allValid = [
            ...this.template.querySelectorAll('lightning-input, lightning-combobox'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        return allValid;
    }

    saveLead() {
        if (!this.validateForm()) {
            return;
        }
        createLead({ leadData: this.formData })
            .then(() => {
                this.showToast('Success', 'Lead created successfully', 'success');
                this.closeModal();
                this.dispatchEvent(new CustomEvent('leadcreated'));
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }
}