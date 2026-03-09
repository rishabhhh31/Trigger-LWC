import { LightningElement, track } from 'lwc';

export default class NotificationSystem extends LightningElement {

    @track notifications = [];
    notificationId = 0;

    addNotification(message, type = 'info', autoDismiss = true) {

        const notification = {
            id: ++this.notificationId,
            message: message,
            type: type,
            cssClass: `slds-notify slds-notify_alert slds-theme_${type} slds-m-bottom_small`,
            icon: this.getIconForType(type)
        };

        this.notifications = [...this.notifications, notification];

        if (autoDismiss) {
            setTimeout(() => {
                this.notifications = this.notifications.filter(n => n.id !== notification.id);
            }, 5000);
        }
    }

    getIconForType(type) {
        const icons = {
            success: 'utility:success',
            error: 'utility:error',
            warning: 'utility:warning',
            info: 'utility:info'
        };

        return icons[type] || icons.info;
    }

    dismissNotification(event) {
        const id = parseInt(event.currentTarget.dataset.notificationId, 10);
        this.notifications = this.notifications.filter(n => n.id !== id);
    }

    handleShowNotification(event) {
        let { message, type } = event.target.dataset;
        this.addNotification(message, type, type != 'error');
    }
}