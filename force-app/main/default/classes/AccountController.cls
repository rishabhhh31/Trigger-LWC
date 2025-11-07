public class AccountController {
	@AuraEnabled(cacheable=true)
	public static List<AccountWrapper> getCurrentUserAccount(){
		List<AccountWrapper> accountWrapperList = new List<AccountWrapper>();
		for(Account acc : [SELECT Id, Name, Type, BillingCountry, Total_Opportunity__c FROM Account WHERE OwnerId =: UserInfo.getUserId() LIMIT 50000]){
			AccountWrapper aw = new AccountWrapper();
			aw.accountId = acc.Id;
			aw.accName = acc.Name;
			aw.accType = acc.Type;
			aw.country = acc.BillingCountry;
			aw.totalOpp = (Integer)acc.Total_Opportunity__c;
			aw.accountLink = '/'+acc.Id;
			accountWrapperList.add(aw);
		}
		return accountWrapperList;
	}

	@AuraEnabled
	public static List<ContactWrapper> getRelatedContacts(String accountId){
		if(String.isBlank(accountId)){
			return null;
		}
		List<ContactWrapper> contactList = new List<ContactWrapper>();
		for(Contact con : [SELECT FirstName, LastName, Email FROM Contact WHERE AccountId =: accountId]){
			ContactWrapper cw = new ContactWrapper();
			cw.conId = con.Id;
			cw.firstName = con.FirstName;
			cw.lastName = con.LastName;
			cw.email = con.Email;
			contactList.add(cw);
		}
		return contactList;
	}

	@AuraEnabled(cacheable=true)
	public static List<AccountPicklistValue> getAccountPicklistValues(){
		List<AccountPicklistValue> accountWrapperList = new List<AccountPicklistValue>();
		System.debug(System.Label.Label1);
		for(Account acc : [SELECT Id, Name FROM Account ORDER BY Name LIMIT 50000]){
			AccountPicklistValue aw = new AccountPicklistValue();
			aw.value = acc.Id;
			aw.label = acc.Name;
			accountWrapperList.add(aw);
		}
		return accountWrapperList;
	}

	@AuraEnabled(cacheable=true)
	public static List<AccountWrapper> getAccountRadio(){
		List<AccountWrapper> accountWrapperList = new List<AccountWrapper>();
		for(Account acc : [SELECT Id, Name, Type, BillingCountry FROM Account WHERE OwnerId =: UserInfo.getUserId() LIMIT 50000]){
			AccountWrapper aw = new AccountWrapper();
			aw.accountId = acc.Id;
			aw.accName = acc.Name;
			aw.accType = acc.Type;
			aw.country = acc.BillingCountry;
			aw.accountLink = '/'+acc.Id;
			accountWrapperList.add(aw);
		}
		return accountWrapperList;
	}	

	@AuraEnabled
	public static Boolean contactDeletion(String contactId){
		try{
			System.debug(contactId);
			Database.DeleteResult result = Database.delete(contactId);
			return result.isSuccess();
		}catch(Exception e){
			throw new AuraHandledException(e.getMessage());
		}
	}	

	@AuraEnabled
	public static void deleteAccount(String accountId){
		List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE IsClosed = false AND AccountId =: accountId];
		if(oppList.size() > 0){
			throw new AuraHandledException('You can not delete account because it has related opportunity');
		}else{
			try {
				Database.delete(accountId);
			} catch (Exception e) {
				throw new AuraHandledException(e.getMessage());
			}
		}
	}

	@AuraEnabled
	public static AccountContactCaseWrapper getAccountContactsCases(String accId){
		try {
			AccountContactCaseWrapper accw = new AccountContactCaseWrapper();
			if(String.isBlank(accId)){
				return accw;
			}
			Account acc = [SELECT Id, (SELECT Id, FirstName, LastName, Phone, Email FROM Contacts), (SELECT Id, CaseNumber, Status, Subject FROM Cases) FROM Account WHERE Id=:accId LIMIT 1];
			accw.conList = new List<ContactWrapper>();
			for(Contact con : acc.Contacts){
				ContactWrapper cw = new ContactWrapper();
				cw.firstName = con.FirstName;
				cw.lastName = con.LastName;
				cw.email = con.Email;
				cw.conId = con.Id;
				cw.phone = con.Phone;
				accw.conList.add(cw);
			}
			
			accw.csList = new List<CaseWrapper>();
			for(Case cs : acc.Cases){
				CaseWrapper cw = new CaseWrapper();
				cw.caseNumber = cs.CaseNumber;
				cw.subject = cs.Subject;
				cw.status = cs.Status;
				cw.caseId = cs.Id;
				accw.csList.add(cw);
			}
			return accw;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled(cacheable=true)
	public static List<AccountOppCaseWrapper> getAccountOppCases(){
		try {
			List<AccountOppCaseWrapper> accountList = new List<AccountOppCaseWrapper>();
			for(Account acc : [SELECT Name, Type, BillingCountry, (SELECT Id, Name, StageName FROM Opportunities), (SELECT Id, CaseNumber, Status, Priority FROM Cases) FROM Account ORDER BY Name]){
				AccountOppCaseWrapper aoc = new AccountOppCaseWrapper();
				aoc.accName = acc.Name;
				aoc.accountId = acc.Id;
				aoc.accType = acc.Type;
				aoc.accountLink = '/'+acc.Id;
				aoc.country = acc.BillingCountry;
				aoc.opportunities = new List<OpportunityWrapper>();
				for(Opportunity op : acc.Opportunities){
					OpportunityWrapper ow = new OpportunityWrapper();
					ow.oppName = op.Name;
					ow.accName = acc.Name;
					ow.oppStage = op.StageName;
					ow.accountIdLink = '/'+acc.Id;
					ow.oppIdLink = '/'+op.Id;
					aoc.opportunities.add(ow);
				}
				
				aoc.cases = new List<CaseWrapper>();
				for(Case cs : acc.Cases){
					CaseWrapper cw = new CaseWrapper();
					cw.caseNumber = cs.CaseNumber;
					cw.priority = cs.Priority;
					cw.status = cs.Status;
					cw.accName = acc.Name;
					cw.accountIdLink = '/'+acc.Id;
					cw.caseIdLink = '/'+cs.Id;
					aoc.cases.add(cw);
				}
				accountList.add(aoc);
			}

			return accountList;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	public class AccountPicklistValue{
		@AuraEnabled
		public String label;
		@AuraEnabled
		public String value;
	}


	public class AccountWrapper{
		@AuraEnabled
		public String accName;
		@AuraEnabled
		public String accType;
		@AuraEnabled
		public String country;
		@AuraEnabled
		public Integer totalOpp;
		@AuraEnabled
		public String accountId;
		@AuraEnabled
		public String accountLink;
	}

	public class AccountOppCaseWrapper{
		@AuraEnabled
		public String accName;
		@AuraEnabled
		public String accType;
		@AuraEnabled
		public String country;
		@AuraEnabled
		public String accountId;
		@AuraEnabled
		public String accountLink;
		@AuraEnabled
		public List<OpportunityWrapper> opportunities;
		@AuraEnabled
		public List<CaseWrapper> cases;
	}

	public class OpportunityWrapper{
		@AuraEnabled
		public String oppName;
		@AuraEnabled
		public String accName;
		@AuraEnabled
		public String oppStage;
		@AuraEnabled
		public String oppIdLink;
		@AuraEnabled
		public String accountIdLink;
	}

	public class CaseWrapper{
		@AuraEnabled
		public String caseNumber;
		@AuraEnabled
		public String accName;
		@AuraEnabled
		public String priority;
		@AuraEnabled
		public String status;
		@AuraEnabled
		public String subject;
		@AuraEnabled
		public String caseIdLink;
		@AuraEnabled
		public String accountIdLink;
		@AuraEnabled
		public String caseId;
	}

	public class ContactWrapper{
		@AuraEnabled
		public String conId;
		@AuraEnabled
		public String firstName;
		@AuraEnabled
		public String lastName;
		@AuraEnabled
		public String email;
		@AuraEnabled
		public String phone;
	}

	public class AccountContactCaseWrapper{
		@AuraEnabled
		public List<ContactWrapper> conList;
		@AuraEnabled
		public List<CaseWrapper> csList;
	}
}