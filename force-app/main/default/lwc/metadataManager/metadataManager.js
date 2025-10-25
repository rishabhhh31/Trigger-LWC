import { LightningElement, track } from 'lwc';
import getOrgWideMetadataTypeNames from '@salesforce/apex/MetadataDeploymentHandler.getOrgWideMetadataTypeNames';
import listMetadata from '@salesforce/apex/MetadataDeploymentHandler.listMetadata';
import retrieveMetadataItem from '@salesforce/apex/MetadataDeploymentHandler.retrieveMetadataItem';
import getSalesforceAuthorizationOrgs from '@salesforce/apex/MetadataDeploymentHandler.getSalesforceAuthorizationOrgs';
import handleClientCredentialsFlow from '@salesforce/apex/AuthService.handleClientCredentialsFlow';
import getDeploymentStatus from '@salesforce/apex/CreateUpdateMetadataUtils.getDeploymentStatus';

export default class MetadataManager extends LightningElement {
    @track label = '';
    @track apiName = '';
    @track environment = '';
    @track selectedMetadata = [];
    @track fetchedFiles = [];

    selectedTarget = '';
    selectedSource = '';
    @track sourceOrgs = [];
    @track targetOrgs = [];

    selectedMetadataTypes = {};

    columns = [
        { label: 'Full Name', fieldName: 'fullName', type: 'text' },
        { label: 'Type', fieldName: 'type', type: 'text' },
        { label: 'Created By', fieldName: 'createdByName', type: 'text' },
        { label: 'Last Modified By', fieldName: 'lastModifiedByName', type: 'text' },
    ];

    metadataOptions = [];

    handleOrgChange(event) {
        let { name } = event.target;
        if (name === 'source') {
            this.selectedSource = event.target.value;
            console.log(this.selectedSource);

            this.filterTargetOrg();
        } else if (name === 'target') {
            this.selectedTarget = event.target.value;
        }
    }

    filterTargetOrg() {
        this.targetOrgs = this.sourceOrgs.filter(org => org.value !== this.selectedSource);
    }

    get isTargetOrgDisabled() {
        return this.selectedSource == '';
    }

    connectedCallback() {
        this.loadMetadata();
    }

    async loadMetadata() {
        let response = await getSalesforceAuthorizationOrgs();
        this.sourceOrgs = response;
        this.targetOrgs = response;
    }

    handleNext() {
        this.getOrgMetadata();
    }

    async getOrgMetadata() {
        try {
            let tokenResponse = await handleClientCredentialsFlow({ metadataId: this.selectedSource });
            console.log(tokenResponse);
            if (tokenResponse == 'Expired') {
                console.log('Token Expired');
                return;
            }
            if (tokenResponse == 'Valid') {
                this.metadataOptions = await getOrgWideMetadataTypeNames({ sourceOrg: this.selectedSource });
            } else {
                const result = await this.pollDeploymentStatus(tokenResponse, 5000);
                console.log(result);
                if (result.success) {
                    this.metadataOptions = await getOrgWideMetadataTypeNames({ sourceOrg: this.selectedSource });
                    console.log(this.metadataOptions);
                } else {
                    console.log('Deployment Failed');
                }
            }
        } catch (error) {
            console.error('getOrgMetadata', error);
        }
    }

    get isMetadataTypeAvailable() {
        return this.metadataOptions.length > 0;
    }

    handleMetadataChange(event) {
        console.log(event.detail.value);
        this.selectedMetadata = event.detail.value;
    }

    handleRowSelection(event) {
        let selectedRows = event.detail.selectedRows;
        const typeMap = {};
        selectedRows.forEach(item => {
            if (!typeMap[item.type]) {
                typeMap[item.type] = [];
            }
            typeMap[item.type].push(item.fullName);
        });
        this.selectedMetadataTypes = { ...typeMap };
        console.log(JSON.stringify(this.selectedMetadataTypes));
    }

    async pollDeploymentStatus(deploymentId, intervalMs) {
        while (true) {
            const status = await getDeploymentStatus({ deploymentId });

            if (status?.done) {
                return status;
            }

            await new Promise((resolve) => setTimeout(resolve, intervalMs));
        }
    }

    async deployMetadata() {
        try {
            let tokenResponse = await handleClientCredentialsFlow({ metadataId: this.selectedTarget });
            console.log(tokenResponse);
            if (tokenResponse == 'Expired') {
                console.log('Token Expired');
                return;
            }
            if (tokenResponse == 'Valid') {
                let response = await retrieveMetadataItem({ componentNamesMap: this.selectedMetadataTypes, sourceOrg: this.selectedSource, targetOrg: this.selectedTarget })
                console.log('success');
            } else {
                const result = await this.pollDeploymentStatus(tokenResponse, 5000);
                console.log(result);
                if (result.success) {
                    let response = await retrieveMetadataItem({ componentNamesMap: this.selectedMetadataTypes, sourceOrg: this.selectedSource, targetOrg: this.selectedTarget })
                    console.log(response);
                    console.log('success');
                } else {
                    console.log('Deployment Failed');
                }
            }
        } catch (error) {
            console.log(error);
        }
    }

    get shouldFetchMetadata() {
        return this.selectedMetadata.length < 1;
    }

    async handleFetchMetadata() {
        try {
            this.fetchedFiles = await listMetadata({ metadataComponents: this.selectedMetadata, sourceOrg: this.selectedSource })
            console.log(response);
        } catch (error) {
            console.log(error);
        }
    }
}