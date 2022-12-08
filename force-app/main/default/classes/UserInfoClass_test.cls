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
  @isTest
  static void userupdate() {
    // Getting App Namespace
    String appNameSpace = FilogixWrapperBinding.getAppNameSpace();
    // Checking Permissions before Query
    FilogixWrapperBinding.permChecker('Profile', 'Id', 'read');
    // Checking Permissions before DML
    FilogixWrapperBinding.permChecker(
      'User',
      appNameSpace +
      'Filogix_Id__c,Alias,Email,EmailEncodingKey,LastName,LanguageLocaleKey,LocaleSidKey,ProfileId,TimeZoneSidKey,UserName',
      'create'
    );
    // Creating a new user
    Profile p = [
      SELECT Id
      FROM Profile
      WHERE Name = 'Standard User'
      WITH SECURITY_ENFORCED
    ];
    User u = new User(
      Alias = 'standt',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      CJA_Mortgage__Filogix_Id__c = 'Agent2',
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'standarduser233@testorg.com'
    );
    insert u;

    String data =
      '[{"CJA_Mortgage__Filogix_Id__c":"thgth","Id":"' +
      u.Id +
      '"}]';
    //object myObj = new Object();
    Object object1 = JSON.deserializeUntyped(data);
    UserInfoClass.updateUsers(object1);

    Test.startTest();
    // Checking Permissions before Query
    FilogixWrapperBinding.permChecker(
      'User',
      appNameSpace + 'Filogix_Id__c',
      'read'
    );

    String Filogix_ID = [
      SELECT CJA_Mortgage__Filogix_Id__c
      FROM USER
      WHERE User.Id = :u.Id
      WITH SECURITY_ENFORCED
    ]
    .CJA_Mortgage__Filogix_Id__c;
    System.assert(Filogix_ID == 'thgth', 'Successfully updated ');
    Test.stopTest();
    System.assert(Filogix_ID == 'thgth', 'Successfully updated ');
  }

  @isTest
  static void getUserList() {
    Test.startTest();
    List<User> user = new List<User>();
    user = UserInfoClass.getUserList();

    //system.assertEquals( user =  UserInfoClass.getUserList(), user);
    //System.assert(condition, msg)
    System.assert(user != null, 'List of user should not be null');
    Test.stopTest();
  }

  @isTest
  static void UserInfoClass_Success() {
    // Getting App Namespace
    String appNameSpace = FilogixWrapperBinding.getAppNameSpace();
    // Checking Permissions before DML
    FilogixWrapperBinding.permChecker(
      'USER',
      'NAME,EMAIL,Department,CompanyName,' +
      appNameSpace +
      'Filogix_Id__c, profile.name',
      'read'
    );

    String query =
      'SELECT NAME,EMAIL,Department,CompanyName,' +
      appNameSpace +
      'Filogix_Id__c FROM USER WHERE profile.name != NULL WITH SECURITY_ENFORCED';
    LIST<sObject> userlist = database.query(String.escapeSingleQuotes(query));

    System.assert(userlist != null, 'Records exists');

    Test.startTest();
    UserInfoClass.getUserInfo();
    List<string> ids = new List<string>();
    UserInfoClass.search('te', ids);
    UserInfoClass.updateUserInfo(userlist);
    Test.stopTest();
  }

  @isTest
  static void testGetFilogixUsers() {
    String filogixId = '7654321';
    User user = createFilogixUser(filogixId);
    // User[] filogixUsers = UserInfoClass.getFilogixUsers();

    List<UserInfoClass.FilogixUsersResult> filogixUsers = UserInfoClass.getFilogixUsers();

    System.assert(
      filogixUsers.size() > 0,
      'Could not retreive stored Filogix User'
    );
  }

  @isTest
  static void testSaveFilogixUsers() {
    String filogixId = '7654321';

    User user = createUser();

    UserInfoClass.saveFilogixUser(user.Id, filogixId);

    User updatedUser = [SELECT Id, Filogix_Id__c FROM User WHERE Id = :user.Id];

    System.assertEquals(
      filogixId,
      updatedUser.Filogix_Id__c,
      'Failed to insert Filogix Id'
    );
  }

  // @isTest
  // static void testSaveDuplicateFilogixUsers() {
  //   String filogixId = '7654321';
  //   User existingUser = createFilogixUser(filogixId);

  //   User newUser = createUser();

  //   Boolean exceptionOccurred = false;

  //   try {
  //     UserInfoClass.saveFilogixUser(newUser.Id, filogixId);
  //   } catch (Exception e) {
  //     exceptionOccurred = true;
  //   }

  //   System.assert(exceptionOccurred, 'duplicate inserted Filogix Id');
  // }

  @isTest
  static void testDeleteFilogixUsers() {
    User user = createUser();

    UserInfoClass.deleteFilogixUser(user.Id);

    User updatedUser = [SELECT Id, Filogix_Id__c FROM User WHERE Id = :user.Id];

    System.assert(
      updatedUser.Filogix_Id__c == null,
      'Failed to delete Filogix Id.'
    );
  }

  private static User createUser() {
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
    Blob b = Crypto.GenerateAESKey(128);
    String h = EncodingUtil.ConvertTohex(b);
    String uid = h.SubString(0, 8);
    User user = new User(
      Alias = uid,
      Email = uid + '@myorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/New_York',
      UserName = uid + '@testorgtestorg.com'
    );

    insert user;

    return user;
  }

  private static User createFilogixUser(String filogixId) {
    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
    Blob b = Crypto.GenerateAESKey(128);
    String h = EncodingUtil.ConvertTohex(b);
    String uid = h.SubString(0, 8);
    User user = new User(
      Alias = uid,
      Email = uid + '@myorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/New_York',
      UserName = uid + '@testorgtestorg.com',
      Filogix_Id__c = filogixId
    );

    insert user;

    return user;
  }
}