import { LightningElement, wire, track } from 'lwc';
import { getListRecordsByName } from 'lightning/uiListsApi';
import USER_OBJECT from '@salesforce/schema/User';

export default class UserMultiSelect extends LightningElement {

    @track selectedUsers = [];
    @track filteredUsers = [];
    showDropdown = false;
    searchTerm = '';

    wiredUsers;

    @wire(getListRecordsByName, {
        objectApiName: USER_OBJECT.objectApiName,
        listViewApiName: 'AllUsers',
        fields: ["User.Id", "User.Name", "User.Email", "User.SmallPhotoUrl"],
        sortBy: ["User.Name"]
    })
    usersWire(result) {
        this.wiredUsers = result;

        if (result.data) {
            this.filterUsers();
        }

        if (result.error) {
            console.error('Error fetching users', result.error);
        }
    }

    get userList() {
        return this.wiredUsers?.data?.records || [];
    }

    connectedCallback() {
        this.handleOutsideClick = this.handleOutsideClick.bind(this);
        document.addEventListener('click', this.handleOutsideClick);
    }

    
    handleSearch(event) {
        this.searchTerm = event.target.value;
        this.showDropdown = true;
        this.filterUsers();
    }

    filterUsers() {

        const search = this.searchTerm?.toLowerCase() || '';

        this.filteredUsers = this.userList.filter(user => {

            const name = user.fields.Name.value.toLowerCase();

            const matchesSearch = !search || name.includes(search);

            const notSelected =
                !this.selectedUsers.some(
                    selected => selected.Id === user.id
                );

            return matchesSearch && notSelected;
        });
    }

    selectUser(event) {

        const userId = event.currentTarget.dataset.userId;

        const user = this.userList.find(
            u => u.id === userId
        );

        if (!user) return;

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
        this.showDropdown = false;

        this.filterUsers();
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

        const clickedInside =
            event.composedPath().includes(this.template.host);

        if (!clickedInside) {
            this.showDropdown = false;
        }
    }

    stopPropagation(event) {
        event.stopPropagation();
    }
}