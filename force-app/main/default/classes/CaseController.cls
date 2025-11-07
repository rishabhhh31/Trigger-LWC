public with sharing class CaseController {
    @AuraEnabled(cacheable=true)
    public static List<CaseWrapper> getTeamCases(){
        try {
            User us = [SELECT ManagerId FROM User WHERE Id=: UserInfo.getUserId() LIMIT 1];
            Set<Id> userIds = new Set<Id>();
            for(User user : [SELECT Id FROM User WHERE ManagerId=:us.ManagerId]){
                userIds.add(user.Id);
            }
            List<CaseWrapper> caseList = new List<CaseWrapper>();
            for(Case cs : [SELECT Id, CaseNumber, Subject, Status, Priority, OwnerId, Owner.Name FROM Case WHERE OwnerId IN: userIds]){
                CaseWrapper cw = new CaseWrapper();
                cw.caseId = cs.Id;
                cw.status = cs.Status;
                cw.caseNumber = cs.CaseNumber;
                cw.priority = cs.Priority;
                cw.ownerId = cs.OwnerId;
                cw.ownerName = cs.Owner.Name;
                cw.subject = cs.Subject;
                caseList.add(cw);
            }
            return caseList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class CaseWrapper{
        @AuraEnabled
        public String caseId;
        @AuraEnabled
        public String caseNumber;
        @AuraEnabled
        public String subject;
        @AuraEnabled
        public String priority;
        @AuraEnabled
        public String ownerId;
        @AuraEnabled
        public String ownerName;
        @AuraEnabled
        public String status;
    }
}