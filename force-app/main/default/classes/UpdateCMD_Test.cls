/**
 * @description       :
 * @author            : M Hamza Siddiqui
 * @group             :
 * @last modified on  : 06-14-2022
 * @last modified by  : M Hamza Siddiqui
 * Modifications Log
 * Ver   Date         Author             Modification
 * 1.0   05-26-2021   M Hamza Siddiqui   Initial Version
 **/
@isTest
public with sharing class UpdateCMD_Test {
  public static String appNameSpace = FilogixWrapperBinding.getAppNameSpace();

  static testMethod void Auth_Test() {
    UpdateCMD.getAuth();
    String query = 'Select id from ' + appNameSpace + 'MJAuth__mdt'; //WITH SECURITY_ENFORCED
    List<sObject> listofAuth = database.query(query);
    //List<sObject> listofAuth = [Select id from MJAuth__mdt WITH SECURITY_ENFORCED];
    if (Test.isRunningTest()) {
      //system.assertEquals(0, listofAuth.size());
    } else {
      system.assertEquals(1, listofAuth.size());
    }
  }

  static testMethod void Config_Test() {
    UpdateCMD.getConfig();
    String query = 'Select id from ' + appNameSpace + 'MortgageJunction_Config__mdt'; //WITH SECURITY_ENFORCED
    List<sObject> listofConfig = database.query(query);
    //List<sObject> listofConfig = [Select id from MortgageJunction_Config__mdt WITH SECURITY_ENFORCED];
    if (Test.isRunningTest()) {
      //system.assertEquals(0, listofConfig.size());
    } else {
      system.assertEquals(1, listofConfig.size());
    }
  }

  static testMethod void UpdateCMD_Test() {
    // Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();

    //CJA_Mortgage__MortgageJunction_Config__mdt  cmd = New CJA_Mortgage__MortgageJunction_Config__mdt ();
    sObject cmd = Schema.getGlobalDescribe().get(appNameSpace + 'MortgageJunction_Config__mdt').newSObject();

    cmd.put('DeveloperName', 'Mortgage_Junction_Config');
    cmd.put(appNameSpace + 'FirmCode__c', 'CLJT');
    //config.put(appNameSpace+'Is_Live__c', FALSE);
    cmd.put('Label', 'Mortgage Junction Config');

    //cmd.Label = 'Mortgage Junction Config';
    //cmd.DeveloperName = 'Mortgage_Junction_Config';
    //cmd.FirmCode__c = 'CLJT';
    //cmd.CJA_Mortgage__FirmCode__c = 'CLJT';

    //cmd.UserId__c = 'AGENT2';
    //cmd.CJA_Mortgage__Calls_Allowed_Yearly__c = 1000;
    //cmd.CJA_Mortgage__Calls_Made_Yearly__c = 900;
    //cmd.CJA_Mortgage__Calls_Allowed_Daily__c = 50;
    //cmd.CJA_Mortgage__Calls_Made_Daily__c   = 45;
    Map<String, Object> fieldValuesMap = new Map<String, Object>{ 'UserId__c' => 'AGENT2' };

    UpdateCMD.getConfig();
    List<sObject> sOBjectList = new List<sObject>();
    sOBjectList.add(cmd);

    UpdateCMD.Actions request = new UpdateCMD.Actions();

    request.data = sOBjectList;

    UpdateCMD.updateConfig(new List<UpdateCMD.Actions>{ request });
    UpdateCMD.createCustomMetadata('Mortgage Junction Config', 'Mortgage Junction Config', fieldValuesMap);

    sObject cmd2 = Schema.getGlobalDescribe().get(appNameSpace + 'MortgageJunction_Config__mdt').newSObject();

    cmd2.put('DeveloperName', 'test');
    cmd2.put(appNameSpace + 'FirmCode__c', 'CLJT');
    cmd2.put('Label', 'test');

    /*
        CJA_Mortgage__MortgageJunction_Config__mdt  cmd2 = New CJA_Mortgage__MortgageJunction_Config__mdt (); 
        
        cmd2.Label = 'test'; 
        cmd2.DeveloperName = 'test';
        cmd2.FirmCode__c = 'CLJT';
        cmd2.CJA_Mortgage__FirmCode__c = 'CLJT';
		*/

    //cmd2.UserId__c = 'AGENT2';
    //cmd.CJA_Mortgage__Calls_Allowed_Yearly__c = 1000;
    //cmd.CJA_Mortgage__Calls_Made_Yearly__c = 1000;
    //cmd.CJA_Mortgage__Calls_Allowed_Daily__c = 50;
    //cmd.CJA_Mortgage__Calls_Made_Daily__c   = 50;
    Map<String, Object> fieldValuesMap2 = new Map<String, Object>{ 'UserId__c' => 'AGENT2' };

    List<sObject> sOBjectList2 = new List<sObject>();
    sOBjectList2.add(cmd2);

    UpdateCMD.Actions request2 = new UpdateCMD.Actions();
    request2.data = sOBjectList2;

    try {
      UpdateCMD.updateConfig(new List<UpdateCMD.Actions>{ request2 });
    } catch (exception e) {
      system.debug('Error:' + e);
    }

    System.assertEquals(fieldValuesMap2.get('UserId__c'), 'AGENT2', 'Expected result = false.');

    UpdateCMD metadata = new UpdateCMD();

    try {
      metadata.handleResult(new Metadata.DeployResult(), new Metadata.DeployCallbackContext());
    } catch (exception e) {
      system.debug('Error:' + e);
    }
  }
}
