public class DynamicNamedCredentialCreation {
	public static void createExternalAuthProvider(String label, String fullName, String endpoint) {
        MetadataService.MetadataPort service = MetadataDeploymentHandler.createService();
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
        MetadataService.MetadataPort service = MetadataDeploymentHandler.createService();

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
        MetadataService.MetadataPort service = MetadataDeploymentHandler.createService();
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

    // Custom exception class
    public class MetadataOperationException extends Exception {}
}