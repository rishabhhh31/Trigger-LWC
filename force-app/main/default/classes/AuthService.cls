public with sharing class AuthService {
    @AuraEnabled
    public static String handleClientCredentialsFlow(String metadataId) {
        try {
            Salesforce_Authorization__mdt metadataType = [
                SELECT Id, MasterLabel, DeveloperName, Access_Token__c, Expire_Time__c,
                Client_Id__c, Client_Secret__c, Base_URL__c
                FROM Salesforce_Authorization__mdt
                WHERE Id = :metadataId
                LIMIT 1
            ];

            String baseUrl = metadataType.Base_URL__c;
            String clientId = metadataType.Client_Id__c;
            String clientSecret = metadataType.Client_Secret__c;
            String tokenStatus = 'Expired';

            // Proceed only if token is expired or missing
            if (metadataType.Expire_Time__c == null || metadataType.Expire_Time__c < System.now()) {
                String tokenUrl = baseUrl + '/services/oauth2/token';

                HttpRequest req = new HttpRequest();
                req.setEndpoint(tokenUrl);
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

                String body = 'grant_type=client_credentials'
                            + '&client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8')
                            + '&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8');
                req.setBody(body);

                Http http = new Http();
                HttpResponse res = http.send(req);

                if (res.getStatusCode() == 200) {
                    Map<String, Object> tokenResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    String accessToken = (String) tokenResponse.get('access_token');

                    Map<String, Object> fieldMap = new Map<String, Object>();
                    fieldMap.put('Access_Token__c', accessToken);
                    fieldMap.put('Expire_Time__c', System.now().addHours(1));
                    fieldMap.put('DeveloperName', metadataType.DeveloperName);
                    fieldMap.put('Label', metadataType.MasterLabel);

                    Id jobId = CreateUpdateMetadataUtils.updateAndDeployMetadata(fieldMap, true);
                    return jobId;
                }
            } else if (metadataType.Access_Token__c != null) {
                tokenStatus = 'Valid';
            }

            return tokenStatus;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}