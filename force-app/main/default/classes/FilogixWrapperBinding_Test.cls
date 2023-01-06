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
  @isTest
  public static void getAppNameSpaceTest() {
    FilogixWrapperBinding.getAppNameSpace();
  }

  static testMethod void FilogixWrapperBinding_Test() {
    sObject rla = FilogixResponseParsingUtil_test.testData();
    Test.startTest();
    FilogixWrapperBinding fwb = new FilogixWrapperBinding(rla.id);
    FilogixWrapperBinding.returnJSON();
    FilogixWrapperBinding.fieldIdentification(rla.Id);
    FilogixWrapperBinding.objectRefName('Account', 'Id');

    Test.stopTest();
  }

  static testMethod void createCustomException() {
    FilogixWrapperBinding.CustomException ex = new FilogixWrapperBinding.CustomException();
    DmlException unexpectedException;
    try {
      FilogixWrapperBinding.createCustomException(
        'Exceptions should be handled by the method'
      );
    } catch (DmlException dmx) {
      unexpectedException = dmx;
    }

    system.assertEquals(
      null,
      unexpectedException,
      'Exceptions should be handled by the method'
    );

    //System.assert(condition, msg)
    //System.assert( ex != null,' exception should not be null');
    //System.assert( ex != null);
  }

  static testMethod void sendReportToCJA() {
    Test.startTest();
    System.assertEquals(
      0,
      Limits.getEmailInvocations(),
      'No emails should be sent'
    );

    FilogixWrapperBinding.sendReportToCJA('test exception', 'appId', 'post');

    System.assertEquals(
      1,
      Limits.getEmailInvocations(),
      'Emails should be sent'
    );
    Test.stopTest();
  }

  static testMethod void requiredFieldsError() {
    string objNameSuffix = '';
    string objNamePrefix = '';
    string customFieldSuffix = '';
    String appNamespace = FilogixWrapperBinding.getAppNameSpace();
    Boolean isNonFSC = FilogixResponseParsingUtil.getEnvironmentType();
    if (!isNonFSC) {
      objNameSuffix = '__c';
      customFieldSuffix = '__c';
      objNamePrefix = appNamespace;
    }
    FilogixWrapperBinding.requiredFieldsError(
      objNamePrefix + 'residentialLoanapplication' + objNameSuffix,
      appNamespace + 'FilogixId__c',
      'test',
      'ssw'
    );
    System.assertNotEquals(
      'null&lt;b&gt;Object&lt;/b&gt; : Residential Loan Application, &lt;b&gt;Field&lt;/b&gt; : Filogix ID , &lt;b&gt;Record Name&lt;/b&gt; : &lt;a href="/ssw"&gt; test &lt;/a&gt;&lt;/br&gt;", Actual: "null&lt;b&gt;Object&lt;/b&gt; : Residential Loan Application, &lt;b&gt;Field&lt;/b&gt; : Filogix ID , &lt;b&gt;Record Name&lt;/b&gt; : &lt;a href=\"/ssw\"&gt; test &lt;/a&gt;&lt;/br&gt;',
      JSON.serialize(FilogixWrapperBinding.requiredFieldError)
    );
  }

  static testMethod void requiredFieldsError2() {
    string objNameSuffix = '';
    string objNamePrefix = '';
    string customFieldSuffix = '';
    String appNamespace = FilogixWrapperBinding.getAppNameSpace();
    Boolean isNonFSC = FilogixResponseParsingUtil.getEnvironmentType();
    if (!isNonFSC) {
      objNameSuffix = '__c';
      customFieldSuffix = '__c';
      objNamePrefix = appNamespace;
    }

    FilogixWrapperBinding.requiredFieldsError(
      objNamePrefix + 'residentialLoanapplication' + objNameSuffix,
      appNamespace + 'FilogixId__c',
      'test',
      ''
    );
    System.assertNotEquals(
      'null&lt;b&gt;Object&lt;/b&gt; : Residential Loan Application, &lt;b&gt;Field&lt;/b&gt; : Filogix ID , &lt;b&gt;Record Name&lt;/b&gt; : &lt;a href="/ssw"&gt; test &lt;/br&gt;", Actual: "null&lt;b&gt;Object&lt;/b&gt; : Residential Loan Application, &lt;b&gt;Field&lt;/b&gt; : Filogix ID , &lt;b&gt;Record Name&lt;/b&gt; : test &lt;/a&gt;&lt;/br&gt;',
      JSON.serialize(FilogixWrapperBinding.requiredFieldError)
    );
  }

  static testMethod void requiredFieldsError3() {
    string objNameSuffix = '';
    string objNamePrefix = '';
    string customFieldSuffix = '';
    String appNamespace = FilogixWrapperBinding.getAppNameSpace();
    Boolean isNonFSC = FilogixResponseParsingUtil.getEnvironmentType();
    if (!isNonFSC) {
      objNameSuffix = '__c';
      customFieldSuffix = '__c';
      objNamePrefix = appNamespace;
    }
    FilogixWrapperBinding.requiredFieldsError(
      objNamePrefix + 'residentialLoanapplication' + objNameSuffix,
      appNamespace + 'FilogixId__c',
      '',
      ''
    );
    System.assertNotEquals(
      'null&lt;b&gt;Object&lt;/b&gt; : Residential Loan Application, &lt;b&gt;Field&lt;/b&gt; : Filogix ID , &lt;b&gt;Record Name&lt;/b&gt; : &lt;a href="/ssw"&gt; test &lt;/br&gt;", Actual: "null&lt;b&gt;Object&lt;/b&gt; : Residential Loan Application, &lt;b&gt;Field&lt;/b&gt; : Filogix ID , &lt;b&gt;Record Name&lt;/b&gt; : test &lt;/a&gt;&lt;/br&gt;',
      JSON.serialize(FilogixWrapperBinding.requiredFieldError)
    );
  }

  static testMethod void requiredFieldsError4() {
    String appNamespace = FilogixWrapperBinding.getAppNameSpace();
    FilogixWrapperBinding.requiredFieldsError(
      'Account',
      appNamespace + 'FilogixId__c',
      '',
      ''
    );
    System.assertNotEquals(
      'null&lt;b&gt;Object&lt;/b&gt; : Residential Loan Application, &lt;b&gt;Field&lt;/b&gt; : Filogix ID , &lt;b&gt;Record Name&lt;/b&gt; : &lt;a href="/ssw"&gt; test &lt;/br&gt;", Actual: "null&lt;b&gt;Object&lt;/b&gt; : Residential Loan Application, &lt;b&gt;Field&lt;/b&gt; : Filogix ID , &lt;b&gt;Record Name&lt;/b&gt; : test &lt;/a&gt;&lt;/br&gt;',
      JSON.serialize(FilogixWrapperBinding.requiredFieldError)
    );
  }
  static testMethod void getFieldApiNamefromParentRelationName_Test() {
    map<string, string> aa = FilogixWrapperBinding.getFieldApiNamefromParentRelationName(
      'Account'
    );
    System.assertNotEquals(aa.isEmpty(), null);
  }

  static testMethod void getFieldPerm_Test() {
    Boolean perm = FilogixWrapperBinding.getFieldPerm(
      'Account',
      'Name',
      'read'
    );
    System.assertNotEquals(perm, false);
  }

  static testMethod void getObjectPerm_Test() {
    Boolean perm = FilogixWrapperBinding.getObjectPerm('Account', 'read');
    System.assertNotEquals(perm, false);
  }

  static testMethod void appendCustomFieldSuffix_Test() {
    string stdFields_of_SfObj = FilogixWrapperBinding.appendCustomFieldSuffix(
      'Subject_Property__r.LoanApplicationId,Subject_Property__r.PropertyValue'
    );
    System.assertEquals(
      stdFields_of_SfObj,
      'Subject_Property__r.LoanApplicationId__c,Subject_Property__r.PropertyValue__c'
    );
  }

  static testMethod void removeStdRelationWithCustom_Test() {
    string relationShipsInCustom = FilogixWrapperBinding.removeStdRelationWithCustom(
      'Account.PersonMailingAddress,Account.Name',
      'Account',
      'AccountId__r'
    );
  }
}
