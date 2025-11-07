public with sharing class OuterClass {
    @AuraEnabled(cacheable = true)
    public static List<Contact> getContacts(){
        try {
            InnerClass i = new InnerClass();
            return i.showContacts();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public class InnerClass {
        public List<Contact> showContacts() {
            return [SELECT Id, Name, Phone, Email FROM Contact];
        }
    }
}