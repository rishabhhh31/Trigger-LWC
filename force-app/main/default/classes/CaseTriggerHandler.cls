public with sharing class CaseTriggerHandler {

    public static void preventArchiveCaseStatusChange(
        List<Case> newCases, 
        Map<Id, Case> oldMap
    ) {
        for (Case cs : newCases) {
            Case oldCase = oldMap.get(cs.Id);

            if (oldCase.Status == 'Archived' && cs.Status != 'Archived') {
                cs.addError('Archived cases cannot be changed back to another status.');
            }
        }
    }

    public static void autoArchiveCases(List<Case> newCases) {

        Date thresholdDate = Date.today().addDays(-30);

        for (Case cs : newCases) {
            if (
                cs.IsClosed &&
                cs.ClosedDate != null &&
                cs.Status != 'Archived' &&
                cs.ClosedDate != null &&
                !cs.IsEscalated &&
                cs.ClosedDate.date().daysBetween(Date.today()) > 30
            ) {
                cs.Status = 'Archived';
            }
        }
    }
}