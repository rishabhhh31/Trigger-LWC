import { LightningElement, track } from 'lwc';
import getOrgWideMetadataTypeNames from '@salesforce/apex/MetadataDeploymentHandler.getOrgWideMetadataTypeNames';
import listMetadata from '@salesforce/apex/MetadataDeploymentHandler.listMetadata';
import retrieveMetadataItem from '@salesforce/apex/MetadataDeploymentHandler.retrieveMetadataItem';
import getSalesforceAuthorizationOrgs from '@salesforce/apex/MetadataDeploymentHandler.getSalesforceAuthorizationOrgs';
import handleClientCredentialsFlow from '@salesforce/apex/AuthService.handleClientCredentialsFlow';
import getDeploymentStatus from '@salesforce/apex/CreateUpdateMetadataUtils.getDeploymentStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class MetadataManager extends LightningElement {
    @track currentStep = 1;

    selectedSource = '';
    selectedTarget = '';
    @track selectedMetadata = [];
    @track selectedMetadataTypes = {};
    @track fetchedFiles = [];
    @track sourceOrgs = [];
    @track targetOrgs = [];
    @track metadataOptions = [];
    @track isLoading = false;

    columns = [
        { label: 'Full Name', fieldName: 'fullName', type: 'text' },
        { label: 'Type', fieldName: 'type', type: 'text' },
        { label: 'Created By', fieldName: 'createdByName', type: 'text' },
        { label: 'Last Modified By', fieldName: 'lastModifiedByName', type: 'text' },
    ];

    connectedCallback() {
        this.loadOrgs();
    }

    async loadOrgs() {
        try {
            const response = await getSalesforceAuthorizationOrgs();
            this.sourceOrgs = response;
            this.targetOrgs = response;
        } catch (error) {
            this.showToast('Error loading orgs', error?.body?.message || error.message, 'error');
        }
    }

    // Step Navigation
    async handleNext() {
        if (this.currentStep === 1) {
            if (this.selectedSource && this.selectedTarget) {
                await this.loadOrgMetadata(this.selectedSource);
                this.currentStep = 2;
            } else {
                this.showToast('Error', 'Please select both Source and Target Orgs', 'error');
            }
        } else if (this.currentStep === 2) {
            if (this.selectedMetadata.length > 0) {
                this.currentStep = 3;
            } else {
                this.showToast('Error', 'Please select at least one Metadata Type', 'error');
            }
        }
    }

    handlePrevious() {
        if (this.currentStep > 1) {
            this.currentStep--;
        }
    }

    get isNextDisabled() {
        if (this.currentStep === 1) {
            return !(this.selectedSource && this.selectedTarget);
        } else if (this.currentStep === 2) {
            return this.selectedMetadata.length < 1;
        }
        return true;
    }

    get isPreviousDisabled() {
        return this.currentStep === 1;
    }

    // Computed Booleans for Template
    get isStep1() {
        return this.currentStep === 1;
    }
    get isStep2() {
        return this.currentStep === 2;
    }
    get isStep3() {
        return this.currentStep === 3;
    }

    get isTargetOrgDisabled() {
        return !this.selectedSource;
    }

    get shouldFetchMetadata() {
        return this.selectedMetadata.length < 1;
    }

    get isMetadataFilesAvailable() {
        return this.fetchedFiles.length > 0;
    }

    handleOrgChange(event) {
        const { name, value } = event.target;
        if (name === 'source') {
            this.selectedSource = value;
            this.selectedTarget = null;
            this.filterTargetOrg();
        } else if (name === 'target') {
            this.selectedTarget = value;
        }
    }

    filterTargetOrg() {
        this.targetOrgs = this.sourceOrgs.filter(org => org.value !== this.selectedSource);
    }

    handleMetadataChange(event) {
        this.selectedMetadata = event.detail.value;
    }

    handleRowSelection(event) {
        const typeMap = {};
        event.detail.selectedRows.forEach(row => {
            if (!typeMap[row.type]) typeMap[row.type] = [];
            typeMap[row.type].push(row.fullName);
        });
        this.selectedMetadataTypes = typeMap;
    }

    showToast(title, message, variant = 'info') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    async loadOrgMetadata(metadataId) {
        try {
            this.isLoading = true;
            const tokenResponse = await handleClientCredentialsFlow({ metadataId });

            if (tokenResponse === 'Expired') {
                this.showToast('Token Expired', 'Please refresh the token', 'warning');
                return;
            }

            if (tokenResponse === 'Valid') {
                this.metadataOptions = await getOrgWideMetadataTypeNames({ sourceOrg: metadataId });
            } else {
                const result = await this.pollDeploymentStatus(tokenResponse);
                if (result.success) {
                    this.metadataOptions = await getOrgWideMetadataTypeNames({ sourceOrg: metadataId });
                } else {
                    this.showToast('Error', 'Deployment failed', 'error');
                }
            }
        } catch (error) {
            this.showToast('Error', error?.body?.message || error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleFetchMetadata() {
        try {
            this.isLoading = true;
            this.fetchedFiles = await listMetadata({
                metadataComponents: this.selectedMetadata,
                sourceOrg: this.selectedSource
            });
            console.log(JSON.stringify(this.fetchedFiles));

            console.log('fetyched')
            if (this.fetchedFiles.length > 0) {
                console.log('console')
                this.handleNext();
            }
        } catch (error) {
            this.showToast('Error fetching metadata', error?.body?.message || error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    get isFileSelectedForDeployment() {
        return !(this.selectedMetadataTypes && Object.keys(this.selectedMetadataTypes).length > 0);
    }

    async deployMetadata() {
        try {
            this.isLoading = true;
            const tokenResponse = await handleClientCredentialsFlow({ metadataId: this.selectedTarget });

            if (tokenResponse === 'Expired') {
                this.showToast('Token Expired', 'Cannot deploy, token expired', 'warning');
                return;
            }

            if (tokenResponse === 'Valid') {
                let jobId = await retrieveMetadataItem({
                    componentNamesMap: this.selectedMetadataTypes,
                    sourceOrg: this.selectedSource,
                    targetOrg: this.selectedTarget
                });
                this.showToast('Success', 'Metadata deployed successfully', 'success');
            } else {
                const result = await this.pollDeploymentStatus(tokenResponse);
                if (result.success) {
                    let jobId = await retrieveMetadataItem({
                        componentNamesMap: this.selectedMetadataTypes,
                        sourceOrg: this.selectedSource,
                        targetOrg: this.selectedTarget
                    });
                    this.showToast('Success', 'Metadata deployed successfully', 'success');
                } else {
                    this.showToast('Deployment Failed', 'Deployment job failed', 'error');
                }
            }
        } catch (error) {
            this.showToast('Deployment Error', error?.body?.message || error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async pollDeploymentStatus(deploymentId, intervalMs = 5000) {
        while (true) {
            const status = await getDeploymentStatus({ deploymentId });
            if (status?.done) return status;
            await new Promise(res => setTimeout(res, intervalMs));
        }
    }
}