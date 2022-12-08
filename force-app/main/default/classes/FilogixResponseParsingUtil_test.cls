/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-15-2022
 * @last modified by  : M Hamza Siddiqui
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   05-04-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
@istest
public class FilogixResponseParsingUtil_test {
    public static String appNameSpace = FilogixWrapperBinding.getAppNameSpace();
	
    @isTest
    public static sObject testDataGET(){
        // Getting App Namespace
        appNameSpace = FilogixWrapperBinding.getAppNameSpace();

         // Checking Permissions before Query
        FilogixWrapperBinding.permChecker('Profile','Id', 'read');
		// Checking Permissions before DML
        FilogixWrapperBinding.permChecker('User',appNameSpace+'Filogix_Id__c,Alias,Email,EmailEncodingKey,LastName,LanguageLocaleKey,LocaleSidKey,ProfileId,TimeZoneSidKey,UserName', 'create');
        // Creating a new user
         Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' WITH SECURITY_ENFORCED]; 
         User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
             EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
             LocaleSidKey='en_US', ProfileId = p.Id, Filogix_Id__c='Agent2',
             TimeZoneSidKey='America/Los_Angeles', UserName='standarduser233@testorg.com');
         insert u;

        //Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        // Because the Person Account RecordType can have a differrent name.
        String PArecordTypeId;
        String sObjT = 'Account';
        // Checking Permissions before Query
        FilogixWrapperBinding.permChecker('RecordType','Id, Name, SobjectType,IsPersonType', 'read');
        String personAccountQuery = 'SELECT Id, Name, SobjectType,IsPersonType FROM RecordType WHERE SobjectType=:sObjT AND IsPersonType=True limit 1';
        sObject personAccountData = Database.query(String.escapeSingleQuotes(personAccountQuery));
        if(personAccountData!=null){
            PArecordTypeId = String.valueof(personAccountData.Id);
        } else {
            String errorMsg = 'Please <a target="_blank" href="https://developer.salesforce.com/docs/atlas.en-us.financial_services_cloud_admin_guide.meta/financial_services_cloud_admin_guide/fsc_admin_enable_person_acct.htm">Enable the Person Account</a>.';
            throw FilogixWrapperBinding.createCustomException(errorMsg);
        }
        //String PArecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        set<string> setOfOppIds = new set<string>();
 
        String accountObjectApiName ='Account';
         sObject acc = Schema.getGlobalDescribe().get(accountObjectApiName).newSObject();
         //Account acc = New Account();
         acc.put('FirstName','Test First Name');
             acc.put('LastName', 'Test Last Name');
             acc.put('PersonMailingCity', 'Toronto');
             acc.put('PersonMailingState', 'Ontario');
             acc.put('PersonMailingCountry', 'CANADA');
             acc.put('PersonMailingPostalCode', 'ON 3131 31');
        	 acc.put('PersonBirthDate', date.today());
             acc.put('PersonEmail','test@email.com');
      	//	 acc.put('HomePhone', '3123123131');
         //    acc.put('Work_Phone__c', '3123123131');
        	//acc.put('PersonMobilePhone','331314');	

             //acc.put('Street_Direction__c', 'Test Street Description');
             acc.put('PersonMailingStreet', 'Street 1');
             //acc.put('Street_Number__c', 'STN 213');
             //acc.put('Street_Type__c', 'Camp');
             //acc.put('Unit_Number__c', 'STU 212');
             acc.put('RecordtypeId', PArecordTypeId);
         insert acc;
         
         System.assert(acc!= null);

         String SecResidentialLoanApplicationObjectApiName ='ResidentialLoanApplication';
         sObject rla = Schema.getGlobalDescribe().get(SecResidentialLoanApplicationObjectApiName).newSObject();
 		// Checking Permissions before Query
        FilogixWrapperBinding.permChecker(SecResidentialLoanApplicationObjectApiName,'FilogixId__c', 'update');
        rla.put('Name' , 'Test RLA');
        rla.put('AccountId' , String.valueof(acc.get('Id')));
        rla.put(appNameSpace+'FilogixId__c' , 'EXBA-35');
        rla.put('ownerId', (ID) u.Id);
        insert rla;

         StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
         mock.setStaticResource('GET_Sample_Response');
         mock.setStatusCode(200);
         mock.setHeader('Content-Type', 'application/json');
         
         // Set the mock callout mode
         Test.setMock(HttpCalloutMock.class, mock);
        StaticResource srObject = [SELECT id, body FROM StaticResource WHERE Name = 'GET_Sample_Response' WITH SECURITY_ENFORCED];
        String json = srObject.body.toString();
        
        MockHttpResponseForGetFilogix fakeRes = new MockHttpResponseForGetFilogix(json);
        Test.setMock(HttpCalloutMock.class,fakeRes);
    
        FilogixGETJSONWrapper res = FilogixGETJSONWrapper.parse(json);
        return rla;
    }

    @isTest
    public static sObject testData(){
        
        // Getting App Namespace
        appNameSpace = FilogixWrapperBinding.getAppNameSpace();
        
        // Creating a new user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' WITH SECURITY_ENFORCED]; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, Filogix_Id__c='Agent2',
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser233@testorg.com');
		insert u;
           
        //String PArecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        //String PArecordTypeId = [SELECT Id, Name, SobjectType,IsPersonType FROM RecordType WHERE SobjectType='Account' AND IsPersonType=True].Id;
        String PArecordTypeId;
        String sObjT = 'Account';
        // Checking Read Permission for Account and their fields before Query
        FilogixWrapperBinding.permChecker('RecordType', 'Id, SobjectType,Name, IsPersonType', 'read');
        String personAccountQuery = 'SELECT Id, Name, SobjectType,IsPersonType FROM RecordType WHERE SobjectType=:sObjT AND IsPersonType=True limit 1';
        List<sObject> personAccountData = Database.query(String.escapeSingleQuotes(personAccountQuery));
        if(personAccountData!=null){
            PArecordTypeId = String.valueof(personAccountData[0].Id);
        }

        set<string> setOfOppIds = new set<string>();
 
        String accountObjectApiName ='Account';
        sObject acc = Schema.getGlobalDescribe().get(accountObjectApiName).newSObject();
        
        //Account acc = New Account();
        acc.put('RecordtypeId', PArecordTypeId);
        acc.put('FirstName','Test First Name');
        acc.put('LastName', 'Test Last Name');
        acc.put('PersonMailingCity', 'Toronto');
        acc.put('PersonMailingState', 'Ontario');
        acc.put('PersonMailingCountry', 'CANADA');
        acc.put('PersonMailingPostalCode', 'ON 3131 31');
        acc.put('PersonEmail','test@email.com');
        acc.put('PersonBirthDate', date.today());
        
         insert acc;
         system.debug('AccountId::'+acc.Id); 
        
         //System.assert(acc!= null);
         Account accTest = [Select PersonBirthDate,PersonContactId,RecordtypeId,FirstName,LastName,PersonMailingCity,PersonMailingState,PersonMailingCountry,PersonMailingPostalCode,PersonEmail from Account where Id=:acc.Id limit 1];
         System.assertEquals(accTest.PersonBirthDate,date.today());
     	
		 //acc.PersonContactId = accTest.PersonContactId;
         //system.debug('PersonAccountId::'+accTest.PersonContactId); 
        
         //Opportunity opp = New Opportunity ();
         String opportunityObjectApiName ='Opportunity';
         sObject opp = Schema.getGlobalDescribe().get(opportunityObjectApiName).newSObject();
         
         opp.put('Name', 'New Opportunity');
         opp.put('AccountId', String.valueof(acc.get('Id')));
         opp.put('StageName', 'Need Analysis');
         opp.put('CloseDate', date.today());
         opp.put('Amount', 55000);
         
         insert opp;
         System.assert(opp!= null);

 
         String SecResidentialLoanApplicationObjectApiName ='ResidentialLoanApplication';
         sObject rla = Schema.getGlobalDescribe().get(SecResidentialLoanApplicationObjectApiName).newSObject();
 
             rla.put('Name' , 'Test RLA');
             rla.put('AccountId' , String.valueof(acc.get('Id')));
             rla.put('OpportunityId' , String.valueof(opp.get('Id')));

            rla.put(appNameSpace+'Deal_Purpose__c', 'Purchase');
            rla.put('Deal_Type__c','Approval');
            rla.put('Estimated_Closing_Date__c', date.today());
            rla.put('Financing_Waiver_Date__c', date.today());
            rla.put('Referral_Reference_Number__c', '131');
            rla.put('Ref_Improvement_Amount__c', 25000);
            rla.put('Ref_Improvement_Description__c', 'Test Ref Description');
            rla.put('Ref_Improvements_Flag__c', True);
            rla.put('Ref_Purpose__c', 'Test Ref Purpose');
            //rla.put('Source_Application_ID__c', 'Source Application Id');
            rla.put('Tax_Payor__c', 'Borrower');
            rla.put('Third_Party_Application_Flag__c', true);
            //rla.put('Description', 'Test Opportunity Description');
            //rla.put('Down_Payment_Source_Type__c', 'Existing Equity');   
         	rla.put('OwnerId', u.Id);
         insert rla;

         String lapplicantObjectApiname ='LoanApplicant';
         sObject lapplicant = Schema.getGlobalDescribe().get(lapplicantObjectApiname).newSObject();
             lapplicant.put('LoanApplicationId', String.valueof(rla.get('Id')));
       	//	 lapplicant.put('LoanApplicationId', rla.Id);
             lapplicant.put('ContactId',String.valueof(accTest.PersonContactId));
        	 system.debug('ContactId::'+String.valueof(accTest.PersonContactId));
             lapplicant.put('ApplicantExtIdentifier' , 'test-la-1');
             lapplicant.put('PreferredLanguage' , 'English');
             lapplicant.put('MaritalStatus' , 'Married');
             lapplicant.put('Name' , 'Test Applicant 1');
        	 //lapplicant.put('Email__c','test@email.com');
             lapplicant.put('DependentCount' , 4);
             lapplicant.put('Preferred_Contact_Method__c' , 'Email');
             lapplicant.put('Primary_Applicant__c' , false);
             //lapplicant.put('Social_Insurance_Number__c' , '4313242');
             lapplicant.put('Relationship_To_Primary_Applicant__c' , 'Spouse');
             lapplicant.put('Existing_Client__c' , true);
             lapplicant.put('First_Time_Buyer__c' , true);
             //lapplicant.put('Identification_Country__c' , 'CA');
             //lapplicant.put('Identification_Number__c' , 'LA1234');
             //lapplicant.put('Identification_Type__c' , 'Country');
             lapplicant.put('Relationship_To_Primary_Applicant__c','Other');

         
         insert lapplicant;
         System.debug('TestApplicantId::'+lapplicant.id);
         System.assert(lapplicant != null);

        
        String LoanApplicantAddressObjectApiname =appNameSpace+'LoanApplicantAddress';
        sObject lappAddress = Schema.getGlobalDescribe().get(LoanApplicantAddressObjectApiname).newSObject();
        lappAddress.put('Name', 'Test Loan Applicant Address');
        lappAddress.put('LoanApplicationId',rla.id);
        lappAddress.put('LoanApplicantId', lapplicant.id);
        lappAddress.put('City__c', 'Toronto');
        lappAddress.put('Province__c', 'Ontario');
        lappAddress.put('Country__c', 'Canada');
        lappAddress.put('PostalCode__c', 'm2m2m2');
        //lappAddress.put('Postal_FSA__c', 'Test Postal FSA');
        //lappAddress.put('Postal_LDU__c', 'Test Postal LDU');
        lappAddress.put('ResidencyType', 'Current');
        lappAddress.put('Street_Direction__c', 'NW');
        lappAddress.put('Mailing_Address__c', true);
        lappAddress.put('Street_Name__c', 'Albert Street 1');
        lappAddress.put('Street_Number__c', '1' );
        lappAddress.put('ResidenceYearCount', 4);
        lappAddress.put('AddressOwnership', 'Own');
        lappAddress.put('Street_Type__c', 'Bypass'); 
        lappAddress.put('Unit_Number__c', '45'); 
        lappAddress.put('MonthlyRentPayment', 55000);
        insert lappAddress;
        System.assert(lappAddress != null);
        
        LoanApplicantAddress ladTest = [Select id, LoanApplicantId from LoanApplicantAddress where Id=:lappAddress.Id limit 1];
        System.assertEquals(ladTest.LoanApplicantId,lappAddress.get('LoanApplicantId'));
        
        System.debug('TestApplicantId::'+lapplicant.id);
        System.debug('TestlappAddress::'+lappAddress.id);
        
         String LoanApplicationPropertyObjectApiname ='LoanApplicationProperty';
         sObject lap = Schema.getGlobalDescribe().get(LoanApplicationPropertyObjectApiname).newSObject();
 
         {
             lap.put(appNameSpace+'AppraisedValue__c',50000);
             lap.put('LoanApplicationId',String.valueof(rla.get('id')));
             lap.put(appNameSpace+'Appraisal_Date__c',date.today().addMonths(4));
             lap.put(appNameSpace+'Loan_Applicant__c',String.valueof(lapplicant.get('Id')));
             //lap.put(appNameSpace+'Style__c', 'Storey and a Half');
             lap.put('PropertyValue', 75000);
             lap.put('ExpNetMonthlyRentalInc', 90000);
             lap.put(appNameSpace+'feesIncludeHeat__c', true);
             lap.put(appNameSpace+'Garage_Size__c','Double');
             lap.put(appNameSpace+'Garage_Type__c','Attached');
             lap.put(appNameSpace+'Heat__c','Electric Baseboard');
             lap.put(appNameSpace+'includetds__c',true);
             lap.put(appNameSpace+'insulatedWithUffi__c', true);
             lap.put(appNameSpace+'lot__c','Legal Line 1');
             lap.put(appNameSpace+'block__c','Legal Line 2');
             lap.put(appNameSpace+'Conc_Township__c','Legal Line 3');
             lap.put(appNameSpace+'livingSpace__c',7); 
             lap.put(appNameSpace+'livingSpaceUnitOfMeasurDd__c','Sq Ft');
             lap.put('RequestedLoanAmount',45000);
             lap.put('PropertyExtIdentifier','PropertyExtIdentifier Test External ID');
             lap.put('LoanPurposeType','Purchase');
             
             lap.put(appNameSpace+'lotSize__c', 7);
             lap.put(appNameSpace+'lotSizeUnitOfMeasure__c','Hectares');
             lap.put('IsManufacturedHome', true);
             //lap.put(appNameSpace+'PropertyState__c','Ontario');
             //lap.put(appNameSpace+'Loan_Applic__c', 'CA');
             lap.put('IsMixedUseProperty',false);
             lap.put(appNameSpace+'mlsListingFlag__c',true);
             lap.put('Name','Test Loan Application Property');
             lap.put(appNameSpace+'Construction_Type__c','New');
             lap.put(appNameSpace+'numberOfUnits__c',4);
             lap.put('PropertyUseType','Owner Occupied and Rental');
             //    lap.put(appNameSpace+'PropertyAddress,
             lap.put(appNameSpace+'Property_Type__c','FreeHold');
             lap.put(appNameSpace+'purchasePrice__c', 96000);
             lap.put(appNameSpace+'realtorInfo__c','Test Realtor Info');
             lap.put(appNameSpace+'rentalOffsetOption__c','Add Percentage to Gross Income');
             lap.put(appNameSpace+'Sewage_Type__c','Holding Tank');
             lap.put(appNameSpace+'structureAge__c',48);
             lap.put(appNameSpace+'taxationYear__c',2020);
             lap.put('UnitsFinancedCount',  3);
             lap.put(appNameSpace+'Water_Type__c', 'Municipal');
             lap.put(appNameSpace+'Street_Name__c','Test Property Street');
             lap.put(appNameSpace+'City__c','Toronto');
             lap.put(appNameSpace+'Street_Number__c','2');
             lap.put(appNameSpace+'PostalCode__c','M2M2M2');
             lap.put(appNameSpace+'Country__c', 'Canada');
             lap.put(appNameSpace+'Province__c', 'Ontario');
             lap.put(appNameSpace+'Street_Type__c','Boulevard');
             lap.put(appNameSpace+'Structure_Type__c', 'Modular Home Semi Detached');
             lap.put(appNameSpace+'PropertyUnitNumber__c', 'Test Property Unit Number');
             lap.put(appNameSpace+'Direction__c','NW');
             lap.put('ExpMonthlyRentalIncome', 33000);
             lap.put(appNameSpace+'Rental_Income_Period__c','Semi Annual');
             lap.put(appNameSpace+'Rental_Income_Type__c','Interest Income');
             lap.put(appNameSpace+'Rental_IncPercentInTds__c',48);
             lap.put(appNameSpace+'Is_Subject_Property__c',true);
             
             //Expenses of Property
             lap.put(appNameSpace+'Annual_Taxes__c',321);
             lap.put(appNameSpace+'Insurance_Expenses__c',321);
             lap.put(appNameSpace+'Heating_Expenses__c',321);
             lap.put(appNameSpace+'Hydro_Expenses__c',321);
             lap.put(appNameSpace+'Management_Expenses__c',321);
             lap.put(appNameSpace+'Other_Expenses__c',321);
             lap.put(appNameSpace+'Repairs_Expenses__c',321);
             lap.put(appNameSpace+'Total_Condo_Fees__c',321);
             lap.put(appNameSpace+'Interest_Expenses__c',321);
         }
     
         insert lap;  
 
         rla.put(appNameSpace+'Subject_Property__c' , String.valueof(lap.get('id')));
         update rla;  
         System.assert(lap!= null);
        
        String PropertyMortgageObjectApiname =appNameSpace+'Mortgage__c';
        sObject mort = Schema.getGlobalDescribe().get(PropertyMortgageObjectApiname).newSObject();
        mort.put('Name','first');
        mort.put('Loan_Application__c',String.valueof(rla.get('id')));
        mort.put(appNameSpace+'Loan_Application_Property__c',String.valueof(lap.get('id')));
        mort.put(appNameSpace+'Existing_Mortgage__c',true);
        mort.put(appNameSpace+'Interest_Rate__c',0);
        mort.put(appNameSpace+'Mortgage_Type__c','First');
        mort.put(appNameSpace+'Original_Mortgage_Amount__c',3211);
        mort.put(appNameSpace+'Balance_Remaining__c',2300);
        mort.put(appNameSpace+'Existing_Mortgage_Holder__c','John Doe');
        mort.put(appNameSpace+'PAndIPaymentAmount__c',23000);
        mort.put(appNameSpace+'Payment_Frequency__c','Monthly');
        mort.put(appNameSpace+'Payment_Term__c','Open');
        mort.put(appNameSpace+'Interest_Type__c','Fixed');
        mort.put(appNameSpace+'Loan_Type__c','Mortgage');
        mort.put(appNameSpace+'Current_Mortgage_Number__c','1');
        mort.put(appNameSpace+'Maturity_Date__c',date.today());
        mort.put(appNameSpace+'Payment_Frequency__c','Monthly');


        insert mort;
        
        sObject mort1 = Schema.getGlobalDescribe().get(PropertyMortgageObjectApiname).newSObject();
        mort1.put('Name','second');
        mort1.put('Loan_Application__c',String.valueof(rla.get('id')));
        mort1.put(appNameSpace+'Loan_Application_Property__c',String.valueof(lap.get('id')));
        mort1.put(appNameSpace+'Existing_Mortgage__c',false);
        mort1.put(appNameSpace+'Interest_Rate__c',0);
        mort1.put(appNameSpace+'Mortgage_Type__c','Second');
        mort1.put(appNameSpace+'Loan_Type__c','Mortgage');
        mort1.put(appNameSpace+'Net_Loan_Amount__c',5000);
        mort1.put(appNameSpace+'Payment_Frequency__c','Monthly');
        mort1.put(appNameSpace+'Payment_Term__c','Open');

        
 		
        insert mort1;
 
         setOfOppIds.add(String.valueOf(rla.get('OpportunityId')));
         System.assert(rla!= null);

          
         String LoanApplicationAssetObjectApiname ='LoanApplicationAsset';
         sObject loanAppAsset = Schema.getGlobalDescribe().get(LoanApplicationAssetObjectApiname).newSObject();
         loanAppAsset.put('Name','Test Loan Application Asset');
         loanAppAsset.put('LoanApplicationId',String.valueof(rla.get('Id')));
         loanAppAsset.put('CashOrMarketValue' , 99000);
         loanAppAsset.put('AssetType' , 'Autoroute');	
         loanAppAsset.put('CJA_Mortgage__Down_Payment_Amount__c' , 150000); 
        loanAppAsset.put('CJA_Mortgage__Description__c' , 'Test Description'); 

         insert loanAppAsset;
         System.assert(loanAppAsset != null);
         
 
         String LoanApplicantAssetObjectApiname ='LoanApplicantAsset';
         sObject lapasset = Schema.getGlobalDescribe().get(LoanApplicantAssetObjectApiname).newSObject();
         //LoanApplicantAsset lapasset = New LoanApplicantAsset();
         lapasset.put('LoanApplicantId',String.valueof(lapplicant.get('Id')));
         lapasset.put('LoanApplicationAssetId',String.valueof(loanAppAsset.get('Id')));
         //lapasset.put(appNameSpace+'Description__c' , 'Test Description of Loan Applicant asset');
         //lapasset.put(appNameSpace+'Type__c' , 'Autoroute');
         //lapasset.put(appNameSpace+'Value__c' , 99000);
         //lapasset.put(appNameSpace+'Down_Payment_Amount__c' , 150000);
         insert lapasset;
         
         System.assert(lapasset != null);
         
 
         String LoanApplicantIncomeObjectApiname =appNameSpace+'LoanApplicantIncome';
         sObject lapIncome = Schema.getGlobalDescribe().get(LoanApplicantIncomeObjectApiname).newSObject();
 
         //LoanApplicantIncome lapIncome = New LoanApplicantIncome();
         {
             lapIncome.put('Name','Test Loan Applicant Income');
             //lapIncome.put('LoanApplicantId','Test Loan Applicant Income');
             lapIncome.put('Description__c','Loan Applicant Income Description');
             lapIncome.put('Income_Amount__c',25000);

             lapIncome.put('IncomeSourceType','Mortgage Differential Payments');
             lapIncome.put('MonthlyIncomeAmount',200000);
             lapIncome.put('Income_Period__c','Semi Annual');
             lapIncome.put('LoanApplicationId',String.valueof(rla.get('Id')));
             lapIncome.put('LoanApplicantId',String.valueof(lapplicant.get('Id')));
             lapIncome.put('IncomeExtIdentifier','Income External Id');
 
         }
             
         insert lapIncome;
         System.assert(lapIncome != null);
           system.assert(lapIncome.get('Name') == 'Test Loan Applicant Income');
         
 
         String LoanApplicantEmploymentObjectApiname =appNameSpace+'LoanApplicantEmployment';
         sObject lappEmp = Schema.getGlobalDescribe().get(LoanApplicantEmploymentObjectApiname).newSObject();
 
         
         {
             lappEmp.put('loanapplicantId',String.valueof(lapplicant.get('id')));
             lappEmp.put('LoanApplicationId',String.valueof(rla.get('id')));
             lappEmp.put('JobTitle','CEO');
             lappEmp.put('EmployerName','Test Filogix');
             lappEmp.put('History_Status__c','Previous');
             lappEmp.put('History_Type__c','Part Time');
             lappEmp.put('MonthlyIncome',150000);
             lappEmp.put('Industry_Sector__c','Leisure Entertainment');
 
             lappEmp.put('Company_Type__c','Enterprise');
             lappEmp.put('Amount__c',25000);
             lappEmp.put('IsSelfEmployed',False);
             lappEmp.put('Income_Frequency__c','Monthly');
             lappEmp.put('Occupation__c','Management');
             lappEmp.put('Name','Test Loan Applicant Employment');
 
             lappEmp.put('Type__c','Other Employment Income');
             lappEmp.put('CurrentJobAdditionalMonthCount',2);
             lappEmp.put('EmployerStreet','Richardson Street');
             lappEmp.put('EmployerCity','Toronto');
             lappEmp.put('EmployerPostalCode','TW 323 213');
             
             lappEmp.put('EmployerCountry','CA');
             lappEmp.put('EmployerState','Ontario');
             lappEmp.put('EmployerPhone','555 444 331 1');
            
         }
        
         insert lappEmp;
         System.assert(lappEmp != null);
       
         String LoanApplicationLiabilityObjectApiname =appNameSpace+'LoanApplicationLiability';
         sObject lappLiability = Schema.getGlobalDescribe().get(LoanApplicationLiabilityObjectApiname).newSObject();
 
 
         // LoanApplicationLiability lappLiability = New LoanApplicationLiability();
         
 
         lappLiability.put('Name','Test Loan Application Liability');
         lappLiability.put('CreditLimitAmount',70000);
         lappLiability.put('Credit_Bureau__c',false);
         //lappLiability.put('Liability_Description__c','Test Loan Application Liability Description');
         lappLiability.put('MonthlyPaymentAmount',3500);
         lappLiability.put('Liability_PayOff_Type__c','Test Payoff Type');
         lappLiability.put('OtherLiabilityType','Credit Card');
         lappLiability.put('Maturity_Date__c',date.today().addMonths(4));
         lappLiability.put('Monthly_Payment_Override__c',true);
         lappLiability.put('Liability_Amount__c',35000);
         lappLiability.put('LoanApplicationId',String.valueof(rla.get('Id')));
 
     
         insert lappLiability;
         System.assert(lappLiability != null);
         
 
         String LoanApplicantLiabilityObjectApiname =appNameSpace+'LoanApplicantLiability';
         sObject loanapplicantLiability = Schema.getGlobalDescribe().get(LoanApplicantLiabilityObjectApiname).newSObject();
 
         // LoanApplicantLiability loanapplicantLiability = New LoanApplicantLiability();
         
         LoanApplicantLiability.put('LoanApplicantId',String.valueof(lapplicant.get('Id')));
         LoanApplicantLiability.put('LoanApplicationLiabilityId',String.valueof(lappLiability.get('Id')));
 
         // loanapplicantLiability.LoanApplicantId = lapplicant.id;
         // loanapplicantLiability.LoanApplicationLiabilityId = lappLiability.id;
        
            insert loanapplicantLiability;
         System.assert(loanapplicantLiability != null);
        
         
         String loanApplicationPropObjectApiname = 'LoanApplicationProperty';
         sObject loanApplicationProp = Schema.getGlobalDescribe().get(loanApplicationPropObjectApiname).newSObject();
 
 
         loanApplicationProp.put(appNameSpace+'AppraisedValue__c', 200000);
         loanApplicationProp.put('LoanApplicationId', String.valueof(rla.get('Id')));
         loanApplicationProp.put(appNameSpace+'Appraisal_Date__c', date.today().addMonths(7));
         loanApplicationProp.put(appNameSpace+'Style__c', 'Storey and a Half');
         loanApplicationProp.put('PropertyValue', 180000);
         loanApplicationProp.put('ExpNetMonthlyRentalInc', 7000);
         loanApplicationProp.put(appNameSpace+'feesIncludeHeat__c', true);
         loanApplicationProp.put(appNameSpace+'Garage_Size__c', 'Double');
         loanApplicationProp.put(appNameSpace+'Garage_Type__c', 'Attached');
         loanApplicationProp.put(appNameSpace+'Heat__c', 'Forced Air Gas Oil Electric');
         loanApplicationProp.put(appNameSpace+'includetds__c', true);
         loanApplicationProp.put(appNameSpace+'insulatedWithUffi__c', true);
         loanApplicationProp.put(appNameSpace+'lot__c', 'Test Legal Line 1');
         loanApplicationProp.put(appNameSpace+'block__c', 'Test Legal Line 2');
         loanApplicationProp.put(appNameSpace+'Conc_Township__c', 'Test Legal Line 3');
         loanApplicationProp.put(appNameSpace+'livingSpace__c', 23);
         loanApplicationProp.put(appNameSpace+'livingSpaceUnitOfMeasurDd__c', 'Sq Ft');
         loanApplicationProp.put('RequestedLoanAmount', 190000);
         loanApplicationProp.put('PropertyExtIdentifier', 'Test External Id');
         loanApplicationProp.put('LoanPurposeType', 'Purchase');
         
 
         loanApplicationProp.put(appNameSpace+'lotSize__c', 2300);
         loanApplicationProp.put(appNameSpace+'lotSizeUnitOfMeasure__c', 'Hectares');
         loanApplicationProp.put('IsManufacturedHome', True);
         loanApplicationProp.put('IsMixedUseProperty', True);
         loanApplicationProp.put(appNameSpace+'mlsListingFlag__c', True);
         loanApplicationProp.put('Name', 'Test Loan Application Property');
         loanApplicationProp.put(appNameSpace+'Construction_Type__c', 'Existing');
         loanApplicationProp.put(appNameSpace+'numberOfUnits__c', 24);
         loanApplicationProp.put('PropertyUseType', 'Owner Occupied');
         loanApplicationProp.put(appNameSpace+'Property_Type__c', 'condo');
         loanApplicationProp.put(appNameSpace+'purchasePrice__c', 60000);
         loanApplicationProp.put(appNameSpace+'realtorInfo__c', 'Test Realtor Info');
         loanApplicationProp.put(appNameSpace+'rentalOffsetOption__c',  'Add Percentage to Gross Income');
         loanApplicationProp.put(appNameSpace+'Sewage_Type__c', 'Municipal');
         loanApplicationProp.put(appNameSpace+'structureAge__c', 45);
         loanApplicationProp.put(appNameSpace+'taxationYear__c', 2020);
         loanApplicationProp.put('UnitsFinancedCount', 20);
         loanApplicationProp.put(appNameSpace+'Water_Type__c', 'Municipal');
         /*loanApplicationProp.put('PropertyStreet', 'Loan Application Property Street');
         loanApplicationProp.put('PropertyCity','Loan Application Property City');
         loanApplicationProp.put('PropertyStreetNumber__c', '4');
         loanApplicationProp.put('PropertyUnitNumber__c', '31');
         loanApplicationProp.put('PropertyPostalCode' , 'ON 13 131');
         loanApplicationProp.put('PropertyCountry', 'CA');
         loanApplicationProp.put('PropertyState', 'ON');*/
        
        loanApplicationProp.put(appNameSpace+'Street_Name__c','Test Property Street');
        loanApplicationProp.put(appNameSpace+'City__c','Toronto');
        loanApplicationProp.put(appNameSpace+'Street_Number__c','2');
        loanApplicationProp.put(appNameSpace+'PostalCode__c','M2M2M2');
        loanApplicationProp.put(appNameSpace+'Country__c', 'Canada');
        loanApplicationProp.put(appNameSpace+'Province__c', 'Ontario');
        
         loanApplicationProp.put(appNameSpace+'Direction__c', 'NW');
         loanApplicationProp.put('ExpMonthlyRentalIncome', 5000);
         loanApplicationProp.put(appNameSpace+'Rental_Income_Period__c', 'Semi Annual');
         loanApplicationProp.put(appNameSpace+'Rental_Income_Type__c', 'Other Employment Income');
         loanApplicationProp.put(appNameSpace+'Rental_IncPercentInTds__c', 25);
         loanApplicationProp.put(appNameSpace+'Structure_Type__c', 'Modular Home Semi Detached');
         loanApplicationProp.put(appNameSpace+'Street_Type__c', 'Boulevard');
         loanApplicationProp.put(appNameSpace+'Original_Purchase_Price__c', 4000);
        loanApplicationProp.put(appNameSpace+'Loan_Applicant__c',String.valueof(lapplicant.get('Id')));
 
         loanApplicationProp.put(appNameSpace+'Purchase_Date__c', date.today().addmonths(6));
         //loanApplicationProp.put('PropertyState__c', 'Test Property State');
         //loanApplicationProp.put('Loan_Applic__c', 'Test Property Country');
 
        //Expenses of Property
        loanApplicationProp.put(appNameSpace+'Annual_Taxes__c',321);
        loanApplicationProp.put(appNameSpace+'Insurance_Expenses__c',321);
        loanApplicationProp.put(appNameSpace+'Heating_Expenses__c',321);
        loanApplicationProp.put(appNameSpace+'Hydro_Expenses__c',321);
        loanApplicationProp.put(appNameSpace+'Management_Expenses__c',321);
        loanApplicationProp.put(appNameSpace+'Other_Expenses__c',321);
        loanApplicationProp.put(appNameSpace+'Repairs_Expenses__c',321);
        loanApplicationProp.put(appNameSpace+'Total_Condo_Fees__c',321);
        loanApplicationProp.put(appNameSpace+'Interest_Expenses__c',321);
 
         insert loanApplicationProp;
         System.assert(loanApplicationProp != null);
 
        //Test Property
        
        String loanApplicationPropObjectApiname2 = 'LoanApplicationProperty';
         sObject loanApplicationProp2 = Schema.getGlobalDescribe().get(loanApplicationPropObjectApiname2).newSObject();
 
 
         loanApplicationProp2.put('AppraisedValue__c', 200000);
         loanApplicationProp2.put('LoanApplicationId', String.valueof(rla.get('Id')));
         loanApplicationProp2.put('Appraisal_Date__c', date.today().addMonths(7));
         loanApplicationProp2.put('Style__c', 'Storey and a Half');
         loanApplicationProp2.put('PropertyValue', 180000);
         loanApplicationProp2.put('ExpNetMonthlyRentalInc', 7000);
         loanApplicationProp2.put('feesIncludeHeat__c', true);
         loanApplicationProp2.put('Garage_Size__c', 'Double');
         loanApplicationProp2.put('Garage_Type__c', 'Attached');
         loanApplicationProp2.put('Heat__c', 'Forced Air Gas Oil Electric');
         loanApplicationProp2.put('includetds__c', true);
         loanApplicationProp2.put('insulatedWithUffi__c', true);
         loanApplicationProp2.put('lot__c', 'Test Legal Line 1');
         loanApplicationProp2.put('block__c', 'Test Legal Line 2');
         loanApplicationProp2.put('Conc_Township__c', 'Test Legal Line 3');
         loanApplicationProp2.put('livingSpace__c', 23);
         loanApplicationProp2.put('livingSpaceUnitOfMeasurDd__c', 'Sq Ft');
         loanApplicationProp2.put('RequestedLoanAmount', 190000);
         loanApplicationProp2.put('PropertyExtIdentifier', 'Test External Id 2');
         loanApplicationProp2.put('LoanPurposeType', 'Purchase');
         
 
         loanApplicationProp2.put('lotSize__c', 2300);
         loanApplicationProp2.put('lotSizeUnitOfMeasure__c', 'Hectares');
         loanApplicationProp2.put('IsManufacturedHome', True);
         loanApplicationProp2.put('IsMixedUseProperty', True);
         loanApplicationProp2.put('mlsListingFlag__c', True);
         loanApplicationProp2.put('Name', 'Test Loan Application Property');
        loanApplicationProp2.put('Country__c', 'Canada');
        loanApplicationProp2.put('Province__c', 'Ontario');
        loanApplicationProp2.put(appNameSpace+'PostalCode__c','M2M2M2');
         loanApplicationProp2.put('Construction_Type__c', 'Existing');
         loanApplicationProp2.put('numberOfUnits__c', 24);
         loanApplicationProp2.put('PropertyUseType', 'Owner Occupied');
         loanApplicationProp2.put('Property_Type__c', 'condo');
         loanApplicationProp2.put('purchasePrice__c', 60000);
         loanApplicationProp2.put('realtorInfo__c', 'Test Realtor Info');
         loanApplicationProp2.put('rentalOffsetOption__c',  'Add Percentage to Gross Income');
         loanApplicationProp2.put('Sewage_Type__c', 'Municipal');
         loanApplicationProp2.put('structureAge__c', 45);
         loanApplicationProp2.put('taxationYear__c', 2020);
         loanApplicationProp2.put('UnitsFinancedCount', 20);
         loanApplicationProp2.put('Water_Type__c', 'Municipal');
        
        //Expenses of Property
        loanApplicationProp2.put(appNameSpace+'Annual_Taxes__c',321);
        loanApplicationProp2.put(appNameSpace+'Insurance_Expenses__c',321);
        loanApplicationProp2.put(appNameSpace+'Heating_Expenses__c',321);
        loanApplicationProp2.put(appNameSpace+'Hydro_Expenses__c',321);
        loanApplicationProp2.put(appNameSpace+'Management_Expenses__c',321);
        loanApplicationProp2.put(appNameSpace+'Other_Expenses__c',321);
        loanApplicationProp2.put(appNameSpace+'Repairs_Expenses__c',321);
        loanApplicationProp2.put(appNameSpace+'Total_Condo_Fees__c',321);
        loanApplicationProp2.put(appNameSpace+'Interest_Expenses__c',321);
        

        loanApplicationProp2.put('Loan_Applicant__c',String.valueof(lapplicant.get('Id')));
 
         loanApplicationProp2.put('Purchase_Date__c', date.today().addmonths(6));

 
         insert loanApplicationProp2;
         System.assert(loanApplicationProp2 != null);

        String IdentificationObjApiName = appNameSpace+'identification__c';
         sObject appIdentity = Schema.getGlobalDescribe().get(IdentificationObjApiName).newSObject();
         
         appIdentity.put('IdentificationNumber__c','asc12');
         appIdentity.put('Country__c','Canada');
         appIdentity.put('Type__c','Alberta Registries');
         appIdentity.put('Loan_Applicant__c', String.valueof(lapplicant.get('Id'))); 
         
         insert appIdentity;

        
         String downPaymentObjApiName = appNameSpace+'Down_Payment_Source__c';
         sObject downPay = Schema.getGlobalDescribe().get(downPaymentObjApiName).newSObject();
         downPay.put('Amount__c',25000);
        downPay.put('Source_Type__c','Personal Cash	');
         downPay.put('Name','Monthly');
         downPay.put('Description__c','Management Expenses');
         downPay.put('Application__c', string.valueof(rla.get('id'))); 
         
         insert downPay;
        
        FilogixWrapperBinding.bindNotesData();
        FilogixWrapperBinding.stripJsonNulls('{"mortgageApplication":{"subjectProperty":{"waterTypeDd":"Municipal","taxationYear":2020.0,"structureAge":12.0,"sewageTypeDd":"Municipal","rentalOffsetOption":"None","purchasePrice":771231.0,"propertyExpense":[{"propertyExpenseTypeDd":"Municipal Taxes","propertyExpensePeriodDd":"Annual","propertyExpenseAmount":312.0},{"propertyExpenseTypeDd":"Condo Fees","propertyExpensePeriodDd":"Monthly","propertyExpenseAmount":1231.0},{"propertyExpenseTypeDd":"Heating Expense","propertyExpensePeriodDd":"Monthly","propertyExpenseAmount":231.0}],"originalPurchasePrice":771231.0,"occupancyTypeDd":"Owner Occupied","numberOfUnits":66.0,"newConstructionDd":"Existing","mlsListingFlag":"N","lotSizeUnitOfMeasureDd":"Acres","lotSize":12.0,"livingSpaceUnitOfMeasurDd":"Sq Ft","livingSpace":31.0,"legalLine2":"11","legalLine1":"21","includetds":"N","heatTypeDd":"Other","garageTypeDd":"Attached","garageSizeDd":"Single","feesIncludeHeat":"N","estimatedAppraisalValue":788131.0,"dwellingTypeDd":"Apartment High Rise","dwellingStyleDd":"One Storey","appraisalDateAct":"1901-05-04T05:00:00-00:00","address":{"unitNumber":"5","streetTypeDd":"Acres","streetNumber":"21","streetName":"","streetDirectionDd":"NE","provinceDd":"Ontario","postalLdu":"0A9","postalFsa":"M6P","countryTypeDd":"Canada","city":"Toronto"},"actualAppraisalValue":798123.0},"requested":[{"subprimeFlag":"N","singleProgressiveTypeDd":"Yes","reverseFlag":"Y","requestedRate":12.0,"refiBlendedAmortization":"N","qualifyRate":2.0,"paymentTermDd":"Closed","paymentFrequencyDd":"Monthly","netLoanAmount":44334.0,"mtgInsIncludeFlag":"N","mortgageTypeDd":"First","locRepaymentTypeDd":"5 and 20","loanTypeDd":"Mortgage","lineOfBusinessDd":"A","interestTypeDd":"Adjustable","interestOnlyFlag":"N","interestCompoundDd":"Monthly","insuredFlag":"N","helocFlag":"Y","existingMortgageFlag":"N","constructionFlag":"N","commercialFlag":"Y","cashBackPercentage":23.0,"cashBackOverride":"N","cashBackAmt":10196.82,"amortizationTerm":32.0,"actualPaymentTerm":23.0}],"existing":[],"deal":{"thirdPartyApplicationFlag":"N","taxPayorDd":"Borrower","sourceApplicationId":"0cdJ00000004D1yIAE","refiImprovementsFlag":"N","estimatedClosingDate":"2022-06-07T16:00:00-00:00","downPaymentSource":[],"dealTypeDd":"Approval","dealPurposeDd":"Refinance"},"applicantGroup":[{"applicantGroupTypeDd":"Applicant","applicant":[{"relationshipToPrimaryApplicant":"Spouse","primaryApplicantFlag":"Y","otherProperty":[],"otherIncome":[{"incomeTypeDd":"Capital Gains","incomePeriodDd":"Quarterly","incomeDescription":"incme","incomeAmount":1000.0}],"numberOfDependents":8.0,"name":{"salutationDd":"Mr.","lastName":"Gerrard","firstName":"null"},"maritalStatusDd":"Married","liability":[],"languagePreferenceDd":"English","identification":[],"firstTimeBuyer":"N","existingClient":"Y","employmentHistory":[{"timeInIndustry":1.0,"selfEmploymentFlag":"N","monthsOfService":14.0,"jobTitle":"CVE","industrySectorDd":"Education","income":{"incomeTypeDd":"Interest Income","incomePeriodDd":"Annual","incomeAmount":1222.0},"grossRevenue":222.0,"employmentHistoryTypeDd":"Full Time","employmentHistoryStatusDd":"Current","employerName":"Name","contact":{"address":{"provinceDd":"ontario","countryTypeDd":"canada","city":"toronto","addressLine2":"12","addressLine1":"123"}}}],"clientReferenceNumber":"0cUJ00000004Cr4MAE","birthDate":"2001-06-07","asset":[],"addressDetail":[{"monthsAtAddress":24.0,"addressTypeDd":"Current","address":{"unitNumber":"2","streetTypeDd":"Alley","streetNumber":"Canadian Headquarters","streetName":"King Street West, Suite 200","streetDirectionDd":"NW","provinceDd":"British Columbia","postalLdu":"1J9","postalFsa":"M5H","countryTypeDd":"Canada","city":"Toronto"}}]}]}]}}');

        FilogixPOSTJSONWrapper.QualifyDetail QualifyDetail = new FilogixPOSTJSONWrapper.QualifyDetail();
        QualifyDetail.amortizationTerm = 232323;
        QualifyDetail.interestCompoundDd = 'Toronto';
        QualifyDetail.interestOnlyFlag = 'Ontario';
        
        FilogixPOSTJSONWrapper.Property Property = new FilogixPOSTJSONWrapper.Property();
        Property.appraisalDateAct = '23-12-2020';
        Property.dwellingStyleDd = 'Split Level';
        Property.dwellingTypeDd = 'Detached';
        Property.garageSizeDd  = 'Single';
        Property.garageTypeDd  = 'Attached';
        Property.heatTypeDd  = 'Other';
        Property.legalLine1  = 'PID213';
        Property.legalLine2  = 'PID214';
        Property.legalLine3  = 'PID215';
        Property.livingSpace  = 2313;
        Property.livingSpaceUnitOfMeasurDd = 'Sq M';
        Property.lotSize  = 10000;
        Property.lotSizeUnitOfMeasureDd = 'Acres';
        Property.mlsListingFlag = 'Y';
        Property.newConstructionDd = 'Existing';
        Property.numberOfUnits = 20;
        Property.propertyTypeDd = 'FreeHold';
        Property.realtorInfo  = '321';
        Property.rentalOffsetOption = 'None';
        Property.sewageTypeDd  = 'Municipal';
        Property.waterTypeDd = 'Municipal';
        Property.structureAge = 212;
        Property.taxationYear = 321;
        
        Test.setMock(HttpCalloutMock.class, new Mock());
    
        StaticResource srObject = [
              SELECT id, body
              FROM StaticResource
              WHERE Name = 'GET_Sample_Response'
            ];
            String json = srObject.body.toString();
        	json = json.replaceAll('0cU4W000000bwJ5UAI', String.valueof(lapplicant.get('id')));
        FilogixGETJSONWrapper res = FilogixGETJSONWrapper.parse(json);
        
         return rla;
    }
    
    // Wrapper Class for Callout Mock
    private class Mock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            
            // Call the method that performs the callout
            StaticResource srObject = [SELECT id, body FROM StaticResource WHERE Name = 'GET_Sample_Response' WITH SECURITY_ENFORCED];
            String getbody = srObject.body.toString();
 			string postbody = '{"result": {"setMortgageAppDataResponse": {"mortgageApplicationId": "CLJT-835"}}}';
            
            if (req.getEndpoint().endsWith('token')) { //for Token
                HTTPResponse res = new HTTPResponse();
                res.setBody('{"accessToken": "450023da7754fee83af3f37090469b3e44fda9a9","accessTokenExpiresAt": "2023-04-25T08:47:37.137Z"}');
                res.setStatusCode(200);
                return res;
            }else if(req.getEndpoint().endsWith('Agent2')){ // for GET         
                HTTPResponse res = new HTTPResponse();
                res.setBody(getbody);
                res.setStatusCode(200);
                return res;
            }else if(req.getEndpoint().endsWith('post')){ // for POST
                    HTTPResponse res = new HTTPResponse();
                    res.setBody(postbody);
                    res.setStatusCode(200);
                    return res;
            
            } else {
                System.assert(false, 'unexpected endpoint ' + req.getEndpoint());
                return null;
            }
        }
    }
    
    @isTest 
    public static  void parseResponseGETApp_success() {
    	// Getting App Namespace
        appNameSpace = FilogixWrapperBinding.getAppNameSpace();
        sObject rla = testData();
		map<string, sObject> mapOfFXIDandAppId = new map<string, sObject>();
        mapOfFXIDandAppId.put(String.valueof(rla.get(appNameSpace+'FilogixId__c')),rla);
        Test.startTest();

        //List<sObject> listofRLA = new List<sObject>();
        //listofRLA.add(rla);
        FilogixResponseParsingUtil.getAppStatus(mapOfFXIDandAppId);

        Test.stopTest();  
    }
    
    @isTest 
    public static  void parseResponsePOSTApp_success() {
        sObject rla = testData();
        
        List<sObject> listOfApps = new List<sObject>();
        listOfApps.add(rla);
       
        String parsedRlaId;
        Test.startTest();        
        parsedRlaId = FilogixResponseParsingUtil.parseResponsePOSTAppId('{"result": {"setMortgageAppDataResponse": {"mortgageApplicationId": "CLJT-92"}}}');
        
        Test.stopTest();
        
        system.assertEquals('CLJT-92', parsedRlaId);
    }
    
}