import { LightningElement } from 'lwc';

export default class SimpleList extends LightningElement {
    items = [
        { id: 1, name: 'Item 1', description: 'First item description' },
        { id: 2, name: 'Item 2', description: 'Second item description' },
        { id: 3, name: 'Item 3', description: 'Third item description' }
    ];
} 