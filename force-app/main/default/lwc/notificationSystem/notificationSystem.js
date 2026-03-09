import { LightningElement, track } from 'lwc';

const ICON_MAP = {
    success: 'utility:success',
    error: 'utility:error',
    warning: 'utility:warning',
    info: 'utility:info'
};

export default class NotificationSystem extends LightningElement {

    @track notifications = [];
    notificationId = 0;

    // Button configuration
    buttons = [
        {
            label: 'Show Info',
            message: 'This is an informational message.',
            type: 'info'
        },
        {
            label: 'Show Success',
            message: 'Operation completed successfully!',
            type: 'success'
        },
        {
            label: 'Show Warning',
            message: 'Warning: Something might be wrong.',
            type: 'warning'
        },
        {
            label: 'Show Error',
            message: 'Error: Failed to complete operation.',
            type: 'error'
        }
    ];

    addNotification(message, type = 'info', autoDismiss = true) {
        const notification = {
            id: ++this.notificationId,
            message,
            type,
            icon: this.getIcon(type),
            cssClass: this.getCssClass(type)
        };

        this.notifications = [...this.notifications, notification];

        if (autoDismiss) {
            window.setTimeout(() => {
                this.removeNotification(notification.id);
            }, 5000);
        }
    }

    removeNotification(id) {
        this.notifications = this.notifications.filter(n => n.id !== id);
    }

    dismissNotification(event) {
        const id = Number(event.currentTarget.dataset.notificationId);
        this.removeNotification(id);
    }

    handleShowNotification(event) {
        const { message, type } = event.currentTarget.dataset;
        const autoDismiss = type !== 'error';

        this.addNotification(message, type, autoDismiss);
    }

    getIcon(type) {
        return ICON_MAP[type] || ICON_MAP.info;
    }

    getCssClass(type) {
        return `slds-notify slds-notify_alert slds-theme_${type} slds-m-bottom_small`;
    }
}