import { LightningElement, wire, track } from 'lwc';
import { getListUi } from 'lightning/uiListApi';
import APPOINTMENT_OBJECT from '@salesforce/schema/Appointment__c';
import createAppointment from '@salesforce/apex/CustomCalendarController.createAppointment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CustomCalendar extends LightningElement {

    @track currentDate = new Date();
    @track calendarDays = [];
    @track showModal = false;
    @track newAppointment = {};
    @track selectedDate = null;

    weekdays = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];

    @wire(getListUi, {
        objectApiName: APPOINTMENT_OBJECT,
        listViewApiName: 'All'
    })
    wiredAppointments;

    get appointmentList() {
        return this.wiredAppointments.data
            ? this.wiredAppointments.data.records
            : [];
    }

    get currentMonthYear() {
        return this.currentDate.toLocaleDateString('en-US', {
            month: 'long',
            year: 'numeric'
        });
    }

    connectedCallback() {
        this.generateCalendar();
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

            const isCurrentMonth = date.getMonth() === month;
            const isToday = this.isToday(date);
            const hasEvents = this.hasEventsOnDate(date);

            this.calendarDays.push({
                date: date.toISOString().split('T')[0],
                dayNumber: date.getDate(),
                cssClass: `day ${isCurrentMonth ? 'current-month':'other-month'} ${isToday ? 'today':''}`,
                hasEvents: hasEvents
            });
        }
    }

    isToday(date){
        const today = new Date();
        return date.toDateString() === today.toDateString();
    }

    hasEventsOnDate(date){

        const dateStr = date.toISOString().split('T')[0];

        return this.appointmentList.some(appointment =>
            appointment.fields.Start_Time__c.value.startsWith(dateStr)
        );
    }

    previousMonth(){
        this.currentDate.setMonth(this.currentDate.getMonth() - 1);
        this.generateCalendar();
    }

    nextMonth(){
        this.currentDate.setMonth(this.currentDate.getMonth() + 1);
        this.generateCalendar();
    }

    selectDate(event){

        this.selectedDate = event.currentTarget.dataset.date;
        this.showAddModal();
    }

    showAddModal(){

        this.showModal = true;

        this.newAppointment = {

            Start_Time__c : this.selectedDate || new Date().toISOString().slice(0,16),

            End_Time__c : new Date(
                Date.now() + 60*60*1000
            ).toISOString().slice(0,16)
        };
    }

    closeModal(){
        this.showModal = false;
        this.newAppointment = {};
        this.selectedDate = null;
    }

    handleInputChange(event){

        const field = event.target.dataset.field;

        this.newAppointment[field] = event.target.value;
    }

    saveAppointment(){

        if(!this.newAppointment.Subject__c){

            this.showToast(
                'Error',
                'Subject is required',
                'error'
            );
            return;
        }

        createAppointment({
            appointmentData : this.newAppointment
        })
        .then(()=>{

            this.showToast(
                'Success',
                'Appointment created successfully',
                'success'
            );

            this.closeModal();

            this.generateCalendar();

        })
        .catch(error=>{

            this.showToast(
                'Error',
                error.body.message,
                'error'
            );
        });
    }

    showToast(title,message,variant){

        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

}