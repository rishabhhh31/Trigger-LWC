public with sharing class DynamicRecordCreation {

    /**
     * @description Fetches a list of UI API–supported, createable, and accessible objects.
     *              This is useful for dynamically displaying object options (e.g., in an LWC dropdown).
     * @return List<ObjectOption> - a list of objects containing API name and label.
     */
    @AuraEnabled
    public static List<ObjectOption> getSupportedObjectOptions() {
        List<ObjectOption> objectOptions = new List<ObjectOption>();

        // Get all described SObject types
        Map<String, Schema.SObjectType> allSObjects = Schema.getGlobalDescribe();

        // Fetch UI API–supported objects
        Map<String, UiObjectDetail> uiSupportedObjects = fetchUiApiSupportedObjects();
        if (uiSupportedObjects == null || uiSupportedObjects.isEmpty()) {
            return objectOptions;
        }

        // Filter objects that are both createable & accessible
        for (String objectApiName : uiSupportedObjects.keySet()) {
            if (!allSObjects.containsKey(objectApiName)) continue;

            Schema.DescribeSObjectResult describe = allSObjects.get(objectApiName).getDescribe();
            UiObjectDetail uiObject = uiSupportedObjects.get(objectApiName);

            if (describe.isCreateable() && describe.isAccessible()) {
                objectOptions.add(new ObjectOption(uiObject.apiName, uiObject.label));
            }
        }

        return objectOptions;
    }

    /**
     * @description Data structure for dropdown-style object options.
     */
    public class ObjectOption {
        @AuraEnabled public String value { get; set; }
        @AuraEnabled public String label { get; set; }

        public ObjectOption(String value, String label) {
            this.value = value;
            this.label = label;
        }
    }

    /**
     * @description Wrapper for the /ui-api/object-info response.
     */
    public class UiApiObjectInfoWrapper {
        public Map<String, UiObjectDetail> objects;
    }

    /**
     * @description Wrapper for individual object metadata inside UI API response.
     */
    public class UiObjectDetail {
        public String apiName;
        public String keyPrefix;
        public String label;
        public String labelPlural;
        public List<String> nameFields;
        public String objectInfoUrl;
    }

    /**
     * @description Makes a callout to the Salesforce UI API endpoint `/ui-api/object-info`
     *              via a Named Credential (SalesforcePersonalNC) and returns the supported objects.
     * @return Map<String, UiObjectDetail> - a map of supported object API names to their metadata.
     */
    private static Map<String, UiObjectDetail> fetchUiApiSupportedObjects() {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:SalesforcePersonalNC/services/data/v65.0/ui-api/object-info');
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(120000);

        Http http = new Http();
        HttpResponse response;

        try {
            response = http.send(request);
        } catch (Exception e) {
            System.debug('⚠️ HTTP callout failed: ' + e.getMessage());
            return null;
        }

        if (response.getStatusCode() == 200) {
            UiApiObjectInfoWrapper result = (UiApiObjectInfoWrapper) JSON.deserialize(response.getBody(), UiApiObjectInfoWrapper.class);
            return result.objects;
        } else {
            System.debug('⚠️ Failed to fetch UI API objects. Status: ' + response.getStatusCode() + ', Body: ' + response.getBody());
            return null;
        }
    }
}