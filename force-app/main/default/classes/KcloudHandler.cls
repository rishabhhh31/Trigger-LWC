public with sharing class KcloudHandler {
    @AuraEnabled(cacheable = true)
    public static List<Account> getAccounts(){
        try {
            return [SELECT Id, Name, Rating, Industry, Type FROM Account ORDER BY Name LIMIT 50000];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean deleteAccount(Account acc){
        try {
            delete acc;
            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}