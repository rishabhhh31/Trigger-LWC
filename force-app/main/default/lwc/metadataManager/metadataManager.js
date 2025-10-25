import { LightningElement, track } from 'lwc';
import getOrgWideMetadataTypeNames from '@salesforce/apex/MetadataDeploymentHandler.getOrgWideMetadataTypeNames';
import listMetadata from '@salesforce/apex/MetadataDeploymentHandler.listMetadata';
import retrieveMetadataItem from '@salesforce/apex/MetadataDeploymentHandler.retrieveMetadataItem';
import getSalesforceAuthorizationOrgs from '@salesforce/apex/MetadataDeploymentHandler.getSalesforceAuthorizationOrgs';
import handleClientCredentialsFlow from '@salesforce/apex/AuthService.handleClientCredentialsFlow';
import getDeploymentStatus from '@salesforce/apex/CreateUpdateMetadataUtils.getDeploymentStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class MetadataManager extends LightningElement {
    // Selections
    selectedSource = '';
    selectedTarget = '';
    @track selectedMetadata = [];
    @track selectedMetadataTypes = {};
    @track fetchedFiles = [];

    // Options
    @track sourceOrgs = [];
    @track targetOrgs = [];
    @track metadataOptions = [];

    // UI state
    @track isLoading = false;
    @track columns = [
        { label: 'Full Name', fieldName: 'fullName', type: 'text' },
        { label: 'Type', fieldName: 'type', type: 'text' },
        { label: 'Created By', fieldName: 'createdByName', type: 'text' },
        { label: 'Last Modified By', fieldName: 'lastModifiedByName', type: 'text' },
    ];

    // Lifecycle
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

    get nextButtonAvailable() {
        return !(this.selectedSource && this.selectedTarget);
    }

    // UI Getters
    get isTargetOrgDisabled() {
        return !this.selectedSource;
    }

    get isMetadataTypeAvailable() {
        return this.metadataOptions.length > 0;
    }

    get shouldFetchMetadata() {
        return this.selectedMetadata.length < 1;
    }

    // Event Handlers
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

    // Toast
    showToast(title, message, variant = 'info') {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    // Metadata Fetching
    async handleNext() {
        await this.loadOrgMetadata(this.selectedSource);
    }

    // Metadata Fetching
    async handlePrevious() {
        this.metadataOptions = [];
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

    get isMetadataFilesAvailables() {
        return this.fetchedFiles.length > 0;
    }

    async pollDeploymentStatus(deploymentId, intervalMs = 5000) {
        while (true) {
            const status = await getDeploymentStatus({ deploymentId });
            if (status?.done) return status;
            await new Promise(res => setTimeout(res, intervalMs));
        }
    }

    async handleFetchMetadata() {
        try {
            this.fetchedFiles = await listMetadata({ metadataComponents: this.selectedMetadata, sourceOrg: this.selectedSource });
        } catch (error) {
            this.showToast('Error fetching metadata', error?.body?.message || error.message, 'error');
        }
    }

    get previousButtonAvailable() {
        return !(this.isMetadataTypeAvailable);
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
                await retrieveMetadataItem({ componentNamesMap: this.selectedMetadataTypes, sourceOrg: this.selectedSource, targetOrg: this.selectedTarget });
                this.showToast('Success', 'Metadata deployed successfully', 'success');
            } else {
                const result = await this.pollDeploymentStatus(tokenResponse);
                if (result.success) {
                    await retrieveMetadataItem({ componentNamesMap: this.selectedMetadataTypes, sourceOrg: this.selectedSource, targetOrg: this.selectedTarget });
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
}