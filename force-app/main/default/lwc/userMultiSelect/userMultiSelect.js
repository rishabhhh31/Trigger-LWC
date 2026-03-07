import { LightningElement, wire, track } from 'lwc';
import { getListRecordsByName } from 'lightning/uiListsApi';
import USER_OBJECT from '@salesforce/schema/User';

export default class UserMultiSelect extends LightningElement {

    @wire(getListRecordsByName, {
        objectApiName: USER_OBJECT.objectApiName,
        listViewApiName: 'AllUsers',
        fields: ["User.Id", "User.Name", "User.Email", "User.SmallPhotoUrl"],
        sortBy: ["User.Name"]
    })
    wiredUsers;

    @track selectedUsers = [];
    @track filteredUsers = [];
    showDropdown = false;
    searchTerm = '';

    get userList() {
        return this.wiredUsers.data
            ? this.wiredUsers.data.records
            : [];
    }

    connectedCallback() {
        this.handleOutsideClick = this.handleOutsideClick.bind(this);
        document.addEventListener('click', this.handleOutsideClick);
        this.filterUsers();
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
        this.filterUsers();
        this.showDropdown = true;
    }

    filterUsers() {
        if (!this.searchTerm) {
            this.filteredUsers = this.userList.filter(user =>
                !this.selectedUsers.some(selected => selected.Id === user.id)
            );
        } else {
            this.filteredUsers = this.userList.filter(user =>
                user.fields.Name.value
                    .toLowerCase()
                    .includes(this.searchTerm.toLowerCase()) &&
                !this.selectedUsers.some(selected => selected.Id === user.id)
            );
        }
    }

    selectUser(event) {
        const userId = event.currentTarget.dataset.userId;
        const user = this.userList.find(u => u.id === userId);
        if (user) {
            this.selectedUsers = [
                ...this.selectedUsers,
                {
                    Id: user.id,
                    Name: user.fields.Name.value,
                    Email: user.fields.Email.value,
                    SmallPhotoUrl: user.fields.SmallPhotoUrl.value
                }
            ];
            this.searchTerm = '';
            this.filterUsers();
            this.showDropdown = false;
        }
    }

    removeUser(event) {
        const userId = event.currentTarget.dataset.userId;
        this.selectedUsers = this.selectedUsers.filter(
            user => user.Id !== userId
        );
        this.filterUsers();
    }

    disconnectedCallback() {
        document.removeEventListener('click', this.handleOutsideClick);
    }

    handleOutsideClick(event) {
        const path = event.composedPath();
        const clickedInside = path.some(el => el === this.template.host);

        if (!clickedInside) {
            this.showDropdown = false;
        }
    }

    stopPropagation(event) {
        event.stopPropagation();
    }
}