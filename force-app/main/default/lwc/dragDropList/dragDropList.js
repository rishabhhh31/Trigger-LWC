import { LightningElement, track } from 'lwc';

export default class DragDropList extends LightningElement {

    @track items = [
        { id: 1, name: 'Item 1' },
        { id: 2, name: 'Item 2' },
        { id: 3, name: 'Item 3' },
        { id: 4, name: 'Item 4' }
    ];

    draggedIndex = null;

    handleDragStart(event) {
        console.log('handleDragStart', event);
        this.draggedIndex = Number(event.currentTarget.dataset.index);
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData('text/plain', this.draggedIndex);
        event.currentTarget.classList.add('dragging');
    }

    handleDragEnter(event) {
        console.log('handleDragEnter', event);
        const element = event.currentTarget;
        element.classList.add('drop-target');
    }

    handleDragOver(event) {
        console.log('handleDragOver', event);
        event.preventDefault();
        event.dataTransfer.dropEffect = 'move';
    }

    handleDragLeave(event) {
        console.log('handleDragLeave', event);
        event.currentTarget.classList.remove('drop-target');
    }

    handleDrop(event) {
        console.log('handleDrop', event);
        event.preventDefault();
        const dropIndex = Number(event.currentTarget.dataset.index);
        const draggedIndex = Number(
            event.dataTransfer.getData('text/plain')
        );
        if (draggedIndex !== dropIndex) {
            const updatedList = [...this.items];
            const draggedItem = updatedList.splice(draggedIndex, 1)[0];
            updatedList.splice(dropIndex, 0, draggedItem);
            this.items = [...updatedList];
        }
        event.currentTarget.classList.remove('drop-target');
    }

    handleDragEnd() {
        const elements = this.template.querySelectorAll('.list-item');
        elements.forEach(el => {
            el.classList.remove('dragging');
            el.classList.remove('drop-target');
        });
    }
}