trigger OpportunityTrigger on Opportunity (after update) {
    if(Trigger.isAfter){
        if(Trigger.isUpdate){
            OpportunityTriggerHandler.changeClosedWonOppLineItemStatus(Trigger.new, Trigger.oldMap);
        }
    }
}