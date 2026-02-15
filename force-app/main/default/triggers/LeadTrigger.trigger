trigger LeadTrigger on Lead (after update) {
    if(trigger.isAfter && trigger.isUpdate){
        LeadTriggerHandler.createFollowUpTask(Trigger.new, Trigger.oldMap);
    }
}