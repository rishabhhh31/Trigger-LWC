import { LightningElement, wire } from 'lwc';
import { getListRecordsByName } from "lightning/uiListsApi";
import CONTACT from "@salesforce/schema/Contact";

export default class ContactList extends LightningElement {
    columns = [
        { label: 'Contact Name', fieldName: 'Name' },
        { label: 'Email', fieldName: 'Email' },
        { label: 'Phone', fieldName: 'Phone' },
        { label: 'Title', fieldName: 'Title' },
    ];

    timeout;
    error;
    contacts;
    isLoading = false;

    @wire(getListRecordsByName, {
        objectApiName: CONTACT.objectApiName,
        listViewApiName: "AllContacts",
        fields: ["Contact.Id", "Contact.Name", "Contact.Email", "Contact.Phone", "Contact.Title"],
        sortBy: ["Contact.Name"],
    })
    contactRecords({ error, data }) {
        if (data) {
            this.contacts = data.records.map(record => {
                const contact = {};
                for (const key in record.fields) {
                    contact[key] = record.fields[key].value;
                }
                return contact;
            });
            this.error = undefined;
        } else if (error) {
            this.contacts = undefined;
            this.error = error;
        }
    }

    handleSearch(event) {
        this.isLoading = true;
        let searchTerm = event.target.value;
        clearTimeout(this.timeout);
        this.timeout = setTimeout(() => {
            this.searchTerm = searchTerm;
            this.isLoading = false;
        }, 300);
    }

    get filteredContacts() {
        return this.searchTerm ? this.contacts.filter(contact => contact.Name.toLowerCase().includes(this.searchTerm.toLowerCase())) : this.contacts;
    }
}