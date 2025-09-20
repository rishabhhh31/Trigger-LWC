import { LightningElement, wire } from "lwc";
import { getListRecordsByName } from "lightning/uiListsApi";
import ACCOUNT from "@salesforce/schema/Account";

export default class AccountList extends LightningElement {
    // Columns for lightning-datatable
    columns = [
        { label: 'Account Name', fieldName: 'Name' },
        { label: 'Rating', fieldName: 'Rating' },
        { label: 'Industry', fieldName: 'Industry' },
        { label: 'Type', fieldName: 'Type' },
    ];

    // State variables
    error;
    pageToken;
    nextPageToken;
    previousPageToken;
    accounts = [];

    // Fetch records using List View API with pagination
    @wire(getListRecordsByName, {
        objectApiName: ACCOUNT.objectApiName,
        listViewApiName: "AllAccounts",
        sortBy: ["Account.Name"],
        pageSize: 5,
        pageToken: "$pageToken",
        fields: ["Account.Id", "Account.Name", "Account.Rating", "Account.Industry", "Account.Type"],
    })
    listRecords({ error, data }) {
        if (data) {
            // Map response to simplified objects
            this.accounts = data.records.map(record => {
                const account = {};
                for (const key in record.fields) {
                    account[key] = record.fields[key].value;
                }
                return account;
            });

            // Save pagination tokens
            this.nextPageToken = data.nextPageToken;
            this.previousPageToken = data.previousPageToken;
            this.error = undefined;
        } else if (error) {
            // Handle error
            this.error = error;
            this.accounts = [];
        }
    }

    // Check if Next button should be enabled
    get hasNextPage() {
        return this.nextPageToken == null;
    }

    // Check if Previous button should be enabled
    get hasPreviousPage() {
        return this.previousPageToken == null;
    }

    // Handle pagination button clicks
    handleListChange(event) {
        const { name } = event.target;
        if (name === 'next') {
            this.pageToken = this.nextPageToken;
        } else if (name === 'previous') {
            this.pageToken = this.previousPageToken;
        }
    }
}