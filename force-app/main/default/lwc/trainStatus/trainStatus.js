import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTrainLiveStatus from '@salesforce/apex/TrainStatusController.getTrainLiveStatus';
import { publish, MessageContext } from 'lightning/messageService';
import mapLocationsChannel from '@salesforce/messageChannel/stationLocationChannel__c';

/**
 * @description LWC to display live train running status and publish
 * station locations to other components via Lightning Message Service.
 */
export default class TrainStatus extends LightningElement {
    @track stationsList = []; // List of processed station data for display
    @track mapMarkers = [];   // Station map markers for map component

    trainStatusMessage;       // Message showing train’s running status (e.g., "On time", "Delayed by 10 min")
    isLoading = false;        // Spinner toggle during API calls
    trainNumber;              // User-entered train number
    trainName;                // Train name fetched from Apex response

    @wire(MessageContext)
    messageContext;


    /**
     * @description Captures user input for the train number.
     */
    handleTrainNumberChange(event) {
        this.trainNumber = event.target.value;
    }

    /**
     * @description Called when user clicks "Check Status".
     * Clears previous data and fetches fresh train status.
     */
    handleCheckStatus() {
        this.mapMarkers = [];
        this.fetchTrainStatus();
    }

    /**
     * @description Fetches live train running status from Apex.
     */
    async fetchTrainStatus() {
        if (!this.trainNumber) {
            this.showToast('Error', 'Please enter a train number', 'error');
            return;
        }

        this.isLoading = true;
        this.stationsList = [];
        this.trainStatusMessage = '';

        try {
            // Call Apex method to get train live status
            const response = await getTrainLiveStatus({
                trainNumber: this.trainNumber
            });

            console.log('Train Live Status Response:', response);

            if (response && response.code === 200) {
                const { stations, current_station, train_status_message, train_name } = response.body;

                // Update high-level properties
                this.trainStatusMessage = train_status_message;
                this.trainName = train_name;

                // Transform stations array into UI-friendly objects
                this.processStationsData(stations, current_station);
            } else {
                this.showToast('Error', response?.error || 'Unable to fetch train data', 'error');
            }
        } catch (error) {
            console.error('Error fetching live train status:', error);
            this.showToast('Error', 'An error occurred while fetching train status', 'error');
        } finally {
            this.isLoading = false; // Always stop the loading spinner
        }
    }

    /**
     * @description Transforms API station data into formatted objects for display and mapping.
     */
    processStationsData(stations, currentStationCode) {
        this.mapMarkers = []; // reset markers
        const processedStations = [];

        stations.forEach((station) => {
            const timingStatus = this.compareScheduledAndActualTimes(
                station.actual_arrival_date,
                station.arrivalTime,
                station.actual_arrival_time
            );

            // Determine visual state based on timing comparison
            let runningStatusText = 'N/A';
            let statusTextClass = 'status-text';
            let statusDotClass = 'status-dot neutral';

            switch (timingStatus.comparison) {
                case 'right':
                    runningStatusText = 'On Time';
                    statusTextClass = 'status-text on-time';
                    statusDotClass = 'status-dot green';
                    break;
                case 'delay':
                    runningStatusText = `${timingStatus.difference} late`;
                    statusTextClass = 'status-text delayed';
                    statusDotClass = 'status-dot red';
                    break;
                case 'early':
                    runningStatusText = `${timingStatus.difference} early`;
                    statusTextClass = 'status-text early';
                    statusDotClass = 'status-dot yellow';
                    break;
            }

            // Create map marker
            const cleanedStationName = station.stationName.replace(/\s*Jn\b/, '').trim();
            const mapMarker = {
                location: {
                    Street: `${cleanedStationName} Railway Station`,
                    Country: 'India'
                },
                value: station.stationCode,
                title: `${cleanedStationName} Railway Station`
            };
            this.mapMarkers.push(mapMarker);

            // Publish to message channel for other components (e.g., map)
            publish(this.messageContext, mapLocationsChannel, {
                locations: this.mapMarkers,
                trainNumber: this.trainNumber
            });

            // Add formatted station object to display list
            processedStations.push({
                stationCode: station.stationCode,
                stationName: station.stationName,
                distance: station.distance,
                platform: station.expected_platform,
                dayCount: station.dayCount,
                runningStatus: runningStatusText,
                statusTextClass,
                statusDotClass,
                expectedArrivalTime: station.arrivalTime,
                expectedDepartureTime: station.departureTime,
                formattedArrivalDate: this.formatDate(station.actual_arrival_date),
                formattedDepartureDate: this.formatDate(station.actual_departure_date),
                actualArrivalTime: station.actual_arrival_time,
                actualDepartureTime: station.actual_departure_time,
                stationCssClass: station.stationCode === currentStationCode ? 'station start' : 'station',
                arrivalHtml: this.formatTimeWithStrike(station.arrivalTime),
                departureHtml: this.formatTimeWithStrike(station.departureTime)
            });
        });

        this.stationsList = processedStations;
    }

    /**
     * @description Displays toast messages to the user.
     */
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    /**
     * @description Converts date string from YYYYMMDD to DD-MMM format.
     */
    formatDate(dateString) {
        if (!dateString) return '';
        const month = dateString.slice(4, 6);
        const day = dateString.slice(6, 8);
        const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
        const monthName = months[parseInt(month, 10) - 1];
        return `${day}-${monthName}`;
    }

    /**
     * @description Compares scheduled vs. actual arrival/departure times and determines delay/early status.
     */
    compareScheduledAndActualTimes(dateString, scheduledTime, actualTime) {
        const year = dateString.slice(0, 4);
        const month = dateString.slice(4, 6);
        const day = dateString.slice(6, 8);

        const scheduledDate = new Date(`${year}-${month}-${day}T${scheduledTime}`);
        let actualDate = new Date(`${year}-${month}-${day}T${actualTime}`);

        // Adjust for midnight crossover (if actual time after midnight)
        if (actualDate < scheduledDate) {
            const diffHours = (scheduledDate - actualDate) / (1000 * 60 * 60);
            if (diffHours > 12) {
                actualDate.setDate(actualDate.getDate() + 1);
            }
        }

        let comparison = 'right';
        if (scheduledDate.getTime() < actualDate.getTime()) {
            comparison = 'delay';
        } else if (scheduledDate.getTime() > actualDate.getTime()) {
            comparison = 'early';
        }

        const diffMs = Math.abs(actualDate - scheduledDate);
        const diffMinutesTotal = Math.floor(diffMs / (1000 * 60));
        const hours = Math.floor(diffMinutesTotal / 60);
        const minutes = diffMinutesTotal % 60;
        const diffReadable = `${hours > 0 ? hours + 'hr ' : ''}${minutes}min`;

        return { comparison, difference: diffReadable };
    }

    /**
     * @description Formats a time string by striking it through (for styling).
     */
    formatTimeWithStrike(timeValue) {
        return `<s>${timeValue}</s>`;
    }

    /**
     * @description Runs after every DOM render. Injects formatted HTML for arrival/departure times.
     */
    renderedCallback() {
        const tableRows = this.template.querySelectorAll('tbody tr');
        this.stationsList.forEach((station, index) => {
            const arrivalCell = tableRows[index]?.querySelectorAll('td.muted')[0];
            const departureCell = tableRows[index]?.querySelectorAll('td.muted')[1];
            if (arrivalCell) arrivalCell.innerHTML = station.arrivalHtml;
            if (departureCell) departureCell.innerHTML = station.departureHtml;
        });
    }
}
