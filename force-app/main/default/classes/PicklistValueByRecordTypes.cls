public with sharing class PicklistValueByRecordTypes {

    public static void getPicklistValuesByRecordType() {

        // 🔹 Step 1: Get Record Type Id safely
        Schema.RecordTypeInfo rtInfo = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('Retail_Customer');

        if (rtInfo == null) {
            System.debug('Record Type not found');
            return;
        }

        Id rtId = rtInfo.getRecordTypeId();

        // 🔹 Step 2: Fetch all picklist values
        ConnectApi.PicklistValuesCollection result = ConnectApi.RecordUi.getPicklistValuesByRecordType('Account', rtId);

        Map<String, ConnectApi.PicklistValues> fieldPicklists = result.picklistFieldValues;

        if (fieldPicklists == null || fieldPicklists.isEmpty()) {
            System.debug('No picklist values found');
            return;
        }

        // 🔹 Step 3: Process Type field
        processIndependentPicklist(fieldPicklists.get('Type'), 'Type');

        // 🔹 Step 4: Process dependent field (CustomerPriority__c → Type)
        processDependentPicklist(
            fieldPicklists.get('Type'),                // dependent
            fieldPicklists.get('CustomerPriority__c')  // controller
        );
    }

    // 🔹 Handles simple picklist (no dependency logic)
    private static void processIndependentPicklist(
        ConnectApi.PicklistValues picklist,
        String fieldName
    ) {
        if (picklist == null) return;

        List<String> values = new List<String>();

        for (ConnectApi.PicklistValue val : picklist.values) {
            values.add(val.label);
        }

        System.debug('Picklist values for ' + fieldName + ' → ' + String.join(values, ', '));
    }

    // 🔹 Handles dependent picklist logic
    private static void processDependentPicklist(
        ConnectApi.PicklistValues dependentField,
        ConnectApi.PicklistValues controllerField
    ) {
        if (dependentField == null || controllerField == null) return;

        Map<String, Integer> controllerMap = controllerField.controllerValues;

        if (controllerMap == null || controllerMap.isEmpty()) {
            System.debug('No dependency found');
            return;
        }

        // Reverse map: index → controller value
        Map<Integer, String> indexToController = new Map<Integer, String>();
        for (String key : controllerMap.keySet()) {
            indexToController.put(controllerMap.get(key), key);
        }

        // Iterate dependent values
        for (ConnectApi.PicklistValue val : dependentField.values) {

            if (val.validFor == null || val.validFor.isEmpty()) continue;

            List<String> validControllers = new List<String>();

            for (Integer index : val.validFor) {
                if (indexToController.containsKey(index)) {
                    validControllers.add(indexToController.get(index));
                }
            }

            System.debug(val.label + ' is valid for → ' + String.join(validControllers, ', '));
        }
    }
}