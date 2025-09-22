trigger ContactTrigger on Contact (after insert, after update, after delete, after undelete) {
    if(Trigger.isInsert || Trigger.isUndelete){
        ContactTriggerHandler.updateAccountContactCounts(Trigger.new, null);
    }
    if(Trigger.isDelete){
        ContactTriggerHandler.updateAccountContactCounts(Trigger.old, null);
    }
    if(Trigger.isUpdate){
        ContactTriggerHandler.updateAccountContactCounts(Trigger.new, Trigger.oldMap);
    }
}