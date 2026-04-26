import { LightningElement, wire, track } from 'lwc';
import { getListRecordsByName } from 'lightning/uiListsApi';
import CONTENT_DOCUMENT_OBJECT from '@salesforce/schema/ContentDocument';
import { NavigationMixin } from 'lightning/navigation';

export default class FileDownloader extends NavigationMixin(LightningElement) {

    // UI State
    @track isDownloadModalOpen = false;
    @track downloadProgress = 0;

    // Data
    wiredDocumentResponse;
    loadError;

    // Wire Files
    @wire(getListRecordsByName, {
        objectApiName: CONTENT_DOCUMENT_OBJECT.objectApiName,
        listViewApiName: 'OwnedContentDocuments',
        fields: [
            "ContentDocument.Title",
            "ContentDocument.Id",
            "ContentDocument.ContentSize",
            "ContentDocument.FileExtension"
        ],
        sortBy: ["ContentDocument.Title"]
    })
    wiredDocuments(response) {
        this.wiredDocumentResponse = response;

        if (response.data) {
            this.loadError = undefined;
        } else if (response.error) {
            this.loadError = response.error;
        }
    }

    // Getter for UI
    get documentList() {
        return this.wiredDocumentResponse?.data?.records || [];
    }

    get downloadProgressLabel() {
        return `${this.downloadProgress}% Complete`;
    }

    // Preview
    handlePreview(event) {
        const documentId = event.currentTarget.dataset.id;

        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: documentId
            }
        });
    }

    // Download Flow
    handleDownload(event) {
        const documentId = event.currentTarget.dataset.id;

        this.isDownloadModalOpen = true;
        this.downloadProgress = 0;

        this.startDownloadSimulation(documentId);
    }

    startDownloadSimulation(documentId) {
        const intervalRef = setInterval(() => {
            this.downloadProgress += 10;

            if (this.downloadProgress >= 100) {
                clearInterval(intervalRef);
                this.finishDownload(documentId);
            }
        }, 200);
    }

    finishDownload(documentId) {
        this.isDownloadModalOpen = false;
        this.downloadProgress = 0;

        window.open(`/sfc/servlet.shepherd/document/download/${documentId}`, '_blank');
    }

    closeModal() {
        this.isDownloadModalOpen = false;
        this.downloadProgress = 0;
    }
}