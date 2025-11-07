public with sharing class DateValidationController {
    @AuraEnabled
    public static void validateDate(Date inputDate) {
        if (inputDate > Date.today()) {
            throw new AuraHandledException('The provided date cannot be in the future.');
        }
    }
}