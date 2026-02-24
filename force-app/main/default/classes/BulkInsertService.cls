public with sharing class BulkInsertService {

    private static final String API_VERSION = 'v61.0';

    @AuraEnabled
    public static String startBulkInsert() {

        // 1️⃣ Create Job
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Salesforce/services/data/' + API_VERSION + '/jobs/ingest');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        Map<String, Object> body = new Map<String, Object>{
            'object' => 'Account',
            'contentType' => 'CSV',
            'operation' => 'insert',
            'lineEnding' => 'CRLF'
        };

        req.setBody(JSON.serialize(body));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if(res.getStatusCode() != 200 && res.getStatusCode() != 201){
            throw new AuraHandledException('Job creation failed: ' + res.getBody());
        }

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

        String jobId = (String) responseMap.get('id');

        // 2️⃣ Upload Sample CSV Data
        uploadCSV(jobId);

        // 3️⃣ Mark Upload Complete
        markUploadComplete(jobId);

        return jobId;
    }

    private static void uploadCSV(String jobId) {

        String csvData = 'Name,ShippingCity,NumberOfEmployees,AnnualRevenue,Website,Description\n' +
                         'Tech Corp,New York,200,5000000,https://techcorp.com,Software Company\n' +
                         'Global Inc,London,150,3000000,https://global.com,Consulting Firm\n';

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Salesforce/services/data/' + API_VERSION + 
                        '/jobs/ingest/' + jobId + '/batches');
        req.setMethod('PUT');
        req.setHeader('Content-Type', 'text/csv');
        req.setBody(csvData);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if(res.getStatusCode() != 201 && res.getStatusCode() != 200){
            throw new AuraHandledException('CSV upload failed: ' + res.getBody());
        }
    }

    private static void markUploadComplete(String jobId){

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Salesforce/services/data/' + API_VERSION + 
                        '/jobs/ingest/' + jobId);
        req.setMethod('PATCH');
        req.setHeader('Content-Type', 'application/json');

        req.setBody('{ "state" : "UploadComplete" }');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if(res.getStatusCode() != 200){
            throw new AuraHandledException('Failed to mark UploadComplete: ' + res.getBody());
        }
    }

    @AuraEnabled
    public static String checkJobStatus(String jobId){

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Salesforce/services/data/' + API_VERSION + 
                        '/jobs/ingest/' + jobId);
        req.setMethod('GET');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if(res.getStatusCode() != 200){
            throw new AuraHandledException('Status check failed: ' + res.getBody());
        }

        return res.getBody();
    }
}