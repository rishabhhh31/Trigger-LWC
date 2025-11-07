public with sharing class MetadataDeploymentHandler {
    public static void updateTriggerStatus() {
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        service.endpoint_x = baseUrl + '/services/Soap/m/' + MetadataService.apiVersion;

        // Query all Apex triggers
        MetadataService.ListMetadataQuery trig = new MetadataService.ListMetadataQuery();
        trig.type_x = 'ApexTrigger';
        MetadataService.ListMetadataQuery apexCls = new MetadataService.ListMetadataQuery();
        apexCls.type_x = 'ApexClass';
        List<MetadataService.ListMetadataQuery> queries = new List<MetadataService.ListMetadataQuery>{ trig, apexCls };

        List<MetadataService.FileProperties> fileProperties = 
            service.listMetadata(queries, MetadataService.apiVersion);

        List<String> triggerNames = new List<String>();
        List<String> classesNames = new List<String>();
        for (MetadataService.FileProperties fileProp : fileProperties) {
            if(fileProp.type_x == 'ApexClass'){
                classesNames.add(fileProp.fullName);
            }
            if(fileProp.type_x == 'ApexTrigger'){
                triggerNames.add(fileProp.fullName);
            }
        }
        MetadataService.RetrieveRequest retrieveRequest = new MetadataService.RetrieveRequest();
        retrieveRequest.apiVersion = MetadataService.apiVersion;
        retrieveRequest.packageNames = null;
		retrieveRequest.singlePackage = true;
		retrieveRequest.specificFiles = null;
        retrieveRequest.unpackaged = new MetadataService.Package_x();
        retrieveRequest.unpackaged.types = new List<MetadataService.PackageTypeMembers>();
        MetadataService.PackageTypeMembers packageType = new MetadataService.PackageTypeMembers();
        packageType.name = 'ApexTrigger';
        packageType.members = triggerNames;
        retrieveRequest.unpackaged.types.add(packageType);

        MetadataService.PackageTypeMembers packageType1 = new MetadataService.PackageTypeMembers();
        packageType1.name = 'ApexClass';
        packageType1.members = classesNames;
        retrieveRequest.unpackaged.types.add(packageType1);
        MetadataService.AsyncResult asyncResult = service.retrieve(retrieveRequest);
        MetadataService.RetrieveResult retrieveResult;
        boolean done = false;
        while (!done) {
            retrieveResult = service.checkRetrieveStatus(asyncResult.Id, true);
            if (retrieveResult.done) {		
                done = true;
            } else {
                datetime start = System.now();
                While(System.now() < start.addseconds(10)){}        
            }
        }
		MetadataService.DeployOptions deployOptions = new MetadataService.DeployOptions();
        deployOptions.allowMissingFiles = false;
        deployOptions.autoUpdatePackage = false;
        deployOptions.checkOnly = false;
        deployOptions.ignoreWarnings = false;
        deployOptions.performRetrieve = false;
        deployOptions.purgeOnDelete = false;
        deployOptions.rollbackOnError = true;
        deployOptions.testLevel = 'NoTestRun';
        deployOptions.singlePackage = true;		
		service.deploy(retrieveResult.zipFile, deployOptions);
    }

    public static MetadataService.MetadataPort createService(String baseUrl, String accessToken) {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.endpoint_x = baseUrl + '/services/Soap/m/'+MetadataService.apiVersion;
        service.SessionHeader.sessionId = accessToken;
        return service;
    }

    public class MetadataOption {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String value { get; set; }

        public MetadataOption(String name) {
            this.label = name;
            this.value = name;
        }
    }

    @AuraEnabled
    public static List<MetadataOption> getOrgWideMetadataTypeNames(String sourceOrg) {
        Salesforce_Authorization__mdt sourceOrgMdt = [SELECT Id, MasterLabel, DeveloperName, Access_Token__c, Expire_Time__c, Client_Id__c, Client_Secret__c, Base_URL__c FROM Salesforce_Authorization__mdt WHERE Id =: sourceOrg LIMIT 1];
        String accessToken = sourceOrgMdt.Access_Token__c;
        String baseUrl = sourceOrgMdt.Base_URL__c;
        if(sourceOrgMdt.Expire_Time__c == null || sourceOrgMdt.Expire_Time__c < System.now()){
            // accessToken = AuthService.handleClientCredentialsFlow(sourceOrgMdt.MasterLabel, sourceOrgMdt.DeveloperName, sourceOrgMdt.Base_URL__c, sourceOrgMdt.Client_Secret__c, sourceOrgMdt.Client_Id__c);
        }
        MetadataService.MetadataPort service = createService(baseUrl, accessToken);
        MetadataService.DescribeMetadataResult describeResult = service.describeMetadata(MetadataService.apiVersion);
        Set<String> uniqueMetadataTypeNames = new Set<String>();
        for(MetadataService.DescribeMetadataObject metadataObject : describeResult.metadataObjects) {
            uniqueMetadataTypeNames.add(metadataObject.xmlName);
            if(metadataObject.childXmlNames != null){
                uniqueMetadataTypeNames.addAll(metadataObject.childXmlNames);
            }
        }
        List<String> metadataTypeNames = new List<String>(uniqueMetadataTypeNames);
        metadataTypeNames.sort();
        List<MetadataOption> formattedList = new List<MetadataOption>();
        for (String name : metadataTypeNames) {
            formattedList.add(new MetadataOption(name));
        }
        return formattedList;
    }

    public class MetadataFileInfo {
        @AuraEnabled public String createdByName { get; set; }
        @AuraEnabled public String fullName { get; set; }
        @AuraEnabled public String lastModifiedByName { get; set; }
        @AuraEnabled public String type { get; set; }

        public MetadataFileInfo(String createdByName, String fullName, String fileName, String lastModifiedByName, String typeName) {
            this.createdByName = createdByName;
            this.fullName = fullName;
            this.lastModifiedByName = lastModifiedByName;
            this.type = typeName;
        }
    }

    @AuraEnabled
    public static List<MetadataFileInfo> listMetadata(List<String> metadataComponents, String sourceOrg) {
        Salesforce_Authorization__mdt sourceOrgMdt = [SELECT Id, MasterLabel, DeveloperName, Access_Token__c, Expire_Time__c, Client_Id__c, Client_Secret__c, Base_URL__c FROM Salesforce_Authorization__mdt WHERE Id =: sourceOrg LIMIT 1];
        String accessToken = sourceOrgMdt.Access_Token__c;
        String baseUrl = sourceOrgMdt.Base_URL__c;
        MetadataService.MetadataPort service = createService(baseUrl, accessToken);
        List<MetadataService.ListMetadataQuery> queries = new List<MetadataService.ListMetadataQuery>();
        for(String metadataComponent : metadataComponents){
            MetadataService.ListMetadataQuery query = new MetadataService.ListMetadataQuery();
            query.type_x = metadataComponent;
            queries.add(query);
        }
        List<MetadataFileInfo> fileInfoList = new List<MetadataFileInfo>();
        for(MetadataService.FileProperties fileProperty : service.listMetadata(queries, MetadataService.apiVersion)){
            fileInfoList.add(
                new MetadataFileInfo(
                    fileProperty.createdByName,
                    fileProperty.fullName,
                    fileProperty.fileName,
                    fileProperty.lastModifiedByName,
                    fileProperty.type_x
                )
            );
        }
        return fileInfoList;
    }

    @AuraEnabled
    public static String retrieveMetadataItem(Map<String, List<String>> componentNamesMap, String sourceOrg, String targetOrg) {
        Salesforce_Authorization__mdt sourceOrgMdt = [SELECT Id, MasterLabel, DeveloperName, Access_Token__c, Expire_Time__c, Client_Id__c, Client_Secret__c, Base_URL__c FROM Salesforce_Authorization__mdt WHERE Id =: sourceOrg LIMIT 1];
        String accessToken = sourceOrgMdt.Access_Token__c;
        String baseUrl = sourceOrgMdt.Base_URL__c;
        MetadataService.MetadataPort service = createService(baseUrl, accessToken);
        MetadataService.RetrieveRequest retrieveRequest = new MetadataService.RetrieveRequest();
        retrieveRequest.apiVersion = MetadataService.apiVersion;
        retrieveRequest.packageNames = null;
		retrieveRequest.singlePackage = true;
		retrieveRequest.specificFiles = null;
        retrieveRequest.unpackaged = new MetadataService.Package_x();
        retrieveRequest.unpackaged.types = new List<MetadataService.PackageTypeMembers>();
        for(String metadataType : componentNamesMap.keySet()){
            MetadataService.PackageTypeMembers packageType = new MetadataService.PackageTypeMembers();
            packageType.name = metadataType;
            packageType.members = componentNamesMap.get(metadataType);
            retrieveRequest.unpackaged.types.add(packageType);
        }
        MetadataService.AsyncResult asyncResult = service.retrieve(retrieveRequest);
        MetadataService.RetrieveResult retrieveResult;
        boolean done = false;
        while (!done) {
            retrieveResult = service.checkRetrieveStatus(asyncResult.Id, true);
            if (retrieveResult.done) {		
                done = true;
            } else {
                datetime start = System.now();
                While(System.now() < start.addseconds(10)){}        
            }
        }
        return deployMetadata(retrieveResult.zipFile, targetOrg);
    }

    public static String deployMetadata(String zipFileData, String targetOrg)
	{
        Salesforce_Authorization__mdt sourceOrgMdt = [SELECT Id, MasterLabel, DeveloperName, Access_Token__c, Expire_Time__c, Client_Id__c, Client_Secret__c, Base_URL__c FROM Salesforce_Authorization__mdt WHERE Id =: targetOrg LIMIT 1];
        String accessToken = sourceOrgMdt.Access_Token__c;
        String baseUrl = sourceOrgMdt.Base_URL__c;
        MetadataService.MetadataPort service = createService(baseUrl, accessToken);
		MetadataService.DeployOptions deployOptions = new MetadataService.DeployOptions();
        deployOptions.allowMissingFiles = false;
        deployOptions.autoUpdatePackage = false;
        deployOptions.checkOnly = false;
        deployOptions.ignoreWarnings = false;
        deployOptions.performRetrieve = false;
        deployOptions.purgeOnDelete = false;
        deployOptions.rollbackOnError = true;
        deployOptions.testLevel = 'NoTestRun';
        deployOptions.singlePackage = true;		
		MetadataService.AsyncResult asyncResult = service.deploy(zipFileData, deployOptions);
        return asyncResult.id;
	}

    public static void createExternalAuthProvider(String label, String fullName, String endpoint) {
        MetadataService.MetadataPort service = createService(null, null);
        service.endpoint_x = '';

        // Create the External Auth Identity Provider
        MetadataService.ExternalAuthIdentityProvider authProvider = new MetadataService.ExternalAuthIdentityProvider();
        authProvider.fullName = fullName;
        authProvider.label = label;
        authProvider.authenticationFlow = 'ClientCredentials';
        authProvider.authenticationProtocol = 'OAuth';

        // Prepare the parameters list
        List<MetadataService.ExternalAuthIdentityProviderParameter> authParameters = new List<MetadataService.ExternalAuthIdentityProviderParameter>();

        // Client Authentication parameter
        MetadataService.ExternalAuthIdentityProviderParameter clientAuthParam = new MetadataService.ExternalAuthIdentityProviderParameter();
        clientAuthParam.parameterName = 'ClientAuthentication';
        clientAuthParam.parameterType = 'ClientAuthentication';
        clientAuthParam.parameterValue = 'ClientSecretBasic';
        authParameters.add(clientAuthParam);

        // Token URL parameter (dynamic based on environment)
        MetadataService.ExternalAuthIdentityProviderParameter tokenUrlParam = new MetadataService.ExternalAuthIdentityProviderParameter();
        tokenUrlParam.parameterName = 'TokenUrl';
        tokenUrlParam.parameterType = 'TokenUrl';
        tokenUrlParam.parameterValue = endpoint + '/services/oauth2/token';
        authParameters.add(tokenUrlParam);

        // Assign parameters to the provider
        authProvider.externalAuthIdentityProviderParameters = authParameters; 

        // Create the provider metadata
        MetadataService.SaveResult[] result = service.createMetadata(new List<MetadataService.Metadata>{authProvider});

        // Check result and throw custom error if unsuccessful
        if (result == null || result.isEmpty() || !result[0].success) {
            String errorMessage = 'Failed to create External Auth Provider';
            if (result != null && result.size() > 0 && result[0].errors != null && result[0].errors.size() > 0) {
                errorMessage += ': ' + result[0].errors[0].message;
            }
            throw new MetadataOperationException(errorMessage);
        }

        createExternalCredentials(label, fullName, endpoint);
    }

    public static void createExternalCredentials(String label, String fullName, String endpoint) {
        MetadataService.MetadataPort service = createService(null, null);

        // Create External Credential
        MetadataService.ExternalCredential externalCredential = new MetadataService.ExternalCredential();
        externalCredential.fullName = fullName;
        externalCredential.label = label;
        externalCredential.authenticationProtocol = 'Oauth';
        externalCredential.description = 'External Credential for connecting ' + label + ' via OAuth';
        externalCredential.externalCredentialParameters = new List<MetadataService.ExternalCredentialParameter>();

        // ExternalAuthIdentityProvider parameter
        MetadataService.ExternalCredentialParameter extAuthIdpParam = new MetadataService.ExternalCredentialParameter();
        extAuthIdpParam.externalAuthIdentityProvider = fullName;
        extAuthIdpParam.parameterGroup = 'DefaultGroup';
        extAuthIdpParam.parameterName = 'ExternalAuthIdentityProvider';
        extAuthIdpParam.parameterType = 'ExternalAuthIdentityProvider';

        // PerUserPrincipal parameter
        MetadataService.ExternalCredentialParameter perUserPrincipalParam = new MetadataService.ExternalCredentialParameter();
        perUserPrincipalParam.parameterName = label.replaceAll('\\s',''); // remove spaces
        perUserPrincipalParam.parameterGroup = perUserPrincipalParam.parameterName;
        perUserPrincipalParam.parameterType = 'PerUserPrincipal';
        perUserPrincipalParam.sequenceNumber = 1;

        // Add parameters to the external credential
        externalCredential.externalCredentialParameters.add(extAuthIdpParam);
        externalCredential.externalCredentialParameters.add(perUserPrincipalParam);

        // Create metadata
        MetadataService.SaveResult[] results = service.createMetadata(
            new List<MetadataService.Metadata>{ (MetadataService.Metadata) externalCredential }
        );

        // Check results and throw custom exception if creation fails
        if (results == null || results.isEmpty() || !results[0].success) {
            String errorMessage = 'Failed to create External Credential';
            if (results != null && results.size() > 0 && results[0].errors != null && results[0].errors.size() > 0) {
                errorMessage += ': ' + results[0].errors[0].message;
            }
            throw new MetadataOperationException(errorMessage);
        }
        // Call next step
        createNamedCredential(label, fullName, endpoint);
    }

    public static void createNamedCredential(String label, String fullName, String endpoint) {
        MetadataService.MetadataPort service = createService(null, null);
        // Create Named Credential
        MetadataService.NamedCredential namedCredential = new MetadataService.NamedCredential();
        namedCredential.fullName = fullName;
        namedCredential.label = label;
        namedCredential.allowMergeFieldsInHeader = false;
        namedCredential.allowMergeFieldsInBody = false;
        namedCredential.calloutStatus = 'Enabled';
        namedCredential.namedCredentialType = 'SecuredEndpoint';
        namedCredential.namedCredentialParameters = new List<MetadataService.NamedCredentialParameter>();

        // External Credential parameter
        MetadataService.NamedCredentialParameter authParam = new MetadataService.NamedCredentialParameter();
        authParam.parameterType = 'Authentication';
        authParam.externalCredential = fullName;
        authParam.parameterName = 'ExternalCredential';
        namedCredential.namedCredentialParameters.add(authParam);

        // URL parameter
        MetadataService.NamedCredentialParameter urlParam = new MetadataService.NamedCredentialParameter();
        urlParam.parameterType = 'Url';
        urlParam.parameterValue = endpoint;
        urlParam.parameterName = 'Url';
        namedCredential.namedCredentialParameters.add(urlParam);

        // Deploy Named Credential
        MetadataService.SaveResult[] results = service.createMetadata(
            new List<MetadataService.Metadata>{ (MetadataService.Metadata) namedCredential }
        );
        // Handle errors and throw custom exception if not successful
        if (results == null || results.isEmpty() || !results[0].success) {
            String errorMessage = 'Failed to create Named Credential: ' + fullName;
            if (results != null && results.size() > 0 && results[0].errors != null && results[0].errors.size() > 0) {
                errorMessage += ' - ' + results[0].errors[0].message;
            }
            throw new MetadataOperationException(errorMessage);
        }

        System.debug('Named Credential created successfully: ' + fullName);
    }

    @AuraEnabled
    public static List<SalesforceMetadataWrapper> getSalesforceAuthorizationOrgs(){
        try {
            List<SalesforceMetadataWrapper> wrapperList = new List<SalesforceMetadataWrapper>();
            for(Salesforce_Authorization__mdt auth : [SELECT Id, Base_URL__c, MasterLabel, DeveloperName, Client_Id__c, Client_Secret__c FROM Salesforce_Authorization__mdt ORDER BY SystemModstamp DESC]){
                wrapperList.add(new SalesforceMetadataWrapper(auth.Base_URL__c, auth.MasterLabel, auth.Id));
            }
            return wrapperList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class SalesforceMetadataWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        public SalesforceMetadataWrapper(
            String baseUrl,
            String metadataName,
            String metadataTypeId
        ) {
            this.label = metadataName + ' (' + baseUrl + ')';
            this.value = metadataTypeId;
        }
    }

    // Custom exception class
    public class MetadataOperationException extends Exception {}
}