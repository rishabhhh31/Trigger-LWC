public with sharing class CreateDeploymentStory {
    @AuraEnabled
    public static String createStory(String components) {
        DeploymentWrapper dw = new DeploymentWrapper();
        dw.workItemId = 'WI1234567890123456';
        dw.projectId = 'PR1234567890123456';
        dw.epicId = 'EP1234567890123456';
        dw.components = components;
        String requestBody = JSON.serialize(dw);
        return createRequest(requestBody);
    }

    public static String createRequest(String jsonString){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:SalesforceQANamed/services/apexrest/deployment');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(jsonString);
        try {
            HttpResponse response = http.send(request);
            System.debug(response.getStatusCode());
            System.debug(response.getBody());
            if (response.getStatusCode() == 201) {
                return getFormattedString(response.getBody());
            } else {
                return String.valueOf('Request Failed because '+getFormattedString(response.getBody())+'. Status code: ' + response.getStatusCode());
            }
        } catch (Exception e) {
            return String.valueOf('Exception during callout: ' + e.getMessage());
        }
    }

    public static String getFormattedString(String responseBody){
        return responseBody.replace('{', '(').replace('}', ')');
    }

    public class DeploymentWrapper{
        public String workItemId;
        public String projectId;
        public String epicId;
        public String components;
    }
}