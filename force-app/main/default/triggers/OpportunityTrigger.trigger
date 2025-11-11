trigger OpportunityTrigger on Opportunity (after insert, after update) {
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            // OpportunityTriggerHandler.sendEmailToHighValueOpportunity(Trigger.new);
            OpportunityTriggerHandler.validateOpportunities(Trigger.new);
        }
        if(Trigger.isUpdate){
            OpportunityTriggerHandler.validateOpportunities(Trigger.new);
            // OpportunityTriggerHandler.changeClosedWonOppLineItemStatus(Trigger.new, Trigger.oldMap);
        }
    }
}