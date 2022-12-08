@isTest
private class CommonTestSetup {
 
    public static list<sObject> setup() {
        // Create common test accounts
        list<sObject> listofRecords = new List<sObject>();

        /*Account acc = New Account();
        acc.FirstName = 'Test First Name';
        acc.LastName = 'Test Last Name';
        acc.PersonMailingCity = 'Toronto';
        acc.PersonMailingState = 'Ontario';
        acc.PersonMailingCountry = 'CANADA';
        acc.PersonMailingPostalCode = 'ON 3131 31';
        acc.Postal_FSA__c = 'ON 213 FAS';
        acc.Postal_LDU__c = 'ON 213 FAS';
        acc.Street_Direction__c = 'Test Street Description';
        acc.PersonMailingStreet = 'Street 1';
        acc.Street_Number__c = 'STN 213';
        acc.Street_Type__c = 'Camp';
        acc.Unit_Number__c = 'STU 212';
        
        insert acc;
        
        system.debug('acc ID =>' + acc.Id);
        
        
        Opportunity opp = New Opportunity ();
        
        opp.Name = 'New Opportunity';
        opp.AccountId = acc.Id;
        opp.StageName = 'Need Analysis';
        opp.CloseDate = date.today();
        opp.CJA_Mortgage__Deal_Purpose__c = 'Purchase';
        opp.Deal_Type__c	 = 'Approval';
        opp.Estimated_Close_Date__c = date.today();
        opp.Financing_Waiver_Date__c = date.today();
        opp.Referral_Reference_Number__c = 131;
        opp.Ref_Improvement_Amount__c = 25000;
        opp.Ref_Improvement_Description__c = 'Test Ref Description';
        opp.Ref_Improvements_Flag__c = True;
        opp.Ref_Purpose__c = 'Test Ref Purpose';
        opp.Source_Application_ID__c = 'Source Application Id';
        opp.Tax_Pay_Or__c = 'Borrower';
        opp.Third_Party_Application_Flag__c = true;
        opp.JSON__c = 'Opportunity JSON';
        opp.Amount = 55000;
        opp.Description = 'Test Opportunity Description';
        opp.Down_Payment_Source_Type__c = 'Existing Equity';            
        
        insert opp;
        system.debug('opp ID =>' + opp.Id);
        
        ResidentialLoanApplication Secrla =  New ResidentialLoanApplication();
        Secrla.FilogixId__c = 'CLJT-2';
        Secrla.Name = 'Test RLA 2';
        Secrla.AccountId = acc.Id;
        Secrla.OpportunityId = opp.id;
        
        insert Secrla;
        
                
        ResidentialLoanApplication Secrla2 =  New ResidentialLoanApplication();
        Secrla2.Name = 'Test RLA 3';
        Secrla2.AccountId = acc.Id;
        Secrla2.OpportunityId = opp.id;
        
        insert Secrla2;*/
        return listofRecords;
    }
    
}