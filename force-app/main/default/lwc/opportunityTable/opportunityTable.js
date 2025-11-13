import { LightningElement, wire, track } from 'lwc';
import { getListRecordsByName } from "lightning/uiListsApi";
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
export default class OpportunityTable extends LightningElement {
    @wire(getListRecordsByName, {
        objectApiName: OPPORTUNITY_OBJECT.objectApiName,
        listViewApiName: 'AllOpportunities',
        fields: ["Opportunity.Name", "Opportunity.Id", "Opportunity.StageName", "Opportunity.Amount", "Opportunity.CloseDate"]
    })
    opportunities;

    sortBy = 'Name';
    sortDirection = 'asc';
    currentPage = 1;
    pageSize = 10;

    columns = [
        { label: 'Name', fieldName: 'Name', sortable: true },
        {
            label: 'Amount', fieldName: 'Amount', type: 'currency', sortable: true, typeAttributes: {
                currencyCode: 'USD',
            }
        },
        { label: 'Stage', fieldName: 'StageName', sortable: true },
        {
            label: 'Close Date', fieldName: 'CloseDate', type: 'date', sortable: true, typeAttributes: {
                day: 'numeric',
                year: 'numeric',
                month: 'long',
                weekday: 'short'
            }
        }
    ];

    get opportunityList() {
        console.log(this.opportunities);
        return this.opportunities.data ? this.opportunities.data.records.map(opp => {
            let fields = {};
            for (let field in opp.fields) {
                fields[field] = opp.fields[field].value;
            }
            return fields;
        }) : [];
    }

    get sortedOpportunities() {
        let sorted = [...this.opportunityList];
        sorted.sort((a, b) => {
            let aValue = a[this.sortBy];
            let bValue = b[this.sortBy];
            if (aValue < bValue) {
                return this.sortDirection === 'asc' ? -1 : 1;
            }
            if (aValue > bValue) {
                return this.sortDirection === 'asc' ? 1 : -1;
            }
            return 0;
        });
        return sorted;
    }

    get displayedOpportunities() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        return this.sortedOpportunities.slice(start, end);
    }

    get totalPages() {
        return Math.ceil(this.sortedOpportunities.length / this.pageSize);
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage === this.totalPages;
    }

    handleSort(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.currentPage = 1;
    }

    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
        }
    }
}