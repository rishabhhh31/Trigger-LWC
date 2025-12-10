public with sharing class OpportunityTriggerHandler {

    public static void addRolesForClosedWon(List<Opportunity> newList, Map<Id, Opportunity> oldMap, Boolean isUpdate) {
        
        // Get Opportunities that are converted to Closed Won
        Map<Id, Opportunity> oppsToProcess = getClosedWonOpps(newList, oldMap, isUpdate);

        // Exit early if no Opportunity meets criteria
        if (oppsToProcess.isEmpty()) {
            return;
        }

        // Fetch all Contacts related to the Opportunity Accounts
        Map<Id, List<Contact>> contactsByAccount = getContactsByAccount(oppsToProcess);

        // Fetch existing OCRs to prevent duplicate records
        Map<Id, Set<Id>> existingRoles = getExistingOCRs(oppsToProcess.keySet());

        // Create new OCR records
        List<OpportunityContactRole> ocrToInsert = createOCRs(oppsToProcess, contactsByAccount, existingRoles);

        // Insert OCRs with partial success enabled
        if (!ocrToInsert.isEmpty()) {
            /*
            Note: If you prefer strict behavior, use 'insert ocrToInsert;' instead.
            */
            Database.insert(ocrToInsert, false);
        }
    }


    // Filter Opportunities that converted to Closed Won
    private static Map<Id, Opportunity> getClosedWonOpps(List<Opportunity> newList, Map<Id, Opportunity> oldMap, Boolean isUpdate ) {
        Map<Id, Opportunity> result = new Map<Id, Opportunity>();

        for (Opportunity opp : newList) {
            Opportunity oldOpp = isUpdate ? oldMap.get(opp.Id) : null;

            Boolean nowClosedWon = (opp.IsClosed && opp.IsWon);  // current opportunity
            Boolean wasClosedWon = (oldOpp != null && oldOpp.IsClosed && oldOpp.IsWon); // previous opportunity

            // Add only newly Closed Won Opportunities with an Account
            if (nowClosedWon && !wasClosedWon && opp.AccountId != null) {
                result.put(opp.Id, opp);
            }
        }
        return result;
    }


    // Query Contacts belonging to all involved Accounts
    private static Map<Id, List<Contact>> getContactsByAccount(Map<Id, Opportunity> opps) {
        Set<Id> accountIds = new Set<Id>();

        // Collect account Ids
        for (Opportunity opp : opps.values()) {
            accountIds.add(opp.AccountId);
        }

        Map<Id, List<Contact>> contactsByAccount = new Map<Id, List<Contact>>();

        // Query all Contacts under those Accounts
        for (Contact con : [
            SELECT Id, AccountId
            FROM Contact
            WHERE AccountId IN :accountIds
        ]) {
            // Group contacts by Account Id
            if (!contactsByAccount.containsKey(con.AccountId)) {
                contactsByAccount.put(con.AccountId, new List<Contact>());
            }
            contactsByAccount.get(con.AccountId).add(con);
        }

        return contactsByAccount;
    }


    // Query existing OpportunityContactRoles
    private static Map<Id, Set<Id>> getExistingOCRs(Set<Id> oppIds) {
        Map<Id, Set<Id>> existing = new Map<Id, Set<Id>>();

        for (OpportunityContactRole ocr : [
            SELECT OpportunityId, ContactId
            FROM OpportunityContactRole
            WHERE OpportunityId IN :oppIds
        ]) {
            // Add OCRs grouped by OpportunityId
            if (!existing.containsKey(ocr.OpportunityId)) {
                existing.put(ocr.OpportunityId, new Set<Id>());
            }
            existing.get(ocr.OpportunityId).add(ocr.ContactId);
        }

        return existing;
    }


    // Create new OCR records, skipping duplicates
    private static List<OpportunityContactRole> createOCRs(
        Map<Id, Opportunity> opps,
        Map<Id, List<Contact>> contactsByAccount,
        Map<Id, Set<Id>> existingRoles
    ) {
        List<OpportunityContactRole> ocrToInsert = new List<OpportunityContactRole>();

        for (Id oppId : opps.keySet()) {
            Opportunity opp = opps.get(oppId);
            List<Contact> contacts = contactsByAccount.get(opp.AccountId);

            // Skip if no related Contacts
            if (contacts == null || contacts.isEmpty()) {
                continue;
            }

            for (Contact con : contacts) {

                // Skip if OCR already exists for this (Opp, Contact)
                if (existingRoles.containsKey(oppId) &&
                    existingRoles.get(oppId).contains(con.Id)) {
                    continue;
                }

                // Create new OCR record
                ocrToInsert.add(new OpportunityContactRole(
                    OpportunityId = oppId,
                    ContactId = con.Id,
                    Role = 'Family Member',
                    IsPrimary = false
                ));
            }
        }

        return ocrToInsert;
    }


    /**
    * @description
    * Performs multiple business validations on Opportunity records before insert or update.
    * Validates stage progression, probability thresholds, required fields, and account consistency.
    *
    * @param opportunityList List of Opportunity records (typically Trigger.new)
    */
    public static void validateOpportunities(List<Opportunity> opportunityList) {
        // Map defining the minimum probability per stage
        Map<String, Integer> stageMinimumProbabilityMap = new Map<String, Integer>{
            'Prospecting' => 10,
            'Qualification' => 20,
            'Needs Analysis' => 30,
            'Value Proposition' => 40,
            'Id. Decision Makers' => 50,
            'Perception Analysis' => 60,
            'Proposal/Price Quote' => 70,
            'Negotiation/Review' => 80,
            'Closed Won' => 100,
            'Closed Lost' => 0
        };

        // Collect all related Account Ids from the Opportunities
        Set<Id> relatedAccountIds = new Set<Id>();
        for (Opportunity oppRecord : opportunityList) {
            if (oppRecord.AccountId != null) {
                relatedAccountIds.add(oppRecord.AccountId);
            }
        }

        // Query Accounts once — no SOQL inside loops
        Map<Id, Account> relatedAccountMap = new Map<Id, Account>(
            [SELECT Id, Type FROM Account WHERE Id IN :relatedAccountIds]
        );

        // Define valid stage order for sequential progression validation
        List<String> validStageOrder = new List<String>{
            'Prospecting', 
            'Qualification', 
            'Needs Analysis', 
            'Value Proposition',
            'Id. Decision Makers', 
            'Perception Analysis', 
            'Proposal/Price Quote',
            'Negotiation/Review', 
            'Closed Won'
        };

        // Loop through each Opportunity record to validate
        for (Opportunity currentOpp : opportunityList) {
            Opportunity previousOpp = Trigger.isUpdate ? (Opportunity) Trigger.oldMap.get(currentOpp.Id) : null;

            // 1️⃣ Validation: CloseDate cannot be in the past for certain stages
            if (currentOpp.StageName == 'Proposal/Price Quote' || currentOpp.StageName == 'Negotiation/Review') {
                if (currentOpp.CloseDate != null && currentOpp.CloseDate < Date.today()) {
                    currentOpp.CloseDate.addError('Close Date cannot be in the past for the "' + currentOpp.StageName + '" stage.');
                }
            }

            // 2️⃣ Validation: Probability must meet minimum stage threshold
            if (stageMinimumProbabilityMap.containsKey(currentOpp.StageName)) {
                Integer minimumProbability = stageMinimumProbabilityMap.get(currentOpp.StageName);
                if (currentOpp.Probability != null && currentOpp.Probability < minimumProbability) {
                    currentOpp.Probability.addError('Probability must be at least ' + minimumProbability + '% for the "' + currentOpp.StageName + '" stage.');
                }
            }

            // 3️⃣ Validation: Amount is required when stage is Proposal/Price Quote
            if (currentOpp.StageName == 'Proposal/Price Quote' && currentOpp.Amount == null) {
                currentOpp.Amount.addError('Amount is required when Opportunity reaches the "Proposal/Price Quote" stage.');
            }

            // 4️⃣ Validation: Cannot create new customer Opportunity for existing customer Account
            if (currentOpp.AccountId != null && relatedAccountMap.containsKey(currentOpp.AccountId)) {
                Account relatedAccount = relatedAccountMap.get(currentOpp.AccountId);
                if (relatedAccount.Type == 'Customer' && currentOpp.Type == 'New Customer') {
                    currentOpp.Type.addError('Cannot create a "New Customer" Opportunity for an Account that is already a Customer.');
                }
            }

            // 5️⃣ Validation: Ensure stage progression is sequential (cannot skip stages)
            if (Trigger.isUpdate && previousOpp != null && previousOpp.StageName != currentOpp.StageName) {
                if (validStageOrder.contains(previousOpp.StageName) && validStageOrder.contains(currentOpp.StageName)) {
                    Integer previousStageIndex = validStageOrder.indexOf(previousOpp.StageName);
                    Integer currentStageIndex = validStageOrder.indexOf(currentOpp.StageName);

                    // Allow forward movement by only one stage or direct move to Closed Lost
                    if (currentStageIndex - previousStageIndex > 1 && currentOpp.StageName != 'Closed Lost') {
                        currentOpp.StageName.addError('Cannot skip stages. Progress through each stage sequentially.');
                    }
                }
            }
        }
    }

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