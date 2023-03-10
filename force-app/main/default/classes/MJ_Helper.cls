global with sharing class MJ_Helper {
  global static String appNameSpace = getAppNameSpace();

  public class CustomException extends Exception {
  }

  public static CustomException createCustomException(String message) {
    CustomException ex = new CustomException(message);
    ex.setMessage(message);
    return ex;
  }

  // Getting the Namespace of the current Package
  // Source: https://forcekingdom.wordpress.com/2013/07/08/handling-namespace-prefix-dynamically-in-apex/
  global static String getAppNameSpace() {
    Integer indexOfToken = -1;
    String namespace = '';
    for (Schema.SObjectType type : Schema.getGlobalDescribe().values()) {
      String sobjName = String.valueOf(type);

      if (null != sobjName) {
        indexOfToken = sobjName.indexOf('Mortgage__c');
      }

      if (indexOfToken != -1) {
        namespace = sobjName.substring(0, indexOfToken);
        break;
      }
    }

    return namespace;
  }

  // Getting Current ORG's MJ Integration Info
  global static MortgageJunction_Config__mdt getMJConfig() {
    return MortgageJunction_Config__mdt.getInstance('Mortgage_Junction_Config');
  }

  @AuraEnabled(cacheable=true)
  public static List<sObject> getPersonAccountRecordTypes() {
    try {
      List<sObject> l_Types = new List<sObject>();

      l_Types = [
        SELECT Id, Name, DeveloperName, SobjectType, IsPersonType
        FROM RecordType
        WHERE IsPersonType = TRUE
      ]; // Can include multiple fields,
      // You can get values from custom setting also.
      return l_Types;
    } catch (Exception e) {
      System.debug('Exception: ' + e.getMessage());
      return null;
    }
  }

  global static void setEnvType(String type) {
    // Validating correct Param is passed
    if (type != 'FSC' && type != 'NON-FSC') {
      throw createCustomException('Only pass the value "FSC" or "NON-FSC" to this method');
    }

    // Get Custom MDT sObject for MJ Env Type
    sObject envType = Schema.getGlobalDescribe().get(appNameSpace + 'MJ_Environment_Type__mdt').newSObject();

    // Set the Custom MDT Env Type value
    envType.put(appNameSpace + 'Type__c', type);
    envType.put('Label', 'Enviroment Type');
    envType.put('DeveloperName', 'Enviroment_Type');

    // Create an UpdateCMD.Actions and pass the created MDT record to updateConfig
    List<sObject> sOBjectList = new List<sObject>();
    sOBjectList.add(envType);
    UpdateCMD.Actions request = new UpdateCMD.Actions();
    request.data = sOBjectList;
    UpdateCMD.updateConfig(new List<UpdateCMD.Actions>{ request });
  }

  public static void isPersonAccountEnabled() {
    //return Schema.sObjectType.Account.fields.getMap().containsKey( 'isPersonAccount' );
    // Checking is Person Account is enabled in the org
    if (!Schema.sObjectType.Account.fields.getMap().containsKey('isPersonAccount')) {
      String errorMsg = 'Please <a target="_blank" href="https://developer.salesforce.com/docs/atlas.en-us.financial_services_cloud_admin_guide.meta/financial_services_cloud_admin_guide/fsc_admin_enable_person_acct.htm">Enable the Person Account</a>.';
      throw createCustomException(errorMsg);
    }
  }

  public static boolean getEnvironmentType() {
    // Getting current class' namespace
    String appNameSpace = getAppNameSpace();
    system.debug('NameSpace::' + appNameSpace);

    //String appNameSpace = '';//FilogixWrapperBinding.getAppNameSpace();
    // Retrieving custom metadata to get env type
    boolean isNonFSC = false;
    String envType;
    //Map<String, MJ_Environment_Type__mdt> EnvTypeMap = MJ_Environment_Type__mdt.getAll();

    String metaDataName = 'Enviroment_Type';
    String query = 'Select Id, ' + appNameSpace + 'Type__c, Label,DeveloperName from ' + appNameSpace + 'MJ_Environment_Type__mdt where DeveloperName=:metaDataName Limit 1';
    System.debug('Query::' + query);
    sObject config = database.query(String.escapeSingleQuotes(query));

    envType = String.valueof(config.get(appNameSpace + 'Type__c'));
    //Show Error when Custom Metadata record is not found
    if (envType == null || envType == '') {
      String errorMsg = 'Please specify environment type under Custom MetaData Type.';
      throw createCustomException(errorMsg);
    }

    if (envType == 'NON-FSC') {
      return isNonFSC = true;
    }
    return isNonFSC;
  }

  public static String getFieldValueFromJson(String jsonBody, String fieldName) {
    String returnValue = '';
    JSONParser parser2 = JSON.createParser(jsonBody);

    Integer textCount = 1;
    while (parser2.nextToken() != null) {
      if ((parser2.getCurrentToken() == JSONToken.FIELD_NAME) && (parser2.getText() == fieldName)) {
        parser2.nextToken();
        String jsonValue = parser2.getText();
        System.debug('fieldname = ' + fieldName + 'and jsonValue = ' + jsonValue);
        if (fieldname.equalsIgnoreCase('text')) {
          System.debug('fieldname is text: ' + jsonValue + 'and textcount = ' + textCount);
          if (textCount == 1) {
            System.debug('textcount = 2 : jsonValue = ' + jsonValue);
            returnValue = parser2.getText();
          }

          textCount++;
        } else
          returnValue = parser2.getText();
      }
    }

    return returnValue;
  }

  public static Integer getMonthIntergerValue(String monthStringValue) {
    Integer monthValue = 0;

    if (monthStringValue.equalsIgnoreCase('Jan'))
      monthValue = 1;
    if (monthStringValue.equalsIgnoreCase('Feb'))
      monthValue = 2;
    if (monthStringValue.equalsIgnoreCase('Mar'))
      monthValue = 3;
    if (monthStringValue.equalsIgnoreCase('Apr'))
      monthValue = 4;
    if (monthStringValue.equalsIgnoreCase('May'))
      monthValue = 5;
    if (monthStringValue.equalsIgnoreCase('Jun'))
      monthValue = 6;
    if (monthStringValue.equalsIgnoreCase('Jul'))
      monthValue = 7;
    if (monthStringValue.equalsIgnoreCase('Aug'))
      monthValue = 8;
    if (monthStringValue.equalsIgnoreCase('Sep'))
      monthValue = 9;
    if (monthStringValue.equalsIgnoreCase('Oct'))
      monthValue = 10;
    if (monthStringValue.equalsIgnoreCase('Nov'))
      monthValue = 11;
    if (monthStringValue.equalsIgnoreCase('Dec'))
      monthValue = 12;

    return monthValue;
  }

  public static String GetSobjectField(Sobject e, String lcfield) {
    String returnValue = '';

    Map<String, Object> fieldsToValueMap = e.getPopulatedFieldsAsMap();
    System.debug('######## fieldsToValueMap: ' + fieldsToValueMap);
    Set<String> fieldsSet = new Set<String>();

    fieldsSet = fieldsToValueMap.keySet();
    System.debug('######## fieldsSet: ' + fieldsSet);

    if (lcfield.contains('.')) {
      // than it is a parent-relationship field
      String relName = lcfield.substringBefore('.');
      System.debug('######## relName: ' + relName);
      String relField = lcfield.substringAfter('.');
      System.debug('######## relField: ' + relField);
      if (relField.contains('.')) {
        // than it is a 2 level parent-relationship field
        String relName2 = relField.substringBefore('.');
        System.debug('######## relName2: ' + relName2);
        String relField2 = relField.substringAfter('.');
        System.debug('######## relField2: ' + relField2);
        if (fieldsSet.contains(lcfield))
          returnValue = String.valueOf(e.getSObject(relName).getSObject(relName2).get(relField2));
      } else {
        if (fieldsSet.contains(lcfield)) {
          System.debug('######## 1st level not null: ');
          returnValue = String.valueOf(e.getSObject(relName).get(relField));
        }
      }
    } else {
      if (fieldsSet.contains(lcfield))
        returnValue = String.valueOf(e.get(lcfield));
    }

    return returnValue;
  }

  // CRUD and FLS Helper Methods

  public static void AddFieldToObjectsMap(String fieldName, String initialObjectName, Map<String, Set<String>> theMap) {
    if (fieldName.contains('.')) {
      // than it is a parent-relationship field
      String relName1 = fieldName.substringBefore('.');
      String relField1 = fieldName.substringAfter('.');
      if (relField1.contains('.')) {
        // than it is a 2 level parent-relationship field
        String relName2 = relField1.substringBefore('.');
        String relField2 = relField1.substringAfter('.');

        // Check if it is a custom relationship field
        if (relName2.contains('__r')) {
          // than it is a custom relationship
          // Object name is the field name replacing "__r" for "__c"
          String objectName2 = relName2.replace('__r', '__c');
          AddFieldToMap(relField2, objectName2, theMap);
        } else {
          // than it is a standard relationship field
          // get the standard object name from a list of values (example: Ownerid = User)
        }
      } else {
        // than it is a 1 level parent-relationship field
        // Check if it is a custom relationship field
        if (relName1.contains('__r')) {
          // than it is a custom relationship
          // Object name is the field name replacing "__r" for "__c"
          String objectName1 = relName1.replace('__r', '__c');
          AddFieldToMap(relField1, objectName1, theMap);
        } else {
          // than it is a standard relationship field
          // get the standard object name from a list of values (example: Ownerid = User)
        }
      }
    } else
      AddFieldToMap(fieldName, initialObjectName, theMap);
  }

  private static void AddFieldToMap(String fieldName, String ObjectName, Map<String, Set<String>> theMap) {
    // Check if object name is already on the map of objects and fields
    if (theMap.containsKey(ObjectName)) {
      // if it is, add the field to the set of field names for the object
      Set<String> existingFieldSet = theMap.get(ObjectName);
      existingFieldSet.add(fieldName);
      theMap.put(ObjectName, existingFieldSet);
    } else {
      // if not, add the object name and the field name to the map
      Set<String> newFieldSet = new Set<String>();
      newFieldSet.add(fieldName);
      theMap.put(ObjectName, newFieldSet);
    }
  }

  public static datetime returnGMTformat(string utcTime) {
    if (!String.isBlank(utcTime) && utcTime != null) {
      DateTime dt = DateTime.valueOf(utcTime.replace('T', ' '));

      Integer addyears = 0;
      Integer MaxYearsfromToday = 3999; // Max year allowed by Salesforce is 4000 //System.Today().year() + 100;
      //https://help.salesforce.com/s/articleView?id=000318735&type=1

      // Making sure to have year 1900 minimum & max year to be 100 years from today
      Integer currentYear = dt.year();
      if (currentYear < 1900) {
        addyears = 1900 - currentYear;
      } else if (currentYear > MaxYearsfromToday) {
        addyears = MaxYearsfromToday - currentYear;
      }

      // Adjusting the date w.r.t the years logic above
      if (addyears != 0) {
        dt = dt.addYears(addyears);
      }

      system.debug('UTC Formatted Date => ' + utcTime);
      system.debug('GMT Formatted Date => ' + dt);

      return dt;
    }
    return null;
  }

  public static boolean UserHasAccessToObjectsAndFields(Map<String, Set<String>> theMap) {
    Boolean hasAccess = true;

    if (theMap.size() > 0) {
      System.debug('######## theMap: ' + theMap);
      for (String objectName : theMap.keySet()) {
        System.debug('######## objectName: ' + objectName);
        SObject sObj = Schema.getGlobalDescribe().get(objectName).newSObject();
        Map<String, Schema.SObjectField> m = sObj.getSobjectType().getDescribe().fields.getMap();
        Set<String> objectFieldSet = theMap.get(objectName);

        for (String fieldToCheck : objectFieldSet) {
          System.debug('######## fieldToCheck: ' + fieldToCheck);
          // Check if the user has access to view field
          if (!m.get(fieldToCheck).getDescribe().isAccessible()) {
            System.debug('######## User does not have access to field: ' + fieldToCheck);
            // Pass error to client
            hasAccess = false;
            throw new System.NoAccessException();
          }
          System.debug('######## User has access to field: ' + fieldToCheck);
        }
      }
    }

    return hasAccess;
  }
}
