trigger OpportunityTrigger on Opportunity (after insert, after update) {
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            OpportunityTriggerHandler.sendEmailToHighValueOpportunity(Trigger.new);
        }
        if(Trigger.isUpdate){
            // OpportunityTriggerHandler.changeClosedWonOppLineItemStatus(Trigger.new, Trigger.oldMap);
        }
    }
}