public with sharing class ApexSecurity {
    // @AuraEnabled(cacheable = true)
    // public static List<Account> getAccounts(){
    //     try {
    //         return [SELECT Id,Total_Budget__c, Total_Opportunity__c, Name, Rating, Industry FROM Account WITH USER_MODE LIMIT 50000];
    //     } catch(QueryException e) {
    //         throw new AuraHandledException(e.getMessage());
    //     } catch(Exception e){
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }

    @AuraEnabled(cacheable = true)
    public static List<Account> getAccounts(){
        try {
            return [SELECT Id, Name, Rating FROM Account WITH SECURITY_ENFORCED LIMIT 50000];
        } catch(QueryException e) {
            throw new AuraHandledException(e.getMessage());
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string createAccount(){
        try {
            Schema.DescribeSObjectResult accDesc = Account.SObjectType.getDescribe();
            if(!accDesc.createable){
                throw new AuraHandledException('User do not have access to create the record');
            }
            Account acc = new Account(Name='Test');
            acc.Industry = 'Banking';
            insert as user acc;
            return acc.Id;
        } catch (Exception e) {
            return e.getMessage();
        }
    }

    @AuraEnabled
    public static String checkFieldAccessForAccount(){
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Rating = 'Hot';
        acc.Industry = 'Banking';
        
        SObjectAccessDecision decision = Security.stripInaccessible(
                                            AccessType.READABLE,
                                            new List<Account>{acc});
        
                                            
        insert decision.getRecords();
        return JSON.serializePretty([SELECT ID FROM Account WITH USER_MODE]);
    }

    @AuraEnabled
    public static string getTaskEvents(){
        try {
            return JSON.serializePretty([SELECT Id, What.Name FROM Task WHERE WhatId != null WITH USER_MODE ]);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string getTaskTypeOfEvents(){
        try {
            // return JSON.serializePretty([SELECT 
            //                             TYPEOF What 
            //                             WHEN Account THEN Name, Phone 
            //                             WHEN Opportunity THEN Name, CloseDate, StageName 
            //                             END 
            //                             FROM Task]);
            return JSON.serializePretty([SELECT Id, Owner.Name, CreatedBy.Username
                                            FROM Account
                                            WITH SECURITY_ENFORCED
                                        ]);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}