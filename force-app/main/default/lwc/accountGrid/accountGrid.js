import { LightningElement, wire, track } from 'lwc';
import { getListRecordsByName } from 'lightning/uiListsApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import INDUSTRY_FIELD from "@salesforce/schema/Account.Industry";
import TYPE_FIELD from "@salesforce/schema/Account.Type";
import createAccount from '@salesforce/apex/AccountGridController.createAccount';
import updateAccount from '@salesforce/apex/AccountGridController.updateAccount';
import deleteAccount from '@salesforce/apex/AccountGridController.deleteAccount';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';

export default class AccountGrid extends LightningElement {

    accountRecordTypeId;
    types = [];
    industries = [];

    @track accounts = [];
    @track originalData = {};

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    objectInfo({ error, data }) {
        if (data) {
            this.accountRecordTypeId = data.defaultRecordTypeId;
        } else if (error) {
            const message = error?.body?.message || error?.message || 'Unknown error';
            this.showToast(
                'Error',
                message,
                'error'
            );
        }
    }

    @wire(getPicklistValues, { recordTypeId: "$accountRecordTypeId", fieldApiName: INDUSTRY_FIELD })
    picklistIndustryResults({ error, data }) {
        if (data) {
            this.industries = data.values;
        } else if (error) {
            const message = error?.body?.message || error?.message || 'Unknown error';
            this.showToast(
                'Error',
                message,
                'error'
            );
        }
    }

    @wire(getPicklistValues, { recordTypeId: "$accountRecordTypeId", fieldApiName: TYPE_FIELD })
    picklistTypeResults({ error, data }) {
        if (data) {
            this.types = data.values;
        } else if (error) {
            const message = error?.body?.message || error?.message || 'Unknown error';
            this.showToast(
                'Error',
                message,
                'error'
            );
        }
    }

    @wire(getListRecordsByName, {
        objectApiName: ACCOUNT_OBJECT.objectApiName,
        listViewApiName: "AllAccounts",
        fields: ["Account.Id", "Account.Name", "Account.Industry", "Account.Type", "Account.Phone"],
        sortBy: ["Account.Name"]
    })
    wiredAccountsRecords({data, error}){
        if(data){
            this.accounts = data.records.map(account => ({
                Id: account.fields.Id.value,
                Name: account.fields.Name.value,
                Industry: account.fields.Industry.value,
                Type: account.fields.Type.value,
                Phone: account.fields.Phone.value,
                isEditing: false,
                rowClass: 'slds-hint-parent'
            }));
        }else if(error){
            const message = error?.body?.message || error?.message || 'Unknown error';
            this.showToast(
                'Error',
                message,
                'error'
            );
        }
    };

    handleFieldChange(event) {
        const id = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.value;

        const updatedAccounts = this.accounts.map(acc => {
            if (acc.Id === id) {
                return { ...acc, [field]: value };
            }
            return acc;
        });

        this.accounts = updatedAccounts;
    }

    editRow(event) {
        const id = event.target.dataset.id;

        this.accounts = this.accounts.map(acc => {
            if (acc.Id === id) {
                this.originalData[id] = { ...acc };

                return {
                    ...acc,
                    isEditing: true,
                    rowClass: 'slds-hint-parent slds-is-selected'
                };
            }
            return acc;
        });
    }

    cancelEdit(event) {
        const id = event.target.dataset.id;

        if (id.startsWith('temp_')) {
            this.accounts = this.accounts.filter(acc => acc.Id !== id);
            delete this.originalData[id];
            return;
        }

        this.accounts = this.accounts.map(acc => {
            if (acc.Id === id) {
                return { ...this.originalData[id] };
            }
            return acc;
        });

        delete this.originalData[id];
    }

    saveRow(event) {
        const id = event.target.dataset.id;
        const account = this.accounts.find(acc => acc.Id === id);
        if (!account.Name) {
            this.showToast('Error', 'Account Name is required', 'error');
            return;
        }
        if (id.startsWith('temp_')) {
            createAccount({ accountData: account })
                .then(result => {
                    this.showToast(
                        'Success',
                        'Account created successfully',
                        'success'
                    );
                    this.accounts = this.accounts.map(acc => {
                        if (acc.Id === id) {
                            return {
                                ...acc,
                                Id: result.Id,
                                isEditing: false,
                                rowClass: 'slds-hint-parent'
                            };
                        }
                        return acc;
                    });

                    delete this.originalData[id];

                })
                .catch(error => {
                    const message =
                        error?.body?.message ||
                        error?.message ||
                        'Unknown error';

                    this.showToast('Error', message, 'error');
                });

        } else {
            updateAccount({
                accountId: account.Id,
                accountData: account
            })
            .then(() => {
                this.showToast(
                    'Success',
                    'Account updated successfully',
                    'success'
                );
                this.accounts = this.accounts.map(acc => {
                    if (acc.Id === id) {
                        return {
                            ...acc,
                            isEditing: false,
                            rowClass: 'slds-hint-parent'
                        };
                    }
                    return acc;
                });
                delete this.originalData[id];
            })
            .catch(error => {
                const message =
                    error?.body?.message ||
                    error?.message ||
                    'Unknown error';
                this.showToast('Error', message, 'error');
            });
        }
    }

    async deleteRow(event) {
        const id = event.target.dataset.id;
        const confirmed = await LightningConfirm.open({
            message: 'Are you sure you want to delete this account?',
            variant: 'header',
            theme: 'error',
            label: 'Confirm Delete'
        });

        if (!confirmed) {
            return;
        }

        const account = this.accounts.find(acc => acc.Id === id);

        deleteAccount({ accountId: account.Id })
            .then(() => {
                this.showToast(
                    'Success',
                    'Account deleted successfully',
                    'success'
                );
                this.accounts = this.accounts.filter(acc => acc.Id !== id);

            })
            .catch(error => {
                const message =
                    error?.body?.message ||
                    error?.message ||
                    'Unknown error';

                this.showToast('Error', message, 'error');
            });
    }

    addNewRow() {
        const tempId = 'temp_' + Date.now();
        const newAccount = {
            Id: tempId,
            Name: '',
            Industry: '',
            Type: '',
            Phone: '',
            isEditing: true,
            rowClass: 'slds-hint-parent slds-is-selected'
        };
        this.originalData[tempId] = {...newAccount};
        this.accounts = [newAccount, ...this.accounts];
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}