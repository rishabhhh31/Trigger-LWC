trigger ContactTrigger on Contact (before insert, before update, after insert, after update, after delete, after undelete) {
    if(Trigger.isAfter){
        if(Trigger.isInsert || Trigger.isUndelete){
            // ContactTriggerHandler.updateAccountContactCounts(Trigger.new, null);
        }
        if(Trigger.isDelete){
            // ContactTriggerHandler.updateAccountContactCounts(Trigger.old, null);
        }
        if(Trigger.isUpdate){
            // ContactTriggerHandler.updateAccountContactCounts(Trigger.new, Trigger.oldMap);
        }
    }
    
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            //ContactTriggerHandler.duplicateContactEmailCheck(Trigger.new, null);
        }
        if(Trigger.isUpdate){
            //ContactTriggerHandler.duplicateContactEmailCheck(Trigger.new, Trigger.oldMap);
        }
    }
}