public with sharing class ApplicationController {

    // Entry point: fetch picklist values for Loan & Job Application record types
    public static void getPicklistValueByRecordType() {
        Map<String, Schema.RecordTypeInfo> recordTypeInfo = Schema.SObjectType.Application__c.getRecordTypeInfosByDeveloperName();

        if (recordTypeInfo.containsKey('Loan_Application')) {
            createRequest('Application__c', recordTypeInfo.get('Loan_Application').getRecordTypeId(), 'Status__c');
        }
        if (recordTypeInfo.containsKey('Job_Application')) {
            createRequest('Application__c', recordTypeInfo.get('Job_Application').getRecordTypeId(), null);
        }
    }

    // Makes a UI API request to fetch picklist values for a record type
    private static void createRequest(String objectApiName, Id recordTypeId, String fieldApiName) {
        try {
            // Build endpoint dynamically
            String endpoint = URL.getOrgDomainUrl().toExternalForm()
                + '/services/data/v63.0/ui-api/object-info/'
                + objectApiName + '/picklist-values/' + recordTypeId;

            if (!String.isBlank(fieldApiName)) {
                endpoint += '/' + fieldApiName;
            }

            // Setup HTTP request
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            request.setHeader('Accept', 'application/json');
            request.setMethod('GET');

            HttpResponse response = new Http().send(request);

            // Handle API errors
            if (response.getStatusCode() != 200) {
                throw new AuraHandledException(
                    'Failed to fetch picklist values. Status: ' + response.getStatusCode() +
                    ', Message: ' + response.getStatus()
                );
            }

            System.debug('Picklist Values Response: ' + response.getBody());

        } catch (Exception e) {
            // Handle unexpected errors
            throw new AuraHandledException('Unexpected error: ' + e.getMessage());
        }
    }
}