/**
* @description       : This invocable class will allow you to update/create customMetadata using Flow/Process Builder.
* @author            : M Hamza Siddiqui @ mhamzas.com
* @group             : Cloudjunction Advisors, Inc.
* @last modified on  : 05-25-2022
* @last modified by  : M Hamza Siddiqui
* Modifications Log
* -----------------
* Ver   Date         Author                             		Modification
* 1.0   01-22-2021   M Hamza Siddiqui @ mhamzas.com		   Initial Version
**/
public with sharing class UpdateCMD implements Metadata.DeployCallback {
    
    public static List<Actions> requestData;
    public static String appNameSpace = FilogixWrapperBinding.getAppNameSpace();
    
    @AuraEnabled
    public static List<sObject> getConfig() {
        List<sObject> listofConfig = new List<sObject>();
        
        try {
            //Looking for existing Metadata Record available
            String metaDataName = 'Mortgage_Junction_Config';
            String query = 'Select Id, '+appNameSpace+'OrgId__c, '+appNameSpace+'FirmCode__c, '+appNameSpace+'Is_Live__c,Label,DeveloperName from '+appNameSpace+'MortgageJunction_Config__mdt where DeveloperName=:metaDataName Limit 1';
            System.debug('Query::'+query);
            listofConfig = database.query(String.escapeSingleQuotes(query));
            
            //sObject appConfig = [Select Id,OrgId__c,FirmCode__c,Is_Live__c,Label,DeveloperName from MortgageJunction_Config__mdt  where QualifiedApiName='Mortgage_Junction_Config' limit 1];
            /*CJA_Mortgage__MortgageJunction_Config__mdt appConfig = CJA_Mortgage__MortgageJunction_Config__mdt.getInstance(
'Mortgage_Junction_Config'
);*/
            system.debug('No records Found' + listofConfig.size());
            // If not available - then create one with dummy values
            if(listofConfig == null || listofConfig.size() == 0 || Test.isRunningTest()){
                //if (appConfig == null || Test.isRunningTest()) {
                system.debug('No records Found');
                /*MortgageJunction_Config__mdt config = new MortgageJunction_Config__mdt();
config.CJA_Mortgage__OrgId__c = '0';
config.CJA_Mortgage__FirmCode__c = 'Enter_FirmCode_Here';
config.CJA_Mortgage__Is_Live__c = false;
config.Label = 'Mortgage Junction Config';*/
                //config.DeveloperName = 'Mortgage_Junction_Config';
                sObject config = Schema.getGlobalDescribe().get(appNameSpace+'MortgageJunction_Config__mdt').newSObject();
                config.put(appNameSpace+'OrgId__c', '0');
                config.put(appNameSpace+'FirmCode__c', 'Enter_FirmCode_Here');
                config.put(appNameSpace+'Is_Live__c', FALSE);
                config.put('Label', 'Mortgage Junction Config');
                
                listofConfig.add(config);
                
                Actions act = new Actions();
                act.data = new List<sObject>{ config };
                    // Create metadata
                    updateConfig(new List<Actions>{ act });
                // Setting required fields back to empty for LWC screen
                //config.OrgId__c = '';
                //config.FirmCode__c = '';
                config.put(appNameSpace+'OrgId__c', '');
                config.put(appNameSpace+'FirmCode__c', '');
            } 
            /*else {
listofConfig.add(appConfig);
}*/
            return listofConfig;
        } catch (Exception e) {
            system.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        //return listofConfig;
    }
    
    @AuraEnabled
    public static List<sObject> getAuth() {
        List<sObject> listofAuth = new List<sObject>(); 
        sObject appAuth;
        try {
            String recordDevName = 'MJ_Auth';
            //Looking for existing Metadata Record available
            //CJA_Mortgage__MJAuth__mdt appAuth = CJA_Mortgage__MJAuth__mdt.getInstance( 'MJ_Auth' );
            String query = 'Select Id, '+appNameSpace+'Username__c, '+appNameSpace+'Password__c,Label,DeveloperName from '+appNameSpace+'MJAuth__mdt WHERE DeveloperName =:recordDevName Limit 1';
            listofAuth = database.query(String.escapeSingleQuotes(query));
            
            //if(appAuthList.size()>0 && appAuthList!=null){
            //appAuth = appAuthList[0];
            
            system.debug('No records Found' + listofAuth.size());
            // If not available - then create one with dummy values
            if (listofAuth == null || listofAuth.size() == 0 || Test.isRunningTest()) {
                //if (appAuth == null || Test.isRunningTest()) {
                system.debug('No records Found');
                //MJAuth__mdt auth = new MJAuth__mdt();
                sObject auth = Schema.getGlobalDescribe().get(appNameSpace+'MJAuth__mdt').newSObject();
                //auth.Username__c = '';
                //auth.Password__c = '';
                //auth.Label = 'MJ Auth';
                auth.put(appNameSpace+'Username__c', '');
                auth.put(appNameSpace+'Password__c', '');
                auth.put('Label', 'MJ Auth');
                listofAuth.add(auth);
                
                Actions act = new Actions();
                act.data = new List<sObject>{ Auth };
                    // Create metadata
                    updateConfig(new List<Actions>{ act });
                
                // Setting required fields back to empty for LWC screen
                //Auth.CJA_Mortgage__Username__c = '';
                //Auth.CJA_Mortgage__Password__c = '';
                Auth.put(appNameSpace+'Username__c', '');
                Auth.put(appNameSpace+'Password__c', '');
                
            } 
            /*else {
listofAuth.add(appAuth);
}*/
            return listofAuth;
        } catch (Exception e) {
            system.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    // @AuraEnabled
    // public static void updateMJSettings(MortgageJunction_Config__mdt obj){
    //     //system.debug(obj);
    //     List<Actions> listofActions = new List<Actions>();
    //     try {
    //         Actions request = new Actions();
    //         request.data = new List<sObject>{obj};
    //         updateConfig(listofActions);
    //     } catch (Exception e) {
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }
    
    public class Actions {
        @AuraEnabled
        public List<sObject> data { get; set; }
    }
    
    // also updating auth in same method
    @AuraEnabled
    public static void updateConfig(List<Actions> requests) {
        requestData = new List<Actions>();
        System.debug('updateConfig req' + JSON.serialize(requests));
        requestData = requests;
        System.debug('requestData::' + JSON.serialize(requestData));
        System.debug('ActualUpdate');
        //System.debug('requestData.size()'+requestData.size());
        FilogixResponseParsingUtil.mDebugUntruncated('requestData::'+JSON.serialize(requestData));
        if(requestData.size()>0 && requestData !=null){
            System.debug('Started');
            for (Actions requestObj : requestData) {
                //Accessing the values from process builder/flow when record is inserted
                for (sObject obj : requestObj.data) {
                    System.debug('requestObj.sObject@@:' + obj);
                    System.debug('requestObj.ObjectType@@:' + obj.getsObjectType());
                    String objectType = String.valueof(obj.getsObjectType());
                    if (objectType.endsWith('__mdt') == true) {
                        // Getting all the Populated fields in a Map
                        Map<String, Object> fieldsToValue = obj.getPopulatedFieldsAsMap();
                        Map<String, Object> metadataFieldValueMap = new Map<String, Object>();
                        String metadataDevName; // To Store Custom Metadata Record API/Developer name
                        String metadataLabel; // To Store Custom Metadata Label name
                        // Looping on all the populated fields
                        for (String fieldName : fieldsToValue.keySet()) {
                            //System.debug('field name is ' + fieldName + ', value is ' + fieldsToValue.get(fieldName));
                            // We don't want to add system fields to the Map for update, so here is some simple logic
                            if (fieldName == 'Label') {
                                metadataLabel = (String) fieldsToValue.get(fieldName);
                            } else if (fieldName == 'DeveloperName') {
                                metadataDevName = (String) fieldsToValue.get(fieldName);
                            } else if (
                                fieldName.endsWith('Made_Daily__c') == true ||
                                fieldName.endsWith('Made_Yearly__c') == true
                            ) {
                                metadataFieldValueMap.put(
                                    fieldName,
                                    integer.valueOf(fieldsToValue.get(fieldName)) + 1
                                );
                            } else if (
                                fieldName != 'Id' &&
                                fieldName != 'Language' &&
                                fieldName != 'MasterLabel' &&
                                fieldName != 'NamespacePrefix' &&
                                fieldName != 'QualifiedApiName'
                            ) {
                                // Populating Map for Processing later
                                metadataFieldValueMap.put(
                                    fieldName,
                                    fieldsToValue.get(fieldName)
                                );
                                //System.debug('Adding::' + fieldName + ' = ' + fieldsToValue.get(fieldName));
                            }
                        }
                        
                        System.debug(
                            'Label is ' +
                            metadataLabel +
                            '& DeveloperName is ' +
                            metadataDevName
                        );
                        // Making sure to have either Label or Developer Name for the CMD record to process
                        if (
                            String.isBlank(metadataDevName) && String.isBlank(metadataLabel)
                        ) {
                            throw createCustomException(
                                'Make sure to add "Label" attribute in assignemnt for Create and "DeveloperName" for update.'
                            );
                        } else {
                            //if metadataDevName available, which means the record exists already - Processing UPDATE
                            if (!String.isBlank(metadataDevName)) {
                                UpdateCMD.updateCustomMetadata(
                                    String.valueof(obj.getSObjectType()),
                                    metadataDevName,
                                    metadataLabel,
                                    metadataFieldValueMap
                                );
                            } else {
                                // Creating a new Custom Metadata record
                                //if ID not available - CREATE
                                UpdateCMD.createCustomMetadata(
                                    String.valueof(obj.getSObjectType()),
                                    metadataLabel,
                                    metadataFieldValueMap
                                );
                            }
                        }
                    } else {
                        throw createCustomException('The Object is not a custom metadata');
                    }
                    //END
                }
            }
        }
    }
    
    /* Custom Metadata Deploy Methods */
    /* ============================================================*/
    //Inteface method
    public void handleResult(
        Metadata.DeployResult result,
        Metadata.DeployCallbackContext context
    ) {
        if (result.status == Metadata.DeployStatus.Succeeded) {
            //Success
            System.debug('Success Result-' + result);
        } else {
            //Failed
            System.debug('Failed Result-' + result);
            throw createCustomException(String.valueof(result));
        }
    }
    
    //Create Custom Metadata record
    public static void createCustomMetadata(
        String metdataName,
        String label,
        Map<String, Object> metadataFieldValueMap
    ) {
        String recordDevName = label.replaceAll(' ', '_');
        Metadata.CustomMetadata cMetadata = new Metadata.CustomMetadata();
        cMetadata.fullName = metdataName + '.' + recordDevName;
        cMetadata.label = label;
        
        for (String key : metadataFieldValueMap.keySet()) {
            Metadata.CustomMetadataValue cMetadataValue = new Metadata.CustomMetadataValue();
            cMetadataValue.Field = key;
            cMetadataValue.Value = metadataFieldValueMap.get(key);
            //System.debug('Adding Val::' + key + ' = ' + metadataFieldValueMap.get(key));
            cMetadata.values.add(cMetadataValue);
        }
        
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(cMetadata);
        UpdateCMD callback = new UpdateCMD();
        if (!Test.isRunningTest()) {
            Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
        }
    }
    
    //Update Custom Metadata record
    public static void updateCustomMetadata(
        String metdataName,
        String recordDevName,
        String label,
        Map<String, Object> metadataFieldValueMap
    ) {
        Metadata.CustomMetadata cMetadata = new Metadata.CustomMetadata();
        cMetadata.fullName = metdataName + '.' + recordDevName;
        cMetadata.label = label;
        //System.debug('cMetadata.fullName == '+ cMetadata.fullName);
        //System.debug('cMetadata.label == '+ cMetadata.label);
        
        // Getting the metadata details for field type mapping for picklist
        // https://help.salesforce.com/articleView?id=000320083&type=1&mode=1
        String objType = metdataName;
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get(objType);
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe()
            .fields.getMap();
        
        for (String key : metadataFieldValueMap.keySet()) {
            Metadata.CustomMetadataValue cMetadataValue = new Metadata.CustomMetadataValue();
            cMetadataValue.Field = key;
            system.debug('key' + key);
            // Checking if the field type is picklist, then add STRING.VALUEOF()
            // https://help.salesforce.com/articleView?id=000320083&type=1&mode=1
            if (
                fieldMap.get(key).getDescribe().getType() == Schema.DisplayType.Picklist
            ) {
                cMetadataValue.Value = String.valueof(metadataFieldValueMap.get(key));
            } else {
                cMetadataValue.Value = metadataFieldValueMap.get(key);
            }
            //System.debug('Adding Val::' + key + ' = ' + metadataFieldValueMap.get(key));
            cMetadata.values.add(cMetadataValue);
        }
        
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(cMetadata);
        UpdateCMD callback = new UpdateCMD();
        
        if (!Test.isRunningTest()) {
            Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
        }
    }
    
    /* Flow Exception Handling */
    /* ============================================================*/
    public class CustomException extends Exception {
    }
    
    static CustomException createCustomException(String message) {
        CustomException ex = new CustomException(message);
        ex.setMessage(message);
        return ex;
    }
}