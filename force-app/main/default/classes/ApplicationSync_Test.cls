/**
 * @description       :
 * @author            : M Hamza Siddiqui
 * @group             :
 * @last modified on  : 02-18-2022
 * @last modified by  : M Hamza Siddiqui
 **/
@isTest
public class ApplicationSync_Test {
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
      } else if (req.getEndpoint().endsWith('AGENT2')) {
        HTTPResponse res = new HTTPResponse();
        res.setBody(getbody);
        res.setStatusCode(200);
        return res;
      } else if (req.getEndpoint().endsWith('post')) {
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
  public static void CreateApp_Test() {
    // Getting App Namespace
    String appNameSpace = FilogixWrapperBinding.getAppNameSpace();
    // Getting test Rla
    sObject rla = FilogixResponseParsingUtil_test.testData();
    //Assignign the mock response
    Test.setMock(HttpCalloutMock.class, new Mock());

    Test.startTest();
    ApplicationSync.createApp(String.valueOf(rla.get('id')));
    Test.stopTest();

    /* ResidentialLoanApplication__c res = [select id, FilogixId__c from ResidentialLoanApplication__c where id=:rla.Id limit 1];
     System.assertNotEquals('', res.FilogixId__c);*/

    String RLAObjAPIName = getObjectName('ResidentialLoanApplication');
    string rlaId = rla.Id;
    String rlaQuery = 'Select Id,Name,FilogixId__c' + ' from  ' + RLAObjAPIName + ' where Id ' + ' =: rlaId LIMIT 1';
    sObject rlaRec = database.query(String.escapeSingleQuotes(rlaQuery));
    System.assertNotEquals('', String.ValueOf(rlaRec.get('FilogixId__c')));
  }

  @isTest
  public static void CreateAppWithoutFilogixID_Test() {
    // Getting App Namespace
    String appNameSpace = FilogixWrapperBinding.getAppNameSpace();
    sObject rla = FilogixResponseParsingUtil_test.testData();
    rla.put(appNameSpace + 'FilogixId__c', '');
    update rla;

    Test.setMock(HttpCalloutMock.class, new Mock());

    Test.startTest();
    String response = ApplicationSync.createApp(String.valueOf(rla.get('id')));
    Test.stopTest();

    /* ResidentialLoanApplication__c res = [select id, FilogixId__c from ResidentialLoanApplication__c where id=:rla.Id limit 1];
     System.assertNotEquals('', res.FilogixId__c);*/

    String RLAObjAPIName = getObjectName('ResidentialLoanApplication');
    string rlaId = rla.Id;
    String rlaQuery = 'Select Id,Name,FilogixId__c' + ' from  ' + RLAObjAPIName + ' where Id ' + ' =: rlaId LIMIT 1';
    sObject rlaRec = database.query(String.escapeSingleQuotes(rlaQuery));
    System.assertNotEquals('', String.ValueOf(rlaRec.get('FilogixId__c')));
  }

  @isTest
  public static void CreateAppWithoutFilogixID_Error() {
    // Getting App Namespace
    String appNameSpace = FilogixWrapperBinding.getAppNameSpace();

    sObject rla = FilogixResponseParsingUtil_test.testData();

    rla.put(appNameSpace + 'FilogixId__c', '');
    rla.put(appNameSpace + 'Deal_Purpose__c', '');
    update rla;

    Test.setMock(HttpCalloutMock.class, new Mock());

    Test.startTest();
    String response = ApplicationSync.createApp(String.valueOf(rla.get('id')));
    Test.stopTest();
    System.assertNotEquals(response, '');
  }

  @isTest
  public static void CreateAppWithoutFilogixID_Error2() {
    Test.startTest();
    String response = ApplicationSync.createApp('');
    Test.stopTest();
    System.assertEquals('Please make sure you are using this action in Residential Loan Application Object or contact the App Developer.', response);
  }

  @isTest
  public static void UpdateApp_Test() {
    // Getting App Namespace
    String appNameSpace = FilogixWrapperBinding.getAppNameSpace();

    sObject rla = FilogixResponseParsingUtil_test.testData();

    rla.put(appNameSpace + 'FilogixId__c', 'CLJT-123');
    update rla;

    Test.startTest();
    ApplicationSync.updateApp(String.valueOf(rla.get('id')));
    Test.stopTest();

    /*ResidentialLoanApplication__c res = [select id, FilogixId__c from ResidentialLoanApplication__c where id=:rla.Id limit 1];
     System.assertEquals('CLJT-123', res.FilogixId__c);*/

    String RLAObjAPIName = getObjectName('ResidentialLoanApplication');
    string rlaId = rla.Id;
    String rlaQuery = 'Select Id,Name,FilogixId__c' + ' from  ' + RLAObjAPIName + ' where Id ' + ' =: rlaId LIMIT 1';
    sObject rlaRec = database.query(String.escapeSingleQuotes(rlaQuery));
    System.assertNotEquals('', String.ValueOf(rlaRec.get('FilogixId__c')));
  }

  public static string getObjectName(String ObjName) {
    boolean isNonFSC = FilogixResponseParsingUtil.getEnvironmentType();

    if (isNonFSC == true) {
      ObjName = 'ResidentialLoanApplication__c';
    }

    return ObjName;
  }
}
