public with sharing class ProgressTrackerController {

    @AuraEnabled
    public static void updateProjectProgress(Id projectId, Integer progress) {

        try {

            Project__c project = [
                SELECT Id, Progress__c
                FROM Project__c
                WHERE Id = :projectId
                LIMIT 1
            ];

            project.Progress__c = progress;

            update project;

        }
        catch (Exception e) {

            throw new AuraHandledException(
                'Error updating project progress: ' + e.getMessage()
            );

        }

    }

}