public with sharing class CreateUpdateMetadataUtils implements Metadata.DeployCallback {

    // Called automatically when Metadata deployment completes
    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
        if (result.status == Metadata.DeployStatus.Succeeded) {
            System.debug('Deployment Succeeded');
        } else {
            System.debug('Deployment Failed: ' + result.errorMessage);
        }
    }

    @AuraEnabled
    public static String updateAndDeployMetadata(Map<String, Object> metadataFields, Boolean isUpdate) {
        try {
            // Extract key fields
            String label = (String) metadataFields.get('Label');
            String baseUrl = (String) metadataFields.get('Base_URL__c');
            String fullName = isUpdate  ? (String) metadataFields.get('DeveloperName') : generateApiName(label);

            // Validate duplicates only for new metadata
            if (!isUpdate) {
                validateDuplicateMetadata(fullName, baseUrl);
            }

            // Create Custom Metadata instance
            Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
            customMetadata.fullName = 'Salesforce_Authorization.' + fullName;
            customMetadata.label = label;
            customMetadata.values = new List<Metadata.CustomMetadataValue>();

            // Clean up redundant keys
            metadataFields.remove('Label');
            metadataFields.remove('DeveloperName');

            // Add all field values dynamically
            for (String key : metadataFields.keySet()) {
                Object val = metadataFields.get(key);
                if (val != null) {
                    Metadata.CustomMetadataValue cmdValue = new Metadata.CustomMetadataValue();
                    cmdValue.field = key;
                    cmdValue.value = val;
                    customMetadata.values.add(cmdValue);
                }
            }

            // Prepare and enqueue metadata deployment
            Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
            mdContainer.addMetadata(customMetadata);

            Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, new CreateUpdateMetadataUtils());
            return jobId;

        } catch (Exception ex) {
            System.debug('Error in updateAndDeployMetadata: ' + ex.getMessage());
            throw new AuraHandledException('Deployment failed: ' + ex.getMessage());
        }
    }

    // Ensures no duplicate record exists in Custom Metadata
    public static void validateDuplicateMetadata(String fullName, String baseUrl) {
        List<Salesforce_Authorization__mdt> existing =
            [SELECT Id FROM Salesforce_Authorization__mdt
             WHERE DeveloperName = :fullName
             AND Base_URL__c = :baseUrl];

        if (!existing.isEmpty()) {
            throw new MetadataOperationException(
                'Metadata with the same name and base URL already exists.'
            );
        }
    }

    // Generates a valid API name from label
    public static String generateApiName(String label) {
        if (String.isBlank(label)) return null;

        String apiName = label.trim();
        apiName = apiName.replaceAll('[^A-Za-z0-9]+', '_'); // replace spaces/symbols with underscore
        apiName = apiName.replaceAll('^_+|_+$', '');        // trim leading/trailing underscores

        if (Pattern.matches('^[0-9].*', apiName)) {
            apiName = 'X_' + apiName;                       // avoid starting with number
        }

        if (apiName.length() > 40) {
            apiName = apiName.substring(0, 40);
        }

        return apiName;
    }

    @AuraEnabled
    public static DeploymentStatusWrapper getDeploymentStatus(String deploymentId) {
        try {
            // Using Named Credential for secure callout
            String endpoint = 'callout:Salesforce_Deployment/services/data/v64.0/metadata/deployRequest/' + deploymentId;

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                if (responseMap.containsKey('deployResult')) {
                    Map<String, Object> deployResult = (Map<String, Object>) responseMap.get('deployResult');

                    Boolean success = (Boolean) deployResult.get('success');
                    String status = (String) deployResult.get('status');
                    Boolean done = (Boolean) deployResult.get('done');
                    Integer numberComponentErrors = (Integer) deployResult.get('numberComponentErrors');

                    return new DeploymentStatusWrapper(success, status, done, numberComponentErrors);
                }
            }
            return new DeploymentStatusWrapper(false, 'Failed', true, 0);
        } catch (Exception e) {
            return new DeploymentStatusWrapper(false, 'Failed', true, 0);
        }
    }

    // Deployment Status Wrapper - returned to LWC
    public class DeploymentStatusWrapper {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String status;
        @AuraEnabled public Boolean done;
        @AuraEnabled public Integer numberComponentErrors;

        public DeploymentStatusWrapper(Boolean success, String status, Boolean done, Integer numberComponentErrors) {
            this.success = success;
            this.status = status;
            this.done = done;
            this.numberComponentErrors = numberComponentErrors;
        }
    }

    // Custom Exception
    public class MetadataOperationException extends Exception {}
}