public class AccountTriggerHandler {
	/**
     * Generates sequential Account Auto Numbers in the format:
     * ACC-<CurrentYear>-<4DigitSequentialNumber>
     * Example: ACC-2025-0001
     *
     * @param accounts List of new Account records to assign numbers to
     */
	public static void generateAccountNumber(List<Account> accounts){
		// Get the current year as a string
		String currentYear = String.valueOf(System.today().year());

		// Build the pattern to find the latest Account Number from this year
        // Example: ACC-2025-%
		String accNumberStr = 'ACC-'+currentYear+'-%';

		// Default start number if none exist yet
		Integer nextNumber = 1;

		// Query to find the most recent Account number for this year
        // NOTE: LIMIT 1 with DESC order gives us the latest number
		List<Account> accountLastNumbers = [SELECT Id, Account_Auto_Number__c FROM Account WHERE Account_Auto_Number__c LIKE: accNumberStr ORDER BY Account_Auto_Number__c DESC LIMIT 1];

		// If there’s already an account with this year’s prefix, extract its last number
		if(!accountLastNumbers.isEmpty()){
			String accNumber = accountLastNumbers[0].Account_Auto_Number__c;
			String lastNumber = accNumber.substring(accNumber.lastIndexOf('-')+1);
			nextNumber = Integer.valueOf(lastNumber) + 1;
		}

		// Loop through all records in the trigger context (bulk-safe)
		for(Account acc : accounts){
			
			// Set the formatted Account Number
			String paddedNumber = 'ACC-'+currentYear+'-'+String.valueOf(nextNumber).leftPad(4,'0');
			acc.Account_Auto_Number__c = paddedNumber;
			
			// Increment for next Account record in the same transaction
			nextNumber++;
		}
	}

	public static void accountScoring(List<Account> accounts){
		Set<Id> accIds = new Set<Id>();
		if(Trigger.isUpdate){
			for(Account acc : accounts){
				accIds.add(acc.Id);
			}
		}

		Map<Id, Decimal> opportunityAmountMap = new Map<Id, Decimal>();
		Map<Id, Integer> opportunityCountMap = new Map<Id, Integer>();
		Map<Id, Integer> contactCountMap = new Map<Id, Integer>();
		if(!accIds.isEmpty()){
			for(AggregateResult result : [SELECT AccountId, count(Id)oppCount, SUM(Amount)oppAmount FROM Opportunity WHERE AccountId IN: accIds GROUP BY AccountId]){
				Id accId = (Id) result.get('AccountId');
				Integer count = (Integer) result.get('oppCount');
				Decimal amount = (Decimal) result.get('oppAmount');
				opportunityAmountMap.put(accId, amount);
				opportunityCountMap.put(accId, count);
			}

			for(AggregateResult result : [SELECT AccountId, count(Id)conCount FROM Contact WHERE AccountId IN: accIds GROUP BY AccountId]){
				Id accId = (Id) result.get('AccountId');
				Integer count = (Integer) result.get('conCount');
				contactCountMap.put(accId, count);
			}
		}

		for(Account acc : accounts){
			Integer totalScore = 0;
			if(acc.AnnualRevenue != null){
				if(acc.AnnualRevenue >= 10000000){
					totalScore += 40;
				} else if(acc.AnnualRevenue >= 5000000){
					totalScore += 35;
				} else if(acc.AnnualRevenue >= 1000000){
					totalScore += 30;
				} else if(acc.AnnualRevenue >= 500000){
					totalScore += 20;
				} else if(acc.AnnualRevenue >= 100000){
					totalScore += 10;
				}
			}

			if(acc.NumberOfEmployees != null){
				if(acc.NumberOfEmployees >= 1000){
					totalScore += 20;
				} else if(acc.NumberOfEmployees >= 500){
					totalScore += 15;
				} else if(acc.NumberOfEmployees >= 100){
					totalScore += 10;
				} else if(acc.NumberOfEmployees >= 50){
					totalScore += 5;
				}
			}

			if(acc.Industry != null){
				if(acc.Industry == 'Technology' || acc.Industry == 'Financial Services'){
					totalScore += 15;
				} else if(acc.Industry == 'Healthcare' || acc.Industry == 'Manufacturing'){
					totalScore += 10;
				} else {
					totalScore += 5;
				}
			}

			if(opportunityCountMap.containsKey(acc.Id)){
				Integer oppCount = opportunityCountMap.get(acc.Id);
				if(oppCount >= 5){
					totalScore += 10;
				} else if(oppCount >= 2){
					totalScore += 5;
				}
			}

			if(opportunityAmountMap.containsKey(acc.Id)){
				Decimal oppAmount = opportunityAmountMap.get(acc.Id);
				if(oppAmount >= 500000){
					totalScore += 10;
				} else if(oppAmount >= 100000){
					totalScore += 5;
				}
			}

			if(contactCountMap.containsKey(acc.Id)){
				Integer conCount = contactCountMap.get(acc.Id);
				if(conCount >= 5){
					totalScore += 5;
				} else if(conCount >= 2){
					totalScore += 3;
				}
			}

			if(totalScore >= 80){
				acc.Rating = 'Hot';
				acc.Priority__c = 'High';
			} else if(totalScore >= 60){
				acc.Rating = 'Warm';
				acc.Priority__c = 'Medium';
			} else{
				acc.Rating = 'Cold';
				acc.Priority__c = 'Low';
			}
			if(totalScore >= 90) {
				acc.Tier__c = 'Tier 1 – Strategic';
			} else if(totalScore >= 70) {
				acc.Tier__c = 'Tier 2 – Key';
			} else if(totalScore >= 50) {
				acc.Tier__c = 'Tier 3 – Standard';
			} else {
				acc.Tier__c = 'Tier 4 – Basic';
			}
		}
	}
}