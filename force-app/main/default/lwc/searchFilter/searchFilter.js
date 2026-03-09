import { LightningElement, wire } from 'lwc';
import getAllCases from '@salesforce/apex/SearchFilter.getAllCases';

import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';

import CASE_OBJECT from '@salesforce/schema/Case';
import STATUS_FIELD from '@salesforce/schema/Case.Status';
import PRIORITY_FIELD from '@salesforce/schema/Case.Priority';

export default class SearchFilter extends LightningElement {

    searchTerm = '';
    statusFilter = '';
    priorityFilter = '';
    startDateFilter = '';

    caseRecordTypeId;

    statuses = [];
    priorities = [];

    cases = [];
    error;

    // Get Case metadata
    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    caseInfo({ data, error }) {
        if (data) {
            this.caseRecordTypeId = data.defaultRecordTypeId;
        } else if (error) {
            console.error('Object Info Error', error);
        }
    }

    // Status picklist
    @wire(getPicklistValues, {
        recordTypeId: '$caseRecordTypeId',
        fieldApiName: STATUS_FIELD
    })
    wiredStatuses({ data, error }) {
        if (data) {
            this.statuses = [
                { label: 'All', value: '' },
                ...data.values.map(item => ({
                    label: item.label,
                    value: item.value
                }))
            ];
        } else if (error) {
            console.error('Status Picklist Error', error);
        }
    }

    // Priority picklist
    @wire(getPicklistValues, {
        recordTypeId: '$caseRecordTypeId',
        fieldApiName: PRIORITY_FIELD
    })
    wiredPriorities({ data, error }) {
        if (data) {
            this.priorities = [
                { label: 'All', value: '' },
                ...data.values.map(item => ({
                    label: item.label,
                    value: item.value
                }))
            ];
        } else if (error) {
            console.error('Priority Picklist Error', error);
        }
    }

    // Apex call
    @wire(getAllCases)
    wiredCases({ data, error }) {
        if (data) {
            this.cases = data;
        } else if (error) {
            console.error('Case Fetch Error', error);
        }
    }

    get filteredRecords() {

        let filtered = [...this.cases];

        if (this.searchTerm) {
            const search = this.searchTerm.toLowerCase();
            filtered = filtered.filter(record =>
                record.CaseNumber.toLowerCase().includes(search)
            );
        }

        if (this.statusFilter) {
            filtered = filtered.filter(
                record => record.Status === this.statusFilter
            );
        }

        if (this.priorityFilter) {
            filtered = filtered.filter(
                record => record.Priority === this.priorityFilter
            );
        }

        if (this.startDateFilter) {
            const selectedDate = new Date(this.startDateFilter);

            filtered = filtered.filter(record =>
                new Date(record.CreatedDate) >= selectedDate
            );
        }

        return filtered;
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
    }

    handleStatusFilter(event) {
        this.statusFilter = event.detail.value;
    }

    handlePriorityFilter(event) {
        this.priorityFilter = event.detail.value;
    }

    handleDateFilter(event) {
        this.startDateFilter = event.target.value;
    }
}