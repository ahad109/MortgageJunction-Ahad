/**
 * @description       : Test Class for UserInfoClass
 * @author            : M Hamza Siddiqui
 * @group             : 
 * @last modified on  : 06-14-2022
 * @last modified by  : M Hamza Siddiqui
 * Modifications Log 
 * Ver   Date         Author             Modification
 * 1.0   05-26-2021   M Hamza Siddiqui   Initial Version
 * 1.0   06-01-2022   M Hamza Siddiqui   Test Class Fixes (User creation in test)
**/
@isTest
public class UserInfoClass_test {
    
    @isTest static void userupdate(){
        // Getting App Namespace
    	String appNameSpace = FilogixWrapperBinding.getAppNameSpace();
        // Checking Permissions before Query
        FilogixWrapperBinding.permChecker('Profile','Id', 'read');
		// Checking Permissions before DML
        FilogixWrapperBinding.permChecker('User',appNameSpace+'Filogix_Id__c,Alias,Email,EmailEncodingKey,LastName,LanguageLocaleKey,LocaleSidKey,ProfileId,TimeZoneSidKey,UserName', 'create');
        // Creating a new user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' WITH SECURITY_ENFORCED]; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, CJA_Mortgage__Filogix_Id__c='Agent2',
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser233@testorg.com');
		insert u;
        
        String data = '[{"CJA_Mortgage__Filogix_Id__c":"thgth","Id":"'+u.Id+'"}]';
		//object myObj = new Object();
        Object object1 = JSON.deserializeUntyped(data);
		UserInfoClass.updateUsers(object1);

        Test.startTest();
		// Checking Permissions before Query
        FilogixWrapperBinding.permChecker('User',appNameSpace+'Filogix_Id__c', 'read');
                                
		String Filogix_ID = [SELECT CJA_Mortgage__Filogix_Id__c FROM USER WHERE User.Id =: u.Id WITH SECURITY_ENFORCED].CJA_Mortgage__Filogix_Id__c;
		System.assert(Filogix_ID =='thgth' ,'Successfully updated ');
        Test.stopTest();
		System.assert(Filogix_ID =='thgth' ,'Successfully updated ');
    }
    
    @isTest static void getUserList(){
        Test.startTest();
        List<User>user = new List<User>();
        user =  UserInfoClass.getUserList();

        //system.assertEquals( user =  UserInfoClass.getUserList(), user);
			//System.assert(condition, msg)
			System.assert(user != null, 'List of user should not be null');
        Test.stopTest();
    }
    
    @isTest static void UserInfoClass_Success() {
        // Getting App Namespace
        String appNameSpace = FilogixWrapperBinding.getAppNameSpace();
        // Checking Permissions before DML
        FilogixWrapperBinding.permChecker('USER','NAME,EMAIL,Department,CompanyName,'+appNameSpace+'Filogix_Id__c, profile.name', 'read');
                                
        String query = 'SELECT NAME,EMAIL,Department,CompanyName,'+appNameSpace+'Filogix_Id__c FROM USER WHERE profile.name != NULL WITH SECURITY_ENFORCED';
        LIST<sObject> userlist = database.query(String.escapeSingleQuotes(query));

        System.assert(userlist!= null, 'Records exists');

        Test.startTest();
        UserInfoClass.getUserInfo();
        List<string> ids = new List<string>();
        UserInfoClass.search('te',ids);
        UserInfoClass.updateUserInfo(userlist);
        Test.stopTest();
        
    }
}