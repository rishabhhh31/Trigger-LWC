import { LightningElement } from 'lwc';

export default class TimerComponent extends LightningElement {
    timeLeft = 60; // seconds
    timerInterval;

    startTimer() {
        if (this.timerInterval) {
            clearInterval(this.timerInterval);
        }

        this.timerInterval = setInterval(() => {
            if (this.timeLeft > 0) {
                this.timeLeft--;
            } else {
                clearInterval(this.timerInterval);
            }
        }, 1000);
    }

    disconnectedCallback() {
        clearInterval(this.timerInterval);
    }

    resetTimer() {
        clearInterval(this.timerInterval);
        this.timerInterval = null
        this.timeLeft = 60;
    }

    get hasTimerStarted(){
        return this.timerInterval != null;
    }
}