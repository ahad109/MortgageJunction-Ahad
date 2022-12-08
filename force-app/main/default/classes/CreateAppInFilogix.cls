/**
 * @description       : 
 * @author            : M Hamza Siddiqui
 * @group             : 
 * @last modified on  : 06-15-2022
 * @last modified by  : M Hamza Siddiqui
 * Modifications Log 
 * Ver   Date         Author             Modification
 * 1.0   05-12-2021   M Hamza Siddiqui   Initial Version
**/
public class CreateAppInFilogix {
    public class CustomException extends Exception {
    }

    public class ActionRequest{
        @AuraEnabled
        public ID recordId{get;set;}

        @AuraEnabled
        public String result{get;set;}
    }


    @AuraEnabled
    public static String getResidentialLoanApplication(String recordID){
        List<ActionRequest> requests = new List<ActionRequest>();
        ActionRequest request = new ActionRequest();
        request.recordId = recordID;
        requests.add(request);
        List<ActionRequest> results = invokeService(requests);
        if(results.size()>0){
        	return results[0].result;
        } else {
            return 'Error Occured';
        }
    }

    
    public static List<ActionRequest> invokeService(List<ActionRequest> requests){
        // Adding a Namespace
        String appNameSpace = FilogixWrapperBinding.getAppNameSpace();
        try {
            List<ActionRequest> ActionRequests = new List<ActionRequest>();
            System.debug('requests in CreateAppInFilogix '+requests);
            for (ActionRequest requestObj : requests) {
                //Accessing the values from process builder when record is inserted
                //System.debug('requestObj.recId@@:' + requestObj.recordId);
                Id recId = requestObj.recordId;
                //requestObj.result = $label.Success_Message;
                string msgToRet = 'Success';
                string FxAppId = '';
                string userFilogixId;
                
                if (!string.isBlank(recId)) {
                    // Checking Permissions before Query
        			FilogixWrapperBinding.permChecker('ResidentialLoanApplication',appNameSpace+'FilogixId__c, OwnerId', 'read');
                    String query = 'Select id, FilogixId__c, OwnerId from residentialloanapplication where id=:recId WITH SECURITY_ENFORCED limit 1 ';
                    sObject appRec = database.query(String.escapeSingleQuotes(query));

                    FxAppId = String.valueof(appRec.get('FilogixId__c'));
 					
                    // Checking Permissions before Query
        			FilogixWrapperBinding.permChecker('User',appNameSpace+'Filogix_Id__c', 'read');
                    userFilogixId = [Select Id, Filogix_Id__c FROM User WHERE Id =: String.valueof(appRec.get('OwnerId')) WITH SECURITY_ENFORCED].Filogix_Id__c;
                }
                
                if (!string.isBlank(FxAppId)) {
                    requestObj.result = 'Application already exists in Filogix';
                    //throw createCustomException('Application already exists. Try again removing Filogix Id field');
                } else {
                    System.debug('recId in CreateAppInFilogix ' + recId);
                        FilogixWrapperBinding fwb = new FilogixWrapperBinding(recId);
                    try {
                        string json = FilogixWrapperBinding.returnJSON();
                        
                        System.debug('Json in CreateAppInFilogix ' + json);
                        if (json.contains('Required')) {
                            system.debug('Error::' + json);
                            requestObj.result = json;
                            //throw createCustomException(json);
                        } else {
                            string jsonResponse = Communication_Handler.insertFilogixApp(
                                json,
                                (ID) recId,
                                'User',userFilogixId
                            );
                            System.debug('JsonResponse in CreateAppInFilogix ' + jsonResponse);
                            if (jsonResponse.contains('mortgageApplicationId')) {
                                FxAppId = FilogixResponseParsingUtil.ParseResponsePOSTAppId(
                                    jsonResponse
                                );
                            } else {
                                requestObj.result = jsonResponse;
                            }
                            if (!string.isBlank(recId) && !string.isblank(FxAppId)) {
	
                                // Checking Permissions before DML
                				FilogixWrapperBinding.permChecker('ResidentialLoanApplication',appNameSpace+'FilogixId__c', 'update');
                                
                                sObject rla = Schema.getGlobalDescribe().get('residentialloanapplication').newSObject();
                                    
                                rla.put('FilogixId__c',FxAppId);
                                rla.put('id', recId);
                                update rla;
                                requestObj.result = Label.Success_Message;
                            }
                        }
                        ActionRequests.add(requestObj);
                    } catch (exception e) {
                        requestObj.result = e.getMessage() + '-' + e.getLineNumber();
                        //throw createCustomException(e.getMessage() +'-'+ e.getLineNumber());
                    }
                }
            }
            return ActionRequests;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}