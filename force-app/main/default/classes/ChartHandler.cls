public with sharing class ChartHandler {
    @AuraEnabled
    public static Map<String,Integer> getOpportunitiesByStages(){
        try {
            Map<String,Integer> stageMap = new Map<String,Integer>();
            for(AggregateResult result : [SELECT count(Id)oppCounts, StageName FROM Opportunity GROUP BY StageName]){
                String stage = (String) result.get('StageName');
                Integer count = (Integer) result.get('oppCounts');
                stageMap.put(stage, count);
            }
            return stageMap;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Integer> getAccountsByIndustry() {
        Map<String, Integer> industryCounts = new Map<String, Integer>();

        for (AggregateResult ar : [
            SELECT Industry, COUNT(Id) total
            FROM Account
            WHERE Industry != null
            GROUP BY Industry
            ORDER BY COUNT(Id) DESC
        ]) {
            industryCounts.put((String)ar.get('Industry'), (Integer)ar.get('total'));
        }

        return industryCounts;
    }

    @AuraEnabled
    public static Map<String, Integer> getCasesByStatus() {
        Map<String, Integer> caseCountByStatus = new Map<String, Integer>();

        for (AggregateResult ar : [
            SELECT Status, COUNT(Id) total
            FROM Case
            GROUP BY Status
            ORDER BY COUNT(Id) DESC
        ]) {
            caseCountByStatus.put((String)ar.get('Status'), (Integer)ar.get('total'));
        }

        return caseCountByStatus;
    }
}