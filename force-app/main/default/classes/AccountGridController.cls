public with sharing class AccountGridController {

	@AuraEnabled
    public static Account createAccount(Map<String, Object> accountData) {

        try {
			Account acc = new Account();
            acc.Name = (String) accountData.get('Name');
            acc.Industry = (String) accountData.get('Industry');
            acc.Type = (String) accountData.get('Type');
            acc.Phone = (String) accountData.get('Phone');
            insert acc;
			return acc;
        }
        catch (Exception e) {
            throw new AuraHandledException(
                'Error creating account: ' + e.getMessage()
            );
        }
    }

    @AuraEnabled
    public static void updateAccount(Id accountId, Map<String, Object> accountData) {

        try {
            Account acc = [
                SELECT Id
                FROM Account
                WHERE Id = :accountId
            ];
            acc.Name = (String) accountData.get('Name');
            acc.Industry = (String) accountData.get('Industry');
            acc.Type = (String) accountData.get('Type');
            acc.Phone = (String) accountData.get('Phone');
            update acc;
        }
        catch (Exception e) {
            throw new AuraHandledException(
                'Error updating account: ' + e.getMessage()
            );
        }
    }

    @AuraEnabled
    public static void deleteAccount(Id accountId) {
        try {
            Account acc = [
                SELECT Id
                FROM Account
                WHERE Id = :accountId
            ];
            delete acc;
        }
        catch (Exception e) {
            throw new AuraHandledException(
                'Error deleting account: ' + e.getMessage()
            );
        }
    }
}