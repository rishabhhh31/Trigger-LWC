import getAllCases from '@salesforce/apex/SearchFilter.getAllCases';
import { LightningElement, wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import CASE_OBJECT from "@salesforce/schema/Case";
import STATUS_FIELD from "@salesforce/schema/Case.Status";
import PRIORITY_FIELD from "@salesforce/schema/Case.Priority";

export default class SearchFilter extends LightningElement {

    searchTerm = '';
    statusFilter = '';
    priorityFilter = '';
    startDateFilter = '';
    caseRecordTypeId;
    statuses = [];
    priorities = [];

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    caseObjectInfo({ error, data }) {
        if (data) {
        this.caseRecordTypeId = data.defaultRecordTypeId;
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getPicklistValues, { recordTypeId: "$caseRecordTypeId", fieldApiName: STATUS_FIELD })
    statusPicklistResults({ error, data }) {
        if (data) {
            this.statuses = data.values;
        } else if (error) {

        }
    }

    @wire(getPicklistValues, { recordTypeId: "$caseRecordTypeId", fieldApiName: PRIORITY_FIELD })
    priorityPicklistResults({ error, data }) {
        if (data) {
            this.priorities = data.values;
            this.error = undefined;
        } else if (error) {
            
        }
    }

    @wire(getAllCases)
    caseResults;

    get allCases(){
        return this.caseResults?.data || [];
    }

    get filteredRecords() {
        console.log(this.allCases);
        let filtered = [...this.allCases];

        if (this.searchTerm) {
            filtered = filtered.filter(record =>
                record.CaseNumber.toLowerCase().includes(this.searchTerm.toLowerCase())
            );
        }

        if (this.statusFilter) {
            filtered = filtered.filter(record =>
                record.Status === this.statusFilter
            );
        }

        if (this.priorityFilter) {
            filtered = filtered.filter(record =>
                record.Priority === this.priorityFilter
            );
        }

        if (this.startDateFilter) {
            filtered = filtered.filter(record =>
                record.CreatedDate >= this.startDateFilter
            );
        }

        return filtered;
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
    }

    handleStatusFilter(event) {
        this.statusFilter = event.target.value;
    }

    handlePriorityFilter(event) {
        this.priorityFilter = event.target.value;
    }

    handleDateFilter(event) {
        this.startDateFilter = event.target.value;
    }
}