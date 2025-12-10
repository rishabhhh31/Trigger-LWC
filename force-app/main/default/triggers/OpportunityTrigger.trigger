trigger OpportunityTrigger on Opportunity (after insert, after update) {
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            // OpportunityTriggerHandler.sendEmailToHighValueOpportunity(Trigger.new);
            // OpportunityTriggerHandler.validateOpportunities(Trigger.new);
            OpportunityTriggerHandler.addRolesForClosedWon(Trigger.new, Trigger.oldMap, Trigger.isUpdate);
        }
        if(Trigger.isUpdate){
            // OpportunityTriggerHandler.validateOpportunities(Trigger.new);
            // OpportunityTriggerHandler.changeClosedWonOppLineItemStatus(Trigger.new, Trigger.oldMap);
            OpportunityTriggerHandler.addRolesForClosedWon(Trigger.new, Trigger.oldMap, Trigger.isUpdate);
        }
    }
}