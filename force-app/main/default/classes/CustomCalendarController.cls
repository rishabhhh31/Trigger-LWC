public with sharing class CustomCalendarController {

    @AuraEnabled
    public static Id createAppointment(Map<String,Object> appointmentData){
        try{
            Appointment__c appointment = new Appointment__c();
            appointment.Subject__c = (String) appointmentData.get('Subject__c');
            appointment.Start_Time__c = parseISODateTime((String)appointmentData.get('Start_Time__c'));
            appointment.End_Time__c = parseISODateTime((String)appointmentData.get('End_Time__c'));
            appointment.Description__c = (String) appointmentData.get('Description__c');
            insert appointment;
            return appointment.Id;
        }
        catch(Exception e){
            throw new AuraHandledException(
            'Error creating appointment: '+ e.getMessage()
            );
        }
    }

    public static Datetime parseISODateTime(String isoString){

        String cleaned =
            isoString.replace('T',' ')
                    .replace('Z','')
                    .substring(0,19);

        return Datetime.valueOfGmt(cleaned);
    }
}