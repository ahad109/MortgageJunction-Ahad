@isTest
public class ApplicationStatusSync_Test {
    
    @isTest
    public static void UpdateFilogix_Test_Error(){

        // Getting App Namespace
        String appNameSpace = FilogixWrapperBinding.getAppNameSpace();

        sObject rla = FilogixResponseParsingUtil_test.testData();
        Test.startTest();
        ApplicationStatusSync.updateFilogix(String.valueof(rla.get('id')));
        Test.stopTest();

    }
    
    @isTest
    public static void UpdateFilogix_Test(){

        // Getting App Namespace
        String appNameSpace = FilogixWrapperBinding.getAppNameSpace();

        sObject rla = FilogixResponseParsingUtil_test.testData();
        rla.put(appNameSpace+'FilogixId__c', 'CLJT-92');
        update rla;
        Test.startTest();
        ApplicationStatusSync.updateFilogix(String.valueof(rla.get('id')));
        Test.stopTest();

    }
    
}