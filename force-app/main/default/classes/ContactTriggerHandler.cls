public class ContactTriggerHandler {
    // Rolls up total contact count to related Accounts
    public static void updateAccountContactCounts(List<Contact> newContacts, Map<Id, Contact> oldContacts) {
        Set<Id> accountIds = new Set<Id>();

        for (Contact newContact : newContacts) {
            // Insert scenario
            if (oldContacts == null) { 
                if (newContact.AccountId != null) {
                    accountIds.add(newContact.AccountId);
                }
            } else {
                // Update scenario
                Contact oldContact = oldContacts.get(newContact.Id);
                if (newContact.AccountId != oldContact.AccountId) {
                    if (newContact.AccountId != null) {
                        accountIds.add(newContact.AccountId);
                    }
                    if (oldContact.AccountId != null) {
                        accountIds.add(oldContact.AccountId);
                    }
                }
            }
        }

        if (accountIds.isEmpty()) return;

        Map<Id, Integer> contactCountByAccountId = new Map<Id, Integer>();
        for (AggregateResult ar : [
                                  SELECT COUNT(Id) contactCount, AccountId 
                                  FROM Contact 
                                  WHERE AccountId IN :accountIds 
                                  GROUP BY AccountId
        ]) {
            Id accountId = (Id) ar.get('AccountId');
            Integer contactCount = (Integer) ar.get('contactCount');
            contactCountByAccountId.put(accountId, contactCount);
        }

        List<Account> accountsToUpdate = new List<Account>();

        for (Id accountId : accountIds) {
            Integer contactCount = contactCountByAccountId.containsKey(accountId) ? contactCountByAccountId.get(accountId) : 0;
            accountsToUpdate.add(new Account( Id = accountId, Number_of_contacts__c = contactCount ));
        }

        if (!accountsToUpdate.isEmpty()) {
            Database.update(accountsToUpdate);
        }
    }
}