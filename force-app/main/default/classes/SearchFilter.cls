public with sharing class SearchFilter {
    @AuraEnabled(cacheable = true)
    public static List<CaseWrapper> getAllCases(){
        List<CaseWrapper> cases = new List<CaseWrapper>();
        for(Case cs : [SELECT Id, CaseNumber, Status, Priority, CreatedDate FROM Case ORDER BY CaseNumber]){
            CaseWrapper caseWrap = new CaseWrapper();
            caseWrap.Id = cs.Id;
            caseWrap.CaseNumber = cs.CaseNumber;
            caseWrap.Status = cs.Status;
            caseWrap.Priority = cs.Priority;
            caseWrap.CreatedDate = cs.CreatedDate.date();
            cases.add(caseWrap);
        }
        return cases;
    }

    public class CaseWrapper{
        @AuraEnabled
        public String Id {get;set;}
        @AuraEnabled
        public String CaseNumber {get;set;}
        @AuraEnabled
        public String Status {get;set;}
        @AuraEnabled
        public String Priority {get;set;}
        @AuraEnabled
        public Date CreatedDate {get;set;}
    }
}