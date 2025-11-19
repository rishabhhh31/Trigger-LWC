trigger AccountTrigger on Account (before insert, before update) {
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            // AccountTriggerHandler.generateAccountNumber(Trigger.new);
            AccountTriggerHandler.accountScoring(Trigger.new);
        }
        if(Trigger.isUpdate){
            AccountTriggerHandler.accountScoring(Trigger.new);
        }
    }
}