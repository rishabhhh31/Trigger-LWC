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

    public static void sendEmailToHighValueOpportunity(List<Opportunity> opportunityList) {
        // Initialize a list to hold all email messages
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();

        // Loop through all opportunities passed to the method
        for (Opportunity opportunityRecord : opportunityList) {
            // Check if the Opportunity qualifies as high-value
            if (opportunityRecord.Amount > 100000) {
                // Create a new email message instance
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

                // Set recipient email address (replace with a dynamic or business email as needed)
                email.setToAddresses(new String[]{'rishabhh3103@gmail.com'});

                // Set subject line including Opportunity name
                email.setSubject('🎉 Congratulations! High Value Opportunity: ' + opportunityRecord.Name);

                // Add unsubscribe URLs for compliance (List-Unsubscribe header)
                email.setUnsubscribeUrls(new List<String>{'https://www.google.com'});

                // Enable one-click unsubscribe functionality for supported clients
                email.setOneClickPost(true);

                // Set 'In-Reply-To' header for email threading (optional)
                email.setInReplyTo('rishabh3123jain@gmail.com');

                // Build plain text email body
                String emailBody = 'A new high-value opportunity has been created.\n\n';
                emailBody += 'Opportunity Name: ' + opportunityRecord.Name + '\n';
                emailBody += 'Amount: $' + opportunityRecord.Amount + '\n';
                emailBody += 'Owner: ' + UserInfo.getName() + '\n\n';
                emailBody += 'To unsubscribe, click here: https://www.google.com'; // Visible unsubscribe link
                email.setPlainTextBody(emailBody);

                // Display sender’s name in the email
                email.setSenderDisplayName(UserInfo.getName());

                // Optional comment for List-Unsubscribe header (not visible to recipients)
                email.unsubscribeComment = 'Email unsubscribe support for marketing or system notifications.';

                // Add the prepared message to the message list
                emailMessages.add(email);
            }
        }

        // Send all collected emails if any exist
        if (!emailMessages.isEmpty()) {
            Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(emailMessages);

            // Check and log the email send status
            if (sendResults[0].success) {
                System.debug('✅ The email was sent successfully.');
            } else {
                System.debug('❌ The email failed to send: ' + sendResults[0].errors[0].message);
            }
        }
    }
}