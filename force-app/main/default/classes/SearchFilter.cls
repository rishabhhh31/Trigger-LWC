public with sharing class SearchFilter {

    @AuraEnabled(cacheable=true)
    public static List<CaseWrapper> getAllCases(){

        List<CaseWrapper> results = new List<CaseWrapper>();

        for(Case cs : [
            SELECT Id, CaseNumber, Status, Priority, CreatedDate
            FROM Case
            ORDER BY CreatedDate DESC
        ]){

            results.add(new CaseWrapper(
                cs.Id,
                cs.CaseNumber,
                cs.Status,
                cs.Priority,
                cs.CreatedDate.date()
            ));
        }

        return results;
    }

    public class CaseWrapper {

        @AuraEnabled public Id Id;
        @AuraEnabled public String CaseNumber;
        @AuraEnabled public String Status;
        @AuraEnabled public String Priority;
        @AuraEnabled public Date CreatedDate;

        public CaseWrapper(Id id,String num,String status,String priority,Date created){
            this.Id = id;
            this.CaseNumber = num;
            this.Status = status;
            this.Priority = priority;
            this.CreatedDate = created;
        }
    }
}