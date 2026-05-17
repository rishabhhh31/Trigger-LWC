import { LightningElement, wire, api } from 'lwc';
import { getRecord, getFieldValue  } from 'lightning/uiRecordApi';

import NAME_FIELD from '@salesforce/schema/Account.Name';
import INDUSTRY_FIELD from '@salesforce/schema/Account.Industry';
import TYPE_FIELD from '@salesforce/schema/Account.Type';

export default class RecordDisplay extends LightningElement {

    @api recordId; // dynamic recordId from page

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [NAME_FIELD, INDUSTRY_FIELD, TYPE_FIELD]
    })
    account;

    get name() {
        return getFieldValue(this.account.data, NAME_FIELD);
    }

    get industry() {
        return getFieldValue(this.account.data, INDUSTRY_FIELD);
    }

    get type() {
        return getFieldValue(this.account.data, TYPE_FIELD);
    }
}