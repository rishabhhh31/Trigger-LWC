public with sharing class OpportunityTriggerHandler {

    /**
     * Updates all OpportunityLineItems' Status__c field to 'Won'
     * when their parent Opportunity is moved to Stage = 'Closed Won'.
     * 
     * @param newOpp List of updated Opportunity records (Trigger.new)
     * @param oldOpps Map of old Opportunity records (Trigger.oldMap)
     */
    public static void changeClosedWonOppLineItemStatus(
        List<Opportunity> newOpp, 
        Map<Id, Opportunity> oldOpps
    ) {
        // Collect Opportunity Ids where Stage changed to 'Closed Won'
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : newOpp) {
            if (opp.StageName == 'Closed Won' &&
                oldOpps.get(opp.Id).StageName != 'Closed Won') {
                oppIds.add(opp.Id);
            }
        }

        // Exit early if no relevant Opportunities
        if (oppIds.isEmpty()) {
            return;
        }

        // Query related OpportunityLineItems for those Opportunities
        // Use 'WITH USER_MODE' to respect current user's sharing/access
        List<OpportunityLineItem> lineItems = [
            SELECT Id, Status__c
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppIds
            WITH USER_MODE
            LIMIT 50000
        ];

        // Exit early if no line items found
        if (lineItems.isEmpty()) {
            return;
        }

        // Update each line item's custom Status field to 'Won'
        for (OpportunityLineItem item : lineItems) {
            item.Status__c = 'Won';
        }

        // Perform a single bulk DML update
        update lineItems;
    }
}