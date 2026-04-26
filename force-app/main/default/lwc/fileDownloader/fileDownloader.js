import { LightningElement, wire, track } from 'lwc';
import { getListRecordsByName } from 'lightning/uiListsApi';
import CONTENT_DOCUMENT_OBJECT from '@salesforce/schema/ContentDocument';
import {NavigationMixin} from 'lightning/navigation'
export default class FileDownloader extends NavigationMixin(LightningElement) {

    @track showProgress = false;
    @track progress = 0;

    wiredResult;
    error;

    @wire(getListRecordsByName, {
        objectApiName: CONTENT_DOCUMENT_OBJECT.objectApiName,
        listViewApiName: 'OwnedContentDocuments',
        fields: ["ContentDocument.Title", "ContentDocument.Id", "ContentDocument.ContentSize", "ContentDocument.FileType", "ContentDocument.FileExtension"],
        sortBy: ["ContentDocument.Title"]
    })
    wiredFiles(result) {
        this.wiredResult = result;
        if (result.data) {
            console.log(result.data);
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
        }
    }

    get files() {
        return this.wiredResult?.data?.records || [];
    }

    previewHandler(event){
        const fileId = event.currentTarget.dataset.fileId;
        this[NavigationMixin.Navigate]({ 
            type:'standard__namedPage',
            attributes:{ 
                pageName:'filePreview'
            },
            state:{ 
                selectedRecordId: fileId
            }
        })
    }

    downloadFile(event) {
        const fileId = event.currentTarget.dataset.fileId;
        this.showProgress = true;
        this.progress = 0;
        this.simulateDownload(fileId);
    }

    simulateDownload(fileId) {
        const interval = setInterval(() => {
            this.progress += 10;

            if (this.progress >= 100) {
                clearInterval(interval);
                this.completeDownload(fileId);
            }
        }, 200);
    }

    completeDownload(fileId) {
        this.showProgress = false;
        this.progress = 0;

        // Actual Salesforce file download
        window.open(`/sfc/servlet.shepherd/document/download/${fileId}`, '_blank');
    }
}