public with sharing class LeadModalController {
    @AuraEnabled
    public static Id createLead(Map<String, Object> leadData) {
        try {
            Lead newLead = new Lead();
            newLead.FirstName = (String)leadData.get('FirstName');
            newLead.LastName = (String) leadData.get('LastName');
            newLead.Company = (String) leadData.get('Company');
            newLead.Email = (String) leadData.get('Email');
            newLead.Phone = (String) leadData.get('Phone');
            newLead.LeadSource = (String)leadData.get('LeadSource');
            insert newLead;
            return newLead.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating lead: ' + e.getMessage());
        }
    }
}