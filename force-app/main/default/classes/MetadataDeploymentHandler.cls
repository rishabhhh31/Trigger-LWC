public with sharing class MetadataDeploymentHandler {
    public static MetadataService.MetadataPort createService() {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        return service;
    }

    public static void getOrgWideMetadataTypeNames() {
        MetadataService.MetadataPort service = createService();
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
    }

    public static void listMetadata(List<String> metadataComponents) {
        MetadataService.MetadataPort service = createService();
        List<MetadataService.ListMetadataQuery> queries = new List<MetadataService.ListMetadataQuery>();
        for(String metadataComponent : metadataComponents){
            MetadataService.ListMetadataQuery query = new MetadataService.ListMetadataQuery();
            query.type_x = metadataComponent;
            queries.add(query);
        }
        for(MetadataService.FileProperties fileProperty : service.listMetadata(queries, MetadataService.apiVersion)){
            System.debug('createdById => ' + fileProperty.createdById);
            System.debug('createdByName => ' + fileProperty.createdByName);
            System.debug('createdDate => ' + fileProperty.createdDate);
            System.debug('fileName => ' + fileProperty.fileName);
            System.debug('fullName => ' + fileProperty.fullName);
            System.debug('id => ' + fileProperty.id);
            System.debug('lastModifiedById => ' + fileProperty.lastModifiedById);
            System.debug('lastModifiedByName => ' + fileProperty.lastModifiedByName);
            System.debug('lastModifiedDate => ' + fileProperty.lastModifiedDate);
            System.debug('manageableState => ' + fileProperty.manageableState);
            System.debug('namespacePrefix => ' + fileProperty.namespacePrefix);
            System.debug('type_x => ' + fileProperty.type_x);
            System.debug('--------------------------------------');
        }
    }

    public static void retrieveMetadataItem(Map<String, List<String>> componentNamesMap) {
        MetadataService.MetadataPort service = createService();	
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
        deployMetadata(retrieveResult.zipFile);
    }

    public static void deployMetadata(String zipFileData)
	{
		MetadataService.MetadataPort service = createService();
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
        // MetadataService.DeployResult deployResult;
        // boolean done = false;
        // while (!done) {
        //     deployResult = service.checkDeployStatus(asyncResult.Id, true);
        //     if (deployResult.done) {		
        //         done = true;
        //     } else {
        //         datetime start = System.now();
        //         While(System.now() < start.addseconds(10)){}        
        //     }
        // }
	}

    public static void createExternalAuthProvider(){
        MetadataService.MetadataPort service = createService();
        MetadataService.ExternalAuthIdentityProvider authProvider = new MetadataService.ExternalAuthIdentityProvider();
        authProvider.fullName = 'Salesforce_B';
        authProvider.label = 'Salesforce B';
        authProvider.authenticationFlow = 'ClientCredentials';
        authProvider.authenticationProtocol = 'OAuth';

        List<MetadataService.ExternalAuthIdentityProviderParameter> parameters = new List<MetadataService.ExternalAuthIdentityProviderParameter>();
        MetadataService.ExternalAuthIdentityProviderParameter parameter = new MetadataService.ExternalAuthIdentityProviderParameter();
        parameter.parameterName = 'ClientAuthentication';
        parameter.parameterType = 'ClientAuthentication';
        parameter.parameterValue = 'ClientSecretBasic';
        parameters.add(parameter);
        
        MetadataService.ExternalAuthIdentityProviderParameter tokenParameter = new MetadataService.ExternalAuthIdentityProviderParameter();
        tokenParameter.parameterName = 'TokenUrl';
        tokenParameter.parameterType = 'TokenUrl';
        tokenParameter.parameterValue = 'https://test.salesforce.com/services/oauth2/token';
        parameters.add(tokenParameter);

        authProvider.externalAuthIdentityProviderParameters = parameters; 
        MetadataService.SaveResult[] result = service.createMetadata(new List<MetadataService.Metadata>{authProvider});
        if(result[0].success){
            createExternalCredentials();
        }
    }

    public static void createExternalCredentials() {
        MetadataService.MetadataPort service = createService();
        MetadataService.ExternalCredential externalCredential = new MetadataService.ExternalCredential();
        externalCredential.fullName = 'Salesforce_B';
        externalCredential.label = 'Salesforce_B';
        externalCredential.authenticationProtocol = 'Oauth';
        externalCredential.description = 'External Credential for connecting Salesforce B via OAuth';
        externalCredential.externalCredentialParameters = new List<MetadataService.ExternalCredentialParameter>();
        MetadataService.ExternalCredentialParameter extAuthIdpParam = new MetadataService.ExternalCredentialParameter();
        extAuthIdpParam.externalAuthIdentityProvider = 'Salesforce_B';
        extAuthIdpParam.parameterGroup = 'DefaultGroup';
        extAuthIdpParam.parameterName = 'ExternalAuthIdentityProvider';
        extAuthIdpParam.parameterType = 'ExternalAuthIdentityProvider';

        MetadataService.ExternalCredentialParameter perUserPrincipalParam = new MetadataService.ExternalCredentialParameter();
        perUserPrincipalParam.parameterName = 'SalesforceB';
        perUserPrincipalParam.parameterGroup = 'SalesforceB';
        perUserPrincipalParam.parameterType = 'PerUserPrincipal';
        perUserPrincipalParam.sequenceNumber = 1;

        externalCredential.externalCredentialParameters.add(extAuthIdpParam);
        externalCredential.externalCredentialParameters.add(perUserPrincipalParam);

        MetadataService.SaveResult[] results = service.createMetadata(
            new List<MetadataService.Metadata>{ (MetadataService.Metadata) externalCredential }
        );
        System.debug(JSON.serialize(results));
        if (results != null && results.size() > 0) {
            System.debug('Success: ' + results[0].success);
            if(results[0].success){
                createNamedCredential();
            }
            if (results[0].errors != null) {
                for (MetadataService.Error err : results[0].errors) {
                    System.debug('Error: ' + err.message);
                }
            }
        }
    }

    public static void createNamedCredential() {
        MetadataService.MetadataPort service = createService();
        MetadataService.NamedCredential namedCredential = new MetadataService.NamedCredential();
        namedCredential.fullName = 'Salesforce_NC';
        namedCredential.label = 'Salesforce NC';
        namedCredential.allowMergeFieldsInHeader = false;
        namedCredential.allowMergeFieldsInBody = false;
        namedCredential.calloutStatus = 'Enabled';
        namedCredential.namedCredentialType = 'SecuredEndpoint';
        namedCredential.namedCredentialParameters = new List<MetadataService.NamedCredentialParameter>();
        MetadataService.NamedCredentialParameter parameter1 = new MetadataService.NamedCredentialParameter();
        parameter1.parameterType = 'Authentication';
        parameter1.externalCredential = 'Salesforce_B';
        parameter1.parameterName = 'ExternalCredential';
        namedCredential.namedCredentialParameters.add(parameter1);
        MetadataService.NamedCredentialParameter parameter2 = new MetadataService.NamedCredentialParameter();
        parameter2.parameterType = 'Url';
        parameter2.parameterValue = 'https://wise-panda-wauvar-dev-ed.trailblaze.my.salesforce.com';
        parameter2.parameterName = 'Url';
        namedCredential.namedCredentialParameters.add(parameter2);
        MetadataService.SaveResult[] results = service.createMetadata(
            new List<MetadataService.Metadata>{ (MetadataService.Metadata) namedCredential }
        );
        if (results != null && results.size() > 0) {
            System.debug('Success: ' + results[0].success);
            if (results[0].errors != null) {
                for (MetadataService.Error err : results[0].errors) {
                    System.debug('Error: ' + err.message);
                }
            }
        }
    }
}