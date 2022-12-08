/**
* @description       : 
* @author            : M Hamza Siddiqui
* @group             : 
* @last modified on  : 06-15-2022
* @last modified by  : M Hamza Siddiqui
* Modifications Log 
* Ver   Date         Author             Modification
* 1.0   05-26-2021   M Hamza Siddiqui   Initial Version
**/
@isTest
public class Communication_Handler_Test {
    
    @testSetup static void setup2() {
        
        // Setting up the MJ Auth Custom Metadata Type
        CJA_Mortgage__MJAuth__mdt cmd = New CJA_Mortgage__MJAuth__mdt(); 
        cmd.Label = 'MJ Auth'; 
        cmd.DeveloperName = 'MJ_Auth';
        cmd.CJA_Mortgage__Username__c = 'CLJT';
        cmd.CJA_Mortgage__Password__c = 'CLJT';
        
        system.debug(CJA_Mortgage__MJAuth__mdt.getAll());
        
        // Creating a new user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' WITH SECURITY_ENFORCED]; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US', ProfileId = p.Id, Filogix_Id__c='Agent2',TimeZoneSidKey='America/Los_Angeles', UserName='standarduser233@testorg.com');
        insert u;
        
        //String PArecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        //String PArecordTypeId = [SELECT Id, Name, SobjectType,IsPersonType FROM RecordType WHERE SobjectType='Account' AND IsPersonType=True].Id;
        String PArecordTypeId;
        String sObjT = 'Account';
        String personAccountQuery = 'SELECT Id, Name, SobjectType,IsPersonType FROM RecordType WHERE SobjectType=:sObjT AND IsPersonType=True limit 1';
        List<sObject> personAccountData = Database.query(String.escapeSingleQuotes(personAccountQuery));
        if(personAccountData!=null){
            PArecordTypeId = String.valueof(personAccountData[0].Id);
        }
        
        // Getting App Namespace
        String appNameSpace = FilogixWrapperBinding.getAppNameSpace();
        
        String accountObjectApiName =appNameSpace+'Account';
        sObject acc = Schema.getGlobalDescribe().get(accountObjectApiName).newSObject();
        //Account acc = New Account();
        acc.put('FirstName','Test First Name');
        acc.put('LastName', 'Test Last Name');
        acc.put('PersonMailingCity', 'Toronto');
        acc.put('PersonMailingState', 'Ontario');
        acc.put('PersonMailingCountry', 'CANADA');
        acc.put('PersonMailingPostalCode', 'ON 3131 31');
        //acc.put('Street_Direction__c', 'Test Street Description');
        acc.put('PersonMailingStreet', 'Street 1');
        //acc.put('Street_Number__c', 'STN 213');
        //acc.put('Street_Type__c', 'Camp');
        //acc.put('Unit_Number__c', 'STU 212');
        acc.put('RecordtypeId', PArecordTypeId);
        
        insert acc;
        
        System.assert(acc!= null);
        //Contact con = [Select LastName from Contact where AccountId=:acc.Id limit 1];
        //System.assertEquals(acc.LastName, con.LastName);

        //Opportunity opp = New Opportunity ();
        String opportunityObjectApiName =appNameSpace+'Opportunity';
        sObject opp = Schema.getGlobalDescribe().get(opportunityObjectApiName).newSObject();
        
        opp.put('Name', 'New Opportunity');
        opp.put('AccountId', String.valueof(acc.get('Id')));
        opp.put('StageName', 'Need Analysis');
        opp.put('CloseDate', date.today());
        opp.put('Amount', 55000);
        opp.put('Description', 'Test Opportunity Description');
        
        insert opp;
        System.assert(opp!= null);
        
        
        String ResidentialLoanApplicationObjectApiName =appNameSpace+'ResidentialLoanApplication';
        sObject Secrla = Schema.getGlobalDescribe().get(ResidentialLoanApplicationObjectApiName).newSObject();
        
        Secrla.put('FilogixId__c','CLJT-2');
        Secrla.put('Name','Test RLA 2');
        Secrla.put('AccountId', String.valueof(acc.get('Id')));
        Secrla.put('OpportunityId',String.valueof(opp.get('Id')));
        Secrla.put('OwnerId',u.Id);
        
        insert Secrla;
        System.assert(Secrla!= null);
        
        sObject Secrla2 = Schema.getGlobalDescribe().get(ResidentialLoanApplicationObjectApiName).newSObject();
        
        Secrla2.put('Name','Test RLA 3');
        Secrla2.put('AccountId', String.valueof(acc.get('Id')));
        Secrla2.put('OpportunityId',String.valueof(opp.get('Id')));
        
        insert Secrla2;
        System.assert(Secrla2!= null);
    }
    
    private class Mock implements HttpCalloutMock {
        
        
        public HTTPResponse respond(HTTPRequest req) {
            
            // Call the method that performs the callout
            string getbody = '{"mortgageApplication":{"subjectProperty":{"waterTypeDd":"Well","taxationYear":2020,"structureAge":10,"rentalIncome":{"incPercentInTds":10,"incomeTypeDd":"Rental Income","incomePeriodDd":"Annual","incomeAmount":3120},"propertyTypeDd":"Condo","propertyExpense":[],"occupancyTypeDd":"Owner Occupied","numberOfUnits":30,"newConstructionDd":"Existing","mlsListingFlag":"Y","lotSizeUnitOfMeasureDd":"Acres","lotSize":20,"livingSpaceUnitOfMeasurDd":"Sq Ft","includetds":"Y","heatTypeDd":"Electric Baseboard","garageTypeDd":"Attached","garageSizeDd":"Double","feesIncludeHeat":"N","estimatedAppraisalValue":5200,"dwellingTypeDd":"Apartment High Rise","dwellingStyleDd":"BiLevel","appraisalDateAct":"2021-02-18T17:00:00-00:00","address":{"unitNumber":"unit 432","streetTypeDd":"Allee","streetNumber":"12","streetName":"553 franklin d. roosevelt","streetDirectionDd":"E","provinceDd":"Ontario","postalLdu":"2M2","postalFsa":"M2M","countryTypeDd":"Canada","city":"Toronto"},"actualAppraisalValue":21520},"notes":[{}],"mortgage":[{"subprimeFlag":"N","reverseFlag":"N","requestedRate":30,"refiBlendedAmortization":"N","rate":{},"qualifyDetail":{"interestOnlyFlag":"N","interestCompoundDd":"Monthly"},"mtgInsIncludeFlag":"N","mortgageTypeDd":"First","interestOnlyFlag":"N","interestCompoundDd":"Monthly","insuredFlag":"N","helocFlag":"N","existingMortgageFlag":"N","constructionFlag":"N","commercialFlag":"N","cashBackOverride":"N","borrowerIds":[{"borrowerId":1}],"balanceRemaining":90755,"actualPaymentTerm":84}],"deal":{"taxPayorDd":"Borrower","sourceApplicationId":"0cd4W000000bwJeQAI","refiImprovementsFlag":"N","referralReferenceNo":"5634234","financingWaiverDate":"2021-03-08T17:00:00-00:00","estimatedClosingDate":"2021-03-03T00:00:00-00:00","downPaymentSource":[],"dealTypeDd":"Approval","dealPurposeDd":"Purchase"},"applicantGroup":[{"mailingAddr":{"unitNumber":"678","streetTypeDd":"Abbey","streetNumber":"452","streetName":"5 Augustusplatz","streetDirectionDd":"E","provinceDd":"Ontario","postalLdu":"2M2","postalFsa":"M2M","countryTypeDd":"Canada","city":"Toronto"},"applicantGroupTypeDd":"Applicant","applicant":[{"socialInsuranceNumber":"9713456347","primaryApplicantFlag":"Y","otherProperty":[],"otherIncome":[],"name":{"lastName":"Adam","firstName":"Bryan"},"liability":[],"identification":[{}],"firstTimeBuyer":"N","existingClient":"N","employmentHistory":[{"selfEmploymentFlag":"N","operatingAs":"Test","monthsOfService":2,"jobTitle":"23234","industrySectorDd":"Banking Finance","income":{"incomeTypeDd":"Salary","incomePeriodDd":"Monthly","incomeAmount":2333},"grossRevenue":13998,"employmentHistoryTypeDd":"Full Time","employmentHistoryStatusDd":"Current","employerName":"tet","contact":{"contactPhoneNumber":"8023934729","address":{"provinceDd":"Ontario","postalLdu":"2M2","postalFsa":"M2M","countryTypeDd":"Canada","city":"Toronto","addressLine1":"S Quebec St."}}}],"clientReferenceNumber":"0cU4W000000bwJPUAY","borrowerWorkPhoneNumber":"+4934121460","borrowerSpouseId":0,"borrowerId":1,"asset":[],"addressDetail":[{"residentialStatusDd":"Rent","monthsAtAddress":4,"addressTypeDd":"Current","address":{"streetName":"5 Augustusplatz","provinceDd":"Ontario","countryTypeDd":"Canada","city":"Toronto"}}]}]}]}}';
	        string postbody = '{"result": {"setMortgageAppDataResponse": {"mortgageApplicationId": "CLJT-835"}}}';
            
            if (req.getEndpoint().endsWith('token')) {
                HTTPResponse res = new HTTPResponse();
                res.setBody('{"accessToken": "450023da7754fee83af3f37090469b3e44fda9a9","accessTokenExpiresAt": "2023-04-25T08:47:37.137Z"}');
                res.setStatusCode(200);
                return res;
            }else if(req.getEndpoint().endsWith('post')){
                    HTTPResponse res = new HTTPResponse();
                    res.setBody(postbody);
                    res.setStatusCode(200);
                    return res;
            } else {
                // for GET
                HTTPResponse res = new HTTPResponse();
                res.setBody(getbody);
                res.setStatusCode(200);
                return res;
            }
            /*} else {
                System.assert(false, 'unexpected endpoint ' + req.getEndpoint());
                return null;
            }*/
        }
    }
    
    @isTest 
    public static void Communication_Handler_Test2(){
        
        String rlaName='Test RLA 3';
        String query = 'Select id,OwnerId,FilogixId__c, Opportunity.StageName from ResidentialLoanApplication where Name =: rlaName WITH SECURITY_ENFORCED';
        sObject testRLA = database.query(query);
        String rlaOwnerId = String.valueof(testRLA.get('OwnerId'));
        String userQuery = 'select Filogix_Id__c from user where id=:rlaOwnerId WITH SECURITY_ENFORCED';
        sObject testuser = database.query(String.escapeSingleQuotes(userQuery));
        
        system.assertEquals('Need Analysis', testRLA.getSObject('Opportunity').get('StageName'),'Opportunity stageName is wrong.');
        
        Test.setMock(HttpCalloutMock.class, new Mock());
        
        // Call the method that performs the callout
        string body = '{"mortgageApplication":{"subjectProperty":{"waterTypeDd":"Well","taxationYear":2020,"structureAge":10,"rentalIncome":{"incPercentInTds":10,"incomeTypeDd":"Rental Income","incomePeriodDd":"Annual","incomeAmount":3120},"propertyTypeDd":"Condo","propertyExpense":[],"occupancyTypeDd":"Owner Occupied","numberOfUnits":30,"newConstructionDd":"Existing","mlsListingFlag":"Y","lotSizeUnitOfMeasureDd":"Acres","lotSize":20,"livingSpaceUnitOfMeasurDd":"Sq Ft","includetds":"Y","heatTypeDd":"Electric Baseboard","garageTypeDd":"Attached","garageSizeDd":"Double","feesIncludeHeat":"N","estimatedAppraisalValue":5200,"dwellingTypeDd":"Apartment High Rise","dwellingStyleDd":"BiLevel","appraisalDateAct":"2021-02-18T17:00:00-00:00","address":{"unitNumber":"unit 432","streetTypeDd":"Allee","streetNumber":"12","streetName":"553 franklin d. roosevelt","streetDirectionDd":"E","provinceDd":"Ontario","postalLdu":"2M2","postalFsa":"M2M","countryTypeDd":"Canada","city":"Toronto"},"actualAppraisalValue":21520},"notes":[{}],"mortgage":[{"subprimeFlag":"N","reverseFlag":"N","requestedRate":30,"refiBlendedAmortization":"N","rate":{},"qualifyDetail":{"interestOnlyFlag":"N","interestCompoundDd":"Monthly"},"mtgInsIncludeFlag":"N","mortgageTypeDd":"First","interestOnlyFlag":"N","interestCompoundDd":"Monthly","insuredFlag":"N","helocFlag":"N","existingMortgageFlag":"N","constructionFlag":"N","commercialFlag":"N","cashBackOverride":"N","borrowerIds":[{"borrowerId":1}],"balanceRemaining":90755,"actualPaymentTerm":84}],"deal":{"taxPayorDd":"Borrower","sourceApplicationId":"0cd4W000000bwJeQAI","refiImprovementsFlag":"N","referralReferenceNo":"5634234","financingWaiverDate":"2021-03-08T17:00:00-00:00","estimatedClosingDate":"2021-03-03T00:00:00-00:00","downPaymentSource":[],"dealTypeDd":"Approval","dealPurposeDd":"Purchase"},"applicantGroup":[{"mailingAddr":{"unitNumber":"678","streetTypeDd":"Abbey","streetNumber":"452","streetName":"5 Augustusplatz","streetDirectionDd":"E","provinceDd":"Ontario","postalLdu":"2M2","postalFsa":"M2M","countryTypeDd":"Canada","city":"Toronto"},"applicantGroupTypeDd":"Applicant","applicant":[{"socialInsuranceNumber":"9713456347","primaryApplicantFlag":"Y","otherProperty":[],"otherIncome":[],"name":{"lastName":"Adam","firstName":"Bryan"},"liability":[],"identification":[{}],"firstTimeBuyer":"N","existingClient":"N","employmentHistory":[{"selfEmploymentFlag":"N","operatingAs":"Test","monthsOfService":2,"jobTitle":"23234","industrySectorDd":"Banking Finance","income":{"incomeTypeDd":"Salary","incomePeriodDd":"Monthly","incomeAmount":2333},"grossRevenue":13998,"employmentHistoryTypeDd":"Full Time","employmentHistoryStatusDd":"Current","employerName":"tet","contact":{"contactPhoneNumber":"8023934729","address":{"provinceDd":"Ontario","postalLdu":"2M2","postalFsa":"M2M","countryTypeDd":"Canada","city":"Toronto","addressLine1":"S Quebec St."}}}],"clientReferenceNumber":"0cU4W000000bwJPUAY","borrowerWorkPhoneNumber":"+4934121460","borrowerSpouseId":0,"borrowerId":1,"asset":[],"addressDetail":[{"residentialStatusDd":"Rent","monthsAtAddress":4,"addressTypeDd":"Current","address":{"streetName":"5 Augustusplatz","provinceDd":"Ontario","countryTypeDd":"Canada","city":"Toronto"}}]}]}]}}';
        
        Test.startTest();
        string responseforPost = Communication_Handler.insertFilogixApp(body,(ID)testRLA.get('Id'),'User',String.valueof(testuser.get('Filogix_Id__c')));
        Test.stopTest();
        
    }
    
    @isTest 
    public static void Communication_Handler_Test(){
        
        String rlaName='Test RLA 3';
        String query = 'Select id,OwnerId,FilogixId__c, Opportunity.StageName from ResidentialLoanApplication where Name =: rlaName WITH SECURITY_ENFORCED';
        sObject testRLA = database.query(String.escapeSingleQuotes(query));
        
        String rlaOwnerId = String.valueof(testRLA.get('OwnerId'));
        String userQuery = 'select Filogix_Id__c from user where id=:rlaOwnerId WITH SECURITY_ENFORCED';
        sObject testuser = database.query(String.escapeSingleQuotes(userQuery));
        
        system.assertEquals('Need Analysis', testRLA.getSObject('Opportunity').get('StageName'),'Opportunity stageName is wrong.');
        
        Test.setMock(HttpCalloutMock.class, new Mock());
        
		Test.startTest();
        string responseforPost = Communication_Handler.getFilogixApp((String)testRLA.get('Id'),(String)testRLA.get('FilogixId__c'),'User',String.valueof(testuser.get('Filogix_Id__c')));
        Test.stopTest();
        
    }
    
}