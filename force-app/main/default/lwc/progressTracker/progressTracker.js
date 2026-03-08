import { LightningElement, wire, track } from 'lwc';
import { getListRecordsByName } from 'lightning/uiListsApi';
import PROJECT_OBJECT from '@salesforce/schema/Project__c';
import updateProjectProgress from '@salesforce/apex/ProgressTrackerController.updateProjectProgress';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ProgressTracker extends LightningElement {

    @track projects = [];
    @track showUpdateModal = false;
    @track updateValue = 0;
    @track selectedProjectId = null;

    wiredProjects;

    @wire(getListRecordsByName, {
        objectApiName: PROJECT_OBJECT.objectApiName,
        listViewApiName: 'All',
        fields: ["Project__c.Id", "Project__c.Name", "Project__c.Start_Date__c", "Project__c.End_Date__c", "Project__c.Progress__c"],
        sortBy: ["Project__c.Name"]
    })
    refreshProjects(result) {
        this.wiredProjects = result;

        if (result.data) {
            this.processProjects();
        }else if(result.error){
            console.log(result.error);
        }
    }

    get projectList() {
        return this.wiredProjects.data?.records || [];
    }

    processProjects() {
        this.projects = this.projectList.map(project => {
            const progress = project.fields.Progress__c.value || 0;
            return {
                Id: project.id,
                Name: project.fields.Name.value,
                Progress__c: progress,
                startDate: project.fields.Start_Date__c.value ? new Date(project.fields.Start_Date__c.value).toDateString() : '',
                endDate: project.fields.End_Date__c.value ? new Date(project.fields.End_Date__c.value).toDateString() : '',
                progressStyle: `width:${progress}%; background-color:${this.getProgressColor(progress)};`
            };
        });
    }

    getProgressColor(progress) {
        if (progress >= 80) return '#4bca81';   // Green
        if (progress >= 60) return '#ffb75d';   // Orange
        if (progress >= 40) return '#ffd75d';   // Yellow
        return '#ff6b6b';                       // Red
    }

    updateProgress(event) {
        this.selectedProjectId = event.currentTarget.dataset.projectId;
        const project = this.projects.find(p => p.Id === this.selectedProjectId);
        this.updateValue = project.Progress__c;
        this.showUpdateModal = true;
    }

    handleUpdateChange(event) {
        this.updateValue = parseInt(event.target.value, 10);
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
            this.handleRefresh();
            this.showToast('Success', 'Progress updated successfully', 'success');
        })
        .catch(error => {
            this.showToast(
                'Error',
                error.body.message,
                'error'
            );
        });
    }

    async handleRefresh() {
        await refreshApex(this.wiredProjects);
        this.closeModal();
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