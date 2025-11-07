public class OpportunityController {
	@AuraEnabled(cacheable=true)
	public static List<OpportunityWrapper> getOpportunities(){
		try{
			List<OpportunityWrapper> oppList = new List<OpportunityWrapper>();
			for(Opportunity op : [SELECT Id, Name, StageName, CloseDate, Amount FROM Opportunity Order BY Account.Name]){
				OpportunityWrapper ow = new OpportunityWrapper();
				ow.oppName = op.Name;
				ow.oppStage = op.StageName;
				ow.closeDate = op.CloseDate;
				ow.amount = op.Amount;
				ow.oppId = op.Id;
				oppList.add(ow);
			}
			return oppList;
		}catch(Exception e){
			throw new AuraHandledException(e.getMessage());
		}
	}

	public class OpportunityWrapper{
		@AuraEnabled
		public String oppId;
		@AuraEnabled
		public String oppName;
		@AuraEnabled
		public String oppStage;
		@AuraEnabled
		public Double amount;
		@AuraEnabled
		public Date closeDate;
	}
}