trigger CaseTrigger on Case (before update) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        CaseTriggerHandler.preventArchiveCaseStatusChange(Trigger.new, Trigger.oldMap);
        CaseTriggerHandler.autoArchiveCases(Trigger.new);
    }
}