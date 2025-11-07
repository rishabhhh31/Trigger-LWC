global class CalloutBatchExample implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful{
    List<Account> accountList;
    public CalloutBatchExample(){
        accountList = new List<Account>();
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id FROM Account]);
    }

    global void execute(Database.BatchableContext bc, List<Account> accounts) {
        accountList.addAll(accounts);
    }

    global void finish(Database.BatchableContext bc) {
        //If size is more than 100, it will throw an exception Too many callout:101
        System.debug(accountList.size());
        for(Account acc : accountList){
            String response = ChatGPTCallouts.askChatGpt('Hello There');
            System.debug(response);
        }
    }
}