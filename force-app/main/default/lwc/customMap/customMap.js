import { LightningElement, track } from 'lwc';

export default class CustomMap extends LightningElement {

    // UI
    isAddModalOpen = false;
    selectedMarkerId;

    // Data
    @track locationList = [];

    @track draftLocation = {
        name: '',
        street: '',
        city: '',
        state: '',
        country: '',
        postalCode: ''
    };

    // CORRECT MARKERS (as per Salesforce doc)
    get mapMarkers() {
        return this.locationList.map(loc => ({
            location: {
                Street: loc.street,
                City: loc.city,
                State: loc.state,
                Country: loc.country,
                PostalCode: loc.postalCode
            },
            title: loc.name,
            description: `<b>${loc.name}</b><br/>${loc.street}, ${loc.city}`,
            value: String(loc.id),
            icon: "standard:location"
        }));
    }

    get showMap(){
        return this.mapMarkers.length > 0;
    }
    // Modal
    openAddLocationModal() {
        this.isAddModalOpen = true;
        this.resetDraft();
    }

    closeModal() {
        this.isAddModalOpen = false;
    }

    resetDraft() {
        this.draftLocation = {
            name: '',
            street: '',
            city: '',
            state: '',
            country: '',
            postalCode: ''
        };
    }

    // Name input
    handleNameChange(event) {
        this.draftLocation.name = event.target.value;
    }

    // Correct address handling
    handleAddressChange(event) {
        const addr = event.detail;

        this.draftLocation = {
            ...this.draftLocation,
            street: addr.street,
            city: addr.city,
            state: addr.province,
            country: addr.country,
            postalCode: addr.postalCode
        };
    }

    // Save
    saveLocation() {
        const { name, city, country } = this.draftLocation;

        if (!name || !city || !country) return;

        const newLocation = {
            id: Date.now(),
            ...this.draftLocation
        };

        this.locationList = [...this.locationList, newLocation];

        this.closeModal();
        this.selectedMarkerId = newLocation.id;
    }

    // View from list
    handleViewLocation(event) {
        this.selectedMarkerId = event.currentTarget.dataset.id;
    }

    // Sync when clicking marker on map
    handleMarkerSelect(event) {
        this.selectedMarkerId = event.target.selectedMarkerValue;
    }
}