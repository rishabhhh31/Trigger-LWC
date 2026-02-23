public with sharing class OrderTriggerHandler {
    public static void newOrderDateAccountUpdate(List<Order> orders) {
        Set<Id> accIds = new Set<Id>();
        Map<Id, Account> accountMap = new Map<Id, Account>();
        for(Order ord : orders){
            if(ord.AccountId != null){
                if(!accountMap.containsKey(ord.AccountId)){
                    Account acc = new Account(Id = ord.AccountId);
                    accountMap.put(ord.AccountId, acc);
                }
                accountMap.get(ord.AccountId).Last_Order_Date_Time__c = ord.CreatedDate;
            }
        }

        if(accountMap.isEmpty()) return;
        
        update accountMap.values();
    }
}