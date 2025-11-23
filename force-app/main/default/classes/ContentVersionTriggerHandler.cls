public with sharing class ContentVersionTriggerHandler {

    /**
     * Trigger handler for creating ContentDistribution when a new file is uploaded
     */
    public static void createContentDistribution() {
        List<ContentVersion> newFileVersions = (List<ContentVersion>) Trigger.new;
        List<ContentDistribution> distributionRecordsToInsert = new List<ContentDistribution>();

        // Iterate over uploaded file versions
        for (ContentVersion fileVersion : newFileVersions) {
            ContentDistribution distributionRecord = new ContentDistribution();

            distributionRecord.Name = fileVersion.Title; // Display name of the shared link
            distributionRecord.ContentVersionId = fileVersion.Id; // Link to ContentVersion

            // Viewer and version settings
            distributionRecord.PreferencesAllowViewInBrowser = true;
            distributionRecord.PreferencesLinkLatestVersion = true;

            // Expiration settings
            distributionRecord.PreferencesExpires = true;
            distributionRecord.ExpiryDate = System.now().addMinutes(10);

            // Email notifications
            distributionRecord.PreferencesNotifyOnVisit = true;
            distributionRecord.PreferencesNotifyRndtnComplete = true;

            // Password protection
            distributionRecord.PreferencesPasswordRequired = true;

            // Downloads
            distributionRecord.PreferencesAllowPDFDownload = true;
            distributionRecord.PreferencesAllowOriginalDownload = true;

            distributionRecordsToInsert.add(distributionRecord);
        }

        // Insert new ContentDistribution records
        if (!distributionRecordsToInsert.isEmpty()) {
            insert distributionRecordsToInsert;
        }
    }


    /**
     * Returns ContentDistribution details for display in LWC
     */
    @AuraEnabled
    public static List<ContentDistributionWrapper> getContentDistribution(String contentVersionId) {
        List<ContentDistributionWrapper> distributionWrapperList = new List<ContentDistributionWrapper>();

        // Query distribution settings for the uploaded content
        for (ContentDistribution distributionRecord : [
            SELECT Id, Name, DistributionPublicUrl, Password, ExpiryDate
            FROM ContentDistribution
            WHERE ContentVersionId = :contentVersionId
        ]) {

            ContentDistributionWrapper wrapper = new ContentDistributionWrapper();
            wrapper.publicUrl = distributionRecord.DistributionPublicUrl;
            wrapper.expireTime = distributionRecord.ExpiryDate;
            wrapper.password = distributionRecord.Password;

            distributionWrapperList.add(wrapper);
        }

        return distributionWrapperList;
    }


    /**
     * Wrapper class used to send ContentDistribution data to LWC
     */
    public class ContentDistributionWrapper {
        @AuraEnabled public String publicUrl;    // External share link
        @AuraEnabled public Datetime expireTime; // Link expiry timestamp
        @AuraEnabled public String password;     // Password for file access
    }
}