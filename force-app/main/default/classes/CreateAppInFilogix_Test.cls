/**
* @description       :
* @author            : M Hamza Siddiqui @ mhamzas.com
* @group             :
* @last modified on  : 03-18-2021
* @last modified by  : M Hamza Siddiqui @ mhamzas.com
* Modifications Log
* Ver   Date         Author                           Modification
* 1.0   03-10-2021   M Hamza Siddiqui @ mhamzas.com   Initial Version
**/
@isTest
public class CreateAppInFilogix_Test {
    @isTest
    public static void createAppInFilogix_success() {
        /* Data Bank Start */
        sObject rla = FilogixResponseParsingUtil_test.testData();
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('GET_Sample_Response');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);
        System.debug('Mock ==> ' + mock );

        CreateAppInFilogix.ActionRequest request = new CreateAppInFilogix.ActionRequest();
        
        request.recordId = String.valueof(rla.get('Id'));
        request.result = 'Success';
        
        Test.startTest();
        CreateAppInFilogix.invokeService(
            new List<CreateAppInFilogix.ActionRequest>{ request }
        );
        Test.stopTest();
    }
    
    @isTest
    public static void getResidentialLoanApplicationTest() {
        
        sObject rla = FilogixResponseParsingUtil_test.testData();
        
        Test.startTest();
        CreateAppInFilogix.getResidentialLoanApplication(string.valueof(rla.get('Id')));
        Test.stopTest();
    }
}