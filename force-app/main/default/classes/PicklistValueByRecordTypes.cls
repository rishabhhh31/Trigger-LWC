public with sharing class PicklistValueByRecordTypes {
    public static void getPicklistValuesByRecordType(){
        Id rtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('Retail_Customer')
            .getRecordTypeId();

        ConnectApi.PicklistValuesCollection result = ConnectApi.RecordUi.getPicklistValuesByRecordType('Account', rtId);

        // Get Type field
        Map<String, ConnectApi.PicklistValues> picklistValues = result.picklistFieldValues;

        ConnectApi.PicklistValues typeValues = picklistValues.get('Type');

        List<String> typePicklistValue = new List<String>();
        for(ConnectApi.PicklistValue value : typeValues.values){
            typePicklistValue.add(value.label);
        }

        System.debug('Picklist values for Retail Customer Record Type is '+String.join(typePicklistValue, ','));

        ConnectApi.PicklistValues customerPriorityValues = picklistValues.get('CustomerPriority__c');

        List<String> customPriorityPicklistValue = new List<String>();
        Map<String,Integer> controllerValueMap = customerPriorityValues.controllerValues;
        for(ConnectApi.PicklistValue value : customerPriorityValues.values){
            if(value.validFor.size() > 0){
                List<String> dependentMap = new List<String>();
                for(String key : controllerValueMap.keySet()){
                    if(value.validFor.contains(controllerValueMap.get(key))){
                        dependentMap.add(key);
                    }
                }
                System.debug(value.label + ' is dependent on '+ String.join(dependentMap, ','));
            }
        }
    }
}