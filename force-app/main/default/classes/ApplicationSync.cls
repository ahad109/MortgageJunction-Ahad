/**
 * @description       :
 * @author            : M Hamza Siddiqui
 * @group             :
 * @last modified on  : 07-01-2022
 * @last modified by  : M Hamza Siddiqui
 * Modifications Log
 * Ver   Date         Author             Modification
 * 1.0   05-20-2021   M Hamza Siddiqui   Initial Version
 **/
public with sharing class ApplicationSync {
  public static string objectNameSuffix = '';
  public static string objectNamePrefix = '';

  @AuraEnabled
  public static String updateApp(String recordID) {
    // Adding a Namespace
    String appNameSpace = FilogixWrapperBinding.getAppNameSpace();
    boolean isNonFSC = FilogixResponseParsingUtil.getEnvironmentType();

    if (isNonFSC == true) {
      objectNameSuffix = '__c';
      objectNamePrefix = appNameSpace;
    }

    String fields = appNameSpace + 'FilogixId__c,OwnerId';
    map<string, sObject> mapOfFXIDandAppId = new Map<string, sObject>();
    try {
      String ResidentialLoanApplication =
        objectNamePrefix +
        'ResidentialLoanApplication' +
        objectNameSuffix;
      System.debug('recordID is ==>' + recordID);
      String query =
        'Select id,' +
        fields +
        ' from ' +
        ResidentialLoanApplication +
        ' where id=:recordID WITH SECURITY_ENFORCED';
      List<sObject> rlaRecord = database.query(
        String.escapeSingleQuotes(query)
      );
      System.debug('rlaRecord is ==>' + rlaRecord);
      SObjectAccessDecision rla = Security.stripInaccessible(
        AccessType.READABLE,
        rlaRecord
      );
      system.debug('rla=' + rla.getRecords().size());
      if (
        rla.getRecords().size() > 0 &&
        !String.isBlank(
          String.valueof(rla.getRecords()[0].get(appNameSpace + 'FilogixId__c'))
        )
      ) {
        System.debug('Filogix id exists');
        //Filogix id exists
        mapOfFXIDandAppId.put(
          String.valueof(rla.getRecords()[0].get(appNameSpace + 'FilogixId__c')).toUppercase(),rla.getRecords()[0]);
        //if(requestObj.mode == 'User'){
        FilogixResponseParsingUtil.getAppStatus(mapOfFXIDandAppId);
        //}
      } else {
        System.debug('Filogix Id does not exist');

        //Filogix Id does not exist
        return 'Click "Push to Filogix" first to create app in Filogix';
      }

      //return 'TRUE';
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
    return 'TRUE';
  }

  @AuraEnabled
  public static String createApp(String recId) {
    // Adding a Namespace
    String appNameSpace = FilogixWrapperBinding.getAppNameSpace();
    boolean isNonFSC = FilogixResponseParsingUtil.getEnvironmentType();

    if (isNonFSC == true) {
      objectNameSuffix = '__c';
      objectNamePrefix = appNameSpace;
    }

    try {
      //requestObj.result = $label.Success_Message;
      string msgToRet = 'Success';
      string FxAppId = '';
      String userFilogixId = '';
      String ResidentialLoanApplication =
        objectNamePrefix +
        'ResidentialLoanApplication' +
        objectNameSuffix;

      if (!string.isBlank(recId)) {
        // Checking Permissions before Query
        FilogixWrapperBinding.permChecker(
          ResidentialLoanApplication,
          'ownerId, ' + appNameSpace + 'FilogixId__c',
          'read'
        );
        String query =
          'Select id, ownerId, ' +
          appNameSpace +
          'FilogixId__c from ' +
          ResidentialLoanApplication +
          ' where id=:recId WITH SECURITY_ENFORCED limit 1 ';
        system.debug('appQuery=' + query);
        sObject appRec = database.query(String.escapeSingleQuotes(query));

        FxAppId = String.valueof(appRec.get(appNameSpace + 'FilogixId__c'));

        //ID userId = UserInfo.getUserId(); // Current userid
        //String userQuery = 'select CJA_Mortgage__Filogix_Id__c From User Where Id = :userId';
        //system.debug('userQuery='+userQuery);
        //sObject userRec = database.query(String.escapeSingleQuotes(userQuery));

        //userFilogixId = String.valueof(appRec.get(appNameSpace+'Owner_FilogixId__c'));

        // Replacing the Formula field with the Query to save post-installation step and Unlock package upgrade bug
        // Checking Permissions before Query
        FilogixWrapperBinding.permChecker(
          'User',
          appNameSpace + 'Filogix_Id__c',
          'read'
        );
        userFilogixId = [
          SELECT Id, Filogix_Id__c
          FROM User
          WHERE Id = :String.valueof(appRec.get('OwnerId'))
          WITH SECURITY_ENFORCED
        ]
        .Filogix_Id__c;
      } else {
        return 'Please make sure you are using this action in Residential Loan Application Object or contact the App Developer.';
      }

      if (string.isBlank(userFilogixId)) {
        return 'Application Owner must have Filogix User Mapping assigned - Please use Setup screen to add the mapping';
      } else {
        if (!string.isBlank(FxAppId)) {
          return 'Application already exists in Filogix';
          //throw createCustomException('Application already exists. Try again removing Filogix Id field');
        } else {
          System.debug('recId in CreateAppInFilogix ' + recId);
          FilogixWrapperBinding fwb = new FilogixWrapperBinding(recId);
          try {
            string json = FilogixWrapperBinding.returnJSON();

            System.debug('Json in CreateAppInFilogix ' + json);
            if (json.contains('Required') || json.contains('Trace')) {
              system.debug('Error::' + json);
              return json;
              //throw createCustomException(json);
            } else {
              string jsonResponse = Communication_Handler.insertFilogixApp(
                json,
                (ID) recId,
                'User',
                userFilogixId
              );
              System.debug(
                'JsonResponse in CreateAppInFilogix ' + jsonResponse
              );
              if (jsonResponse.contains('mortgageApplicationId')) {
                FxAppId = FilogixResponseParsingUtil.ParseResponsePOSTAppId(
                  jsonResponse
                );
              } else {
                return jsonResponse;
              }
              if (!string.isBlank(recId) && !string.isblank(FxAppId)) {
                system.debug('RLAObjName::' + ResidentialLoanApplication);
                // Checking Permissions before DML
                FilogixWrapperBinding.permChecker(
                  ResidentialLoanApplication,
                  appNameSpace +
                    'Last_Sync_Date__c, ' +
                    appNameSpace +
                    'FilogixId__c',
                  'update'
                );

                sObject rla = Schema.getGlobalDescribe()
                  .get(ResidentialLoanApplication)
                  .newSObject();
                rla.put(appNameSpace + 'FilogixId__c', FxAppId);
                rla.put(appNameSpace + 'Last_Sync_Date__c', datetime.now());
                rla.put('id', recId);
                update rla;
                return Label.Success_Message;
              }
            }
          } catch (exception e) {
            return e.getMessage() + '-' + e.getLineNumber();
            //throw createCustomException(e.getMessage() +'-'+ e.getLineNumber());
          }
        }
      }
      return 'FALSE';
    } catch (Exception e) {
      system.debug('error:' + e.getMessage());
      throw new AuraHandledException(e.getMessage());
    }
  }
}