import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTrainLiveStatus from '@salesforce/apex/TrainStatusController.getTrainLiveStatus';
import { publish, MessageContext } from 'lightning/messageService';
import mapLocations from '@salesforce/messageChannel/stationLocationChannel__c';

export default class TrainStatus extends LightningElement {
    @track stops = [];
    trainStatusMessage;
    isLoading = false;
    trainNumber;
    trainName;
    @track mapMarkers = [];

    handleChange(event) {
        this.trainNumber = event.target.value;
    }

    @wire(MessageContext)
    messageContext;

    checkStatus() {
        this.mapMarkers = [];
        this.getLiveRunningStatuses();
    }

    async getLiveRunningStatuses() {
        if (!this.trainNumber) {
            this.showToast('Error', 'Please enter a train number', 'error');
            return;
        }

        this.isLoading = true;
        this.stops = [];
        this.trainStatusMessage = '';

        try {
            let response = await getTrainLiveStatus({
                trainNumber: this.trainNumber,
                departureDate: null
            });

            console.log(response);
            if (response && response.code === 200) {
                let { stations, current_station, train_status_message, train_name } = response.body;
                this.trainStatusMessage = train_status_message;;
                this.trainName = train_name;

                this.stops = stations.map((station) => {
                    let status = this.compareTimesWithDate(
                        station.actual_arrival_date,
                        station.arrivalTime,
                        station.actual_arrival_time
                    );

                    let runningStatus;
                    let statusClass = 'status-text';
                    let statusDot = 'status-dot neutral';

                    if (status.comparison.includes('right')) {
                        runningStatus = 'On Time';
                        statusClass = 'status-text on-time';
                        statusDot = 'status-dot green';
                    } else if (status.comparison.includes('delay')) {
                        runningStatus = `${status.difference} late`;
                        statusClass = 'status-text delayed';
                        statusDot = 'status-dot red';
                    } else if (status.comparison.includes('early')) {
                        runningStatus = `${status.difference} early`;
                        statusClass = 'status-text early';
                        statusDot = 'status-dot yellow';
                    }

                    let stationName = station.stationName.replace(/\s*Jn\b/, '').trim();

                    let obj = {};
                    obj.location = {};
                    obj.location.Street = stationName + " Railway Station";
                    obj.location.Country = 'India';
                    obj.value = station.stationCode;

                    obj.title = stationName + " Railway Station";
                    this.mapMarkers = [...this.mapMarkers, obj];
                    publish(this.messageContext, mapLocations, { locations: this.mapMarkers, trainNumber: this.trainNumber });

                    return {
                        stationCode: station.stationCode,
                        stationName: station.stationName,
                        distance: station.distance,
                        platform: station.expected_platform,
                        day: station.dayCount,
                        statusClass,
                        statusDot,
                        runningStatus,
                        expectedArrivalTime: station.arrivalTime,
                        expectedDepartureTime: station.departureTime,
                        expectedArrivalDate: this.dateFormat(station.actual_arrival_date),
                        expectedDepartureDate: this.dateFormat(station.actual_departure_date),
                        actualArrivalTime: station.actual_arrival_time,
                        actualDepartureTime: station.actual_departure_time,
                        // isCurrentStation: station.stationCode === current_station,
                        stationClass: station.stationCode === current_station ? 'station start' : 'station',
                        arrHtml: this.formatTime(station.arrivalTime),
                        depHtml: this.formatTime(station.departureTime)
                    };
                });
            } else {
                this.showToast('Error', response.error, 'error');
            }
        } catch (error) {
            console.error(error);
            this.showToast('Error', 'Something went wrong while fetching data', 'error');
        } finally {
            this.isLoading = false; // stop spinner
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    dateFormat(dateStr) {
        const year = dateStr.slice(0, 4);
        const month = dateStr.slice(4, 6);
        const day = dateStr.slice(6, 8);

        const months = [
            "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
            "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
        ];

        const monthName = months[parseInt(month, 10) - 1];
        return `${day}-${monthName}`;
    }

    compareTimesWithDate(dateStr, scheduledTime, actualTime) {
        // Parse date parts
        const year = dateStr.slice(0, 4);
        const month = dateStr.slice(4, 6);
        const day = dateStr.slice(6, 8);

        // Create Date objects
        const scheduledDate = new Date(`${year}-${month}-${day}T${scheduledTime}`);
        let actualDate = new Date(`${year}-${month}-${day}T${actualTime}`);

        // Check if actual time is past midnight (next day)
        if (actualDate < scheduledDate) {
            const diffHours = (scheduledDate - actualDate) / (1000 * 60 * 60);
            if (diffHours > 12) {
                actualDate.setDate(actualDate.getDate() + 1);
            }
        }

        // Determine comparison
        let comparison;
        if (scheduledDate.getTime() === actualDate.getTime()) {
            comparison = "right";
        } else if (scheduledDate.getTime() < actualDate.getTime()) {
            comparison = "delay";
        } else {
            comparison = "early";
        }

        // Calculate difference
        const diffMs = Math.abs(actualDate - scheduledDate);
        const diffMinutesTotal = Math.floor(diffMs / (1000 * 60));
        const hours = Math.floor(diffMinutesTotal / 60);
        const minutes = diffMinutesTotal % 60;

        // Human-readable string
        const diffString = `${hours > 0 ? hours + 'hr ' : ''}${minutes}min`;

        return {
            comparison,
            difference: diffString  // e.g., "1hr 5min"
        };
    }

    renderedCallback() {
        const rows = this.template.querySelectorAll('tbody tr');
        this.stops.forEach((stop, index) => {
            const arrCell = rows[index].querySelectorAll('td.muted')[0];
            const depCell = rows[index].querySelectorAll('td.muted')[1];
            if (arrCell) arrCell.innerHTML = stop.arrHtml;
            if (depCell) depCell.innerHTML = stop.depHtml;
        });
    }

    formatTime(value) {
        return `<s>${value}</s>`;
    }
}