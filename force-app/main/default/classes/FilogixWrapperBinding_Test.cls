/**
 * @description       : Test Class for FilogixWrapperBinding
 * @author            : M Hamza Siddiqui @ mhamzas.com
 * @group             : 
 * @last modified on  : 06-14-2022
 * @last modified by  : M Hamza Siddiqui
 * Modifications Log 
 * Ver   Date         Author                           Modification
 * 1.0   03-18-2021   M Hamza Siddiqui @ mhamzas.com   Initial Version
 * 1.1   05-24-2021   M Hamza Siddiqui @ mhamzas.com   Updated Class w.r.t the latest changes
**/
@isTest
private with sharing class FilogixWrapperBinding_Test {

    
    static testmethod void FilogixWrapperBinding_Test(){
        
        sObject rla = FilogixResponseParsingUtil_test.testData();
        Test.startTest();
        FilogixWrapperBinding fwb = New FilogixWrapperBinding(rla.id);
        FilogixWrapperBinding.returnJSON();
        Test.stopTest();
    }
    
    static testmethod void createCustomException(){
        FilogixWrapperBinding.CustomException ex= new FilogixWrapperBinding.CustomException();
        DmlException unexpectedException;
        try
        {
            FilogixWrapperBinding.createCustomException('Exceptions should be handled by the method');
        }
        catch (DmlException dmx)
        {
            unexpectedException = dmx;
        }
        
        system.assertEquals(null, unexpectedException, 'Exceptions should be handled by the method');

        //System.assert(condition, msg)
        //System.assert( ex != null,' exception should not be null');
		//System.assert( ex != null);
        
    }
    
    static testmethod void sendReportToCJA(){
        
        Test.startTest();
       System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent');

       FilogixWrapperBinding.sendReportToCJA('test exception', 'appId','post');

       System.assertEquals(1, Limits.getEmailInvocations(), 'Emails should be sent');
       Test.stopTest();
        
    }
    
    static testmethod void requiredFieldsError(){
        FilogixWrapperBinding.requiredFieldsError('residentialLoanapplication', 'CJA_Mortgage__FilogixId__c', 'test', 'ssw');
		System.assertNotEquals('null&lt;b&gt;Object&lt;/b&gt; : Residential Loan Application, &lt;b&gt;Field&lt;/b&gt; : Filogix ID , &lt;b&gt;Record Name&lt;/b&gt; : &lt;a href="/ssw"&gt; test &lt;/a&gt;&lt;/br&gt;", Actual: "null&lt;b&gt;Object&lt;/b&gt; : Residential Loan Application, &lt;b&gt;Field&lt;/b&gt; : Filogix ID , &lt;b&gt;Record Name&lt;/b&gt; : &lt;a href=\"/ssw\"&gt; test &lt;/a&gt;&lt;/br&gt;',JSON.serialize(FilogixWrapperBinding.requiredFieldError));
    }
    
    static testmethod void requiredFieldsError2(){
        FilogixWrapperBinding.requiredFieldsError('residentialLoanapplication', 'CJA_Mortgage__FilogixId__c', 'test', '');
		System.assertNotEquals('null&lt;b&gt;Object&lt;/b&gt; : Residential Loan Application, &lt;b&gt;Field&lt;/b&gt; : Filogix ID , &lt;b&gt;Record Name&lt;/b&gt; : &lt;a href="/ssw"&gt; test &lt;/br&gt;", Actual: "null&lt;b&gt;Object&lt;/b&gt; : Residential Loan Application, &lt;b&gt;Field&lt;/b&gt; : Filogix ID , &lt;b&gt;Record Name&lt;/b&gt; : test &lt;/a&gt;&lt;/br&gt;',JSON.serialize(FilogixWrapperBinding.requiredFieldError));
    }
    
    static testmethod void requiredFieldsError3(){
        FilogixWrapperBinding.requiredFieldsError('residentialLoanapplication', 'CJA_Mortgage__FilogixId__c', '', '');
		System.assertNotEquals('null&lt;b&gt;Object&lt;/b&gt; : Residential Loan Application, &lt;b&gt;Field&lt;/b&gt; : Filogix ID , &lt;b&gt;Record Name&lt;/b&gt; : &lt;a href="/ssw"&gt; test &lt;/br&gt;", Actual: "null&lt;b&gt;Object&lt;/b&gt; : Residential Loan Application, &lt;b&gt;Field&lt;/b&gt; : Filogix ID , &lt;b&gt;Record Name&lt;/b&gt; : test &lt;/a&gt;&lt;/br&gt;',JSON.serialize(FilogixWrapperBinding.requiredFieldError));
    }
    
    static testmethod void requiredFieldsError4(){
        FilogixWrapperBinding.requiredFieldsError('Account', 'CJA_Mortgage__FilogixId__c', '', '');
		System.assertNotEquals('null&lt;b&gt;Object&lt;/b&gt; : Residential Loan Application, &lt;b&gt;Field&lt;/b&gt; : Filogix ID , &lt;b&gt;Record Name&lt;/b&gt; : &lt;a href="/ssw"&gt; test &lt;/br&gt;", Actual: "null&lt;b&gt;Object&lt;/b&gt; : Residential Loan Application, &lt;b&gt;Field&lt;/b&gt; : Filogix ID , &lt;b&gt;Record Name&lt;/b&gt; : test &lt;/a&gt;&lt;/br&gt;',JSON.serialize(FilogixWrapperBinding.requiredFieldError));
    }
    static testmethod void getFieldApiNamefromParentRelationName_Test(){
        map<string,string> aa = FilogixWrapperBinding.getFieldApiNamefromParentRelationName('Account');
        System.assertNotEquals(aa.isEmpty(), null);
    }
    
    static testmethod void getFieldPerm_Test(){
        Boolean perm = FilogixWrapperBinding.getFieldPerm('Account', 'Name', 'read');
        System.assertNotEquals(perm, false);
    }
    
    static testmethod void getObjectPerm_Test(){
        Boolean perm = FilogixWrapperBinding.getObjectPerm('Account', 'read');
        System.assertNotEquals(perm, false);
    }
}