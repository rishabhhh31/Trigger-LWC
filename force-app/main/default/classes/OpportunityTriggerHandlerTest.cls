@IsTest
private class OpportunityTriggerHandlerTest {
    // Helper to create a StageName
    static String closedWonStage = 'Closed Won';

    @IsTest static void testInsertClosedWonCreatesRoles() {
        // Setup data
        Account acc = new Account(Name = 'Account 1');
        insert acc;

        Contact con1 = new Contact(FirstName='Test', LastName='User 1', AccountId = acc.Id);
        Contact con2 = new Contact(FirstName='Test', LastName='User 2', AccountId = acc.Id);
        insert new List<Contact>{con1, con2};

        // Insert an Opportunity already Closed & Won
        Opportunity opp = new Opportunity(
            Name = 'Opp Closed Won Insert',
            AccountId = acc.Id,
            CloseDate = Date.today().addDays(30),
            StageName = closedWonStage
        );
        insert opp;

        // Verify OpportunityContactRole records created for both contacts
        List<OpportunityContactRole> ocrs = [
            SELECT Id, OpportunityId, ContactId, Role
            FROM OpportunityContactRole
            WHERE OpportunityId = :opp.Id
        ];
        Assert.areEqual(2, ocrs.size(), 'Two contact roles should be created');

        Set<Id> contactIds = new Set<Id>();
        for (OpportunityContactRole ocr : ocrs) {
            contactIds.add(ocr.ContactId);
        }
        Assert.isTrue(contactIds.contains(con1.Id), 'Opportunity Role should be created for Contact 1.');
        Assert.isTrue(contactIds.contains(con2.Id), 'Opportunity Role should be created for Contact 2.');
    }

    @IsTest static void testUpdateToClosedWonCreatesRolesAndNoDuplicates() {
        // Setup data
        Account acc = new Account(Name = 'Account 1');
        insert acc;

        Contact con1 = new Contact(FirstName='Test', LastName='User 1', AccountId = acc.Id);
        Contact con2 = new Contact(FirstName='Test', LastName='User 2', AccountId = acc.Id);
        insert new List<Contact>{con1, con2};

        // Insert Opportunity NOT closed/won
        Opportunity opp = new Opportunity(
            Name = 'Opp to Update',
            AccountId = acc.Id,
            CloseDate = Date.today().addDays(10),
            StageName = 'Prospecting'
        );
        insert opp;

        // Update to Closed & Won - should create 2 OCRs
        opp.StageName = closedWonStage;
        update opp;

        List<OpportunityContactRole> ocrs = [
            SELECT Id, OpportunityId, ContactId
            FROM OpportunityContactRole
            WHERE OpportunityId = :opp.Id
        ];
        Assert.areEqual(2, ocrs.size(), 'Two contact roles should be created');

        // Update again to Closed Won — should NOT create duplicates
        update opp;

        List<OpportunityContactRole> ocrsAfter = [
            SELECT Id, OpportunityId, ContactId
            FROM OpportunityContactRole
            WHERE OpportunityId = :opp.Id
        ];
        Assert.areEqual(2, ocrsAfter.size(), 'No duplicate contact roles should be created on repeated update');
    }

    @IsTest static void testDoesNotRunForOtherStages() {
        Account acc = new Account(Name = 'Account 1');
        insert acc;

        Contact con1 = new Contact(FirstName='Test', LastName='User 1', AccountId = acc.Id);
        insert new List<Contact>{con1};

        Opportunity opp = new Opportunity(
            Name = 'Opp Not Closed Won',
            AccountId = acc.Id,
            CloseDate = Date.today().addDays(5),
            StageName = 'Prospecting'
        );
        insert opp;

        // Ensure no OCR created
        List<OpportunityContactRole> ocrs = [
            SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :opp.Id
        ];
        Assert.areEqual(0, ocrs.size(), 'No contact roles should be created for non-Closed/Won opps');

        // Update some field, still should not create OCRs
        opp.Name = 'Changed name';
        update opp;

        List<OpportunityContactRole> ocrs2 = [
            SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :opp.Id
        ];
        Assert.areEqual(0, ocrs2.size(), 'Still no contact roles should be created for non-Closed Won opps after updates');
    }

    @IsTest static void testNoRoleCreatedNoContacts() {
        Account acc = new Account(Name = 'Account 1');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Opp Closed Won',
            AccountId = acc.Id,
            CloseDate = Date.today().addDays(5),
            StageName = closedWonStage
        );
        insert opp;

        // Ensure no OCR created
        List<OpportunityContactRole> ocrs = [
            SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :opp.Id
        ];
        Assert.areEqual(0, ocrs.size(), 'No contact roles should be created for accounts with no contacts');
    }

     @IsTest static void testExistingOCRs() {
        Account acc = new Account(Name = 'Account 1');
        insert acc;

        Contact con1 = new Contact(FirstName='Test', LastName='User 1', AccountId = acc.Id);
        insert new List<Contact>{con1};

        Opportunity opp = new Opportunity(
            Name = 'Opp Not Closed Won',
            AccountId = acc.Id,
            CloseDate = Date.today().addDays(5),
            StageName = 'Prospecting'
        );
        insert opp;

        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.OpportunityId = opp.Id;
        ocr.ContactId = con1.Id;
        ocr.Role = 'Family Member';
        ocr.IsPrimary = false;
        insert ocr;

        opp.StageName = closedWonStage;
        update opp;

        // Ensure no OCR created
        List<OpportunityContactRole> ocrs = [
            SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :opp.Id
        ];
        Assert.areEqual(1, ocrs.size(), 'No new contact roles should be created for accounts with existing OCRs');
    }
}