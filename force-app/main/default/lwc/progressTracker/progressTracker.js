import { LightningElement, wire, track } from 'lwc';
import { getListRecordsByName } from 'lightning/uiListsApi';
import PROJECT_OBJECT from '@salesforce/schema/Project__c';
import updateProjectProgress from '@salesforce/apex/ProgressTrackerController.updateProjectProgress';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const FIELDS = [
    'Project__c.Id',
    'Project__c.Name',
    'Project__c.Start_Date__c',
    'Project__c.End_Date__c',
    'Project__c.Progress__c'
];

export default class ProgressTracker extends LightningElement {

    @track projects = [];
    showUpdateModal = false;
    updateValue = 0;
    selectedProjectId;

    wiredResult;

    @wire(getListRecordsByName, {
        objectApiName: PROJECT_OBJECT.objectApiName,
        listViewApiName: 'All',
        fields: FIELDS,
        sortBy: ['Project__c.Start_Date__c']
    })
    wiredProjects(result) {

        this.wiredResult = result;

        if (result.data) {
            this.projects = this.transformProjects(result.data.records);
        }

        if (result.error) {
            console.error(result.error);
        }

    }

    transformProjects(records) {

        return records.map(record => {

            const fields = record.fields;
            const progress = fields.Progress__c?.value ?? 0;

            return {
                Id: record.id,
                Name: fields.Name?.value,
                Progress__c: progress,
                startDate: this.formatDate(fields.Start_Date__c?.value),
                endDate: this.formatDate(fields.End_Date__c?.value),
                progressStyle: `width:${progress}%; background-color:${this.getProgressColor(progress)}`
            };

        });

    }

    formatDate(date) {
        return date
            ? new Intl.DateTimeFormat('en-US').format(new Date(date))
            : '';
    }

    getProgressColor(progress) {

        if (progress >= 95) return '#2e844a';   // Dark Green (Almost Complete)
        if (progress >= 85) return '#4bca81';   // Green
        if (progress >= 70) return '#7fd3a5';   // Light Green
        if (progress >= 55) return '#ffb75d';   // Orange
        if (progress >= 40) return '#ffd75d';   // Yellow
        if (progress >= 25) return '#ff9a3c';   // Dark Orange
        if (progress >= 10) return '#ff7b7b';   // Light Red

        return '#d64545'; // Dark Red (Very Low Progress)

    }

    updateProgress(event) {

        this.selectedProjectId = event.currentTarget.dataset.projectId;

        const project = this.projects.find(p => p.Id === this.selectedProjectId);

        this.updateValue = project?.Progress__c ?? 0;

        this.showUpdateModal = true;

    }

    handleUpdateChange(event) {
        this.updateValue = Number(event.target.value);
    }

    closeModal() {
        this.showUpdateModal = false;
        this.selectedProjectId = null;
        this.updateValue = 0;
    }

    saveProgress() {

        if (this.updateValue < 0 || this.updateValue > 100) {
            this.showToast('Error', 'Progress must be between 0 and 100', 'error');
            return;
        }

        updateProjectProgress({
            projectId: this.selectedProjectId,
            progress: this.updateValue
        })
        .then(() => {

            this.showToast('Success', 'Progress updated successfully', 'success');

            return refreshApex(this.wiredResult);

        })
        .then(() => {

            this.closeModal();

        })
        .catch(error => {

            const message =
                error?.body?.message ||
                error?.body?.[0]?.message ||
                'Unknown error';

            this.showToast('Error', message, 'error');

        });

    }

    showToast(title, message, variant) {

        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );

    }

}