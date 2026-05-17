import { LightningElement } from 'lwc';

export default class SearchInput extends LightningElement {
    searchTerm = '';

    items = [
        { id: 1, name: 'Apple' },
        { id: 2, name: 'Banana' },
        { id: 3, name: 'Orange' },
        { id: 4, name: 'Grape' },
        { id: 5, name: 'Strawberry' }
    ];

    get filteredItems() {
        return this.items.filter(item =>
            item.name.toLowerCase().includes(this.searchTerm.toLowerCase())
        );
    }

    get showNoData() {
        return this.filteredItems.length === 0;
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
    }
}