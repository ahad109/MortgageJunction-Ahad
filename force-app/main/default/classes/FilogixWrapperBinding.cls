/**
* @description       : This class handles all the callouts to the middleware for filogix
* @author            : Zain Abbas @ cloudjunction.cloud
* @group             : Cloudjunction Advisors, Inc.
* @last modified on  : 06-22-2022
* @last modified by  : M Hamza Siddiqui
* Modifications Log
* -----------------
* Ver   Date         Author                             		Modification
* 1.0   01-13-2021   Zain Abbas @ cloudjunction.cloud    		Initial Version
* 1.1   02-26-2021   M Hamza Siddiqui @ cloudjunction.cloud   	First/Last Name of Applicant Fix + StripNUll Method Update
* 1.2   09-28-2021   M Hamza Siddiqui @ cloudjunction.cloud   	Mapping Fixes for Applicant, Employment and Mortgages
* 1.3   10-21-2021   M Hamza Siddiqui @ cloudjunction.cloud     Phone Validation Fix
* 1.4   11-29-2021   M Hamza Siddiqui @ cloudjunction.cloud     Misc Fixes (please look at the commits for log)
* 1.5   11-30-2021   M Hamza Siddiqui @ cloudjunction.cloud     Introduced listofSubjectPropertyMortgages to store the subject property's mortgage data
* 1.6   12-01-2022   M Hamza Siddiqui @ cloudjunction.cloud     Existing Mortgage check on Other Property
* 1.7   04-02-2022   M Hamza Siddiqui @ cloudjunction.cloud     Custom Address fields.
**/
global with sharing class FilogixWrapperBinding {
    public static map<string, Opportunity> mapofOpp;
    public static map<string, sObject> mapOfLoanApplication;
    public static List<sObject> listOfMortgages;
    public static List<sObject> listofSubjectPropertyMortgages;
    public static map<string, map<string, sObject>> mapofLoanAppIdAndApplicants;
    public static map<string, map<string, sObject>> mapofApplicantIdAndAddr;
    public static map<string, map<string, sObject>> mapofApplicantIdAndAsset;
    public static map<string, map<string, sObject>> mapofApplicantIdAndIncome;
    public static map<string, map<string, sObject>> mapofApplicantIdAndEmployment;
    public static map<string, map<string, sObject>> mapofApplicantIdAndLiability;
    public static Map<string, map<string, sObject>> mapofApplicantIdAndIdentification;
    public static map<string, map<string, sObject>> mapofLoanAppIdAndProperties;
    //public static map<string, map<string, sObject>> mapofPropIdAndExpenses;
    public static map<string, map<string, sObject>> mapofOppIdAndDownSources;
    public static Map<string, List<sObject>> mapOfMortgageAgainstProp;
    public static string requiredFieldError;
    public static String objAccessError = 'Please make sure you have the access to all the FSC Mortgage and MortgageJunction objects and fields.</br>';

       
    
    public class CustomException extends Exception {}
    
    public static CustomException createCustomException(String message) {
        CustomException ex = new CustomException(message);
        ex.setMessage(message);
        return ex;
    }

    public static String getAppNameSpace(){
        //String appNameSpace = ''; // 'CJA_Mortgage__'
        // Adding a Namespace for Publishing org to prevent test class errors
        //if(UserInfo.getOrganizationId() == '00D4W000002TezwUAC'){
        //String appNameSpace = 'CJA_Mortgage__';
        //}
        return 'CJA_Mortgage__';
    }
    @AuraEnabled
    public static void sendReportToCJA(String ex, String appId, String action){
        // Generating email
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new String[] { 'appdev@cloudjunction.cloud' };
        message.optOutPolicy = 'FILTER';
        message.subject = 'MJ App - Incident - '+Userinfo.getOrganizationName();
        message.plainTextBody = 'Incident occured in orgId '+UserInfo.getOrganizationId()+'\nException:'+ex+'\nAppId:'+appId+'\nUser:'+UserInfo.getUserId()+'\nAction:'+action;
        
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
    }
    
    public static void requiredFieldsError(String objectApi, String fieldApi, String recName, String recId){
        String appNameSpace = FilogixWrapperBinding.getAppNameSpace();

        if(!String.IsBlank(objectApi) && !String.IsBlank(fieldApi)){
            objectApi = objectApi.endsWith('__c')?appNameSpace+objectApi: objectApi;
            fieldApi = fieldApi.endsWith('__c')?appNameSpace+fieldApi: fieldApi;
            system.debug('Object::'+objectApi+' Field::'+fieldApi);
            try{
                requiredFieldError += '<b>Object</b> : '+String.valueof(Schema.getGlobalDescribe().get(objectApi).getDescribe().getLabel())+', <b>Field</b> : '+ String.valueof(Schema.getGlobalDescribe().get(objectApi).getDescribe().fields.getMap().get(fieldApi).getDescribe().getLabel());
                if(!String.isBlank(recName)){
                    if(String.isBlank(recId)){
                        requiredFieldError += ' , <b>Record Name</b> : '+recName+' </br>';
                    } else {
                        requiredFieldError += ' , <b>Record Name</b> : <a href="/'+recId+'"> '+recName+' </a></br>';
                    }
                } else {
                    requiredFieldError += ' </br>';
                }
                
            } catch(exception e){
                createCustomException('Please make sure the field='+fieldApi+' from the object='+objectApi+' is populated');
            }
        }
    }
    
    global FilogixWrapperBinding(string recId) {
        
        mapofOpp = new Map<string, Opportunity>();
        mapOfLoanApplication = new Map<string, sObject>();
        listOfMortgages = new List<sObject>();
        listofSubjectPropertyMortgages = new List<sObject>();
        mapofLoanAppIdAndApplicants = new Map<string, map<string, sObject>>();
        mapofApplicantIdAndAddr = new Map<string, map<string, sObject>>();
        mapofApplicantIdAndAsset = new Map<string, map<string, sObject>>();
        mapofApplicantIdAndIncome = new Map<string, map<string, sObject>>();
        mapofApplicantIdAndEmployment = new Map<string, map<string, sObject>>();
        mapofApplicantIdAndLiability = new Map<string, map<string, sObject>>();
        mapofLoanAppIdAndProperties = new Map<string, map<string, sObject>>();
        //mapofPropIdAndExpenses = new Map<string, map<string, sObject>>();
        mapofApplicantIdAndIdentification = new Map<string, map<string, sObject>>();
        mapofOppIdAndDownSources = new Map<string, map<string, sObject>>();
        mapOfMortgageAgainstProp = new Map<string, List<sObject>>();
        requiredFieldError = '';
        initialize(recId);
    }
    
    public static void isPersonAccountEnabled() {
        //return Schema.sObjectType.Account.fields.getMap().containsKey( 'isPersonAccount' );  
        // Checking is Person Account is enabled in the org
        if(!Schema.sObjectType.Account.fields.getMap().containsKey('isPersonAccount')){
            String errorMsg = 'Please <a target="_blank" href="https://developer.salesforce.com/docs/atlas.en-us.financial_services_cloud_admin_guide.meta/financial_services_cloud_admin_guide/fsc_admin_enable_person_acct.htm">Enable the Person Account</a>.';
            throw createCustomException(errorMsg);
        }
    }

    /* This method is to Get the Parent Object Api Name from field API Name */
    public static string objectRefName(String objName, String fieldName){
        String appNameSpace = FilogixWrapperBinding.getAppNameSpace();
        String ObjectName='';
        if(!String.isBlank(objName) && !String.isBlank(fieldName)){

            // Identification of Object Either Standard or Custom for the perticular reference to be used in permission checker
            //objName = fieldIdentification(objName);
            // Identification of Object Either Standard or Custom for the perticular reference to be used in permission checker
            fieldName= fieldIdentification(fieldName);

            System.debug('Relationship Checker:: Parent Object::'+objName+'& Object Field::'+fieldName);
            // Getting the Parent Object Api Name
            Schema.DescribeFieldResult f = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap().get(fieldName).getDescribe();
            for(Schema.SObjectType reference : f.getReferenceTo()) {
                ObjectName = reference.getDescribe().getName();
            }
        }
        return ObjectName;
    }

    /* Identification of Object Either Standard or Custom for the perticular reference to be used in permission checker */
    public static string fieldIdentification(String fieldApiName){
        String strToReturn='';
        String appNameSpace = FilogixWrapperBinding.getAppNameSpace();
        if(!String.isBlank(fieldApiName)){
            strToReturn = fieldApiName;
            // Identification of Object Either Standard or Custom for the perticular reference to be used in permission checker
            if(!strToReturn.endsWith('Id') && !fieldApiName.endsWith('__c')){
                if(strToReturn.endsWith('__r')){
                    strToReturn = strToReturn.replaceAll('__r','__c');

                    // Appending a NameSpace if it's a custom object.
                    if(!strToReturn.startsWith(appNameSpace)){
                        strToReturn = appNameSpace+strToReturn;
                    }
                } else { // Appending "ID" for all the standard fields.
                    strToReturn = strToReturn+'Id';
                }
            } else {
                return strToReturn;
            }
        }
        return strToReturn;
    }
    
    /* This method is to check all the Object and fields per object has the access
    Obj & FLS secuity checker */
    public static void permChecker(String objName, string listofCommaSeperatedFields, String perm){
        String appNameSpace = FilogixWrapperBinding.getAppNameSpace();
        // Checking permission on Object
        if(!String.isBlank(objName) && !String.isBlank(perm)){

            /*// Appending a NameSpace if it's a custom object.
            if(objName.endsWith('__c') && !objName.startsWith(appNameSpace)){
                objName = appNameSpace+objName;
            }*/
            
            //Checking permissions on Fields
            if(!String.isBlank(listofCommaSeperatedFields)){
                listofCommaSeperatedFields = listofCommaSeperatedFields.replaceAll('(\\s+)', ''); // Removing all the whitespaces
                List<String> lstFields = new List<string>();
                // Checkking if String contains comma seperated fields
                if(listofCommaSeperatedFields.contains(',')){
                    lstFields = listofCommaSeperatedFields.split(','); //Converting String to list
                } else { // Means single field is provided.
                    lstFields.add(listofCommaSeperatedFields);
                }
                system.debug('lstFields='+JSON.serialize(lstFields));
                if(lstFields.size()>0 && lstFields!=null){
                    for(String fieldApiName : lstFields){
                        String objectName = objName;

                        //Handling parent fields
                        // Example: Account.Name being queried from ResidentialLoanApplication
                        if(fieldApiName.contains('.')){
                            System.debug('Object::'+objectName+'& Field::'+fieldApiName);
                            List<String> fieldApi = fieldApiName.split('\\.');
                            system.debug('fieldApi='+JSON.serialize(fieldApi));
                            // Example: Account.Name from ResidentialLoanApplication
                            if(fieldApi.size()==2){
                                objectName = fieldApi[0];
                                fieldApiName = fieldApi[1];
                                permChecker(objName, fieldIdentification(fieldApi[0]), perm); //as permChecker('ResidentialLoanApplication','AccountId','read');
                                // continue as permChecker('Account','Name','read');
                            }

                            // Example: LoanApplicant.Contact.FirstName from LoanApplicantEmployment
                            if(fieldApi.size()==3){
                                objectName = fieldApi[0];
                                fieldApiName = fieldIdentification(fieldApi[1]);
                                // Checking Permission for Grand Parent Object and it's fields.
                                // Re-calling the same method,
                                permChecker(fieldApi[0], fieldApi[1]+'.'+fieldApi[2], perm); //as permChecker('LoanApplicant','Contact.FirstName','read');
                                permChecker(objName, objectName+'.'+fieldApiName, perm); //as permChecker('LoanApplicantEmployment','LoanApplicant.Contact','read');
                                // continue as permChecker('LoanApplicantEmployment','LoanApplicant','read');
                            }

                            System.debug('Parent Object::'+objName+'& Object Field::'+objectName);
                            // Getting the Parent Object Api Name before passing it to permission checker
                            objectName = objectRefName(objName,objectName);
                        }
                        // // Replacing custom object's relationship field with appropriate syntax
                        // Appending a NameSpace if it's a custom object.
                        if(objectName.endsWith('__c') && !objectName.startsWith(appNameSpace)){
                            objectName = appNameSpace+objectName;
                        }

                        // Appending a NameSpace if it's a custom field.
                        if(fieldApiName.endsWith('__c') && !fieldApiName.startsWith(appNameSpace)){
                            fieldApiName = appNameSpace+fieldApiName;
                        }

                        System.debug('Object::'+objectName+'& Field::'+fieldApiName);
                        System.debug('Object::'+objName+'& Field::'+fieldApiName);
                        
                        Schema.DescribeSObjectResult objDesc = Schema.getGlobalDescribe().get(objectName).getDescribe();
                        Schema.DescribeFieldResult fieldDesc = objDesc.fields.getMap().get(fieldApiName).getDescribe();
                        
                        // Throw an error if Object is not readable
                        if(!objDesc.isAccessible()){
                            throw createCustomException(objAccessError+'Object: '+objName+'</br>');
                        }
                        
                        // Throw an error if the field is not readable
                        if(!fieldDesc.isAccessible()){
                            throw createCustomException(objAccessError+'Object: '+objectName+', Field: '+fieldApiName+'</br>');
                        }
                    }
                }
            }
        }
    }

    public static void initialize(string recId) {
        String appNameSpace = FilogixWrapperBinding.getAppNameSpace();
        //String ObjAccessError = 'Please make sure you have the access to all the FSC Mortgage and MortgageJunction objects and fields.</br> Please contact MortgageJunction support</br>';
	
        set<string> setOfApplicantIDs = new Set<string>();
        String applicationPropertyObjName = 'LoanApplicationProperty';
        String applicantLiabilityObjName = 'LoanApplicantLiability';
        String applicantEmploymentObjName = 'LoanApplicantEmployment';
        String applicantIncomeObjApiName = 'LoanApplicantIncome';
        String appAssetObjApiName = 'LoanApplicantAsset';
        String loanApplicantIdentityObjApiName = appNameSpace+'Identification__c';
        String loanApplicantAddressObjApiName = 'LoanApplicantAddress';
        String downPaymentObjApiName = appNameSpace+'Down_Payment_Source__c';
        String loanApplicantObjApiName = 'LoanApplicant';
        String rLAObjApiName = 'ResidentialLoanApplication';
        String rLAMortgageApiName = appNameSpace+'Mortgage__c';

        String rLAfields = 'id,Name, Deal_Purpose__c,Deal_Type__c, Third_Party_Application_Flag__c,Financing_Waiver_Date__c,Referral_Reference_Number__c, Ref_Improvement_Amount__c,Ref_Improvement_Description__c, Ref_Improvements_Flag__c,Ref_Purpose__c,Account.PersonMailingAddress, Estimated_Closing_Date__c,Tax_Payor__c, Account.Name,Subject_Property__c,Subject_Property__r.AppraisedValue__c, Subject_Property__r.LoanApplicationId,Subject_Property__r.Appraisal_Date__c,Subject_Property__r.Style__c, Subject_Property__r.PropertyValue,Subject_Property__r.ExpNetMonthlyRentalInc,Subject_Property__r.feesIncludeHeat__c, Subject_Property__r.Garage_Size__c,Subject_Property__r.Garage_Type__c,Subject_Property__r.Heat__c,Subject_Property__r.includetds__c, Subject_Property__r.insulatedWithUffi__c,Subject_Property__r.LastModifiedById, Subject_Property__r.purchasePrice__c, Subject_Property__r.lot__c, Subject_Property__r.block__c,Subject_Property__r.Conc_Township__c,Subject_Property__r.livingSpace__c, Subject_Property__r.livingSpaceUnitOfMeasurDd__c,Subject_Property__r.RequestedLoanAmount, Subject_Property__r.PropertyExtIdentifier,Subject_Property__r.LoanPurposeType,Subject_Property__r.lotSize__c, Subject_Property__r.lotSizeUnitOfMeasure__c,Subject_Property__r.IsManufacturedHome,Subject_Property__r.IsMixedUseProperty, Subject_Property__r.mlsListingFlag__c,Subject_Property__r.Name,Subject_Property__r.Construction_Type__c,Subject_Property__r.numberOfUnits__c, Subject_Property__r.PropertyUseType,Subject_Property__r.PropertyAddress,Subject_Property__r.Property_Type__c,Subject_Property__r.Original_Purchase_Price__c, Subject_Property__r.realtorInfo__c,Subject_Property__r.rentalOffsetOption__c,Subject_Property__r.Sewage_Type__c, Subject_Property__r.structureAge__c,Subject_Property__r.taxationYear__c,Subject_Property__r.UnitsFinancedCount, Subject_Property__r.Water_Type__c,Subject_Property__r.PropertyStreet,Subject_Property__r.PropertyCity, Subject_Property__r.Street_Number__c,Subject_Property__r.Street_Name__c, Subject_Property__r.Street_Type__c,Subject_Property__r.Structure_Type__c, Subject_Property__r.PropertyUnitNumber__c,Subject_Property__r.PropertyPostalCode,Subject_Property__r.PropertyCountry, Subject_Property__r.PropertyState,Subject_Property__r.Direction__c,Subject_Property__r.ExpMonthlyRentalIncome, Subject_Property__r.Rental_Income_Period__c,Subject_Property__r.Rental_Income_Type__c,Subject_Property__r.Rental_IncPercentInTds__c,Subject_Property__r.City__c,Subject_Property__r.Country__c,Subject_Property__r.Province__c,Subject_Property__r.PostalCode__c,Subject_Property__r.Annual_Taxes__c,Subject_Property__r.Insurance_Expenses__c,Subject_Property__r.Heating_Expenses__c,Subject_Property__r.Hydro_Expenses__c,Subject_Property__r.Interest_Expenses__c,Subject_Property__r.Management_Expenses__c,Subject_Property__r.Other_Expenses__c,Subject_Property__r.Repairs_Expenses__c,Subject_Property__r.Total_Condo_Fees__c';    
        String mortgage_Fields ='id,Name, Qualify_Amortization_Term__c,Maturity_date__c,PAndIPaymentAmount__c,Qualify_Interest_Compound__c,Qualify_Is_Interest_Only__c,Repayment_Type__c,Loan_Application_Property__c,Interest_Rate__c,Discount__c,Net_Rate__c,Premium__c,Is_Interest_Only__c,Actual_Payment_Term__c, Amortization_Term__c,Cash_Back_Amount__c,Cash_Back_Override__c,Cash_Back_Percentage__c,Commercial__c,Construction__c, Current_Mortgage_Number__c,Existing_Mortgage__c,Existing_Mortgage_Holder__c,Heloc__c,Is_Insured__c,Insurance_Adjustment_Date__c, Interest_Compound__c,Interest_Type__c,Line_Of_Business__c,Loan_Type__c,LOC_Repayment_Type__c,MI_Reference_Number__c,Mortgage_Insurer__c, Mortgage_Type__c,Mortgage_Insurance_Included__c,Net_Loan_Amount__c,Original_Mortgage_Amount__c,Payment_Frequency__c,Payment_Term__c,Payoff_Type__c, Qualify_Rate__c,Rate_Guarantee_Length__c,Ref_Additional_Information__c,Ref_Blended_Amortization__c,Requested_Rate__c, Reverse_Flag__c,Single_Progressive_Type__c,Sub_Prime__c,Balance_Remaining__c, Buydown_Rate__c';
        String rlaQuery='Select '+rLAfields+ ', (Select '+mortgage_Fields+' from '+appNameSpace+'Mortgages__r) from '+rLAObjApiName+'  Where Id =: recId WITH SECURITY_ENFORCED' ;

        String loanApplicantFields     = 'Id,  Applicant_Group_Type__c, Business_Account__c,Business_Account__r.Name, Business_Account__r.Phone, LoanApplicationId, LoanApplication.AccountId, Contact.Birthdate, ContactId, Contact.Fax, Contact.Phone, Contact.Name,Contact.FirstName, Contact.LastName, Contact.Work_Phone__c, Contact.Work_Phone_Extension__c, Contact.Email, ApplicantExtIdentifier, Contact.MailingAddress, PreferredLanguage, MaritalStatus, Name, DependentCount,Preferred_Contact_Method__c ,Primary_Applicant__c , Contact.Social_Insurance_Number__c, Relationship_To_Primary_Applicant__c, Existing_Client__c, First_Time_Buyer__c, Contact.MobilePhone, Contact.HomePhone, Contact.AccountId, Contact.Salutation';
        String loanApplicantQuery      ='Select '+ loanApplicantFields+ ' from  '+loanApplicantObjApiName+' where LoanApplicationId =: recId WITH SECURITY_ENFORCED'  ;
        
        String downPaymentObjFields = 'id, Name, Amount__c,Application__c, Description__c, Source_Type__c';
        String downPaymentObjQuery  ='Select '+downPaymentObjFields+ ' from  '+downPaymentObjApiName+'  Where Application__c =: recId WITH SECURITY_ENFORCED';    

        String loanApplicantAddressFields = 'Id, Name, LoanApplicantId, LoanApplicationId, ResidencyType, Street_Direction__c, Street_Number__c, Street_Name__c, ResidenceStreet,  ResidenceYearCount,ResidenceAdditionalMonthCount, AddressOwnership,Street_Type__c,Unit_Number__c, MonthlyRentPayment, Mailing_Address__c, City__c, Province__c, PostalCode__c, Country__c';
        String loanApplicantAddressQuery  ='Select  '+loanApplicantAddressFields+ ' from   '+loanApplicantAddressObjApiName+'  Where LoanApplicantId IN : setOfApplicantIDs WITH SECURITY_ENFORCED' ;    

        String loanApplicantIdentityFields = 'Id, Name, '+appNameSpace+'Country__c, '+appNameSpace+'IdentificationNumber__c, '+appNameSpace+'Type__c, '+appNameSpace+'Loan_Applicant__c';
        String loanApplicantIdentityQuery  ='Select  '+loanApplicantIdentityFields+ ' from  '+loanApplicantIdentityObjApiName+'  Where '+appNameSpace+'Loan_Applicant__c IN : setOfApplicantIDs WITH SECURITY_ENFORCED' ;    

        String appAssetFields = ' Id, Name, LoanApplicantId, LoanApplicationAsset.Description__c, LoanApplicationAsset.Name, LoanApplicationAsset.AssetType, LoanApplicationAsset.CashOrMarketValue, LoanApplicationAsset.'+appNameSpace+'Down_Payment_Amount__c ';
        String appAssetQuery  ='Select ' + appAssetFields+ ' from  '+appAssetObjApiName+'  Where LoanApplicantId IN :   setOfApplicantIDs WITH SECURITY_ENFORCED' ;    
        
        String applicantIncomeFields = '  Id, Name, LoanApplicantId,  IncomeSourceType, Income_Amount__c, Income_Period__c';
        String applicantIncomeQuery  ='Select '+applicantIncomeFields+ ' from '+applicantIncomeObjApiName+'  Where LoanApplicantId IN :   setOfApplicantIDs WITH SECURITY_ENFORCED' ;    

        String applicantEmploymentFields = ' Id, JobTitle, Operating_As__c, Time_In_Industry__c, LoanApplicant.Contact.FirstName, LoanApplicant.Contact.Salutation, LoanApplicant.Contact.LastName, LoanApplicant.Contact.MailingAddress, LoanApplicant.Contact.MailingCity, LoanApplicant.Contact.MailingState, LoanApplicant.Contact.MailingCountry, CurrentJobYearCount,  LoanApplicant.Contact.MobilePhone, LoanApplicant.Contact.Email, LoanApplicant.Contact.Phone, LoanApplicant.Contact.FinServ__ContactPreference__c, EmployerName, History_Status__c, History_Type__c, MonthlyIncome, Amount__c, Industry_Sector__c, Company_Type__c, IsSelfEmployed, Income_Frequency__c, Occupation__c, Name, Gross_Revenue__c, Income_Description__c, Type__c, CurrentJobAdditionalMonthCount, EmployerStreet, EmployerCity, EmployerPostalCode, Address_Line_2__c, EmployerCountry, EmployerState, EmployerPhone';
        String applicantEmploymentQuery  ='Select '+applicantEmploymentFields+ ' from  '+applicantEmploymentObjName+'  Where LoanApplicantId IN :   setOfApplicantIDs WITH SECURITY_ENFORCED' ;    

        String applicantLiabilityFields = ' Id, Name, LoanApplicantId, LoanApplicationLiability.CreditLimitAmount, LoanApplicationLiability.Pay_Off__c, LoanApplicationLiability.Credit_Bureau__c, LoanApplicationLiability.Name, LoanApplicationLiability.MonthlyPaymentAmount, LoanApplicationLiability.OtherLiabilityType, LoanApplicationLiability.Maturity_Date__c, LoanApplicationLiability.Monthly_Payment_Override__c, LoanApplicationLiability.Liability_Amount__c';
        String applicantLiabilityQuery  ='Select '+applicantLiabilityFields+ ' from  '+applicantLiabilityObjName+'  Where LoanApplicantId IN :  setOfApplicantIDs WITH SECURITY_ENFORCED' ;    

        String applicationPropertyFields = ' id, Loan_Applicant__c, Is_Subject_Property__c, AppraisedValue__c, LoanApplicationId, Appraisal_Date__c, Style__c, PropertyValue, ExpNetMonthlyRentalInc, feesIncludeHeat__c, Garage_Size__c, Garage_Type__c, Heat__c, includetds__c, insulatedWithUffi__c, LastModifiedById, lot__c, block__c, Conc_Township__c, livingSpace__c, livingSpaceUnitOfMeasurDd__c, RequestedLoanAmount, PropertyExtIdentifier, LoanPurposeType, lotSize__c, lotSizeUnitOfMeasure__c, IsManufacturedHome, IsMixedUseProperty, mlsListingFlag__c, Name, Construction_Type__c, numberOfUnits__c, PropertyUseType, PropertyAddress, Property_Type__c,  realtorInfo__c, rentalOffsetOption__c, Sewage_Type__c, structureAge__c, taxationYear__c, UnitsFinancedCount, Water_Type__c, PropertyStreet, PropertyCity, Street_Number__c,Street_Name__c , PropertyUnitNumber__c, PropertyPostalCode, PropertyCountry, PropertyState, Direction__c, ExpMonthlyRentalIncome, Rental_Income_Period__c, Rental_Income_Type__c, Rental_IncPercentInTds__c, Structure_Type__c, Street_Type__c, Original_Purchase_Price__c, Purchase_Date__c, City__c, PostalCode__c, Country__c, Province__c,Annual_Taxes__c,Insurance_Expenses__c,Heating_Expenses__c,Hydro_Expenses__c,Interest_Expenses__c,Management_Expenses__c,Other_Expenses__c,Repairs_Expenses__c,Total_Condo_Fees__c';
        String mortgageFields ='id,Name,Qualify_Amortization_Term__c,Qualify_Interest_Compound__c,Qualify_Is_Interest_Only__c,Repayment_Type__c,Interest_Rate__c,Discount__c,Net_Rate__c,Premium__c,Is_Interest_Only__c,Actual_Payment_Term__c, Amortization_Term__c,Cash_Back_Amount__c,Cash_Back_Override__c,Cash_Back_Percentage__c,Commercial__c,Construction__c, Current_Mortgage_Number__c,Existing_Mortgage__c,Existing_Mortgage_Holder__c,Heloc__c,Is_Insured__c,Insurance_Adjustment_Date__c, Interest_Compound__c,Interest_Type__c,Line_Of_Business__c,Loan_Type__c,LOC_Repayment_Type__c,MI_Reference_Number__c,Mortgage_Insurer__c, Mortgage_Type__c,Mortgage_Insurance_Included__c,Net_Loan_Amount__c,Original_Mortgage_Amount__c,Payment_Frequency__c,Payment_Term__c,Payoff_Type__c, Qualify_Rate__c,Rate_Guarantee_Length__c,Ref_Additional_Information__c,Ref_Blended_Amortization__c,Requested_Rate__c, Reverse_Flag__c,Single_Progressive_Type__c,Sub_Prime__c,Balance_Remaining__c, Buydown_Rate__c';
        String applicationPropertyQuery  ='Select '+applicationPropertyFields+ ' , (Select '+mortgageFields+' from '+appNameSpace+'Mortgages__r) from  '+applicationPropertyObjName+'  Where LoanApplicationId = :  recId AND Loan_Applicant__c!= NULL WITH SECURITY_ENFORCED'  ;                  


        // Checking is Person Account is enabled in the org
        isPersonAccountEnabled();

        if (!string.isBlank(recId)) {

            // Checking Object and Field Level Read Access
            // 
            // NOT NEEDED ANYMORE AS WE'RE USING SECURITY.stripInaccessible
            // 
            /*permChecker(rLAObjApiName,rLAfields,'read');
            permChecker(rLAMortgageApiName,mortgage_Fields,'read');
            permChecker(loanApplicantObjApiName,loanApplicantFields,'read');
            permChecker(downPaymentObjApiName,downPaymentObjFields,'read');
            permChecker(loanApplicantAddressObjApiName,loanApplicantAddressFields,'read');
            permChecker(loanApplicantIdentityObjApiName,loanApplicantIdentityFields,'read');
            permChecker(appAssetObjApiName,appAssetFields,'read');
            permChecker(applicantIncomeObjApiName,applicantIncomeFields,'read');
            permChecker(applicantEmploymentObjName,applicantEmploymentFields,'read');
            permChecker(applicantLiabilityObjName,applicantLiabilityFields,'read');
            permChecker(applicationPropertyObjName,applicationPropertyFields,'read');
            
            /* Populating Maps for further usage */
            set<string> setOfSubjProdIds = new Set<string>();

            /* RLA and Mortgage */
          List<sObject> rlaLIst = database.query(String.escapeSingleQuotes(rlaQuery));

          // Strip fields that are not readable
          SObjectAccessDecision rlaRecords = Security.stripInaccessible(AccessType.READABLE,rlaLIst);
        
        // Loop on the records to get Mortgages
        for(Sobject sobj: rlaRecords.getRecords()){
            if(sobj!=null){
                // Removing the Subject Property Check as it's not required as per the schema
                // 09-28-2021
                //Checking if Subject Property is available
                //if(sobj.get(appNameSpace+'Subject_Property__c')==null){
                    //throw createCustomException('Subject Property field is Required: Please make sure the Subject Property field is populated');
                //    requiredFieldError +='Please make sure the <b>Subject Property field</b> is populated</br>';
                //}
                //Checking if Mortgage(s) available
                if(sobj.getSObjects(appNameSpace+'Mortgages__r')==null){
                    //throw createCustomException('Please make sure the at-least one record of Mortgage is created');
                    requiredFieldError +='Please make sure the at-least one record of Requesting <b>Mortgage</b> is created.</br>';
                }
                
                Boolean requestingExists = false;
                
                // Populating Map of Application
                mapOfLoanApplication.put(String.valueof(sobj.get('Id')), sobj);
                // Getting list of Mortgages under RLA
                List<sObject> mortgages = sobj.getSObjects(appNameSpace+'Mortgages__r');
                if(mortgages!=null && mortgages.size() > 0){
                    // Adding all the Mortgages to a List
                    //listOfMortgages.addAll(mortgages);
                    for(sObject mortgage : mortgages){
                        // Populating Mortgages of Subject Property in a List
                        //if(String.valueof(mortgage.get(appNameSpace+'Loan_Application_Property__c')) == String.valueof(sobj.get(appNameSpace+'Subject_Property__c'))){
                        
                        // NEW: Only add if EXISTING MORTGAGE is FALSE
                        // UPDATE : Adding all the mortgages for the Subject Property
                        //if(Boolean.valueof(mortgage.get(appNameSpace+'Existing_Mortgage__c')) == false){
                            listOfMortgages.add(mortgage);    
                        //}
                        //
                        
                        
                        // Checking if any Requesting Mortgage exists
                        if(Boolean.valueof(mortgage.get(appNameSpace+'Existing_Mortgage__c')) == false && requestingExists==false){
                        	requestingExists=true;
                        }

                        // Populating SubjectProperty Mortgages
                        if(String.isBlank(String.valueof(mortgage.get(appNameSpace+'Loan_Application_Property__c'))) || String.valueof(mortgage.get(appNameSpace+'Loan_Application_Property__c')) == String.valueof(sobj.get(appNameSpace+'Subject_Property__c'))){
                            listofSubjectPropertyMortgages.add(mortgage);
                        }

                        // Creating a Map of Property and their Mortgages
                        //mapOfMortgageAgainstProp.put(mortgage.get('Loan_Application_Property__c'), mortgage);
                        if (mapOfMortgageAgainstProp.containsKey(String.valueof(mortgage.get(appNameSpace+'Loan_Application_Property__c')))){
                            list<sObject> tempList = mapOfMortgageAgainstProp.get(String.valueof(mortgage.get(appNameSpace+'Loan_Application_Property__c')));
                            //map<string, sObject> tempMap = new map<String, sObject>();
                            //tempMap.put(String.valueof(mortgage.get('Loan_Application_Property__c')), mortgage);
                            tempList.add(mortgage);
                            mapOfMortgageAgainstProp.put(String.valueof(mortgage.get(appNameSpace+'Loan_Application_Property__c')), tempList);
                        } else {
                            //map<string, sObject> tempMap = new Map<string, LoanApplicant>();
                            list<sObject> tempList = new list<sObject>();
                            //tempMap.put(String.valueof(mortgage.get('Loan_Application_Property__c')), mortgage);
                            tempList.add(mortgage);
                            mapOfMortgageAgainstProp.put(String.valueof(mortgage.get(appNameSpace+'Loan_Application_Property__c')), tempList);
                        }
                    }

                     /*Boolean RequestingMortgage=false;
                    //Looping again to check the Requirement
                    for(sObject mortgage : mortgages){
                        
                        // Making sure to create Mortgage only if it's Existing
                        if(Boolean.valueof(mortgage.get(appNameSpace+'Existing_Mortgage__c')) == false){
                            RequestingMortgage = true;
                        }
                    }*/

                    // Checking if the Loan Application has Requesting Mortgage
                    if(listOfMortgages ==null || listOfMortgages.size() == 0 || requestingExists==false){
                        // Preventing Same error message to show up
                        if(!requiredFieldError.contains('Requesting')){
                            requiredFieldError +='Please make sure the at-least one record of Requesting <b>Mortgage</b> is created</br>';
                        }
                    }
                }    
            }
        }

            
            If(rlaRecords.getRecords().size()>0){
                for (sObject rla : rlaRecords.getRecords()){
                
                    //setOfOppIds.add(String.valueof(rla.get('OpportunityId')));
                    if(rla.get(appNameSpace+'Subject_Property__c') !=null){
                        setOfSubjProdIds.add(String.valueof(rla.get(appNameSpace+'Subject_Property__c')));
                    }

                    /*
                    setOfOppIds.add(rla.OpportunityId);
                    setOfSubjProdIds.add(rla.Subject_Property__c);
                */
                    string rlaId = String.valueof(rla.get('Id'));

                //    mapOfLoanApplication.put(rla.id, rla);
                //mapOfLoanApplication.put(rlaId, rla);

                }
            } 

            // if(setOfOppIds.size() == 0 || setOfOppIds == null){
            //     requiredFieldError += 'Opportunity record is required';
            // }

            /* Down Payment Sources*/
            
           
            List<sObject> downSourceList = database.query(String.escapeSingleQuotes(downPaymentObjQuery));
            
            // Strip fields that are not readable
            SObjectAccessDecision downSourceRecords = Security.stripInaccessible(AccessType.READABLE,downSourceList);

            If(downSourceRecords.getRecords().size()>0){
            
                for(sObject dwnSrc : downSourceRecords.getRecords()){
                    if (mapofOppIdAndDownSources.containsKey(String.valueof(dwnSrc.get('Application__c')))) {
                        map<string, sObject> tempMap = mapofOppIdAndDownSources.get(String.valueof(dwnSrc.get('Application__c')));
                        tempMap.put(String.valueof(dwnSrc.get('id')), dwnSrc);
                        mapofOppIdAndDownSources.put(String.valueof(dwnSrc.get('Application__c')), tempMap);
                    } else {
                    map<string, sObject> tempMap = new Map<string, sObject>();//
                    tempMap.put(String.valueof(dwnSrc.get('id')), dwnSrc);
                        mapofOppIdAndDownSources.put(String.valueof(dwnSrc.get('Application__c')), tempMap);
                    }
                }
            }   

            
            List<sObject> loanApplicantList = database.query(String.escapeSingleQuotes(loanApplicantQuery));

            // Strip fields that are not readable
            SObjectAccessDecision loanApplicantRecords = Security.stripInaccessible(AccessType.READABLE,loanApplicantList);

            If(loanApplicantRecords.getRecords().size()>0){
                for (sObject lapp : loanApplicantRecords.getRecords()){
                    setOfApplicantIDs.add(lapp.Id);
                    if (mapofLoanAppIdAndApplicants.containsKey(String.valueof(lapp.get('LoanApplicationId')))){
                        map<string, sObject> tempMap = mapofLoanAppIdAndApplicants.get(String.valueof(lapp.get('LoanApplicationId')));
                        tempMap.put(String.valueof(lapp.get('id')), lapp);
                        mapofLoanAppIdAndApplicants.put(String.valueof(lapp.get('LoanApplicationId')), tempMap);
                    } else {
                        map<string, sObject> tempMap = new Map<string, LoanApplicant>();
                        string lappid = String.valueof(lapp.get('id'));
                        tempMap.put(String.valueof(lapp.get('id')), lapp);
                        mapofLoanAppIdAndApplicants.put(String.valueof(lapp.get('LoanApplicationId')), tempMap);
                    }
                }
            }  
            
            /*if(loanApplicantList.size()>2){  
            	 requiredFieldError +='Please make sure to add not more then <b> Two </b> applicants for same application.';  
                requiredFieldError +='<br>';  

            }*/

            /* Applicant Address */
            
           
            List<sObject> addressList = database.query(String.escapeSingleQuotes(loanApplicantAddressQuery));

            // Strip fields that are not readable
            SObjectAccessDecision addressRecords = Security.stripInaccessible(AccessType.READABLE,addressList);

            If(addressRecords.getRecords().size()>0){
                for (sObject addr : addressRecords.getRecords()){
                    if (mapofApplicantIdAndAddr.containsKey(String.valueof(addr.get('LoanApplicantId')))) {
                        map<string, sObject> tempMap = mapofApplicantIdAndAddr.get(String.valueof(addr.get('LoanApplicantId')));
                        tempMap.put(String.valueof(addr.get('id')), addr);
                        mapofApplicantIdAndAddr.put(String.valueof(addr.get('LoanApplicantId')), tempMap);
                    } else {
                        map<string, sObject> tempMap = new Map<string, sObject>();
                        tempMap.put(String.valueof(addr.get('id')), addr);
                        mapofApplicantIdAndAddr.put(String.valueof(addr.get('LoanApplicantId')), tempMap);
                    }
                }
            }  
            
            /*if(addressList.size() == 0 ){
                //throw createCustomException('Please make sure the at-least one record of Mortgage is created.');
                requiredFieldError +='Please make sure the at-least one record of Loan Applicant <b>Address</b> is created.</br>';
            }*/

            /* Applicant Identities */
            
            List<sObject> identityList = database.query(String.escapeSingleQuotes(loanApplicantIdentityQuery));

            // Strip fields that are not readable
            SObjectAccessDecision identityRecords = Security.stripInaccessible(AccessType.READABLE,identityList);

            If(identityRecords.getRecords().size()>0){
                for (sObject identity : identityRecords.getRecords()){
                    if (mapofApplicantIdAndIdentification.containsKey(String.valueof(identity.get(appNameSpace+'Loan_Applicant__c')))) {
                        map<string, sObject> tempMap = mapofApplicantIdAndIdentification.get(String.valueof(identity.get(appNameSpace+'Loan_Applicant__c')));
                        tempMap.put(String.valueof(identity.get('id')), identity);
                        mapofApplicantIdAndIdentification.put(String.valueof(identity.get(appNameSpace+'Loan_Applicant__c')), tempMap);
                    } else {
                        map<string, sObject> tempMap = new Map<string, sObject>();
                        tempMap.put(String.valueof(identity.get('id')), identity);
                        mapofApplicantIdAndIdentification.put(String.valueof(identity.get(appNameSpace+'Loan_Applicant__c')), tempMap);

                    }
                }
            }  

            /* Applicant Assets */
           

            
            List<sObject> assetList = database.query(String.escapeSingleQuotes(appAssetQuery));
            
            // Strip fields that are not readable
            SObjectAccessDecision assetRecords = Security.stripInaccessible(AccessType.READABLE,assetList);

            If(assetRecords.getRecords().size()>0){
                for (sObject asst : assetRecords.getRecords()){
                    if (mapofApplicantIdAndAsset.containsKey(String.valueof(asst.get('LoanApplicantId')))) {
                        map<string, sObject> tempMap = mapofApplicantIdAndAsset.get(String.valueof(asst.get('LoanApplicantId')));
                        tempMap.put(String.valueof(asst.get('id')), asst);
                        mapofApplicantIdAndAsset.put(String.valueof(asst.get('LoanApplicantId')), tempMap);
                    } else {
                        map<string, sObject> tempMap = new Map<string, LoanApplicantAsset>();
                        tempMap.put(String.valueof(asst.get('id')), asst);
                        mapofApplicantIdAndAsset.put(String.valueof(asst.get('LoanApplicantId')), tempMap);
                    }
                }
            }   

            /* Applicant Income */
            
           
            List<sObject> applicantIncomeList = database.query(String.escapeSingleQuotes(applicantIncomeQuery));

            // Strip fields that are not readable
            SObjectAccessDecision incomeRecords = Security.stripInaccessible(AccessType.READABLE,applicantIncomeList);

            if(incomeRecords.getRecords().size()>0){
                for (sObject inc : incomeRecords.getRecords()){
                    if (mapofApplicantIdAndIncome.containsKey(String.valueof(inc.get('LoanApplicantId')))) {
                        map<string, sObject> tempMap = mapofApplicantIdAndIncome.get(String.valueof(inc.get('LoanApplicantId')));
                        tempMap.put(String.valueof(inc.get('id')), inc);
                        mapofApplicantIdAndIncome.put(String.valueof(inc.get('LoanApplicantId')), tempMap);
                    } else {
                        map<string, sObject> tempMap = new Map<string, sObject>();
                        tempMap.put(String.valueof(inc.get('id')), inc);
                        mapofApplicantIdAndIncome.put(String.valueof(inc.get('LoanApplicantId')), tempMap);
                    }
                }
            }

            /* Applicant Employment */
            
            
            List<sObject> empList = database.query(String.escapeSingleQuotes(applicantEmploymentQuery));
            
            // Strip fields that are not readable
            SObjectAccessDecision employmentRecords = Security.stripInaccessible(AccessType.READABLE,empList);

            If(employmentRecords.getRecords().size()>0){
            
                for (sObject emp : employmentRecords.getRecords()){
                    if (mapofApplicantIdAndEmployment.containsKey(String.valueof(emp.get('LoanApplicantId')))) {
                        map<string, sObject> tempMap = mapofApplicantIdAndEmployment.get(String.valueof(emp.get('LoanApplicantId')));
                        tempMap.put(String.valueof(emp.get('id')), emp);
                        mapofApplicantIdAndEmployment.put(String.valueof(emp.get('LoanApplicantId')), tempMap);
                    } else {
                        map<string, sObject> tempMap = new Map<string, LoanApplicantEmployment>();
                        tempMap.put(String.valueof(emp.get('id')), emp);
                        mapofApplicantIdAndEmployment.put(String.valueof(emp.get('LoanApplicantId')), tempMap);
                    }
                }
            }    
           
           
            List<sObject> applicantLiabilityList = database.query(String.escapeSingleQuotes(applicantLiabilityQuery));
            
             // Strip fields that are not readable
             SObjectAccessDecision liabilityRecords = Security.stripInaccessible(AccessType.READABLE,applicantLiabilityList);

            If(liabilityRecords.getRecords().size()>0) {
                for (sObject lia : liabilityRecords.getRecords()){
                        if (mapofApplicantIdAndLiability.containsKey(String.valueof(lia.get('LoanApplicantId'))))
                        {
                            map<string, sObject> tempMap = mapofApplicantIdAndLiability.get(String.valueof(lia.get('LoanApplicantId')));
                            tempMap.put(String.valueof(lia.get('id')), lia);
                            mapofApplicantIdAndLiability.put(String.valueof(lia.get('LoanApplicantId')), tempMap);
                        } else {
                            map<string, sObject> tempMap = new Map<string, sObject>();
                            tempMap.put(String.valueof(lia.get('id')), lia);
                            mapofApplicantIdAndLiability.put(String.valueof(lia.get('LoanApplicantId')), tempMap);
                        }
                    } 
            }
            set<string> setOfPropIDs = new Set<string>();
            //  Applicant Properties
           List<sObject> applicationPropertyList = database.query(String.escapeSingleQuotes(applicationPropertyQuery));

           // Strip fields that are not readable
           SObjectAccessDecision propertyRecords = Security.stripInaccessible(AccessType.READABLE,applicationPropertyList);
   
            If(propertyRecords.getRecords().size()>0){
                for (sObject lapr : propertyRecords.getRecords()){

                        // Earlier Implementation
                        //mapofLoanAppIdAndProperties(<RLA-ID>,(<property-Id>,<Property-sObject>));
                        // New Implementation - Hamza
                        //mapofLoanAppIdAndProperties(<Loan-Applicant-Id>,(<propertyId>,<PropertysObject>));

                        setOfPropIDs.add(lapr.Id);
                        if (mapofLoanAppIdAndProperties.containsKey(string.valueof(lapr.get('Loan_Applicant__c')))) {
                            map<string, sObject> tempMap =  mapofLoanAppIdAndProperties.get(String.valueof(lapr.get('Loan_Applicant__c')));
                            //tempMap.put(lapr.id, lapr);
                            tempMap.put(String.valueof(lapr.get('id')), lapr);
                            mapofLoanAppIdAndProperties.put(String.valueof(lapr.get('Loan_Applicant__c')), tempMap);
                        } else {
                            map<string, sObject> tempMap = new Map<string,sObject>();
                            //tempMap.put(lapr.id, lapr);
                            tempMap.put(String.valueof(lapr.get('id')), lapr);
                            mapofLoanAppIdAndProperties.put(String.valueof(lapr.get('Loan_Applicant__c')), tempMap);
                        }
                    }
            }
        }
    }
    
    global static string returnJSON() {
        try{
            string jsonStr = null;
            FilogixPOSTJSONWrapper.Deal deal = bindDealData(mapOfLoanApplication,mapofOppIdAndDownSources);
            
            System.debug('deal in returnJSON '+ deal);
            list<FilogixPOSTJSONWrapper.ApplicantGroup> applicantGroup = bindAPGroupData(
                mapOfLoanApplication,
                mapofLoanAppIdAndApplicants,
                mapofApplicantIdAndIdentification,
                mapofApplicantIdAndAddr,
                mapofApplicantIdAndAsset,
                mapofApplicantIdAndIncome,
                mapofApplicantIdAndEmployment,
                mapofApplicantIdAndLiability,
                mapofLoanAppIdAndProperties
            );
            system.debug('#applicantGroup=' + applicantGroup);
            list<FilogixPOSTJSONWrapper.Mortgage_Existing> mortgage_existing = bindExistingMortgageData(mapOfLoanApplication, listofSubjectPropertyMortgages);
            System.debug('mortgage ' + mortgage_existing);

            list<FilogixPOSTJSONWrapper.Mortgage_Requesting> mortgage_requesting = bindRequestingMortgageData(mapOfLoanApplication, listofSubjectPropertyMortgages);
            System.debug('mortgage_requesting ' + mortgage_requesting);

            FilogixPOSTJSONWrapper.SubjectProperty subjectProperty = bindSubjPropData(mapOfLoanApplication,mapofLoanAppIdAndProperties);
            
            System.debug('subjectProperty ' + subjectProperty);
            // Commenting our Notes because we do not have a mapping and sending null doesn't makes sense.
            //list<FilogixPOSTJSONWrapper.Notes> notes = bindNotesData();
            
            FilogixPOSTJSONWrapper.mortgageApplication mortApp = new FilogixPOSTJSONWrapper.mortgageApplication();
            mortApp.deal = deal;
            mortApp.applicantGroup = applicantGroup;
            mortApp.existing = mortgage_existing;
            mortApp.requested = mortgage_requesting;
            mortApp.subjectProperty = subjectProperty;
            //mortApp.notes = notes; //Commenting out for a purpose
            System.debug('mortApp ' + mortApp);
            if (!string.isBlank(requiredFieldError)) {
                string errorMsg = '<h3>Required information is missing,</h3>' + requiredFieldError;
                //return errorMsg;
                //throw new OtherException(errorMsg);
                //throw createCustomException(errorMsg);
                System.debug('errorMsg ' + errorMsg);
                return errorMsg;
            } else {
                //return requiredFieldError;
                FilogixPOSTJSONWrapper classInstance = new FilogixPOSTJSONWrapper();
                classInstance.mortgageApplication = mortApp;
                jsonStr = JSON.serialize(classInstance, true);
                system.debug('###Json=' + jsonStr);
                //jsonStr = stripJsonNulls(jsonStr);
                System.debug('jsonStr in returnJSON' + stripJsonNulls(jsonStr));

                return jsonStr;
            }
        } catch(Exception e){
            system.debug('Error:'+ e + String.valueOf(e.getLineNumber()));
            return 'Please make sure all the records are populated - Example: Subject Property, Mortgages, Loan Applicant, Loan Applicant Employment and etc.<br>Stack Trace:'+e+' - '+ String.valueOf(e.getLineNumber()+'</br> Please contact the App Developer.');
        }
    }
    
    public static list<FilogixPOSTJSONWrapper.Notes> bindNotesData() {
        List<FilogixPOSTJSONWrapper.Notes> noteList = new List<FilogixPOSTJSONWrapper.Notes>();
        FilogixPOSTJSONWrapper.Notes notes = new FilogixPOSTJSONWrapper.Notes();
        notes.categoryDd = null; //Admin
        notes.entryDate = null; //2020-10-09T12:01:02
        notes.text = null; //a
        noteList.add(notes);
        
        return noteList;
    }
    
    public static FilogixPOSTJSONWrapper.Deal bindDealData(
        map<string, sObject> mapOfLoanApplication,
        map<string, map<string, sObject>> mapofOppIdAndDownSources
    ) {
        system.debug('dealfunction');
        FilogixPOSTJSONWrapper.Deal d = new FilogixPOSTJSONWrapper.Deal();
                String appNameSpace = getAppNameSpace();

        list<FilogixPOSTJSONWrapper.DownPaymentSource> dpSources = new List<FilogixPOSTJSONWrapper.DownPaymentSource>();
        if (!mapOfLoanApplication.isEmpty()) {
            for (string rlaId : mapOfLoanApplication.keyset()) {
                sObject rlaRecord = mapOfLoanApplication.get(rlaId);
                if (mapofOppIdAndDownSources.containsKey(rlaId)) {
                    map<string, sObject> mapOfDwnSrces = mapofOppIdAndDownSources.get(
                        //mapOfLoanApplication.get(rlaId).OpportunityId
                        rlaId
                    );
                    for (string dwnSrcId : mapOfDwnSrces.keySet()) {
                        FilogixPOSTJSONWrapper.DownPaymentSource dpSrc = new FilogixPOSTJSONWrapper.DownPaymentSource();
                        dpSrc.amount = mapOfDwnSrces.containsKey(dwnSrcId)? (double)mapOfDwnSrces.get(dwnSrcId).get('Amount__c'): null;
                        dpSrc.description = mapOfDwnSrces.containsKey(dwnSrcId)? String.valueof(mapOfDwnSrces.get(dwnSrcId).get('Description__c')): null;
                        dpSrc.downPaymentSourceTypeDd = mapOfDwnSrces.containsKey(dwnSrcId)? String.valueof(mapOfDwnSrces.get(dwnSrcId).get('Source_Type__c')): null; //Borrowed Against Liquid Assets
                        
                        dpSources.add(dpSrc);
                        
                        if (string.Valueof(mapOfDwnSrces.get(dwnSrcId).get(appNameSpace+'Amount__c')) == null ||String.isBlank(String.valueof(mapOfDwnSrces.get(dwnSrcId).get(appNameSpace+'Amount__c')))) {
                            requiredFieldsError('Down_Payment_Source__c','Amount__c',String.valueof(mapOfDwnSrces.get('Name')),String.valueof(mapOfDwnSrces.get('Id')));
                        }
                        
                        if (string.Valueof(mapOfDwnSrces.get(dwnSrcId).get(appNameSpace+'Description__c')) == null ||String.isBlank(String.valueof(mapOfDwnSrces.get(dwnSrcId).get(appNameSpace+'Description__c')))) {
                            requiredFieldsError('Down_Payment_Source__c','Description__c',String.valueof(mapOfDwnSrces.get('Name')),String.valueof(mapOfDwnSrces.get('Id')));
                        }
                        
                        if (string.Valueof(mapOfDwnSrces.get(dwnSrcId).get(appNameSpace+'Source_Type__c')) == null ||String.isBlank(String.valueof(mapOfDwnSrces.get(dwnSrcId).get(appNameSpace+'Source_Type__c')))) {
                            requiredFieldsError('Down_Payment_Source__c','Source_Type__c',String.valueof(mapOfDwnSrces.get('Name')),String.valueof(mapOfDwnSrces.get('Id')));
                        }
                        
                    }
                }
                
                // Validating if Opportunity Id is present in the record
                //if(rlaRecord.getSObject('Opportunity') !=null){
                    // Required fields check
                    if (mapOfLoanApplication.containsKey(rlaId) && string.isBlank(String.valueof(rlaRecord.get('Deal_Purpose__c')))) {
                        requiredFieldsError('ResidentialLoanApplication','Deal_Purpose__c',String.valueof(rlaRecord.get('Name')),String.valueof(rlaRecord.get('Id')));
                    }
                    
                    if (mapOfLoanApplication.containsKey(rlaId) &&  rlaRecord.get('Deal_Type__c') == null || string.isBlank(String.valueof(rlaRecord.get('Deal_Type__c')))) {
                        requiredFieldsError('ResidentialLoanApplication','Deal_Type__c',String.valueof(rlaRecord.get('Name')),String.valueof(rlaRecord.get('Id')));
                    }
                
                        if (mapOfLoanApplication.containsKey(rlaId) && (Datetime) rlaRecord.get('Estimated_Closing_Date__c') == null ) {
                        requiredFieldsError('ResidentialLoanApplication','Estimated_Closing_Date__c',String.valueof(rlaRecord.get('Name')),String.valueof(rlaRecord.get('Id')));
                    }
                    
                    // if (mapOfLoanApplication.containsKey(rlaId) && (String.valueof(rlaRecord.get('Ref_Purpose__c')) == null || string.isBlank(String.valueof(rlaRecord.get('Ref_Purpose__c'))))) {
                    //     requiredFieldsError('ResidentialLoanApplication','Ref_Purpose__c',String.valueof(rlaRecord.get('Name')),String.valueof(rlaRecord.get('Id')));
                    // }
                    
                    d.dealPurposeDd = mapOfLoanApplication.containsKey(rlaId)? String.valueof(rlaRecord.get('Deal_Purpose__c')):null;
                    d.dealTypeDd = mapOfLoanApplication.containsKey(rlaId)? String.valueof(rlaRecord.get('Deal_Type__c')):null;
                    d.downPaymentSource = dpSources;
                    d.refiImprovementAmount = mapOfLoanApplication.containsKey(rlaId) && Double.valueof(rlaRecord.get('Ref_Improvement_Amount__c')) != null ? Double.valueof(rlaRecord.get('Ref_Improvement_Amount__c')): null;
                    d.refiImprovementsDesc = mapOfLoanApplication.containsKey(rlaId) && String.valueof(rlaRecord.get('Ref_Improvement_Description__c')) != null ? string.valueOf(rlaRecord.get('Ref_Improvement_Description__c')): null;
                    d.thirdPartyApplicationFlag = BooleanToString(String.valueof(rlaRecord.get('Third_Party_Application_Flag__c')));
                    d.estimatedClosingDate = formatDateTime(mapOfLoanApplication.containsKey(rlaId) && (Datetime) rlaRecord.get('Estimated_Closing_Date__c') != null? (datetime) rlaRecord.get('Estimated_Closing_Date__c'):null);			
                    d.financingWaiverDate = formatDateTime(mapOfLoanApplication.containsKey(rlaId) && (Datetime) rlaRecord.get('Financing_Waiver_Date__c') != null? (datetime) rlaRecord.get('Financing_Waiver_Date__c'):null);			
                    d.referralReferenceNo = mapOfLoanApplication.containsKey(rlaId) && String.valueof(rlaRecord.get('Referral_Reference_Number__c')) != null ? string.valueOf(rlaRecord.get('Referral_Reference_Number__c')): null;
                    d.refiImprovementsFlag = mapOfLoanApplication.containsKey(rlaId) ? BooleanToString(string.valueOf(rlaRecord.get('Ref_Improvements_Flag__c'))): 'N';
                    d.refiPurpose = mapOfLoanApplication.containsKey(rlaId) ? String.valueof(rlaRecord.get('Ref_Purpose__c')): null;
                    d.sourceApplicationId = mapOfLoanApplication.containsKey(rlaId)? String.valueof(rlaRecord.get('Id')): null;
                    d.taxPayorDd = mapOfLoanApplication.containsKey(rlaId) && String.valueof(rlaRecord.get('Tax_Payor__c'))!='' ? String.valueof(rlaRecord.get('Tax_Payor__c')): null;
                // } else {
                //     requiredFieldError +='Please make sure the Opportunity record is associated with this Residential Loan Application record';
                // }
            }
        }
        
        return d;
    }
    
    public static List<FilogixPOSTJSONWrapper.Mortgage_Existing> bindExistingMortgageData(map<string, sObject> mapOfLoanApplication, List<sObject> listofMortgages) {
        List<FilogixPOSTJSONWrapper.Mortgage_Existing> listMortgages = new List<FilogixPOSTJSONWrapper.Mortgage_Existing>();
        
        if (!listofMortgages.isEmpty()) {
            for (sObject mortgageRecord : listofMortgages) {
                //sObject rlaRecord = mortgage.get(rlaId);
    
                // Ignoring BorrowerIds - Hamza
                //list<FilogixPOSTJSONWrapper.BorrowerIds> brIDs = new List<FilogixPOSTJSONWrapper.BorrowerIds>();
                
                // FilogixPOSTJSONWrapper.BorrowerIds brId = new FilogixPOSTJSONWrapper.BorrowerIds();
                // brId.borrowerId = 1;
                // brIDs.add(brId);

                // Making sure to create Mortgage only if it's Existing
                if(Boolean.valueof(mortgageRecord.get('Existing_Mortgage__c')) == true){
                    
                    FilogixPOSTJSONWrapper.Rate_Z rt = new FilogixPOSTJSONWrapper.Rate_Z();
                    rt.interestRate = mortgageRecord.get('Interest_Rate__c') != null? Double.valueof(mortgageRecord.get('Interest_Rate__c')): null;
                    // Initializing Mortgages
                    FilogixPOSTJSONWrapper.Mortgage_Existing mortgage = new FilogixPOSTJSONWrapper.Mortgage_Existing();

                    mortgage.balanceRemaining = mortgageRecord.get('Balance_Remaining__c')!= null? Double.valueof(mortgageRecord.get('Balance_Remaining__c')): null;
                    mortgage.currentMortgageNumber = String.valueof(mortgageRecord.get('Current_Mortgage_Number__c'));
                    mortgage.existingMortgageFlag = BooleanToString(String.valueof(mortgageRecord.get('Existing_Mortgage__c')));
                    mortgage.existingMortgageHolder = String.valueof(mortgageRecord.get('Existing_Mortgage_Holder__c'));
                    mortgage.insuredFlag = BooleanToString(String.valueof(mortgageRecord.get('Is_Insured__c')));
                    mortgage.interestTypeDd = String.valueof(mortgageRecord.get('Interest_Type__c'));
                    mortgage.loanTypeDd = String.valueof(mortgageRecord.get('Loan_Type__c'));
                    mortgage.maturityDate = formatDateTime((DateTime) mortgageRecord.get('Maturity_Date__c'));
                    mortgage.miReferenceNumber =  String.valueOf(mortgageRecord.get('MI_Reference_Number__c'));
                    mortgage.mortgageInsurerId = String.valueOf(mortgageRecord.get('Mortgage_Insurer__c'));
                    mortgage.mortgageTypeDd = String.valueof(mortgageRecord.get('Mortgage_Type__c')); //mapOfLoanApplication.get(rlaId).Mortgage_Type__c;
                    mortgage.originalMortgageAmount = mortgageRecord.get('Original_Mortgage_Amount__c') != null? Double.valueOf(mortgageRecord.get('Original_Mortgage_Amount__c')): null;
                    mortgage.PAndIPaymentAmount = mortgageRecord.get('PAndIPaymentAmount__c') != null? Double.valueOf(mortgageRecord.get('PAndIPaymentAmount__c')): null;
                    mortgage.paymentFrequencyDd = string.valueof(mortgageRecord.get('Payment_Frequency__c'));
                    mortgage.paymentTermDd = string.valueof(mortgageRecord.get('Payment_Term__c'));
                    mortgage.payoffTypeDd = String.valueof(mortgageRecord.get('Payoff_Type__c'));
                    mortgage.refiAdditionalInformation = String.valueof(mortgageRecord.get('Ref_Additional_Information__c'));
                    mortgage.refiBlendedAmortization = BooleanToString(string.valueof(mortgageRecord.get('Ref_Blended_Amortization__c')));

                    listMortgages.add(mortgage);
                    

                if (mortgageRecord.get('Balance_Remaining__c') == null) {
                    requiredFieldsError('Mortgage__c','Balance_Remaining__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                }
                if (mortgageRecord.get('Current_Mortgage_Number__c') == null) {
                    requiredFieldsError('Mortgage__c','Current_Mortgage_Number__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                }

                if (mortgageRecord.get('Existing_Mortgage__c') == null) {
                    requiredFieldsError('Mortgage__c','Existing_Mortgage__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                }
                if (mortgageRecord.get('Existing_Mortgage_Holder__c') == null) {
                    requiredFieldsError('Mortgage__c','Existing_Mortgage_Holder__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                }

                if (mortgageRecord.get('Interest_Type__c') == null) {
                    requiredFieldsError('Mortgage__c','Interest_Type__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                }

                if (mortgageRecord.get('Loan_Type__c') == null) {
                    requiredFieldsError('Mortgage__c','Loan_Type__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                }

                if (mortgageRecord.get('Maturity_Date__c') == null) {
                    requiredFieldsError('Mortgage__c','Maturity_Date__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                }

                if (mortgageRecord.get('Mortgage_Type__c') == null) {
                    requiredFieldsError('Mortgage__c','Mortgage_Type__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                }

                if (mortgageRecord.get('Original_Mortgage_Amount__c') == null) {
                    requiredFieldsError('Mortgage__c','Original_Mortgage_Amount__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                }

                if (mortgageRecord.get('PAndIPaymentAmount__c') == null) {
                    requiredFieldsError('Mortgage__c','PAndIPaymentAmount__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                }

                if (mortgageRecord.get('Payment_Frequency__c') == null) {
                    requiredFieldsError('Mortgage__c','Payment_Frequency__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                }

                if (mortgageRecord.get('Payment_Term__c') == null) {
                    requiredFieldsError('Mortgage__c','Payment_Term__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                }

                /*if (mortgageRecord.get('Interest_Rate__c') == null) {
                    requiredFieldsError('Mortgage__c','Interest_Rate__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                }*/

                }
            }
        }
        return listMortgages;
    }
    
    public static List<FilogixPOSTJSONWrapper.Mortgage_Requesting> bindRequestingMortgageData(map<string, sObject> mapOfLoanApplication, List<sObject> listofMortgages) {
        List<FilogixPOSTJSONWrapper.Mortgage_Requesting> listMortgages = new List<FilogixPOSTJSONWrapper.Mortgage_Requesting>();
        
        if (!listofMortgages.isEmpty()) {
            for (sObject mortgageRecord : listofMortgages) {
         
                // Making sure to create Mortgage only if it's Requesting Mortgage
                if(Boolean.valueof(mortgageRecord.get('Existing_Mortgage__c')) == false){
  
                    // Initializing Mortgages
                    FilogixPOSTJSONWrapper.Mortgage_Requesting mortgage = new FilogixPOSTJSONWrapper.Mortgage_Requesting();
                    //mortgage.borrowerIds = brIDs;
                   
                    mortgage.actualPaymentTerm =  mortgageRecord.get('Actual_Payment_Term__c')!= null? Double.valueof(mortgageRecord.get('Actual_Payment_Term__c')): null;
                    mortgage.amortizationTerm =  mortgageRecord.get('Amortization_Term__c')!= null? Double.valueof(mortgageRecord.get('Amortization_Term__c')): null;
                    mortgage.cashBackAmt = mortgageRecord.get('Cash_Back_Amount__c')!= null? Double.valueof(mortgageRecord.get('Cash_Back_Amount__c')): null;
                    mortgage.cashBackOverride = BooleanToString(String.valueof(mortgageRecord.get('Cash_Back_Override__c')));
                    mortgage.cashBackPercentage = mortgageRecord.get('Cash_Back_Percentage__c')!= null? Double.valueof(mortgageRecord.get('Cash_Back_Percentage__c')): null;
                    mortgage.commercialFlag = BooleanToString(String.valueof(mortgageRecord.get('Commercial__c')));
                    mortgage.constructionFlag = BooleanToString(String.valueof(mortgageRecord.get('Construction__c')));
                    mortgage.existingMortgageFlag = BooleanToString(String.valueof(mortgageRecord.get('Existing_Mortgage__c')));
                    mortgage.helocFlag = BooleanToString(String.valueof(mortgageRecord.get('Heloc__c')));
                    mortgage.insuredFlag = BooleanToString(String.valueof(mortgageRecord.get('Is_Insured__c')));
                    mortgage.interestAdjustmentDate = formatDateTime((DateTime) mortgageRecord.get('Insurance_Adjustment_Date__c'));
                    mortgage.interestCompoundDd = String.valueof(mortgageRecord.get('Interest_Compound__c'));
                    mortgage.interestOnlyFlag = BooleanToString(String.valueof(mortgageRecord.get('Is_Interest_Only__c')));
                    mortgage.interestTypeDd = String.valueof(mortgageRecord.get('Interest_Type__c'));
                    mortgage.lineOfBusinessDd = String.valueof(mortgageRecord.get('Line_Of_Business__c'));
                    mortgage.loanTypeDd = String.valueof(mortgageRecord.get('Loan_Type__c'));
                    mortgage.locRepaymentTypeDd = String.valueof(mortgageRecord.get('LOC_Repayment_Type__c'));
                    mortgage.mortgageTypeDd = String.valueof(mortgageRecord.get('Mortgage_Type__c')); //mapOfLoanApplication.get(rlaId).Mortgage_Type__c;
                    mortgage.mtgInsIncludeFlag = BooleanToString(String.valueof(mortgageRecord.get('Mortgage_Insurance_Included__c')));
                    mortgage.netLoanAmount = mortgageRecord.get('Net_Loan_Amount__c') != null? Double.valueOf(mortgageRecord.get('Net_Loan_Amount__c')): null;
                    mortgage.paymentFrequencyDd = string.valueof(mortgageRecord.get('Payment_Frequency__c'));
                    mortgage.paymentTermDd = string.valueof(mortgageRecord.get('Payment_Term__c'));
                   
                    // POPULATING QUALIFYDETAILS
                    FilogixPOSTJSONWrapper.QualifyDetail_Z quaDet = new FilogixPOSTJSONWrapper.QualifyDetail_Z();
                    quaDet.amortizationTerm = mortgageRecord.get('Qualify_Amortization_Term__c')!= null? Double.valueof(mortgageRecord.get('Qualify_Amortization_Term__c')): null;
                    quaDet.interestCompoundDd = string.valueOf(mortgageRecord.get('Qualify_Interest_Compound__c'));
                    quaDet.interestOnlyFlag = BooleanToString(string.valueOf(mortgageRecord.get('Qualify_Is_Interest_Only__c')));
                   
                    mortgage.qualifyRate = mortgageRecord.get('Qualify_Rate__c') != null? Double.valueOf(mortgageRecord.get('Qualify_Rate__c')): null;

                    FilogixPOSTJSONWrapper.Rate_Z rt = new FilogixPOSTJSONWrapper.Rate_Z();
                    rt.discount = mortgageRecord.get('Discount__c') != null? Double.valueof(mortgageRecord.get('Discount__c')): null;
                    rt.premium = mortgageRecord.get('Premium__c') != null? Double.valueof(mortgageRecord.get('Premium__c')): null;
                    rt.buyDownRate = mortgageRecord.get('Buydown_Rate__c') != null? Double.valueof(mortgageRecord.get('Buydown_Rate__c')): null;
                
                    mortgage.rate = rt;
                    
                    mortgage.refiBlendedAmortization = BooleanToString(string.valueof(mortgageRecord.get('Ref_Blended_Amortization__c')));
                    mortgage.repaymentTypeDd = String.valueof(mortgageRecord.get('Repayment_Type__c'));
                    mortgage.requestedRate = mortgageRecord.get('Interest_Rate__c') !=null? Double.valueOf(mortgageRecord.get('Interest_Rate__c')): null;
                    mortgage.reverseFlag = BooleanToString(string.valueof(mortgageRecord.get('Reverse_Flag__c')));
                    mortgage.singleProgressiveTypeDd = string.valueof(mortgageRecord.get('Single_Progressive_Type__c'));
                    mortgage.subprimeFlag = BooleanToString(String.valueof(mortgageRecord.get('Sub_Prime__c')));

                    listMortgages.add(mortgage);
                    
                    //Required fields Check
                    if (mortgageRecord.get('Existing_Mortgage__c') == null) {
                        requiredFieldsError('Mortgage__c','Existing_Mortgage__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                    }
    
                    if (mortgageRecord.get('Loan_Type__c') == null) {
                        requiredFieldsError('Mortgage__c','Loan_Type__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                    }
    
                    if (mortgageRecord.get('Mortgage_Type__c') == null) {
                        requiredFieldsError('Mortgage__c','Mortgage_Type__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                    }
    
                    if (mortgageRecord.get('Net_Loan_Amount__c') == null) {
                        requiredFieldsError('Mortgage__c','Net_Loan_Amount__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                    }
    
                    if (mortgageRecord.get('Payment_Frequency__c') == null) {
                        requiredFieldsError('Mortgage__c','Payment_Frequency__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                    }
    
                    if (mortgageRecord.get('Payment_Term__c') == null) {
                        requiredFieldsError('Mortgage__c','Payment_Term__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                    }

                    if (mortgageRecord.get('Interest_Rate__c') == null) {
                        requiredFieldsError('Mortgage__c','Interest_Rate__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                    }
    
                }
            }
        }
        return listMortgages;
    }


    public static FilogixPOSTJSONWrapper.SubjectProperty bindSubjPropData(map<string, sObject> mapOfLoanApplication,map<string, map<string, sObject>> mapOfProp) {
        String appNameSpace = getAppNameSpace();
        FilogixPOSTJSONWrapper.SubjectProperty subPrp = new FilogixPOSTJSONWrapper.SubjectProperty();
        
        for (string rlaId : mapOfLoanApplication.keyset()) {
           
            sObject rlaRecord = mapOfLoanApplication.get(rlaId);
            system.debug('rlaRecord='+rlaRecord);
            list<FilogixPOSTJSONWrapper.PropertyExpense> ListExpenses = new List<FilogixPOSTJSONWrapper.PropertyExpense>();
            string SubPrpId = rlaRecord.get('Subject_Property__c') != null? string.Valueof(rlaRecord.get('Subject_Property__c')): null;
            
            // Precautionary check
            /*if(SubPrpId == null && !requiredFieldError.contains('Subject Property field')){
                 //throw createCustomException('Subject Property field is Required: Please make sure the Subject Property field is populated');
                 requiredFieldError +='Please make sure the <b>Subject Property field</b> is populated</br>';
            }*/
            
            if(!string.isEmpty(SubPrpId)){

                // Property Expenses
                Double Municipal = rlaRecord.getSObject('Subject_Property__r').get('Annual_Taxes__c')!=null?Double.valueOf(rlaRecord.getSObject('Subject_Property__r').get('Annual_Taxes__c')): 0;
                Double Insurance = rlaRecord.getSObject('Subject_Property__r').get('Insurance_Expenses__c')!=null?Double.valueOf(rlaRecord.getSObject('Subject_Property__r').get('Insurance_Expenses__c')): 0;
                Double Heat = rlaRecord.getSObject('Subject_Property__r').get('Heating_Expenses__c')!=null?Double.valueOf(rlaRecord.getSObject('Subject_Property__r').get('Heating_Expenses__c')): 0;
                Double Hydro = rlaRecord.getSObject('Subject_Property__r').get('Hydro_Expenses__c')!=null?Double.valueOf(rlaRecord.getSObject('Subject_Property__r').get('Hydro_Expenses__c')): 0;
                Double Interest = rlaRecord.getSObject('Subject_Property__r').get('Interest_Expenses__c')!=null?Double.valueOf(rlaRecord.getSObject('Subject_Property__r').get('Interest_Expenses__c')): 0;
                Double General = rlaRecord.getSObject('Subject_Property__r').get('Management_Expenses__c')!=null?Double.valueOf(rlaRecord.getSObject('Subject_Property__r').get('Management_Expenses__c')): 0;
                Double Other = rlaRecord.getSObject('Subject_Property__r').get('Other_Expenses__c')!=null?Double.valueOf(rlaRecord.getSObject('Subject_Property__r').get('Other_Expenses__c')): 0;
                Double Repair = rlaRecord.getSObject('Subject_Property__r').get('Repairs_Expenses__c')!=null?Double.valueOf(rlaRecord.getSObject('Subject_Property__r').get('Repairs_Expenses__c')): 0;
                Double Condo = rlaRecord.getSObject('Subject_Property__r').get('Total_Condo_Fees__c')!=null?Double.valueOf(rlaRecord.getSObject('Subject_Property__r').get('Total_Condo_Fees__c')): 0;
                
                
                if(Municipal!=0){
                    FilogixPOSTJSONWrapper.PropertyExpense MunicipalExpense = new FilogixPOSTJSONWrapper.PropertyExpense();
                    MunicipalExpense.propertyExpenseAmount = Municipal;//Double.valueOf(rlaRecord.getSObject('Subject_Property__r').get('Annual_Taxes__c')): 0;
                    MunicipalExpense.propertyExpensePeriodDd = 'Annual';///String.valueof(mapOfPropExp.get(expId).get('propertyExpensePeriod__c'));
                    MunicipalExpense.propertyExpenseTypeDd = 'Municipal Taxes';
                    ListExpenses.add(MunicipalExpense);
                }
                if(Condo!=0){
                    FilogixPOSTJSONWrapper.PropertyExpense CondoExpense = new FilogixPOSTJSONWrapper.PropertyExpense();
                    CondoExpense.propertyExpenseAmount = Condo;//Double.valueOf(rlaRecord.getSObject('Subject_Property__r').get('Annual_Taxes__c')): 0;
                    CondoExpense.propertyExpensePeriodDd = 'Monthly';///String.valueof(mapOfPropExp.get(expId).get('propertyExpensePeriod__c'));
                    CondoExpense.propertyExpenseTypeDd = 'Condo Fees';
                    ListExpenses.add(CondoExpense);
                }
                if(General!=0){
                    FilogixPOSTJSONWrapper.PropertyExpense GeneralExpense = new FilogixPOSTJSONWrapper.PropertyExpense();
                    GeneralExpense.propertyExpenseAmount = General;//Double.valueOf(rlaRecord.getSObject('Subject_Property__r').get('Annual_Taxes__c')): 0;
                    GeneralExpense.propertyExpensePeriodDd = 'Monthly';///String.valueof(mapOfPropExp.get(expId).get('propertyExpensePeriod__c'));
                    GeneralExpense.propertyExpenseTypeDd = 'General Expenses';
                    ListExpenses.add(GeneralExpense);
                }
                if(Heat!=0){
                    FilogixPOSTJSONWrapper.PropertyExpense HeatingExpense = new FilogixPOSTJSONWrapper.PropertyExpense();
                    HeatingExpense.propertyExpenseAmount = Heat;//Double.valueOf(rlaRecord.getSObject('Subject_Property__r').get('Annual_Taxes__c')): 0;
                    HeatingExpense.propertyExpensePeriodDd = 'Monthly';///String.valueof(mapOfPropExp.get(expId).get('propertyExpensePeriod__c'));
                    HeatingExpense.propertyExpenseTypeDd = 'Heating Expense';
                    ListExpenses.add(HeatingExpense);
                }
                if(Hydro!=0){
                    FilogixPOSTJSONWrapper.PropertyExpense HydroExpense = new FilogixPOSTJSONWrapper.PropertyExpense();
                    HydroExpense.propertyExpenseAmount = Hydro;//Double.valueOf(rlaRecord.getSObject('Subject_Property__r').get('Annual_Taxes__c')): 0;
                    HydroExpense.propertyExpensePeriodDd = 'Monthly';///String.valueof(mapOfPropExp.get(expId).get('propertyExpensePeriod__c'));
                    HydroExpense.propertyExpenseTypeDd = 'Hydro';
                    ListExpenses.add(HydroExpense);
                }
                if(Insurance!=0){
                    FilogixPOSTJSONWrapper.PropertyExpense InsuranceExpense = new FilogixPOSTJSONWrapper.PropertyExpense();
                    InsuranceExpense.propertyExpenseAmount = Insurance;//Double.valueOf(rlaRecord.getSObject('Subject_Property__r').get('Annual_Taxes__c')): 0;
                    InsuranceExpense.propertyExpensePeriodDd = 'Monthly';///String.valueof(mapOfPropExp.get(expId).get('propertyExpensePeriod__c'));
                    InsuranceExpense.propertyExpenseTypeDd = 'Insurance';
                    ListExpenses.add(InsuranceExpense);
                }
                if(Interest!=0){
                    FilogixPOSTJSONWrapper.PropertyExpense InterestExpense = new FilogixPOSTJSONWrapper.PropertyExpense();
                    InterestExpense.propertyExpenseAmount = Interest;//Double.valueOf(rlaRecord.getSObject('Subject_Property__r').get('Annual_Taxes__c')): 0;
                    InterestExpense.propertyExpensePeriodDd = 'Monthly';///String.valueof(mapOfPropExp.get(expId).get('propertyExpensePeriod__c'));
                    InterestExpense.propertyExpenseTypeDd = 'Interest Charges';
                    ListExpenses.add(InterestExpense);
                }
                if(Other!=0){
                    FilogixPOSTJSONWrapper.PropertyExpense OtherExpense = new FilogixPOSTJSONWrapper.PropertyExpense();
                    OtherExpense.propertyExpenseAmount = Other;//Double.valueOf(rlaRecord.getSObject('Subject_Property__r').get('Annual_Taxes__c')): 0;
                    OtherExpense.propertyExpensePeriodDd = 'Monthly';///String.valueof(mapOfPropExp.get(expId).get('propertyExpensePeriod__c'));
                    OtherExpense.propertyExpenseTypeDd = 'Management Expenses';
                    ListExpenses.add(OtherExpense);
                }
                
                if(Repair!=0){
                    FilogixPOSTJSONWrapper.PropertyExpense RepairExpense = new FilogixPOSTJSONWrapper.PropertyExpense();
                    RepairExpense.propertyExpenseAmount = Repair;//Double.valueOf(rlaRecord.getSObject('Subject_Property__r').get('Annual_Taxes__c')): 0;
                    RepairExpense.propertyExpensePeriodDd = 'Monthly';///String.valueof(mapOfPropExp.get(expId).get('propertyExpensePeriod__c'));
                    RepairExpense.propertyExpenseTypeDd = 'Repairs';
                    ListExpenses.add(RepairExpense);
                }

                /* Expense END */

  
                //if (!string.isblank(SubPrpId)){
                FilogixPOSTJSONWrapper.Address addr = new FilogixPOSTJSONWrapper.Address();
                addr.unitNumber = string.valueof(rlaRecord.getSObject('Subject_Property__r').get('PropertyUnitNumber__c'));
                addr.streetNumber = string.valueof(rlaRecord.getSObject('Subject_Property__r').get('Street_Number__c')); //!string.isEmpty(string.valueof(rlaRecord.getSObject('Subject_Property__r').get('Street_Number__c')))?string.valueof(rlaRecord.getSObject('Subject_Property__r').get('PropertyStreet')).SubStringBefore(' '):'';//
                addr.streetName = !String.isEmpty(String.valueof(rlaRecord.getSObject('Subject_Property__r').get('Street_Name__c')))?String.valueof(rlaRecord.getSObject('Subject_Property__r').get('Street_Name__c')):'';///string.valueof(rlaRecord.getSObject('Subject_Property__r').get('PropertyStreet')).SubStringAfter(' ');
                addr.streetTypeDd = string.valueof(rlaRecord.getSObject('Subject_Property__r').get('Street_Type__c'));
                addr.streetDirectionDd =  string.valueof(rlaRecord.getSObject('Subject_Property__r').get('Direction__c'));
                // Filogix supports upto 20 characters for City
                addr.city = cityNamegen(string.valueof(rlaRecord.getSObject('Subject_Property__r').get('City__c')));
                //addr.city = string.valueof(rlaRecord.getSObject('Subject_Property__r').get('PropertyCity')).length()>20 ? string.valueof(rlaRecord.getSObject('Subject_Property__r').get('PropertyCity')).substr(0,20):string.valueof(rlaRecord.getSObject('Subject_Property__r').get('PropertyCity'));
                addr.provinceDd = getFullProvinceName(string.valueof(rlaRecord.getSObject('Subject_Property__r').get('Province__c')));
                if(postalFSAGen(string.valueof(rlaRecord.getSObject('Subject_Property__r').get('PostalCode__c')))!=''){
                    addr.postalFsa = postalFSAGen(string.valueof(rlaRecord.getSObject('Subject_Property__r').get('PostalCode__c')));
                }
                if(postalLDUGen(string.valueof(rlaRecord.getSObject('Subject_Property__r').get('PostalCode__c')))!=''){
                    addr.postalLdu = postalLDUGen(string.valueof(rlaRecord.getSObject('Subject_Property__r').get('PostalCode__c')));
                }
                addr.countryTypeDd = getFullCountryName(string.valueof(rlaRecord.getSObject('Subject_Property__r').get('Country__c')));
                
                //Required fields check
                if (rlaRecord.getSObject('Subject_Property__r').get('Country__c') == null) {
                    requiredFieldsError('LoanApplicationProperty','Country__c',String.valueof(rlaRecord.getSObject('Subject_Property__r').get('Name')),String.valueof(rlaRecord.getSObject('Subject_Property__r').get('Id')));
                }
                //Required fields check
                if (rlaRecord.getSObject('Subject_Property__r').get('Province__c') == null) {
                    requiredFieldsError('LoanApplicationProperty','Province__c',String.valueof(rlaRecord.getSObject('Subject_Property__r').get('Name')),String.valueof(rlaRecord.getSObject('Subject_Property__r').get('Id')));
                }
                //Required fields check
                if (rlaRecord.getSObject('Subject_Property__r').get('PostalCode__c') == null) {
                    requiredFieldsError('LoanApplicationProperty','PostalCode__c',String.valueof(rlaRecord.getSObject('Subject_Property__r').get('Name')),String.valueof(rlaRecord.getSObject('Subject_Property__r').get('Id')));
                }

                // RENTAL INCOME
                // If Occupancy Type contains "Rental"
                if(!string.isBlank(string.Valueof(rlaRecord.getSObject('Subject_Property__r').get('PropertyUseType'))) && string.Valueof(rlaRecord.getSObject('Subject_Property__r').get('PropertyUseType')).contains('Rental')){
                    FilogixPOSTJSONWrapper.RentalIncome rInc = new FilogixPOSTJSONWrapper.RentalIncome();
                    rInc.incomeAmount = rlaRecord.getSObject('Subject_Property__r').get('ExpMonthlyRentalIncome') != null? Double.valueOf(rlaRecord.getSObject('Subject_Property__r').get('ExpMonthlyRentalIncome')): null;
                    rInc.incomePeriodDd = string.valueof(rlaRecord.getSObject('Subject_Property__r').get('Rental_Income_Period__c'));
                    rInc.incomeTypeDd = string.valueof(rlaRecord.getSObject('Subject_Property__r').get('Rental_Income_Type__c'));
                    rInc.incPercentInTds = rInc.incPercentInGds = rlaRecord.getSObject('Subject_Property__r').get('Rental_IncPercentInTds__c') != null? Double.valueOf(rlaRecord.getSObject('Subject_Property__r').get('Rental_IncPercentInTds__c')): null;
                    //rInc.incomeDescription (Missing Mappping)
                    
                    //Required fields check
                    if (rlaRecord.getSObject('Subject_Property__r').get('ExpMonthlyRentalIncome') == null) {
                        requiredFieldsError('LoanApplicationProperty','ExpMonthlyRentalIncome',String.valueof(rlaRecord.getSObject('Subject_Property__r').get('Name')),String.valueof(rlaRecord.getSObject('Subject_Property__r').get('Id')));
                    }
                    
                    if (rlaRecord.getSObject('Subject_Property__r').get('Rental_Income_Period__c') == null) {
                        requiredFieldsError('LoanApplicationProperty','Rental_Income_Period__c',String.valueof(rlaRecord.getSObject('Subject_Property__r').get('Name')),String.valueof(rlaRecord.getSObject('Subject_Property__r').get('Id')));
                    }
                    
                    if (rlaRecord.getSObject('Subject_Property__r').get('Rental_Income_Type__c') == null) {
                        requiredFieldsError('LoanApplicationProperty','Rental_Income_Type__c',String.valueof(rlaRecord.getSObject('Subject_Property__r').get('Name')),String.valueof(rlaRecord.getSObject('Subject_Property__r').get('Id')));
                    }
                    // Adding rInc to the Subject Property
                    subPrp.rentalIncome = rInc;
                }
                
                subPrp.actualAppraisalValue = rlaRecord.getSObject('Subject_Property__r').get('AppraisedValue__c') != null? Double.valueof(rlaRecord.getSObject('Subject_Property__r').get('AppraisedValue__c')): null;
                subPrp.address = addr;
                subPrp.appraisalDateAct = rlaRecord.getSObject('Subject_Property__r').get('Appraisal_Date__c') != null? formatDateTime((datetime)rlaRecord.getSObject('Subject_Property__r').get('Appraisal_Date__c')):null;
                subPrp.dwellingStyleDd = string.valueof(rlaRecord.getSObject('Subject_Property__r').get('Style__c'));
                subPrp.dwellingTypeDd = string.valueof(rlaRecord.getSObject('Subject_Property__r').get('Structure_Type__c'));
                subPrp.estimatedAppraisalValue = rlaRecord.getSObject('Subject_Property__r').get('PropertyValue') != null? Double.valueof(rlaRecord.getSObject('Subject_Property__r').get('PropertyValue')): null;
                subPrp.originalPurchasePrice = Double.valueof(rlaRecord.getSObject('Subject_Property__r').get('purchasePrice__c'));         
                subPrp.feesIncludeHeat = BooleanToString(string.valueOf( rlaRecord.getSObject('Subject_Property__r').get('feesIncludeHeat__c')));
                subPrp.garageSizeDd = string.valueOf( rlaRecord.getSObject('Subject_Property__r').get('Garage_Size__c'));
                subPrp.garageTypeDd = string.valueOf( rlaRecord.getSObject('Subject_Property__r').get('Garage_Type__c'));
                subPrp.heatTypeDd = string.valueOf( rlaRecord.getSObject('Subject_Property__r').get('Heat__c'));
                subPrp.includetds = BooleanToString(string.valueOf( rlaRecord.getSObject('Subject_Property__r').get('includetds__c')));
                subPrp.purchasePrice = Double.valueof(rlaRecord.getSObject('Subject_Property__r').get('purchasePrice__c'));   
                //subPrp.insulatedWithUffi = mapOfProperties.get(propId).insulatedWithUffi__c; 
                subPrp.legalLine1 =  string.valueOf( rlaRecord.getSObject('Subject_Property__r').get('lot__c'));
                subPrp.legalLine2 =  string.valueOf( rlaRecord.getSObject('Subject_Property__r').get('block__c'));
                subPrp.legalLine3 = string.valueOf( rlaRecord.getSObject('Subject_Property__r').get('Conc_Township__c'));
                subPrp.livingSpace = rlaRecord.getSObject('Subject_Property__r').get('livingSpace__c') != null? Double.valueof( rlaRecord.getSObject('Subject_Property__r').get('livingSpace__c')): null;
                subPrp.livingSpaceUnitOfMeasurDd = string.valueof(rlaRecord.getSObject('Subject_Property__r').get('livingSpaceUnitOfMeasurDd__c'));
                subPrp.lotSize = rlaRecord.getSObject('Subject_Property__r').get('lotSize__c') != null? Double.valueof(rlaRecord.getSObject('Subject_Property__r').get('lotSize__c')): null;
                subPrp.lotSizeUnitOfMeasureDd = string.Valueof(rlaRecord.getSObject('Subject_Property__r').get('lotSizeUnitOfMeasure__c'));
                subPrp.mlsListingFlag = BooleanToString(String.valueof(rlaRecord.getSObject('Subject_Property__r').get('mlsListingFlag__c')));
                subPrp.newConstructionDd = string.Valueof(rlaRecord.getSObject('Subject_Property__r').get('Construction_Type__c'));
                subPrp.numberOfUnits = rlaRecord.getSObject('Subject_Property__r').get('numberOfUnits__c') != null? Double.valueof(rlaRecord.getSObject('Subject_Property__r').get('numberOfUnits__c')): null;
                subPrp.occupancyTypeDd = string.Valueof(rlaRecord.getSObject('Subject_Property__r').get('PropertyUseType'));
                subPrp.propertyTypeDd = string.Valueof(rlaRecord.getSObject('Subject_Property__r').get('Property_Type__c'));
                //subPrp.propertyValueIndexId = mapOfProperties.get(propId).propertyValueIndexId__c;
                subPrp.purchasePrice = rlaRecord.getSObject('Subject_Property__r').get('Original_Purchase_Price__c') != null? Double.valueof(rlaRecord.getSObject('Subject_Property__r').get('Original_Purchase_Price__c')): null;
                subPrp.realtorInfo = string.valueof(rlaRecord.getSObject('Subject_Property__r').get('realtorInfo__c'));
                subPrp.rentalOffsetOption = string.valueof(rlaRecord.getSObject('Subject_Property__r').get('rentalOffsetOption__c'));
                subPrp.sewageTypeDd = string.valueof(rlaRecord.getSObject('Subject_Property__r').get('Sewage_Type__c'));
                subPrp.structureAge = rlaRecord.getSObject('Subject_Property__r').get('structureAge__c') != null? Double.valueof(rlaRecord.getSObject('Subject_Property__r').get('structureAge__c')): null;
                subPrp.taxationYear = rlaRecord.getSObject('Subject_Property__r').get('taxationYear__c') != null? Double.valueof( rlaRecord.getSObject('Subject_Property__r').get('taxationYear__c')): null;
                subPrp.waterTypeDd = string.Valueof(rlaRecord.getSObject('Subject_Property__r').get('Water_Type__c'));
                subPrp.propertyExpense = ListExpenses;
            //}
            } else { // Adding the Filogix Default values
                FilogixPOSTJSONWrapper.Address addr = new FilogixPOSTJSONWrapper.Address();
                addr.provinceDd = 'Ontario';
                addr.countryTypeDd = 'Canada';
                subPrp.address = addr;
            } // END IF
        } // END FOR
        return subPrp;
    }
    
    public static list<FilogixPOSTJSONWrapper.ApplicantGroup> bindAPGroupData(
        map<string, sObject> mapOfLoanApplication,
        map<string, map<string, sObject>> mapofLoanAppIdAndApplicants,
        map<string, map<string, sObject>> mapofApplicantIdAndIdentification,
        map<string, map<string, sObject>> mapofApplicantIdAndAddr,
        map<string, map<string, sObject>> mapofApplicantIdAndAsset,
        map<string, map<string, sObject>> mapofApplicantIdAndIncome,
        map<string, map<string, sObject>> mapofApplicantIdAndEmployment,
        map<string, map<string, sObject>> mapofApplicantIdAndLiability,
        map<string, map<string, sObject>> mapofLoanAppIdAndProperties
    ) {
        String appNameSpace = getAppNameSpace();
        list<FilogixPOSTJSONWrapper.ApplicantGroup> ListAppGrp = new List<FilogixPOSTJSONWrapper.ApplicantGroup>();
        for (string rlaId : mapOfLoanApplication.keyset()) {
            Boolean PrimaryAppExist=false;
            map<String,List<FilogixPOSTJSONWrapper.Applicant>> mapofLoanApplicantsbyGroup = new map<String,List<FilogixPOSTJSONWrapper.Applicant>>();
            sObject rlaRecord = mapOfLoanApplication.get(rlaId);
            FilogixPOSTJSONWrapper.ApplicantGroup AppGrp = new FilogixPOSTJSONWrapper.ApplicantGroup();
            list<FilogixPOSTJSONWrapper.Applicant> ListOfApplicants = new List<FilogixPOSTJSONWrapper.Applicant>();
            
            if (mapofLoanAppIdAndApplicants.containskey(rlaId)) {
                map<string, sObject> mapApplicants = mapofLoanAppIdAndApplicants.get(rlaId);
                //integer Borrowerid = 0;
                for (string applicantId : mapApplicants.keySet()) {

                    // Making sure to have at least one lookup populated either Business or Contact
                    if(
                    (mapApplicants.get(applicantId).getSObject('Contact') != null && mapApplicants.get(applicantId).get(appNameSpace+'Business_Account__c')!=null)
                    ||
                    (mapApplicants.get(applicantId).getSObject('Contact') == null && mapApplicants.get(applicantId).get(appNameSpace+'Business_Account__c')==null)
                    ){
                        requiredFieldError+='Please fill either Business Account or Contact Lookup for Applicant <a href="/'+applicantId+'">'+String.valueof(mapApplicants.get(applicantId).get('Name'))+'</a></br>';
                    }

                    //Borrowerid += 1;
                    FilogixPOSTJSONWrapper.Applicant Applicant = new FilogixPOSTJSONWrapper.Applicant();

                    FilogixPOSTJSONWrapper.Name appName = new FilogixPOSTJSONWrapper.Name();
                    String fullName='';
                    // For Person Account
                    if(mapApplicants.get(applicantId).getSObject('Contact') != null){
                        appName.firstName = string.valueof(mapApplicants.get(applicantId).getSObject('Contact')) != null ?string.valueof(mapApplicants.get(applicantId).getSObject('Contact').get('firstname')) : '';
                        appName.lastName = string.valueof(mapApplicants.get(applicantId).getSObject('Contact')) != null ? string.valueof(mapApplicants.get(applicantId).getSObject('Contact').get('LastName')) : '';
                    	fullName = appName.firstName +' '+appName.lastName;
                        // For Business Account
                    } else if(mapApplicants.get(applicantId).getSObject('Business_Account__r') != null){
                        fullName = String.valueof(mapApplicants.get(applicantId).getSObject('Business_Account__r').get('Name'));
                    } else {
                       fullName = String.valueof(mapApplicants.get(applicantId).get('Name'));
                     //   fullName = String.valueof(mapApplicants.get(applicantId).getSObject('Contact').get('FirstName'));
                    }

                    system.debug('appName.firstName' + appName.firstName);
                    system.debug('appName.lastName' + appName.lastName);
                    system.debug('appName.fullName' + fullName);

                    
                    //Splitting First and Last Name from the Either Business or Loan Applicant's Name.
                    if((appName.firstName!='' || appName.firstName!=null) && fullName!=''){
                        fullName = fullName.trim();
                        String firstName = '';
                        String lastName = '';
                        boolean hasLength = fullName.trim().length() > 0;
                        boolean containsSpace = fullName.Contains(' ');
                        if( hasLength  ) {
                            If(  containsSpace ) {
                                firstName = fullName.Substring(0,fullName.indexOf(' '));
                                lastName = fullName.Substring(fullName.indexOf(' '),fullName.length());
                                lastName = lastName.trim();
                                if (lastName.length() == 0){
                                    lastName = '';
                                }//endif
                            } else{
                                firstName = fullName;
                            }//endif  
                        }//endif


                        system.debug('first='+firstName);
                        system.debug('last='+lastName);
                        //and use them...
                        appName.firstName = firstName;
                        appName.lastName = lastName;

                    } else {
                        requiredFieldsError('LoanApplicant','Name',String.valueof(mapApplicants.get(applicantId).get('Name')),String.valueof(mapApplicants.get(applicantId).get('Id')));
                    }

                    appName.middleInitial = null;
                    appName.salutationDd = string.valueof(mapApplicants.get(applicantId).getSObject('Contact')) != null ?string.valueof(mapApplicants.get(applicantId).getSObject('Contact').get('Salutation')) : null;
                    appName.suffixDd = null;
                    
                    if (mapApplicants.get(applicantId).get(appNameSpace+'Applicant_Group_Type__c') == null || String.isBlank(String.valueof(mapApplicants.get(applicantId).get(appNameSpace+'Applicant_Group_Type__c')))) {
                        requiredFieldsError('LoanApplicant',appNameSpace+'Applicant_Group_Type__c',String.valueof(mapApplicants.get(applicantId).get('Name')),String.valueof(mapApplicants.get(applicantId).get('Id')));
                    }

                    // Applicant Identification Mapping
                    list<FilogixPOSTJSONWrapper.Identification> listOfIdentity = new List<FilogixPOSTJSONWrapper.Identification>();
                    if (mapofApplicantIdAndIdentification.containsKey(applicantId)) {
                        map<string, sObject> mapOfIdentity = mapofApplicantIdAndIdentification.get(applicantId);
                        
                        //Exception when identifications records are more then 3  per applicant
                        if(mapOfIdentity.size() > 2){
                     
                            requiredFieldError +='Identification records for applicant <a href="/'+applicantId+'">'+String.valueof(mapApplicants.get(applicantId).get('Name'))+'</a> should not be more than <b> Two </b>.';
                            
                        }
                        
                        for (string Identity : mapOfIdentity.keySet()) {

                            // Adding the Address
                            FilogixPOSTJSONWrapper.Identification AppIdentity = new FilogixPOSTJSONWrapper.Identification();
                            AppIdentity.identificationNumber = String.valueof(mapOfIdentity.get(Identity).get(appNameSpace+'IdentificationNumber__c'));
                            AppIdentity.identificationCountry = String.valueof(mapOfIdentity.get(Identity).get(appNameSpace+'Country__c'));//!String.isEmpty(String.valueof(mapOfAddr.get(addrId).get('ResidenceStreet')))?String.valueof(mapOfAddr.get(addrId).get('ResidenceStreet')).SubStringBefore(' '):'';
                            AppIdentity.identificationTypeDd = String.valueof(mapOfIdentity.get(Identity).get(appNameSpace+'Type__c'));
                            
                            listOfIdentity.add(AppIdentity);
                            
                            if (string.Valueof(mapOfIdentity.get(Identity).get(appNameSpace+'IdentificationNumber__c')) == null ||String.isBlank(String.valueof(mapOfIdentity.get(Identity).get(appNameSpace+'IdentificationNumber__c')))) {
                                requiredFieldsError('Identification__c','IdentificationNumber__c',String.valueof(mapOfIdentity.get(Identity).get('Name')),String.valueof(mapOfIdentity.get(Identity).get('Id')));
                            }
                            
                            if (string.Valueof(mapOfIdentity.get(Identity).get(appNameSpace+'Country__c')) == null ||String.isBlank(String.valueof(mapOfIdentity.get(Identity).get(appNameSpace+'Country__c')))) {
                                requiredFieldsError('Identification__c','Country__c',String.valueof(mapOfIdentity.get(Identity).get('Name')),String.valueof(mapOfIdentity.get(Identity).get('Id')));
                            }
                            
                            if (string.Valueof(mapOfIdentity.get(Identity).get(appNameSpace+'Type__c')) == null ||String.isBlank(String.valueof(mapOfIdentity.get(Identity).get(appNameSpace+'Type__c')))) {
                                requiredFieldsError('Identification__c','Type__c',String.valueof(mapOfIdentity.get(Identity).get('Name')),String.valueof(mapOfIdentity.get(Identity).get('Id')));
                            }
                            
                        }
                    }
                    
                    
                    
                    // Applicant Address Mapping
                    list<FilogixPOSTJSONWrapper.AddressDetail> listOfAddresses = new List<FilogixPOSTJSONWrapper.AddressDetail>();
                    if (mapofApplicantIdAndAddr.containsKey(applicantId)) {
                        
                        map<string, sObject> mapOfAddr = mapofApplicantIdAndAddr.get(applicantId);

                        for (string addrId : mapOfAddr.keySet()) {
                            //Checking for Mailing Address
                            if(Boolean.valueof(mapOfAddr.get(addrId).get('Mailing_Address__c'))==true){
                                // Mapping Mailing Address for this Applicant Group
                                FilogixPOSTJSONWrapper.MailingAddr mailAddr = new FilogixPOSTJSONWrapper.MailingAddr();
                                mailAddr.unitNumber = String.valueof(mapOfAddr.get(addrId).get(appNameSpace+'Unit_Number__c'));
                                mailAddr.streetNumber = String.valueof(mapOfAddr.get(addrId).get(appNameSpace+'Street_Number__c'));//!String.isEmpty(String.valueof(mapOfAddr.get(addrId).get('ResidenceStreet')))?String.valueof(mapOfAddr.get(addrId).get('ResidenceStreet')).SubStringBefore(' '):'';
                                mailAddr.streetName = !String.isEmpty(String.valueof(mapOfAddr.get(addrId).get(appNameSpace+'Street_Name__c')))?String.valueof(mapOfAddr.get(addrId).get(appNameSpace+'Street_Name__c')):'';
                                mailAddr.streetTypeDd = String.valueof(mapOfAddr.get(addrId).get(appNameSpace+'Street_Type__c'));
                                mailAddr.streetDirectionDd = String.valueof(mapOfAddr.get(addrId).get(appNameSpace+'Street_Direction__c'));
                                // Filogix supports upto 20 characters for City
                                mailAddr.city = cityNamegen(String.valueof(mapOfAddr.get(addrId).get(appNameSpace+'City__c')));
                                mailAddr.provinceDd = getFullProvinceName(String.valueof(mapOfAddr.get(addrId).get(appNameSpace+'Province__c')));
                                
                                // To support USA postalcodes
                                if (mapOfAddr.get(addrId).get(appNameSpace+'PostalCode__c') !=null && String.valueof(mapOfAddr.get(addrId).get(appNameSpace+'PostalCode__c')).length() < 6) {
                                    mailAddr.internationalPostalCode = string.Valueof(mapOfAddr.get(addrId).get(appNameSpace+'PostalCode__c'));
                                } else if (mapOfAddr.get(addrId).get(appNameSpace+'PostalCode__c') !=null && String.valueof(mapOfAddr.get(addrId).get(appNameSpace+'PostalCode__c')).length() >= 6){
                                    mailAddr.postalFsa = postalFSAGen(string.Valueof(mapOfAddr.get(addrId).get(appNameSpace+'PostalCode__c')));
                                    mailAddr.postalLdu = postalLDUGen(string.Valueof(mapOfAddr.get(addrId).get(appNameSpace+'PostalCode__c')));
                                }
                                mailAddr.countryTypeDd = getFullCountryName(String.valueof(mapOfAddr.get(addrId).get(appNameSpace+'Country__c')));

                                AppGrp.mailingAddr = mailAddr;
                            }

                            // Adding the Address
                            FilogixPOSTJSONWrapper.Address addr = new FilogixPOSTJSONWrapper.Address();
                            addr.unitNumber = String.valueof(mapOfAddr.get(addrId).get('Unit_Number__c'));

                            addr.streetNumber = String.valueof(mapOfAddr.get(addrId).get('Street_Number__c'));//!String.isEmpty(String.valueof(mapOfAddr.get(addrId).get('ResidenceStreet')))?String.valueof(mapOfAddr.get(addrId).get('ResidenceStreet')).SubStringBefore(' '):'';
                            addr.streetName = !String.isEmpty(String.valueof(mapOfAddr.get(addrId).get('Street_Name__c')))?String.valueof(mapOfAddr.get(addrId).get('Street_Name__c')):'';//.SubStringAfter(' '):'';
            
                            addr.streetTypeDd = String.valueof(mapOfAddr.get(addrId).get('Street_Type__c'));
                            addr.streetDirectionDd = String.valueof(mapOfAddr.get(addrId).get('Street_Direction__c'));
                            // Filogix supports upto 20 characters for City
                            addr.city = cityNamegen(String.valueof(mapOfAddr.get(addrId).get(appNameSpace+'City__c')));
                            addr.provinceDd = getFullProvinceName(String.valueof(mapOfAddr.get(addrId).get(appNameSpace+'Province__c')));
                            addr.postalFsa = postalFSAGen(String.valueof(mapOfAddr.get(addrId).get(appNameSpace+'PostalCode__c')));
                            addr.postalLdu = postalLDUGen(String.valueof(mapOfAddr.get(addrId).get(appNameSpace+'PostalCode__c')));
                            addr.countryTypeDd = getFullCountryName(String.valueof(mapOfAddr.get(addrId).get(appNameSpace+'Country__c')));
                            
                            FilogixPOSTJSONWrapper.AddressDetail addrDet = new FilogixPOSTJSONWrapper.AddressDetail();
                            addrDet.address = addr;
                            addrDet.addressTypeDd = String.valueof(mapOfAddr.get(addrId).get('ResidencyType'));
                            Double monthsCal = Double.valueof(mapOfAddr.get(addrId).get('ResidenceYearCount'))!=null?12*Double.valueof(mapOfAddr.get(addrId).get('ResidenceYearCount')):0;
                            Double monthsVal = Double.valueof(mapOfAddr.get(addrId).get('ResidenceAdditionalMonthCount'))!=null?Double.valueof(mapOfAddr.get(addrId).get('ResidenceAdditionalMonthCount')):0;
                            addrDet.monthsAtAddress = monthsCal+monthsVal;
                            //addrDet.monthsAtAddress = Double.valueof(mapOfAddr.get(addrId).get('ResidenceYearCount'));
                            addrDet.residentialStatusDd = String.valueof(mapOfAddr.get(addrId).get('AddressOwnership'));
                            addrDet.rentPaymentAmount = (decimal)mapOfAddr.get(addrId).get('MonthlyRentPayment');
                            
                            listOfAddresses.add(addrDet);
                            //Required fields check
                            if (string.Valueof(mapOfAddr.get(addrId).get(appNameSpace+'Province__c')) == null ||String.isBlank(String.valueof(mapOfAddr.get(addrId).get(appNameSpace+'Province__c')))) {
                                requiredFieldsError('LoanApplicantAddress',appNameSpace+'Province__c',String.valueof(mapOfAddr.get(addrId).get('Name')),String.valueof(mapOfAddr.get(addrId).get('Id')));
                            }

                            if (mapOfAddr.get(addrId).get(appNameSpace+'PostalCode__c') == null || String.isBlank(String.valueof(mapOfAddr.get(addrId).get(appNameSpace+'PostalCode__c')))) {
                                requiredFieldsError('LoanApplicantAddress',appNameSpace+'PostalCode__c',String.valueof(mapOfAddr.get(addrId).get('Name')),String.valueof(mapOfAddr.get(addrId).get('Id')));
                            }

                            if (mapOfAddr.get(addrId).get(appNameSpace+'Country__c') == null || String.isBlank(String.valueof(mapOfAddr.get(addrId).get(appNameSpace+'Country__c')))) {
                                requiredFieldsError('LoanApplicantAddress',appNameSpace+'Country__c',String.valueof(mapOfAddr.get(addrId).get('Name')),String.valueof(mapOfAddr.get(addrId).get('Id')));
                            }
                            
                            if (string.Valueof(mapOfAddr.get(addrId).get('ResidencyType')) == null ||String.isBlank(String.valueof(mapOfAddr.get(addrId).get('ResidencyType')))) {
                                requiredFieldsError('LoanApplicantAddress','ResidencyType',String.valueof(mapOfAddr.get(addrId).get('Name')),String.valueof(mapOfAddr.get(addrId).get('Id')));
                            }
                            
                      /*      if (monthsCal == null && monthsVal == null) {
                                //requiredFieldsError('LoanApplicantAddress','ResidenceYearCount',String.valueof(mapOfAddr.get(addrId).get('Name')),String.valueof(mapOfAddr.get(addrId).get('Id')));
                                requiredFieldError +='Please make sure the field "Years in Residence"  <b> or "Additional Months in Residence"</b> is populated on your applicant(s) address record.</br>';
                            }*/
                            
                            if (string.Valueof(mapOfAddr.get(addrId).get('ResidenceYearCount')) == null ||String.isBlank(String.valueof(mapOfAddr.get(addrId).get('ResidenceYearCount'))) &&
                                string.Valueof(mapOfAddr.get(addrId).get('ResidenceAdditionalMonthCount')) == null ||String.isBlank(String.valueof(mapOfAddr.get(addrId).get('ResidenceYearCount')))) {
                                //requiredFieldsError('LoanApplicantAddress','ResidenceYearCount',String.valueof(mapOfAddr.get(addrId).get('Name')),String.valueof(mapOfAddr.get(addrId).get('Id')));
                                //requiredFieldError +='Please make sure the field <b> "Years in Residence" </b> or <b> "Additional Months in Residence"</b> is populated on your applicant(s) address record.</br>';
                            }
                            
                        }
                    } else {
                        requiredFieldError += 'Please create at least 1 Loan Applicant Address record against <a href="/'+applicantId+'">'+String.valueof(mapApplicants.get(applicantId).get('Name'))+'</a> Applicant. </br>';
                    }
                    list<FilogixPOSTJSONWrapper.Asset> listOfAssets = new List<FilogixPOSTJSONWrapper.Asset>();
                    if (mapofApplicantIdAndAsset.containsKey(applicantId)) {
                        map<string, sObject> mapOfAssets = mapofApplicantIdAndAsset.get(applicantId);
                        for (string asstId : mapOfAssets.keyset()) {
                            // As of v.1.6.1 Filogix POST Schema - These values are not supported but available in GET
                            // Making sure to not process the assets having this value to prevent error on user-end.
                            if(String.valueof(mapOfAssets.get(asstId).getSObject('LoanApplicationAsset').get('AssetType')) !=null && 
                              String.valueof(mapOfAssets.get(asstId).getSObject('LoanApplicationAsset').get('AssetType'))!='Property' && 
                              String.valueof(mapOfAssets.get(asstId).getSObject('LoanApplicationAsset').get('AssetType'))!= 'Rental Property'){
                                FilogixPOSTJSONWrapper.Asset asst = new FilogixPOSTJSONWrapper.Asset();
                                asst.assetDescription = String.valueof(mapOfAssets.get(asstId).getSObject('LoanApplicationAsset').get('Description__c'));//String.valueof(mapOfAssets.get(asstId).get('Name'));
                                asst.assetTypeDd = String.valueof(mapOfAssets.get(asstId).getSObject('LoanApplicationAsset').get('AssetType'));
                                asst.assetValue =  mapOfAssets.get(asstId).getSObject('LoanApplicationAsset').get('CashOrMarketValue') != null? Double.valueof(mapOfAssets.get(asstId).getSObject('LoanApplicationAsset').get('CashOrMarketValue')): null;
                                asst.downpaymentAmount = mapOfAssets.get(asstId).getSObject('LoanApplicationAsset').get(appNameSpace+'Down_Payment_Amount__c') != null? Double.valueof(mapOfAssets.get(asstId).getSObject('LoanApplicationAsset').get(appNameSpace+'Down_Payment_Amount__c')): null;
                                
                                //Required fields check
                                if (string.Valueof(mapOfAssets.get(asstId).getSObject('LoanApplicationAsset').get('Description__c')) == null ||String.isBlank(String.valueof(mapOfAssets.get(asstId).getSObject('LoanApplicationAsset').get('Description__c')))) {
                                    requiredFieldsError('LoanApplicationAsset','Description__c',String.valueof(mapOfAssets.get(asstId).getSObject('LoanApplicationAsset').get('Name')),String.valueof(mapOfAssets.get(asstId).getSObject('LoanApplicationAsset').get('Id')));
                                }
                                //Required fields check
                                if (string.Valueof(mapOfAssets.get(asstId).getSObject('LoanApplicationAsset').get('AssetType')) == null ||String.isBlank(String.valueof(mapOfAssets.get(asstId).getSObject('LoanApplicationAsset').get('AssetType')))) {
                                    requiredFieldsError('LoanApplicationAsset','AssetType',String.valueof(mapOfAssets.get(asstId).getSObject('LoanApplicationAsset').get('Name')),String.valueof(mapOfAssets.get(asstId).getSObject('LoanApplicationAsset').get('Id')));
                                }
                                //Required fields check
                                if (string.Valueof(mapOfAssets.get(asstId).getSObject('LoanApplicationAsset').get('CashOrMarketValue')) == null ||String.isBlank(String.valueof(mapOfAssets.get(asstId).getSObject('LoanApplicationAsset').get('CashOrMarketValue')))) {
                                    requiredFieldsError('LoanApplicationAsset','CashOrMarketValue',String.valueof(mapOfAssets.get(asstId).getSObject('LoanApplicationAsset').get('Name')),String.valueof(mapOfAssets.get(asstId).getSObject('LoanApplicationAsset').get('Id')));
                                }
    
                                listOfAssets.add(asst);
                            }
                        }
                        
                        
                    }
                    
                    
                    list<FilogixPOSTJSONWrapper.Liability> listOfLiabilities = new List<FilogixPOSTJSONWrapper.Liability>();
                    if (mapofApplicantIdAndLiability.containsKey(applicantId)) {
                        map<string, sObject> mapOfLia = mapofApplicantIdAndLiability.get(applicantId);
                        for (string liaId : mapOfLia.keySet()) {
                            FilogixPOSTJSONWrapper.Liability lia = new FilogixPOSTJSONWrapper.Liability();
                            lia.cbScraped = BooleantoString(String.valueof(mapOfLia.get(liaId).getSObject('LoanApplicationLiability').get('Credit_Bureau__c')));
                            lia.creditLimit = mapOfLia.get(liaId).getSObject('LoanApplicationLiability').get('CreditLimitAmount') != null? Double.valueof(mapOfLia.get(liaId).getSObject('LoanApplicationLiability').get('CreditLimitAmount')): null;
                            lia.liabilityAmount = mapOfLia.get(liaId).getSObject('LoanApplicationLiability').get(appNameSpace+'Liability_Amount__c') != null? Double.valueof(mapOfLia.get(liaId).getSObject('LoanApplicationLiability').get(appNameSpace+'Liability_Amount__c')): null;
                            lia.liabilityDescription = String.valueof(mapOfLia.get(liaId).getSObject('LoanApplicationLiability').get('Name'));
                            lia.liabilityMonthlyPayment = mapOfLia.get(liaId).getSObject('LoanApplicationLiability').get('MonthlyPaymentAmount') != null? Double.valueof(mapOfLia.get(liaId).getSObject('LoanApplicationLiability').get('MonthlyPaymentAmount')): null;
                            lia.liabilityTypeDd = String.valueof(mapOfLia.get(liaId).getSObject('LoanApplicationLiability').get('OtherLiabilityType'));
                            lia.maturityDate = mapOfLia.get(liaId).getSObject('LoanApplicationLiability').get(appNameSpace+'Maturity_Date__c') !=null? formatDateTime( (DateTime) mapOfLia.get(liaId).getSObject('LoanApplicationLiability').get(appNameSpace+'Maturity_Date__c')): null;
                            lia.monthlyPaymentOverride = BooleantoString(string.valueOf(mapOfLia.get(liaId).getSObject('LoanApplicationLiability').get(appNameSpace+'Monthly_Payment_Override__c')));
                            lia.liabilityPayOffTypeDd = string.valueOf(mapOfLia.get(liaId).getSObject('LoanApplicationLiability').get(appNameSpace+'Pay_Off__c'));
                            listOfLiabilities.add(lia);

                            //Required fields check
                            if (string.Valueof(mapOfLia.get(liaId).getSObject('LoanApplicationLiability').get('OtherLiabilityType')) == null ||String.isBlank(String.valueof(mapOfLia.get(liaId).getSObject('LoanApplicationLiability').get('OtherLiabilityType')))) {
                                requiredFieldsError('LoanApplicationLiability','OtherLiabilityType',String.valueof(mapOfLia.get(liaId).getSObject('LoanApplicationLiability').get('Name')),String.valueof(mapOfLia.get(liaId).getSObject('LoanApplicationLiability').get('Id')));
                            }
                            if (string.Valueof(mapOfLia.get(liaId).getSObject('LoanApplicationLiability').get('Liability_Amount__c')) == null ||String.isBlank(String.valueof(mapOfLia.get(liaId).getSObject('LoanApplicationLiability').get('Liability_Amount__c')))) {
                                requiredFieldsError('LoanApplicationLiability','Liability_Amount__c',String.valueof(mapOfLia.get(liaId).getSObject('LoanApplicationLiability').get('Name')),String.valueof(mapOfLia.get(liaId).getSObject('LoanApplicationLiability').get('Id')));
                            }
                        }
                    }
                    list<FilogixPOSTJSONWrapper.OtherIncome> listOfOtherIncomes = new List<FilogixPOSTJSONWrapper.OtherIncome>();
                    if (mapofApplicantIdAndIncome.containsKey(applicantId)) {
                        map<string, sObject> mapOfOthInc = mapofApplicantIdAndIncome.get(applicantId);
                        for (string incId : mapOfOthInc.keySet()) {
                            FilogixPOSTJSONWrapper.OtherIncome othInc = new FilogixPOSTJSONWrapper.OtherIncome();
                            othInc.incomeAmount = mapOfOthInc.get(incId).get('Income_Amount__c') != null? Double.valueof(mapOfOthInc.get(incId).get('Income_Amount__c')): null;
                            othInc.incomeDescription = String.valueof(mapOfOthInc.get(incId).get('Name'));
                            othInc.incomePeriodDd = String.valueof(mapOfOthInc.get(incId).get('Income_Period__c'));
                            othInc.incomeTypeDd = String.valueof(mapOfOthInc.get(incId).get('IncomeSourceType'));
                            
                            listOfOtherIncomes.add(othInc);
                            
                            if (mapOfOthInc.get(incId).get('Income_Amount__c') == null) {
                                //requiredFieldError += '<b>Object</b> : Loan Applicant Income, <b>Field</b> : Monthly Income \n';
                                requiredFieldsError('LoanApplicantIncome','Income_Amount__c',String.valueof(mapOfOthInc.get(incId).get('Name')),String.valueof(mapOfOthInc.get(incId).get('Id')));
                            }
                            
                            if (
                                mapOfOthInc.get(incId).get('Income_Period__c') == null || String.isBlank(String.valueof(mapOfOthInc.get(incId).get('Income_Period__c')))
                            ) {
                                //requiredFieldError += '<b>Object</b> : Loan Applicant Income, <b>Field</b> : Income Period \n';
                                requiredFieldsError('LoanApplicantIncome','Income_Period__c',String.valueof(mapOfOthInc.get(incId).get('Name')),String.valueof(mapOfOthInc.get(incId).get('Id')));
                            }
                            if (
                                mapOfOthInc.get(incId).get('IncomeSourceType') == null ||
                                String.isBlank(String.valueof(mapOfOthInc.get(incId).get('IncomeSourceType')))
                            ) {
                                //requiredFieldError += '<b>Object</b> : Loan Applicant Income, <b>Field</b> : Income Source Type \n';
                                requiredFieldsError('LoanApplicantIncome','IncomeSourceType',String.valueof(mapOfOthInc.get(incId).get('Name')),String.valueof(mapOfOthInc.get(incId).get('Id')));
                            }
                        }
                    }
                    list<FilogixPOSTJSONWrapper.EmploymentHistory> listEmp = new List<FilogixPOSTJSONWrapper.EmploymentHistory>();
                    if (mapofApplicantIdAndEmployment.containsKey(applicantId)) {
                        map<string, sObject> mapOfEmp = mapofApplicantIdAndEmployment.get(applicantId);
                        for (string empId : mapOfEmp.keySet()) {
                            FilogixPOSTJSONWrapper.Address_Z addrZ = new FilogixPOSTJSONWrapper.Address_Z();
                            addrZ.addressLine1 = String.valueof(mapOfEmp.get(empId).get('EmployerStreet'));
                            addrZ.addressLine2 = String.valueof(mapOfEmp.get(empId).get('Address_Line_2__c'));
                            // Filogix supports upto 20 characters for City
                            addrZ.city = cityNamegen(String.valueof(mapOfEmp.get(empId).get('EmployerCity')));
                            if (
                                mapOfEmp.get(empId).get('EmployerPostalCode') != null && String.valueof(mapOfEmp.get(empId). get('EmployerPostalCode')).length() < 6
                            ) {
                                addrZ.internationalPostalCode = String.valueof(mapOfEmp.get(empId).get('EmployerPostalCode'));
                            } else if (
                                mapOfEmp.get(empId).get('EmployerPostalCode') != null && String.valueof(mapOfEmp.get(empId).get('EmployerPostalCode')).length() >= 6
                            ) {
                                addrZ.postalFsa = postalFSAGen(String.valueof(mapOfEmp.get(empId).get('EmployerPostalCode')));
                                addrZ.postalLdu = postalLDUGen(String.valueof(mapOfEmp.get(empId).get('EmployerPostalCode')));
                            }
                            
                            addrZ.countryTypeDd = getFullCountryName(String.valueof(mapOfEmp.get(empId).get('EmployerCountry')));
                            addrZ.provinceDd = getFullProvinceName(String.valueof(mapOfEmp.get(empId).get('EmployerState')));
                            //Required fields check
                            if (
                                mapOfEmp.get(empId).get('EmployerCountry') == null || String.isBlank(String.valueof(mapOfEmp.get(empId).get('EmployerCountry')))
                            ) {
                                requiredFieldsError('LoanApplicantEmployment','EmployerCountry',String.valueof(mapOfEmp.get(empId).get('Name')),String.valueof(mapOfEmp.get(empId).get('Id')));
                                //requiredFieldError += '<b>Object</b> : Loan Applicant Employment, <b>Field</b> : Employer Country \n';
                            }
                            
                            if (
                                mapOfEmp.get(empId).get('EmployerState') == null || String.isBlank(String.valueof(mapOfEmp.get(empId).get('EmployerState')))
                            ) {
                                requiredFieldsError('LoanApplicantEmployment','EmployerState',String.valueof(mapOfEmp.get(empId).get('Name')),String.valueof(mapOfEmp.get(empId).get('Id')));
                                //requiredFieldError += '<b>Object</b> : Loan Applicant Employment, <b>Field</b> : Employer State \n';
                            }
                            
                            FilogixPOSTJSONWrapper.Contact con = new FilogixPOSTJSONWrapper.Contact();
                            con.contactPhoneNumber = removeSpeacialChar(String.valueof(mapOfEmp.get(empId).get('EmployerPhone')));
                            con.address = addrZ;
                            
                            FilogixPOSTJSONWrapper.Income inc = new FilogixPOSTJSONWrapper.Income();
                            inc.incomeAmount = mapOfEmp.get(empId).get('Amount__c') != null ? Double.valueof(mapOfEmp.get(empId).get('Amount__c')): null;
                            inc.incomePeriodDd = mapOfEmp.get(empId).get('Income_Frequency__c') != null ? string.valueOf(mapOfEmp.get(empId).get('Income_Frequency__c')): null;
                            inc.incomeTypeDd = String.valueof(mapOfEmp.get(empId).get('Type__c'));
                            
                            //Required fields check
                            if (mapOfEmp.get(empId).get('Amount__c') == null || mapOfEmp.get(empId).get('Amount__c') == '') {
                                requiredFieldsError('LoanApplicantEmployment','Amount__c',String.valueof(mapOfEmp.get(empId).get('Name')),String.valueof(mapOfEmp.get(empId).get('Id')));
                            }
                            String phoneval = removeSpeacialChar(String.valueof(mapOfEmp.get(empId).get('EmployerPhone')));
                            if (!String.isblank(phoneval) && phoneval.length() > 10) {
                                throw FilogixWrapperBinding.createCustomException('Phone number should not contain country code. Example: 1112223333 - Current value= '+phoneval);
                            }

                            if (
                                mapOfEmp.get(empId).get('Income_Frequency__c') == null || string.isBlank(String.valueof(mapOfEmp.get(empId).get('Income_Frequency__c')))
                            ) {
                                requiredFieldsError('LoanApplicantEmployment','Income_Frequency__c',String.valueof(mapOfEmp.get(empId).get('Name')),String.valueof(mapOfEmp.get(empId).get('Id')));
                                //requiredFieldError += '<b>Object</b> : Loan Applicant Employment, <b>Field</b> : Income Frequency \n';
                            }
                            
                            if (mapOfEmp.get(empId).get('Type__c') == null || string.isBlank(String.valueof(mapOfEmp.get(empId).get('Type__c')))) {
                                requiredFieldsError('LoanApplicantEmployment','Type__c',String.valueof(mapOfEmp.get(empId).get('Name')),String.valueof(mapOfEmp.get(empId).get('Id')));
                            }

                            if (mapOfEmp.get(empId).get('History_Status__c') == null || string.isBlank(String.valueof(mapOfEmp.get(empId).get('History_Status__c')))) {
                                requiredFieldsError('LoanApplicantEmployment','TypHistory_Status__ce__c',String.valueof(mapOfEmp.get(empId).get('Name')),String.valueof(mapOfEmp.get(empId).get('Id')));
                            }
                            
                            FilogixPOSTJSONWrapper.EmploymentHistory emp = new FilogixPOSTJSONWrapper.EmploymentHistory();
                            emp.companyType = String.valueof(mapOfEmp.get(empId).get('Company_Type__c'));
                            emp.contact = con;
                            emp.employerName = String.valueof(mapOfEmp.get(empId).get('EmployerName'));
                            emp.employmentHistoryStatusDd = String.valueof(mapOfEmp.get(empId).get('History_Status__c'));
                            emp.employmentHistoryTypeDd = String.valueof(mapOfEmp.get(empId).get('History_Type__c'));
                            emp.grossRevenue = mapOfEmp.get(empId).get('Gross_Revenue__c') != null ? Double.valueof(mapOfEmp.get(empId).get('Gross_Revenue__c')): null;
                            emp.income = inc;
                            emp.industrySectorDd = String.valueof(mapOfEmp.get(empId).get('Industry_Sector__c'));
                            emp.jobTitle = String.valueof(mapOfEmp.get(empId).get('JobTitle'));
                            Double monthsCal = Double.valueof(mapOfEmp.get(empId).get('CurrentJobYearCount'))!=null?12*Double.valueof(mapOfEmp.get(empId).get('CurrentJobYearCount')):0;
                            Double monthsVal = Double.valueof(mapOfEmp.get(empId).get('CurrentJobAdditionalMonthCount'))!=null?Double.valueof(mapOfEmp.get(empId).get('CurrentJobAdditionalMonthCount')):0;
                            emp.monthsOfService = monthsCal+monthsVal;
                            emp.occupationDd = String.valueof(mapOfEmp.get(empId).get('Occupation__c'));
                            emp.operatingAs = String.valueof(mapOfEmp.get(empId).get('Operating_As__c'));
                            emp.selfEmploymentFlag = BooleanToString(string.valueOf(mapOfEmp.get(empId).get('IsSelfEmployed')));
                            emp.timeInIndustry = Double.valueof(mapOfEmp.get(empId).get('Time_In_Industry__c'));
                            
                            if (String.valueof(mapOfEmp.get(empId).get('EmployerName')) == null ||String.isBlank(String.valueof(mapOfEmp.get(empId).get('EmployerName')))) {
                                requiredFieldsError('LoanApplicantEmployment','EmployerName',String.valueof(mapOfEmp.get(empId).get('Name')),String.valueof(mapOfEmp.get(empId).get('Id')));
                            }

                            if (String.valueof(mapOfEmp.get(empId).get('History_Status__c')) == null ||String.isBlank(String.valueof(mapOfEmp.get(empId).get('History_Status__c')))) {
                                requiredFieldsError('LoanApplicantEmployment','History_Status__c',String.valueof(mapOfEmp.get(empId).get('Name')),String.valueof(mapOfEmp.get(empId).get('Id')));
                            }

                            if (String.valueof(mapOfEmp.get(empId).get('History_Type__c')) == null ||String.isBlank(String.valueof(mapOfEmp.get(empId).get('History_Type__c')))) {
                                requiredFieldsError('LoanApplicantEmployment','History_Type__c',String.valueof(mapOfEmp.get(empId).get('Name')),String.valueof(mapOfEmp.get(empId).get('Id')));
                            }

                            listEmp.add(emp);

                            
                        }
                    }

                    
                    //Other Properties
                    list<FilogixPOSTJSONWrapper.OtherProperty> listOthProp = new List<FilogixPOSTJSONWrapper.OtherProperty>();
                    if (mapofLoanAppIdAndProperties.containsKey(applicantId)) {
                        map<string, sObject> mapOfProps = mapofLoanAppIdAndProperties.get(applicantId);
                        for (string propId : mapOfProps.keySet()) {
                            // Proceed only when the Property is not a Subject Property
                            if(Boolean.valueOf(mapOfProps.get(propId).get('Is_Subject_Property__c')) == false){
                                list<FilogixPOSTJSONWrapper.PropertyExpense> listPrpExp = new List<FilogixPOSTJSONWrapper.PropertyExpense>();
                                
                                // Property Expenses
                                Double Municipal = mapOfProps.get(propId).get('Annual_Taxes__c')!=null?Double.valueOf(mapOfProps.get(propId).get('Annual_Taxes__c')): 0;
                                Double Insurance = mapOfProps.get(propId).get('Insurance_Expenses__c')!=null?Double.valueOf(mapOfProps.get(propId).get('Insurance_Expenses__c')): 0;
                                Double Heat = mapOfProps.get(propId).get('Heating_Expenses__c')!=null?Double.valueOf(mapOfProps.get(propId).get('Heating_Expenses__c')): 0;
                                Double Hydro = mapOfProps.get(propId).get('Hydro_Expenses__c')!=null?Double.valueOf(mapOfProps.get(propId).get('Hydro_Expenses__c')): 0;
                                Double Interest = mapOfProps.get(propId).get('Interest_Expenses__c')!=null?Double.valueOf(mapOfProps.get(propId).get('Interest_Expenses__c')): 0;
                                Double General = mapOfProps.get(propId).get('Management_Expenses__c')!=null?Double.valueOf(mapOfProps.get(propId).get('Management_Expenses__c')): 0;
                                Double Other = mapOfProps.get(propId).get('Other_Expenses__c')!=null?Double.valueOf(mapOfProps.get(propId).get('Other_Expenses__c')): 0;
                                Double Repair = mapOfProps.get(propId).get('Repairs_Expenses__c')!=null?Double.valueOf(mapOfProps.get(propId).get('Repairs_Expenses__c')): 0;
                                Double Condo = mapOfProps.get(propId).get('Total_Condo_Fees__c')!=null?Double.valueOf(mapOfProps.get(propId).get('Total_Condo_Fees__c')): 0;


                                if(Municipal!=0){
                                    FilogixPOSTJSONWrapper.PropertyExpense MunicipalExpense = new FilogixPOSTJSONWrapper.PropertyExpense();
                                    MunicipalExpense.propertyExpenseAmount = Municipal;//Double.valueOf(mapOfProps.get(propId).get('Annual_Taxes__c')): 0;
                                    MunicipalExpense.propertyExpensePeriodDd = 'Annual';///String.valueof(mapOfPropExp.get(expId).get('propertyExpensePeriod__c'));
                                    MunicipalExpense.propertyExpenseTypeDd = 'Municipal Taxes';
                                    listPrpExp.add(MunicipalExpense);
                                }
                                if(Condo!=0){
                                    FilogixPOSTJSONWrapper.PropertyExpense CondoExpense = new FilogixPOSTJSONWrapper.PropertyExpense();
                                    CondoExpense.propertyExpenseAmount = Condo;//Double.valueOf(mapOfProps.get(propId).get('Annual_Taxes__c')): 0;
                                    CondoExpense.propertyExpensePeriodDd = 'Monthly';///String.valueof(mapOfPropExp.get(expId).get('propertyExpensePeriod__c'));
                                    CondoExpense.propertyExpenseTypeDd = 'Condo Fees';
                                    listPrpExp.add(CondoExpense);
                                }
                                if(General!=0){
                                    FilogixPOSTJSONWrapper.PropertyExpense GeneralExpense = new FilogixPOSTJSONWrapper.PropertyExpense();
                                    GeneralExpense.propertyExpenseAmount = General;//Double.valueOf(mapOfProps.get(propId).get('Annual_Taxes__c')): 0;
                                    GeneralExpense.propertyExpensePeriodDd = 'Monthly';///String.valueof(mapOfPropExp.get(expId).get('propertyExpensePeriod__c'));
                                    GeneralExpense.propertyExpenseTypeDd = 'General Expenses';
                                    listPrpExp.add(GeneralExpense);
                                }
                                if(Heat!=0){
                                    FilogixPOSTJSONWrapper.PropertyExpense HeatingExpense = new FilogixPOSTJSONWrapper.PropertyExpense();
                                    HeatingExpense.propertyExpenseAmount = Heat;//Double.valueOf(mapOfProps.get(propId).get('Annual_Taxes__c')): 0;
                                    HeatingExpense.propertyExpensePeriodDd = 'Monthly';///String.valueof(mapOfPropExp.get(expId).get('propertyExpensePeriod__c'));
                                    HeatingExpense.propertyExpenseTypeDd = 'Heating Expense';
                                    listPrpExp.add(HeatingExpense);
                                }
                                if(Hydro!=0){
                                    FilogixPOSTJSONWrapper.PropertyExpense HydroExpense = new FilogixPOSTJSONWrapper.PropertyExpense();
                                    HydroExpense.propertyExpenseAmount = Hydro;//Double.valueOf(mapOfProps.get(propId).get('Annual_Taxes__c')): 0;
                                    HydroExpense.propertyExpensePeriodDd = 'Monthly';///String.valueof(mapOfPropExp.get(expId).get('propertyExpensePeriod__c'));
                                    HydroExpense.propertyExpenseTypeDd = 'Hydro';
                                    listPrpExp.add(HydroExpense);
                                }
                                if(Insurance!=0){
                                    FilogixPOSTJSONWrapper.PropertyExpense InsuranceExpense = new FilogixPOSTJSONWrapper.PropertyExpense();
                                    InsuranceExpense.propertyExpenseAmount = Insurance;//Double.valueOf(mapOfProps.get(propId).get('Annual_Taxes__c')): 0;
                                    InsuranceExpense.propertyExpensePeriodDd = 'Monthly';///String.valueof(mapOfPropExp.get(expId).get('propertyExpensePeriod__c'));
                                    InsuranceExpense.propertyExpenseTypeDd = 'Insurance';
                                    listPrpExp.add(InsuranceExpense);
                                }
                                if(Interest!=0){
                                    FilogixPOSTJSONWrapper.PropertyExpense InterestExpense = new FilogixPOSTJSONWrapper.PropertyExpense();
                                    InterestExpense.propertyExpenseAmount = Interest;//Double.valueOf(mapOfProps.get(propId).get('Annual_Taxes__c')): 0;
                                    InterestExpense.propertyExpensePeriodDd = 'Monthly';///String.valueof(mapOfPropExp.get(expId).get('propertyExpensePeriod__c'));
                                    InterestExpense.propertyExpenseTypeDd = 'Interest Charges';
                                    listPrpExp.add(InterestExpense);
                                }
                                if(Other!=0){
                                    FilogixPOSTJSONWrapper.PropertyExpense OtherExpense = new FilogixPOSTJSONWrapper.PropertyExpense();
                                    OtherExpense.propertyExpenseAmount = Other;//Double.valueOf(mapOfProps.get(propId).get('Annual_Taxes__c')): 0;
                                    OtherExpense.propertyExpensePeriodDd = 'Monthly';///String.valueof(mapOfPropExp.get(expId).get('propertyExpensePeriod__c'));
                                    OtherExpense.propertyExpenseTypeDd = 'Management Expenses';
                                    listPrpExp.add(OtherExpense);
                                }

                                if(Repair!=0){
                                    FilogixPOSTJSONWrapper.PropertyExpense RepairExpense = new FilogixPOSTJSONWrapper.PropertyExpense();
                                    RepairExpense.propertyExpenseAmount = Repair;//Double.valueOf(mapOfProps.get(propId).get('Annual_Taxes__c')): 0;
                                    RepairExpense.propertyExpensePeriodDd = 'Monthly';///String.valueof(mapOfPropExp.get(expId).get('propertyExpensePeriod__c'));
                                    RepairExpense.propertyExpenseTypeDd = 'Repairs';
                                    listPrpExp.add(RepairExpense);
                                }

                                /* Expense END */

                                
                                FilogixPOSTJSONWrapper.Address_Y addrY = new FilogixPOSTJSONWrapper.Address_Y();
                                addrY.streetNumber = String.valueof(mapOfProps.get(propId).get('Street_Number__c')); //!String.isEmpty(String.valueof(mapOfProps.get(propId).get('Street_Number__c')))?String.valueof(mapOfProps.get(propId).get('Street_Number__c')).SubStringBefore(' '):'';
                                addrY.streetName = !String.isEmpty(String.valueof(mapOfProps.get(propId).get('Street_Name__c')))?String.valueof(mapOfProps.get(propId).get('Street_Name__c')):'';
                                addrY.streetTypeDd = String.valueof(mapOfProps.get(propId).get('Street_Type__c'));
                                addrY.streetDirectionDd = String.valueof(mapOfProps.get(propId).get('Direction__c'));
                                // Filogix supports upto 20 characters for City
                                addrY.city = cityNamegen(String.valueof(mapOfProps.get(propId).get(appNameSpace+'City__c')));
                                addrY.postalFsa = postalFSAGen(String.valueof(mapOfProps.get(propId).get(appNameSpace+'PostalCode__c')));
                                addrY.postalLdu = postalLDUGen(String.valueof(mapOfProps.get(propId).get(appNameSpace+'PostalCode__c')));
                                addrY.countryTypeDd = getFullCountryName(String.valueof(mapOfProps.get(propId).get(appNameSpace+'Country__c')));
                                addrY.provinceDd = getFullProvinceName(String.valueof(mapOfProps.get(propId).get(appNameSpace+'Province__c')));
                                
                                //Required fields check
                                if (mapOfProps.get(propId).get(appNameSpace+'Province__c') == null ||string.isBlank(String.valueof(mapOfProps.get(propId).get(appNameSpace+'Province__c')))) {
                                    requiredFieldsError('LoanApplicationProperty',appNameSpace+'Province__c',String.valueof(mapOfProps.get(propId).get('Name')),String.valueof(mapOfProps.get(propId).get('Id')));
                                }
                                if (mapOfProps.get(propId).get(appNameSpace+'Country__c') == null || string.isBlank(String.valueof(mapOfProps.get(propId).get(appNameSpace+'Country__c')))) {
                                    requiredFieldsError('LoanApplicationProperty',appNameSpace+'Country__c',String.valueof(mapOfProps.get(propId).get('Name')),String.valueof(mapOfProps.get(propId).get('Id')));
                                }
                                if (mapOfProps.get(propId).get(appNameSpace+'PostalCode__c') == null || string.isBlank(String.valueof(mapOfProps.get(propId).get(appNameSpace+'PostalCode__c')))) {
                                    requiredFieldsError('LoanApplicationProperty',appNameSpace+'PostalCode__c',String.valueof(mapOfProps.get(propId).get('Name')),String.valueof(mapOfProps.get(propId).get('Id')));
                                }
                                
                                FilogixPOSTJSONWrapper.Property prp = new FilogixPOSTJSONWrapper.Property();
                                prp.address = addrY;
                                
                           //     prp.actualAppraisalValue = mapOfProps.get(propId).get('AppraisedValue__c') != null? Double.valueof(mapOfProps.get(propId).get('AppraisedValue__c')): null;
                                prp.estimatedAppraisalValue = mapOfProps.get(propId).get('PropertyValue') != null? Double.valueof(mapOfProps.get(propId).get('PropertyValue')): null;
                                prp.feesIncludeHeat = BooleanToString(string.valueOf(mapOfProps.get(propId).get('feesIncludeHeat__c')));
                                prp.includetds = BooleanToString(string.valueOf(mapOfProps.get(propId).get('includetds__c')));
                                prp.occupancyTypeDd = string.valueOf(mapOfProps.get(propId).get('PropertyUseType'));
                                prp.originalPurchasePrice = Double.valueof(mapOfProps.get(propId).get('Original_Purchase_Price__c'));
                                prp.refiOrigPurchaseDate = formatDateTime(dateTime.valueof(mapOfProps.get(propId).get('Purchase_Date__c')));
                         //       prp.purchasePrice = mapOfProps.get(propId).get('Original_Purchase_Price__c') != null? Double.valueof(mapOfProps.get(propId).get('Original_Purchase_Price__c')): null;

                                //Filogix API does not support other values.
                                // Other Values
                                /*prp.taxationYear = mapOfProps.get(propId).get('taxationYear__c') != null? Double.valueof( mapOfProps.get(propId).get('taxationYear__c')): null;
                                prp.structureAge = mapOfProps.get(propId).get('structureAge__c') != null? Double.valueof( mapOfProps.get(propId).get('structureAge__c')): null;
                                prp.appraisalDateAct = mapOfProps.get(propId).get('Appraisal_Date__c') != null? formatDateTime((datetime)mapOfProps.get(propId).get('Appraisal_Date__c')):null;
                                prp.dwellingStyleDd = string.valueof(mapOfProps.get(propId).get('Style__c'));
                                prp.dwellingTypeDd = string.valueof(mapOfProps.get(propId).get('Structure_Type__c'));
                                prp.garageSizeDd = string.valueOf( mapOfProps.get(propId).get('Garage_Size__c'));
                                prp.garageTypeDd = string.valueOf( mapOfProps.get(propId).get('Garage_Type__c'));
                                prp.heatTypeDd = string.valueOf( mapOfProps.get(propId).get('Heat__c'));
                                prp.legalLine1 =  string.valueOf( mapOfProps.get(propId).get('lot__c'));
                                prp.legalLine2 =  string.valueOf( mapOfProps.get(propId).get('block__c'));
                                prp.legalLine3 = string.valueOf( mapOfProps.get(propId).get('Conc_Township__c'));
                                prp.livingSpace = mapOfProps.get(propId).get('livingSpace__c') != null? Double.valueof( mapOfProps.get(propId).get('livingSpace__c')): null;
                                prp.livingSpaceUnitOfMeasurDd = string.valueof(mapOfProps.get(propId).get('livingSpaceUnitOfMeasurDd__c'));
                                prp.lotSize = mapOfProps.get(propId).get('lotSize__c') != null? Double.valueof(mapOfProps.get(propId).get('lotSize__c')): null;
                                prp.lotSizeUnitOfMeasureDd = string.Valueof(mapOfProps.get(propId).get('lotSizeUnitOfMeasure__c'));
                                //prp.mlsListingFlag = BooleanToString(String.valueof(mapOfProps.get(propId).get('mlsListingFlag__c')));
                                prp.newConstructionDd = string.Valueof(mapOfProps.get(propId).get('Construction_Type__c'));
                                prp.numberOfUnits = mapOfProps.get(propId).get('numberOfUnits__c') != null? Double.valueof(mapOfProps.get(propId).get('numberOfUnits__c')): null;
                                prp.propertyTypeDd = string.Valueof(mapOfProps.get(propId).get('Property_Type__c'));
                                prp.realtorInfo = string.valueof(mapOfProps.get(propId).get('realtorInfo__c'));
                                prp.rentalOffsetOption = string.valueof(mapOfProps.get(propId).get('rentalOffsetOption__c'));
                                prp.sewageTypeDd = string.valueof(mapOfProps.get(propId).get('Sewage_Type__c'));
                                prp.waterTypeDd = string.Valueof(mapOfProps.get(propId).get('Water_Type__c'));*/
                                // Adding Expenses
                                prp.propertyExpense = listPrpExp;


                                
                                // RENTAL INCOME
                                // If Occupancy Type contains "Rental"
                                if(!string.isBlank(string.valueOf(mapOfProps.get(propId).get('PropertyUseType'))) && string.valueOf(mapOfProps.get(propId).get('PropertyUseType')).contains('Rental')){
                                    // Adding Rental Values
                                    FilogixPOSTJSONWrapper.RentalIncome renInc = new FilogixPOSTJSONWrapper.RentalIncome();
                                    renInc.incomeAmount = mapOfProps.get(propId).get('ExpMonthlyRentalIncome') != null? Double.valueof(mapOfProps.get(propId).get('ExpMonthlyRentalIncome')): 0;
                                    renInc.incomePeriodDd = String.valueof(mapOfProps.get(propId).get('Rental_Income_Period__c'));
                                    renInc.incomeTypeDd = String.valueof(mapOfProps.get(propId).get('Rental_Income_Type__c'));
                                    renInc.incPercentInTds = renInc.incPercentInGds = Double.valueof(mapOfProps.get(propId).get('Rental_IncPercentInTds__c')) != null? Double.valueof(mapOfProps.get(propId).get('Rental_IncPercentInTds__c')): 0;
                                    //renInc.incomeDescription (Missing Mappping)
                                    //Required fields check
                                    if (mapOfProps.get(propId).get('ExpMonthlyRentalIncome') == null) {
                                        requiredFieldsError('LoanApplicationProperty','ExpMonthlyRentalIncome',String.valueof(mapOfProps.get(propId).get('Name')),String.valueof(mapOfProps.get(propId).get('Id')));
                                    }
                                    
                                    if (mapOfProps.get(propId).get('Rental_Income_Period__c') == null) {
                                        requiredFieldsError('LoanApplicationProperty','Rental_Income_Period__c',String.valueof(mapOfProps.get(propId).get('Name')),String.valueof(mapOfProps.get(propId).get('Id')));
                                    }
                                    
                                    if (mapOfProps.get(propId).get('Rental_Income_Type__c') == null) {
                                        requiredFieldsError('LoanApplicationProperty','Rental_Income_Type__c',String.valueof(mapOfProps.get(propId).get('Name')),String.valueof(mapOfProps.get(propId).get('Id')));
                                    }
                                    // Adding RentalIncome to the Property
                                    prp.rentalIncome = renInc;
                                }
                                
                                list<FilogixPOSTJSONWrapper.OtherPropMortgage> listMort = new List<FilogixPOSTJSONWrapper.OtherPropMortgage>(); 
                               
                            if(mapOfMortgageAgainstProp.containsKey(propId) && mapOfMortgageAgainstProp.get(propId).size() > 3){
                                requiredFieldError +='Existing Mortgages against property <a href="/'+propId+'">'+String.valueof(mapOfProps.get(propId).get('Name'))+'</a> should not be more than <b> Three </b>.';
                            }
                            
                            if(mapOfMortgageAgainstProp.containsKey(propId) && mapOfMortgageAgainstProp.get(propId).size() > 0 && mapOfMortgageAgainstProp.get(propId).size() < 4){
                                    for(sObject mortgageRecord : mapOfMortgageAgainstProp.get(propId)){
                                        
                                        // Making sure to create Mortgage only if it's Existing
                                        // API doedsn't allow Existing Mortgage to be FALSE for OTHER PROPERTIES
                                        if(Boolean.valueof(mortgageRecord.get(appNameSpace+'Existing_Mortgage__c')) == true && Boolean.valueof(mapOfProps.get(propId).get('Is_Subject_Property__c')) == false){
                                            FilogixPOSTJSONWrapper.Rate_Z rt = new FilogixPOSTJSONWrapper.Rate_Z();
                                            rt.interestRate = mortgageRecord.get('Interest_Rate__c') != null? Double.valueof(mortgageRecord.get('Interest_Rate__c')): null;
                                   
                                            // Initializing Mortgages
                                            //===========================
                                            FilogixPOSTJSONWrapper.OtherPropMortgage mortgage = new FilogixPOSTJSONWrapper.OtherPropMortgage();
                                            //mortgage.borrowerIds = brIDs;
                                            mortgage.balanceRemaining = mortgageRecord.get('Balance_Remaining__c')!= null? Double.valueof(mortgageRecord.get('Balance_Remaining__c')): null;
                                            mortgage.existingMortgageFlag = BooleanToString(String.valueof(mortgageRecord.get(appNameSpace+'Existing_Mortgage__c')));
                                            mortgage.existingMortgageHolder = String.valueof(mortgageRecord.get(appNameSpace+'Existing_Mortgage_Holder__c'));
                                            mortgage.interestTypeDd = String.valueof(mortgageRecord.get(appNameSpace+'Interest_Type__c'));
                                            mortgage.loanTypeDd = String.valueof(mortgageRecord.get('Loan_Type__c'));
                                            mortgage.maturityDate = formatDateTime((DateTime) mortgageRecord.get('Maturity_Date__c'));
                                            mortgage.mortgageTypeDd = String.valueof(mortgageRecord.get('Mortgage_Type__c')); //mapOfLoanApplication.get(rlaId).Mortgage_Type__c;
                                            mortgage.PAndIPaymentAmount = mortgageRecord.get('PAndIPaymentAmount__c') != null? Double.valueOf(mortgageRecord.get('PAndIPaymentAmount__c')): null;
                                            mortgage.paymentFrequencyDd = string.valueof(mortgageRecord.get('Payment_Frequency__c'));
                                            mortgage.paymentTermDd = string.valueof(mortgageRecord.get('Payment_Term__c'));
                                            mortgage.payoffTypeDd = String.valueof(mortgageRecord.get('Payoff_Type__c'));
                                            mortgage.rate = rt;
                                        

                                            listMort.add(mortgage);
                                            
                                            //Required fields Check
                                      
                                            if (mortgageRecord.get('Balance_Remaining__c') == null) {
                                                requiredFieldsError('Mortgage__c','Balance_Remaining__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                                            }
                            
                                            if (mortgageRecord.get('Existing_Mortgage__c') == null) {
                                                requiredFieldsError('Mortgage__c','Existing_Mortgage__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                                            }
                                            if (mortgageRecord.get('Existing_Mortgage_Holder__c') == null) {
                                                requiredFieldsError('Mortgage__c','Existing_Mortgage_Holder__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                                            }
                            
                                            if (mortgageRecord.get('Interest_Type__c') == null) {
                                                requiredFieldsError('Mortgage__c','Interest_Type__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                                            }
                            
                                            if (mortgageRecord.get('Loan_Type__c') == null) {
                                                requiredFieldsError('Mortgage__c','Loan_Type__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                                            }

                                            if (mortgageRecord.get('Maturity_Date__c') == null) {
                                                requiredFieldsError('Mortgage__c','Maturity_Date__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                                            }
                            
                                            if (mortgageRecord.get('Mortgage_Type__c') == null) {
                                                requiredFieldsError('Mortgage__c','Mortgage_Type__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                                            }
                            
                            
                                            if (mortgageRecord.get('PAndIPaymentAmount__c') == null) {
                                                requiredFieldsError('Mortgage__c','PAndIPaymentAmount__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                                            }
                            
                                            if (mortgageRecord.get('Payment_Frequency__c') == null) {
                                                requiredFieldsError('Mortgage__c','Payment_Frequency__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                                            }
                            
                                            if (mortgageRecord.get('Payment_Term__c') == null) {
                                                requiredFieldsError('Mortgage__c','Payment_Term__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                                            }
                            
                                            /*if (mortgageRecord.get('Interest_Rate__c') == null) {
                                                requiredFieldsError('Mortgage__c','Interest_Rate__c',String.valueof(mortgageRecord.get('Name')),String.valueof(mortgageRecord.get('Id')));
                                            }*/

                                        } // End IF
                                    } // END FOR
                                }
                        
                                
                                FilogixPOSTJSONWrapper.OtherProperty othPrp = new FilogixPOSTJSONWrapper.OtherProperty();
                                othPrp.property = prp;
                                othPrp.mortgage = listMort;
                                
                                listOthProp.add(othPrp);
                            }
                        }
                    }
                    /*Info for Other Property End */
                    
                    /*Info of Applicant*/
                    //Applicant.borrowerId = Borrowerid;

                    // Field mappings from Account/Contact Object
					
                    // Person Account Mapping
                    if(mapApplicants.get(applicantId).get('ContactId')!=null ){
                        String appPhoneval = removeSpeacialChar(String.valueof(mapApplicants.get(applicantId).getSObject('Contact').get('Phone')));
                        if (!String.isblank(appPhoneval) && appPhoneval.length() > 10) {
                            throw FilogixWrapperBinding.createCustomException('Phone number should not contain country code. Example: 1112223333 - Current value= '+appPhoneval);
                        }
                        Applicant.borrowerCellNumber = removeSpeacialChar(String.valueof(mapApplicants.get(applicantId).getSObject('Contact').get('Phone')));//string.valueOf(mapApplicants.get(applicantId).getSObject('Contact')) != null ? String.valueof(mapApplicants.get(applicantId).getSObject('Contact').getSObject('Account').get('PersonMobilePhone')) : '';
                        Applicant.borrowerFaxNumber = string.valueOf(mapApplicants.get(applicantId).getSObject('Contact')) != null ? removeSpeacialChar(String.valueof(mapApplicants.get(applicantId).getSObject('Contact').get('Fax'))) : '';
                        Applicant.borrowerHomePhoneNumber = removeSpeacialChar(string.valueOf(mapApplicants.get(applicantId).getSObject('Contact'))) != null ? removeSpeacialChar(String.valueof(mapApplicants.get(applicantId).getSObject('Contact').get('HomePhone'))) : '';
                        Applicant.borrowerWorkPhoneExtension = removeSpeacialChar(string.valueOf(mapApplicants.get(applicantId).getSObject('Contact'))) != null ? removeSpeacialChar(String.valueof(mapApplicants.get(applicantId).getSObject('Contact').get(appNamespace+'Work_Phone_Extension__c'))) : '';
                        Applicant.borrowerWorkPhoneNumber = removeSpeacialChar(string.valueOf(mapApplicants.get(applicantId).getSObject('Contact'))) != null ? removeSpeacialChar(String.valueof(mapApplicants.get(applicantId).getSObject('Contact').get(appNamespace+'Work_Phone__c'))) : '';
                        if(!String.isBlank(String.valueOf(mapApplicants.get(applicantId).getSObject('Contact').get('Birthdate')))){
                            Applicant.birthDate = String.valueOf(mapApplicants.get(applicantId).getSObject('Contact').get('Birthdate')).removeEnd(' 00:00:00');
                        } else {
                            requiredFieldsError('Contact','Birthdate',String.valueof(mapApplicants.get(applicantId).getSObject('contact').get('Name')),String.valueof(mapApplicants.get(applicantId).getSObject('contact').get('Id')));
                           // requiredFieldsError('Account','PersonBirthdate',String.valueof(mapApplicants.get(applicantId).getSObject('contact').get('Name')),String.valueof(mapApplicants.get(applicantId).getSObject('contact').get('Id')));

                        }
                        Applicant.emailAddress = String.valueof(mapApplicants.get(applicantId).getsObject('contact').get('Email'));
                        Applicant.preferredContactMethodDd = string.valueOf(mapApplicants.get(applicantId).get(appNameSpace+'Preferred_Contact_Method__c'));
                        Applicant.socialInsuranceNumber = removeSpeacialChar(string.valueOf(mapApplicants.get(applicantId).getSObject('contact').get('Social_Insurance_Number__c')));
                    
                        //Business Account mapping
                    } else if (mapApplicants.get(applicantId).get(appNameSpace+'Business_Account__c')!=null){
                        String appPhoneval = removeSpeacialChar(String.valueof(mapApplicants.get(applicantId).getSObject('Business_Account__r').get('Phone')));
                        if (!String.isblank(appPhoneval) && appPhoneval.length() > 10) {
                            throw FilogixWrapperBinding.createCustomException('Phone number should not contain country code. Example: 1112223333 - Current value= '+appPhoneval);
                        }
                        Applicant.birthDate = '2000-01-01'; //Adding a dummy birthDate because the field is required and Corporate doesn't have the birthdate.
                        Applicant.borrowerCellNumber = removeSpeacialChar(String.valueof(mapApplicants.get(applicantId).getSObject('Business_Account__r').get('Phone')));//string.valueOf(mapApplicants.get(applicantId).getSObject('Contact')) != null ? String.valueof(mapApplicants.get(applicantId).getSObject('Contact').getSObject('Account').get('PersonMobilePhone')) : '';
                        //Applicant.borrowerFaxNumber = string.valueOf(mapApplicants.get(applicantId).getSObject('Business_Account__r')) != null ? removeSpeacialChar(String.valueof(mapApplicants.get(applicantId).getSObject('Business_Account__r').get('Fax'))) : '';
                        //Applicant.borrowerHomePhoneNumber = removeSpeacialChar(string.valueOf(mapApplicants.get(applicantId).getSObject('Contact'))) != null ? removeSpeacialChar(String.valueof(mapApplicants.get(applicantId).getSObject('Contact').getSObject('Account').get('PersonHomePhone'))) : '';
                        //Applicant.borrowerWorkPhoneExtension = removeSpeacialChar(string.valueOf(mapApplicants.get(applicantId).getSObject('Contact'))) != null ? removeSpeacialChar(String.valueof(mapApplicants.get(applicantId).getSObject('Contact').getSObject('Account').get(appNamespace+'Work_Phone_Extension__pc'))) : '';
                        //Applicant.borrowerWorkPhoneNumber = removeSpeacialChar(string.valueOf(mapApplicants.get(applicantId).getSObject('Contact'))) != null ? removeSpeacialChar(String.valueof(mapApplicants.get(applicantId).getSObject('Contact').getSObject('Account').get(appNamespace+'Work_Phone__pc'))) : '';
                        /*if(!String.isBlank(String.valueOf(mapApplicants.get(applicantId).getSObject('contact').get(appNamespace+'PersonBirthdate')))){
                            Applicant.birthDate = String.valueOf(mapApplicants.get(applicantId).getSObject('contact').get(appNamespace+'PersonBirthdate')).removeEnd(' 00:00:00');
                        }
                        Applicant.emailAddress = String.valueof(mapApplicants.get(applicantId).getsObject('contact').get(appNameSpace+'PersonEmail'));
                        Applicant.preferredContactMethodDd = string.valueOf(mapApplicants.get(applicantId).get(appNameSpace+'Preferred_Contact_Method__c'));
                        Applicant.socialInsuranceNumber = removeSpeacialChar(string.valueOf(mapApplicants.get(applicantId).getSObject('contact').get('Social_Insurance_Number__c')));*/
                    }

                    // Field mappings from LoanApplicant Object

                    //Applicant.borrowerSpouseId = 0;

                     //Applicant.birthDate = string.valueof(date.parse(string.valueof(mapApplicants.get(applicantId).get(appNamespace+'Birthday__c'))));
                    //https://salesforce.stackexchange.com/questions/229075/how-to-remove-time-from-date

                    Applicant.languagePreferenceDd = String.valueof(mapApplicants.get(applicantId).get('PreferredLanguage'));
                    Applicant.maritalStatusDd = String.valueof(mapApplicants.get(applicantId).get('MaritalStatus'));
                    Applicant.name = appName;
                    Applicant.numberOfDependents = Double.valueof(mapApplicants.get(applicantId).get('DependentCount'));
                    Applicant.addressDetail = listOfAddresses;
                    Applicant.clientReferenceNumber = mapApplicants.get(applicantId).id;
                    Applicant.existingClient = 'Y'; //Handle by code
                    Applicant.firstTimeBuyer = 'N'; //Handle by code
                    Applicant.identification = listOfIdentity;
                    if ( !PrimaryAppExist &&
                //        mapApplicants.get(applicantId).get('LoanApplication.AccountId') != null &&
                        mapApplicants.get(applicantId).getSObject('LoanApplication').get('AccountId') != null &&
                        mapApplicants.get(applicantId).getSObject('Contact') != null &&
                        mapApplicants.get(applicantId).getSObject('Contact').get('AccountId') != null &&
                   //   mapApplicants.get(applicantId).get('LoanApplication.AccountId') == mapApplicants.get(applicantId).getSObject('Contact').get('AccountId')
                        mapApplicants.get(applicantId).getSObject('LoanApplication').get('AccountId') == mapApplicants.get(applicantId).getSObject('Contact').get('AccountId')
  						|| Boolean.valueof(mapApplicants.get(applicantId).get('Primary_Applicant__c'))==true
                    ) {	
                        Applicant.primaryApplicantFlag = 'Y';
                        PrimaryAppExist=true;
                    } else {
                        Applicant.primaryApplicantFlag = 'N';
                    }
                    
                    Applicant.relationshipToPrimaryApplicant = String.valueof(mapApplicants.get(applicantId).get('Relationship_To_Primary_Applicant__c'));
                    Applicant.employmentHistory = listEmp;
                    Applicant.otherIncome = listOfOtherIncomes;
                    Applicant.asset = listOfAssets;
                    Applicant.liability = listOfLiabilities;
                    Applicant.otherProperty = listOthProp;
                    
                    //ListOfApplicants.add(Applicant);
                    
                    // Checking If the current applicant is a business coroporation
                    if(mapApplicants.get(applicantId).get(appNameSpace+'Business_Account__c')!=null){
                        //Adding this Business corporation in a new Group
                        List<FilogixPOSTJSONWrapper.Applicant> lstofAppl = new List<FilogixPOSTJSONWrapper.Applicant>();
                        lstofAppl.add(Applicant);
                        AppGrp.applicant = lstofAppl;
                        AppGrp.applicantGroupTypeDd = string.Valueof(mapApplicants.get(applicantId).get('Applicant_Group_Type__c'));
                        ListAppGrp.add(AppGrp);
                        AppGrp = new FilogixPOSTJSONWrapper.ApplicantGroup(); // Resetting AppGrp instance
                    } else {
                        // Populating map of applicants w.r.t their group type
                        if(mapofLoanApplicantsbyGroup.containskey(string.Valueof(mapApplicants.get(applicantId).get('Applicant_Group_Type__c')))){
                            List<FilogixPOSTJSONWrapper.Applicant> lstofApplicantsbyGroup = mapofLoanApplicantsbyGroup.get(string.Valueof(mapApplicants.get(applicantId).get('Applicant_Group_Type__c')));                                                                  
                            lstofApplicantsbyGroup.add(Applicant);
                                                                      
                            // When the list has 2 or Applicant is a Business Account, Create a New Applicant Group
                            if(lstofApplicantsbyGroup.size()==2){
                                AppGrp.applicant = lstofApplicantsbyGroup;
                                AppGrp.applicantGroupTypeDd = string.Valueof(mapApplicants.get(applicantId).get('Applicant_Group_Type__c'));
                                ListAppGrp.add(AppGrp);
                                
                                // Removing the list items for the next iteration
                                mapofLoanApplicantsbyGroup.put(string.Valueof(mapApplicants.get(applicantId).get('Applicant_Group_Type__c')),new List<FilogixPOSTJSONWrapper.Applicant>());
                                AppGrp = new FilogixPOSTJSONWrapper.ApplicantGroup(); // Resetting AppGrp instance
                            } else {
                            mapofLoanApplicantsbyGroup.put(string.Valueof(mapApplicants.get(applicantId).get('Applicant_Group_Type__c')),lstofApplicantsbyGroup);       
                            }
                        } else {
                            List<FilogixPOSTJSONWrapper.Applicant> lstofApplicantsbyGroup = new List<FilogixPOSTJSONWrapper.Applicant>();
                            lstofApplicantsbyGroup.add(Applicant);
                            mapofLoanApplicantsbyGroup.put(string.Valueof(mapApplicants.get(applicantId).get('Applicant_Group_Type__c')),lstofApplicantsbyGroup);   
                        }
                    }
                    
                    //system.debug('mapofLoanApplicantsbyGroup 1 ::'+JSON.serialize(mapofLoanApplicantsbyGroup));
                    
                } //Applicant loop END
            } // If END
            
            // When there is no Primary Applicant Selected
            if(!PrimaryAppExist){
                requiredFieldError+='Please make sure at least one applicant is marked as Primary </br>';
            }
            
            //system.debug('AppGrp::'+JSON.serialize(AppGrp));
            //system.debug('mapofLoanApplicantsbyGroup 2 ::'+JSON.serialize(mapofLoanApplicantsbyGroup));
            
            // Adding Applicant Group for the rest of the types
            if(!mapofLoanApplicantsbyGroup.isEmpty()){
                for(String groupType : mapofLoanApplicantsbyGroup.keySet()){
                    if(mapofLoanApplicantsbyGroup.get(groupType).size() >0 && mapofLoanApplicantsbyGroup.get(groupType)!=null){
                        AppGrp.applicant = mapofLoanApplicantsbyGroup.get(groupType);
                        AppGrp.applicantGroupTypeDd = groupType;
                        ListAppGrp.add(AppGrp);
                    }
                }
            }
            //system.debug('AppGrp::'+JSON.serialize(AppGrp));
        }
        
        system.debug('#ListAppGrp=' + ListAppGrp);
        return ListAppGrp;
    }

    public static string cityNamegen(string cityName) {
        if (cityName == null || String.isBlank(cityName)) {
            return '';
        }
        return cityName.length()>20? cityName.substring(0,20):cityName;
                
    }
    
    public static string postalFSAGen(string postalCode) {
        string fsa = '';

        if (!string.isBlank(postalCode) && postalCode.length() >= 3 && postalcode!='null'){
            fsa = postalCode.substring(0, 3).toUpperCase();
        }

        /*// Checking the PostalCode Regex w.r.t Filgoix
        Pattern MyPattern = Pattern.compile('^(?!.*[DFIOQU]) ?[A-Z][0-9][A-Z]$');
        Matcher MyMatcher = MyPattern.matcher('fsa);
        if(!MyMatcher.matches()){
            requiredFieldError += '';
        }*/

        return fsa;
    }
    
    public static string postalLDUGen(string postalCode) {
        string ldu = '';
        if (!string.isBlank(postalCode) && postalCode.length() >= 6&& postalcode!='null'){
            //ldu = postalCode.substring(3, 6).toUpperCase();
            ldu = postalCode.right(3).toUpperCase(); // To Prevent getting spaces in case if Postalcode is "M2M 2M2".
        }

        /*// Checking the PostalCode Regex w.r.t Filgoix
        Pattern MyPattern = Pattern.compile('^(?!.*[DFIOQU]) ?[0-9][A-Z][0-9]$');
        Matcher MyMatcher = MyPattern.matcher(ldu);
        if(!MyMatcher.matches()){
            requiredFieldError += '';
        }*/

        return ldu;
    }
    
    public static string formatDateTime(datetime dt) {
        if (dt != null) {
            /*TimeZone tz = UserInfo.getTimeZone();
System.debug('Display name: ' + tz.getDisplayName());
System.debug('ID: ' + tz.getID());
*/
            string formattedDate = '';
            formattedDate = dt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss-00:00');
            system.debug('form=' + formattedDate);
            return formattedDate;
        }
        return null;
    }
    
    // This method will remove the null JSON elements and turns boolean values to Y or N
    public static string stripJsonNulls(string jsonString) {
        if (jsonString != null) {
            jsonString = jsonString.replaceAll('\"[^\"]*\":null', ''); //basic removeal of null values
            jsonString = jsonString.replaceAll(',{2,}', ','); //remove duplicate/multiple commas
            jsonString = jsonString.replace('{,', '{'); //prevent opening brace from having a comma after it
            jsonString = jsonString.replace(',}', '}'); //prevent closing brace from having a comma before it
            jsonString = jsonString.replace('[,', '['); //prevent opening bracket from having a comma after it
            jsonString = jsonString.replace(',]', ']'); //prevent closing bracket from having a comma before it
            
            jsonString = jsonString.replace('"false"', '"N"'); //converts boolean FALSE to N
            jsonString = jsonString.replace('"true"', '"Y"'); //converts boolean TRUE to Y
        }
        
        return jsonString;
    }

    public static String BooleanToString(String flagValue){
        if(!String.isBlank(flagValue)){
            if(flagValue=='false'){
                return 'N';
            }
        }
        return 'Y';
    }

    public static String getFullProvinceName(String shortCode){
        if(!String.isBlank(shortCode) && shortCode!=null){
            Map<String, String> provMap = new Map<String, String>{'NL' => 'Newfoundland and Labrador', 'PE' => 'Prince Edward Island', 'NS' => 'Nova Scotia', 'NB' => 'New Brunswick', 'QC' => 'Quebec', 'ON' => 'Ontario', 'MB' => 'Manitoba', 'SK' => 'Saskatchewan', 'AB' => 'Alberta', 'BC' => 'British Columbia', 'YT' => 'Yukon', 'NT' => 'Northwest Territories', 'NU' => 'Nunavut'};

            if(shortCode.length() < 3){
                return provMap.get(shortCode);
            } else {
                return shortCode.capitalize();
            }
        }
        return shortCode;
    }

    public static String getFullCountryName(String shortCode){
        if(!String.isBlank(shortCode) && shortCode!=null){
            Map<String, String> provMap = new Map<String, String>{'CA' => 'Canada', 'US' => 'United States'};

            if(shortCode.length() < 3){
                return provMap.get(shortCode);
            } else {
                return shortCode.capitalize();
            }
        }
        return shortCode;
    }
    /* This method removes special characters*/
    /* Initially created for Phone Number Values */
    public static string removeSpeacialChar(string stringVal){
        String returnVal;
        if(!string.isBlank(stringVal)){
            returnVal=stringVal.replaceAll('([^\\+|\\d])','');

            /* If the Phone number contains country code without + */
            if(returnVal.length() > 10){
                /* Getting 10 characters from right */
                returnVal = returnVal.right(10);
            }
        }
        return returnVal;
    }

    // This method will return object's permission wrt the action.
    // Example: Boolean isCreationAllowed_Account = getObjectPerm('Account','create');
    // Returns Boolean
    // 1st Param - sObject API Name
    // 2nd Param - create, update, delete, read
    public static boolean getObjectPerm(String objName, string perm){
        
        if(!String.isBlank(perm) && !String.isBlank(objName)){
            try{
                Schema.DescribeSObjectResult objDesc = Schema.getGlobalDescribe().get(objName).getDescribe();
                if(perm=='create') {
                    return objDesc.isCreateable();
                } else if(perm=='update') {
                    return objDesc.isUpdateable();
                } else if(perm=='delete') {
                    return objDesc.isDeletable();
                } else if(perm=='read') {
                    return objDesc.isAccessible();
                }
            } catch(Exception e){
                String error = ''+String.valueof(e.getMessage());
                System.debug('The following exception has occurred: ' + error);
                throw createCustomException(String.valueof(error));
            }
        }
        return false;
    }

    // This method will return object's permission wrt the action.
    // Example: Boolean isCreationAllowed_Account_Name = getFieldPerm('Account','Name','create');
    // Returns Boolean
    // 1st Param - sObject API Name
    // 2nd Param - sObject's Field Api Name
    // 3rd Param - create, update, delete, read
    public static boolean getFieldPerm(String objName, String fieldName, string perm){
        
        if(!String.isBlank(perm) && !String.isBlank(objName) && !String.isBlank(fieldName)){
            try{
                Schema.DescribeFieldResult fieldDesc = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap().get(fieldName).getDescribe();
                if(perm=='create') {
                    return fieldDesc.isCreateable();
                } else if(perm=='update') {
                    return fieldDesc.isUpdateable();
                } else if(perm=='read') {
                    return fieldDesc.isAccessible();
                }else if(perm=='null') {
                    return fieldDesc.isNillable();
                }
            } catch(Exception e){
                String error = ''+String.valueof(e.getMessage());
                System.debug('The following exception has occurred: ' + error);
                throw createCustomException(String.valueof(error));
            }
        }
        return false;
    }        
    
    /* This method will return the field Api Name against object and the parent relationship name 
        Example: getFieldApiNamefromParentRelationName('LoanApplicantAddress','LoanApplicant');
    */
    /*public static String getFieldApiNamefromParentRelationName(String objName, String relationshipName){
        String fieldApiName='';
        if(!String.isBlank(objName) && !String.isBlank(relationshipName)){
            map<string,string> mapofRelationandName = new map<string,string>();
            fieldApiName = relationshipName;
            for(Schema.SobjectField strFld: Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap().Values()){
                if(strFld.getDescribe().getType() == Schema.DisplayType.REFERENCE){
                    mapofRelationandName.put(String.valueof(strFld.getDescribe().getReferenceTo()[0]),String.valueof(strFld.getDescribe().getName()));
                } 
            }

            if(mapofRelationandName.containskey(relationshipName)){
                return mapofRelationandName.get(relationshipName);
            }
        }
        return fieldApiName;
    }*/
    
    /* This method will return the field Api Name against object and the parent relationship name 
        Example: getFieldApiNamefromParentRelationName('LoanApplicantAddress');
    */
    public static map<string,string> getFieldApiNamefromParentRelationName(String objName){
        system.debug('objName::'+objName);
        map<string,string> mapofRelationandName = new map<string,string>();
        if(!String.isBlank(objName)){
            for(Schema.SobjectField strFld: Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap().Values()){
                if(strFld.getDescribe().getType() == Schema.DisplayType.REFERENCE){
                    mapofRelationandName.put(String.valueof(strFld.getDescribe().getReferenceTo()[0]),String.valueof(strFld.getDescribe().getName()));
                } 
            }

            //if(!mapofRelationandName.isEmpty()){
            //    return mapofRelationandName;
            //}
        }
        return mapofRelationandName;
    }
}