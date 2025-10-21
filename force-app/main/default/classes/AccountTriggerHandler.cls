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
		List<Account> accountLastNumbers = [SELECT Id, Account_Auto_Number__c FROM Account
											WHERE Account_Auto_Number__c LIKE: accNumberStr
											ORDER BY Account_Auto_Number__c DESC LIMIT 1
											];

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
}