public with sharing class BulkMultipartAccountService {

    private static final String API_VERSION = 'v63.0';
    private static final String BOUNDARY = '----MyBoundary12345';

    @AuraEnabled
    public static String createMultipartBulkInsert() {

        // 1️⃣ Prepare CSV Data
        String csvData =
            'Name,ShippingStreet,ShippingCity,ShippingState,ShippingPostalCode,ShippingCountry,Phone,Website,NumberOfEmployees,AnnualRevenue,Industry,Description\n' +
            'TechNova Solutions,123 Market St,San Francisco,CA,94105,USA,4155551000,https://technova.com,250,7500000,Technology,Cloud software provider\n' +
            'GreenField Agriculture,45 Farm Road,Dallas,TX,75201,USA,2145552000,https://greenfieldagri.com,120,3200000,Agriculture,Sustainable farming company\n' +
            'BlueWave Consulting,78 King Street,London,,EC2V 8AU,UK,02079460000,https://bluewave.co.uk,85,2100000,Consulting,Business advisory services\n';

        // 2️⃣ Prepare JSON Job Metadata
        String jobJson = JSON.serialize(new Map<String,Object>{
            'object' => 'Account',
            'contentType' => 'CSV',
            'operation' => 'insert',
            'lineEnding' => 'LF'
        });

        // 3️⃣ Build Multipart Body
        String requestBody =
            '--' + BOUNDARY + '\n' +
            'Content-Type: application/json\n' +
            'Content-Disposition: form-data; name="job"\n\n' +
            jobJson + '\n\n' +

            '--' + BOUNDARY + '\n' +
            'Content-Type: text/csv\n' +
            'Content-Disposition: form-data; name="content"; filename="accounts.csv"\n\n' +
            csvData + '\n' +

            '--' + BOUNDARY + '--';

        // 4️⃣ Create HTTP Request
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Salesforce/services/data/' + API_VERSION + '/jobs/ingest/');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'multipart/form-data; boundary=' + BOUNDARY);
        req.setHeader('Accept', 'application/json');
        req.setBody(requestBody);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200 && res.getStatusCode() != 201) {
            throw new AuraHandledException('Bulk job creation failed: ' + res.getBody());
        }

        Map<String,Object> responseMap =
            (Map<String,Object>) JSON.deserializeUntyped(res.getBody());

        return (String) responseMap.get('id');
    }

    @AuraEnabled
    public static String checkJobStatus(String jobId) {

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Salesforce/services/data/' + API_VERSION +
                        '/jobs/ingest/' + jobId);
        req.setMethod('GET');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            throw new AuraHandledException('Status check failed: ' + res.getBody());
        }

        return res.getBody();
    }

    @AuraEnabled
    public static String getSuccessfulResults(String jobId) {

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Salesforce/services/data/' + API_VERSION +
                        '/jobs/ingest/' + jobId + '/successfulResults/');
        req.setMethod('GET');
        req.setHeader('Accept', 'text/csv');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            throw new AuraHandledException('Failed to get results: ' + res.getBody());
        }

        return res.getBody();
    }
}