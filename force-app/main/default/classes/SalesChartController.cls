public with sharing class SalesChartController {
    @AuraEnabled(cacheable=true)
    public static List<SalesDataWrapper> getSalesData() {
        List<SalesDataWrapper> salesData = new List<SalesDataWrapper>();
        List<AggregateResult> results = [
                                        SELECT CALENDAR_MONTH(CloseDate) month, SUM(Amount) total
                                        FROM Opportunity
                                        WHERE StageName = 'Closed Won' AND CloseDate =
                                        THIS_YEAR
                                        GROUP BY CALENDAR_MONTH(CloseDate)
                                        ORDER BY CALENDAR_MONTH(CloseDate)
                                        ];
        for (AggregateResult ar : results) {
            salesData.add(new SalesDataWrapper(String.valueOf(ar.get('month')),(Decimal) ar.get('total')));
        }
        return salesData;
    }
    public class SalesDataWrapper {
        @AuraEnabled public String Month;
        @AuraEnabled public Decimal Amount;
        public SalesDataWrapper(String month, Decimal amount) {
            this.Month = month;
            this.Amount = amount;
        }
    }
}