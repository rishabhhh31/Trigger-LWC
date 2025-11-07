public with sharing class UIPicklistService {
    public static String getPicklistValues(String objectApiName, String recordTypeId, String fieldApiName) {
        List<String> values = new List<String>();
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        
        // Build URL (make sure to use the correct API version, e.g., v61.0)
        String endpoint = Url.getOrgDomainUrl().toExternalForm() +
            '/services/data/v61.0/ui-api/object-info/' + objectApiName +
            '/picklist-values/' + recordTypeId + '/' + fieldApiName;
        
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        
        HttpResponse res = h.send(req);
        return res.getBody();
    }
}