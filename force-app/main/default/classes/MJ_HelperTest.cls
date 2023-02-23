@isTest
public class MJ_HelperTest {
  @isTest
  public static void setEnvTypeTest() {
    MJ_Helper.setEnvType('FSC');
  }

  /*@isTest
    public static void setEnvTypeTest2() {
        MJ_Helper.setEnvType('Other');
    }*/

  @isTest
  public static void getAppNameSpaceTest() {
    MJ_Helper.getAppNameSpace();
  }
  @isTest
  public static void createCustomException_Test() {
    MJ_Helper.CustomException cls = MJ_Helper.createCustomException('Test');
  }

  @isTest
  public static void getFieldValueFromJson_Test() {
    MJ_Helper.getFieldValueFromJson('{"Test":"Test"}', 'Test');
  }

  @isTest
  public static void getMonthIntergerValue_Test() {
    MJ_Helper.getMonthIntergerValue('Jan');
    MJ_Helper.getMonthIntergerValue('Feb');
    MJ_Helper.getMonthIntergerValue('Mar');
    MJ_Helper.getMonthIntergerValue('Apr');
    MJ_Helper.getMonthIntergerValue('May');
    MJ_Helper.getMonthIntergerValue('Jun');
  }

  @isTest
  public static void AddFieldToObjectsMap_Test() {
    MJ_Helper.AddFieldToObjectsMap('Account', '', new Map<String, Set<String>>());
  }

  @isTest
  public static void AddFieldToObjectsMap_Test2() {
    MJ_Helper.AddFieldToObjectsMap('Account.Name', 'Contact', new Map<String, Set<String>>());
  }

  @isTest
  public static void UserHasAccessToObjectsAndFields_Test() {
    Map<String, Set<String>> dataMap = new Map<String, Set<String>>();
    dataMap.put('Account', new Set<String>{ 'Name' });
    MJ_Helper.UserHasAccessToObjectsAndFields(dataMap);
  }

  @isTest
  public static void GetSobjectField_Test() {
    String objName = 'Account';
    String recordName = 'Salesforce';
    sObject sObj = Schema.getGlobalDescribe().get(objName).newSObject();
    sObj.put('Name', recordName);
    MJ_Helper.GetSobjectField(sObj, 'Name');
  }

  @isTest
  public static void GetSobjectField_Test2() {
    Account acc = new Account(Name = 'Blog Acc 8', FilogixId__c = 'Blog Acc 8');
    Contact cont = new Contact(FirstName = 'Bob', LastName = 'Buzzard', Account = new Account(FilogixId__c = 'Blog Acc 8'));
    List<sObject> records = new List<Sobject>{ acc, cont };
    insert records;

    Contact con = [
      SELECT id, AccountId, Account.Name
      FROM Contact
      WHERE id = :records[1].id
      LIMIT 1
    ];

    MJ_Helper.GetSobjectField(con, 'Account.Name');
  }
}
