import { LightningElement, wire, track } from 'lwc';
import { getListRecordsByName } from 'lightning/uiListsApi';
import APPOINTMENT_OBJECT from '@salesforce/schema/Appointment__c';
import createAppointment from '@salesforce/apex/CustomCalendarController.createAppointment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

const FIELDS = [
    'Appointment__c.Subject__c',
    'Appointment__c.Start_Time__c',
    'Appointment__c.End_Time__c',
    'Appointment__c.Description__c'
];

export default class CustomCalendar extends LightningElement {
    isLoading = false;
    currentDate = new Date();
    @track calendarDays = [];
    showModal = false;
    newAppointment = {};
    selectedDate = null;

    weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    wiredAppointmentsResult;

    @wire(getListRecordsByName, {
        objectApiName: APPOINTMENT_OBJECT.objectApiName,
        listViewApiName: 'All',
        fields: FIELDS
    })
    wiredAppointmentsInfo(result) {
        this.wiredAppointmentsResult = result;
        if (result.data) {
            this.generateCalendar();
        }
        else if (result.error) {
            this.showToast('Error', 'Unable to load appointments', 'error');
        }
    }

    get appointmentList() {
        return this.wiredAppointmentsResult?.data?.records || [];
    }

    get currentMonthYear() {
        return this.currentDate.toLocaleDateString('en-US', {
            month: 'long',
            year: 'numeric'
        });
    }

    generateCalendar() {

        const year = this.currentDate.getFullYear();
        const month = this.currentDate.getMonth();

        const firstDay = new Date(year, month, 1);
        const startDate = new Date(firstDay);

        startDate.setDate(startDate.getDate() - firstDay.getDay());

        this.calendarDays = [];

        for (let i = 0; i < 42; i++) {

            const date = new Date(startDate);
            date.setDate(startDate.getDate() + i);

            const y = date.getFullYear();
            const m = String(date.getMonth() + 1).padStart(2, '0');
            const d = String(date.getDate()).padStart(2, '0');

            const localDate = `${y}-${m}-${d}`;

            const isCurrentMonth = date.getMonth() === month;
            const isToday = this.isToday(date);
            const hasEvents = this.hasEventsOnDate(date);

            this.calendarDays.push({
                date: localDate,
                dayNumber: date.getDate(),
                cssClass: `day ${isCurrentMonth ? 'current-month' : 'other-month'} ${isToday ? 'today' : ''} ${localDate === this.selectedDate ? 'selected-day' : ''}`,
                hasEvents: hasEvents
            });
        }
    }

    isToday(date) {
        const today = new Date();
        return date.toDateString() === today.toDateString();
    }

    hasEventsOnDate(date) {

        return this.appointmentList.some(record => {

            const value = record.fields.Start_Time__c.value;

            if (!value) return false;

            const eventDate = new Date(value);

            return (
                eventDate.getFullYear() === date.getFullYear() &&
                eventDate.getMonth() === date.getMonth() &&
                eventDate.getDate() === date.getDate()
            );
        });
    }

    previousMonth() {
        this.currentDate = new Date(
            this.currentDate.setMonth(this.currentDate.getMonth() - 1)
        );
        this.generateCalendar();
    }

    nextMonth() {
        this.currentDate = new Date(
            this.currentDate.setMonth(this.currentDate.getMonth() + 1)
        );
        this.generateCalendar();
    }

    selectDate(event) {
        this.selectedDate = event.currentTarget.dataset.date;
        this.showAddModal();
    }

    getLocalISOString(date) {

        const pad = (num) => String(num).padStart(2, '0');

        const year = date.getUTCFullYear();
        const month = pad(date.getUTCMonth() + 1);
        const day = pad(date.getUTCDate());

        const hours = pad(date.getUTCHours());
        const minutes = pad(date.getUTCMinutes());
        const seconds = pad(date.getUTCSeconds());

        return `${year}-${month}-${day}T${hours}:${minutes}:${seconds}.000Z`;
    }

    showAddModal() {

        const now = new Date();

        let startDateTime;
        let endDateTime;

        if (this.selectedDate) {

            const [year, month, day] = this.selectedDate.split('-');

            const selected = new Date(
                year,
                month - 1,
                day,
                now.getHours(),
                now.getMinutes()
            );

            startDateTime = this.getLocalISOString(selected);

            const oneHourLater = new Date(selected.getTime() + 3600000);

            endDateTime = this.getLocalISOString(oneHourLater);

        }
        else {

            const oneHourLater = new Date(now.getTime() + 3600000);

            startDateTime = this.getLocalISOString(now);
            endDateTime = this.getLocalISOString(oneHourLater);
        }

        this.newAppointment = {
            Start_Time__c: startDateTime,
            End_Time__c: endDateTime
        };

        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
        this.newAppointment = {};
        this.selectedDate = null;
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        this.newAppointment[field] = event.target.value;
    }

    saveAppointment() {
        if (!this.newAppointment.Subject__c) {
            this.showToast('Error', 'Subject is required', 'error');
            return;
        }
        this.isLoading = true;
        createAppointment({
            appointmentData: this.newAppointment
        })
            .then(() => {
                this.showToast('Success', 'Appointment created', 'success');
                return refreshApex(this.wiredAppointmentsResult);
            })
            .then(() => {
                this.closeModal();
                this.generateCalendar();
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            })
            .finally(()=>{
                this.isLoading = false;
            });
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

}