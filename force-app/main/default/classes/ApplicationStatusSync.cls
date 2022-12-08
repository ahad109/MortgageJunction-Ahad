/*
Author: CloudJunction Advisors, Inc
Description (Old): This class will have Invocable methods and variables
to utilize it in Declarative tools of SFDC (Flows, Process Builders)

Description: This class will have Aura Enabled methods and variables
to utilize it in LWC and AUra components.

*/
public class ApplicationStatusSync {
    
    @AuraEnabled
    public static  List<ActionRequest>  updateFilogix(String recordID){
        // Getting App Namespace
        String appNameSpace = FilogixWrapperBinding.getAppNameSpace();
        
        String field = appNameSpace+'FilogixId__c,OwnerId';
        
        try {
            List<ActionRequest> requests = new List<ActionRequest>();
            ActionRequest request = new ActionRequest();
            
            if(recordID!=null){
                System.debug('recordID is ==>'+recordID  );
                //List<residentialloanapplication> listOfRla = [Select id,CJA_Mortgage__FilogixId__c from ResidentialLoanApplication limit 1];
                String query = 'Select id,'+field+' from ResidentialLoanApplication where id=:recordID WITH SECURITY_ENFORCED limit 1';
                List<sObject> listOfRla = database.query(String.escapeSingleQuotes(query));
                System.debug('listOfRla is ==>'+listOfRla  );
                
                
                if(!String.isBlank(String.valueof(listOfRla[0].get(appNameSpace+'FilogixId__c'))) ){
                    System.debug('Filogix id exists'  );
                    //Filogix id exists

                    request.listOfApps = listOfRla;
                    requests.add(request);
                    request.mode = 'User';


                    System.debug('requests is ==>'+requests  );
                    invokeService(requests);
                }
                else{
                    System.debug('Filogix Id does not exist');
                    
                    //Filogix Id does not exist
                    request.mode = 
                        'Click "Push to Filogix" first to create app in Filogix';
                }
                requests.add(request);
                System.debug('requests is ==>'+requests  );
            }
            return requests;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void invokeService(List < ActionRequest > requests) {
        // Getting App Namespace
        String appNameSpace = FilogixWrapperBinding.getAppNameSpace();
        for (ActionRequest requestObj: requests) {
            //Accessing the values from process builder when record is inserted
            System.debug('requestObj.leadId@@:' + requestObj.mode);
            map<string, sObject> mapOfFXIDandAppId = new map<string, sObject>();
        	mapOfFXIDandAppId.put(String.valueof(requestObj.listOfApps[0].get(appNameSpace+'FilogixId__c')),requestObj.listOfApps[0]);
            //if(requestObj.mode == 'User')
            //{
                FilogixResponseParsingUtil.getAppStatus(mapOfFXIDandAppId);
            //}
            
        }
        
    }

    public class ActionRequest 
    {
        
        @AuraEnabled
        public string mode;
        
        @AuraEnabled
        public list<ResidentialLoanApplication> listOfApps;
    }

    // global class ActionRequest 
    // {
        
    //     @InvocableVariable(required = true description='User, Schedule, Cancel')
    //     public string mode;
        
    //     @InvocableVariable(description='List of Applications (Only pass when Mode is "User")')
    //     public list<ResidentialLoanApplication> listOfApps;
        
    //     /*@InvocableVariable(description='Frequency of Scheduler i.e. Weekly or Monthly')
    //     public string Frequency;
        
    //     @InvocableVariable
    //     public Date StartDate;
        
    //     @InvocableVariable
    //     public Date EndDate;
        
    //     @InvocableVariable(description='If Frequency is Monthly, specific day to Schedule')
    //     public string DayOfMonth;
        
    //     @InvocableVariable(description='Prefered / Desired Time to Start Scheduled Job')
    //     public string PreferedStartTime;
        
    //     @InvocableVariable(description='If Frequency is Weekly, run scheduled job on Mondays only')
    //     public boolean Mon;
        
    //     @InvocableVariable(description='If Frequency is Weekly, run scheduled job on Tuesdays only')
    //     public boolean Tue;
        
    //     @InvocableVariable(description='If Frequency is Weekly, run scheduled job on Wednesdays only')
    //     public boolean Wed;
        
    //     @InvocableVariable(description='If Frequency is Weekly, run scheduled job on Thursdays only')
    //     public boolean Thu;
        
    //     @InvocableVariable(description='If Frequency is Weekly, run scheduled job on Fridays only')
    //     public boolean Fri;
        
    //     @InvocableVariable(description='If Frequency is Weekly, run scheduled job on Saturdays only')
    //     public boolean Sat;
        
    //     @InvocableVariable(description='If Frequency is Weekly, run scheduled job on Sundays only')
    //     public boolean Sun;
        
    //     @InvocableVariable(description='Name of the Scheduled Job to cancel')
    //     public string JobName;*/

    // }
    
    // @InvocableMethod(label = 'Update Application Status')
    // global static void invokeService(List < ActionRequest > requests) {
    //     for (ActionRequest requestObj: requests) {
    //         //Accessing the values from process builder when record is inserted
    //         System.debug('requestObj.leadId@@:' + requestObj.mode);
    //         if(requestObj.mode == 'User')
    //         {
    //             FilogixResponseParsingUtil.getAppStatus(requestObj.listOfApps);
    //         }
    //         /*else if(requestObj.mode == 'Schedule')
    //         {
    //             FilogixResponseParsingUtil.ScheduleApplicationSyncCallout(requestObj.Frequency, requestObj.StartDate, requestObj.EndDate, 
    //                                                                       	requestObj.DayOfMonth, requestObj.PreferedStartTime,
    //                                                  						requestObj.Mon, requestObj.Tue, requestObj.Wed, requestObj.Thu,
    //                                                  						requestObj.Fri, requestObj.Sat, requestObj.Sun);
    //         }
    //         else if(requestObj.mode == 'Cancel')
    //         {
    //             FilogixResponseParsingUtil.AbortScheduledJob(requestObj.JobName);
    //         }*/
    //     }
        
    // }
    
    
    
}