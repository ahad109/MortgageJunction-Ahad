/**
 * @description       : Returns a Boolean value of limit exceeded, if limit is not exceeded returns false and increases the Daily and Yearly count by 1
 * @author            : M Hamza Siddiqui
 * @group             : 
 * @last modified on  : 05-26-2022
 * @last modified by  : M Hamza Siddiqui
 * Modifications Log 
 * Ver   Date         Author             Modification
 * 1.0   05-12-2021   M Hamza Siddiqui   Initial Version
**/
//
//Description: 	Returns a Boolean value of limit exceeded, 
//				if limit is not exceeded returns false and increases the Daily and Yearly count by 1
//
public with sharing class CalloutHandler {
   
    public static Plan_Details__mdt details = Plan_Details__mdt.getInstance('Clients_Plan_Details');
    public static MJ_Setting__mdt settingsRec = MJ_Setting__mdt.getInstance('MJ_Setting');
    
    @AuraEnabled
    public static string getMonthlyReport(String [] ListOfMonths){
        try {
            
            //Communication_Handler handlerClass = new Communication_Handler();
            // Getting Token
            String tokenResponse = Communication_Handler.getToken();
        
            // Token Error Handling
            if(tokenResponse.startsWith('Error')){
                throw FilogixWrapperBinding.createCustomException(tokenResponse);
            }
            
            String url = settingsRec.Endpoint__c+'/getMonthlyReport?month=';
            for(String tempMonth: ListOfMonths){
                url+=tempMonth +',';
            }
            //MortgageJunction_Config__mdt Firm = [select FirmCode__c,OrgId__c from MortgageJunction_Config__mdt limit 1];
            // Getting Current ORGs Filogix Integration Info
            MortgageJunction_Config__mdt Firm = MortgageJunction_Config__mdt.getInstance('Mortgage_Junction_Config');
           
            Http h = new Http();
            // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
            HttpRequest req = new HttpRequest();
            
            if(!String.Isblank(Firm.FirmCode__c) && !String.Isblank(UserInfo.getOrganizationId())){
                
                url = url+'&FirmCode='+Firm.FirmCode__c.replaceAll(' ','%20') +'&subscriberId='+UserInfo.getOrganizationId();
                //url = url +'&FirmCode='+Firm.FirmCode__c+'&subscriberId='+UserInfo.getOrganizationId();
                System.debug('URL RECIEVED '+url);
                req.setEndpoint(url);
                req.setMethod('GET');
                // Access Token
                req.setHeader('Authorization', 'Bearer ' + Communication_Handler.accessToken);
                req.setTimeout(120000); // To Prevent System.CalloutException: Read timed out - Adding 20s of timeout.
                // Send the request, and return a response
                HttpResponse res = h.send(req);
                System.debug('res '+ res);
                System.debug('res.getBody() '+ res.getBody());

                //Updating Token
                if (Communication_Handler.isTokenChanged == true) {
                    //Communication_Handler.updateToken(Communication_Handler.accessToken, Communication_Handler.accessTokenExpiry);
                    ID jobID = System.enqueueJob(new Communication_Handler(Communication_Handler.accessToken,Communication_Handler.accessTokenExpiry));
                }

                return (String)res.getBody();
            }
           return '';
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static boolean limitExceeded(){
        boolean limitExceeded = true; 
        System.debug(details);
        System.debug(details.CJA_Mortgage__Call_Date__c.day());
        
        DateTime currentDateTime = datetime.now();
        //if(!details.isEmpty() ){//list is not empty
            if(currentDateTime.year()==details.CJA_Mortgage__Call_Date__c.year()){ //year is same
                system.debug('Comparison='+details.CJA_Mortgage__Call_Date__c.day() + ' & ' + currentDateTime.day());
                if(currentDateTime.day() == details.CJA_Mortgage__Call_Date__c.day()){//day is same
                    if(dailyLimitExceeded() && yearlyLimitExceeded()){//check limit
                        limitExceeded = false;
                        updateAndDeployMetadata();
                    }
                }
                else{//day is different
                    limitExceeded = true;
                    updateAndDeployMetadata();
                }
            }
            else{//year is different
                limitExceeded = true;
                updateAndDeployMetadata();
            }
            
            
        //}
        
        return limitExceeded;
    }
    
    public static boolean dailyLimitExceeded(){
        
        System.debug('dailyLimitExceeded');
        System.debug( details.CJA_Mortgage__Calls_Allowed_Daily__c  );
        System.debug( details.CJA_Mortgage__Calls_Made_Daily__c + 1);
        System.debug( details.CJA_Mortgage__Calls_Allowed_Daily__c >= details.CJA_Mortgage__Calls_Made_Daily__c + 1);
        return details.CJA_Mortgage__Calls_Allowed_Daily__c >= details.CJA_Mortgage__Calls_Made_Daily__c + 1;
        
        
    }
    public static boolean yearlyLimitExceeded(){
        
        System.debug('Yearly Limit');
        System.debug(details.CJA_Mortgage__Calls_Allowed_Yearly__c >= details.CJA_Mortgage__Calls_Made_Yearly__c + 1);
        System.debug(details.CJA_Mortgage__Calls_Allowed_Yearly__c );
        System.debug(details.CJA_Mortgage__Calls_Made_Yearly__c + 1);
        
        return details.CJA_Mortgage__Calls_Allowed_Yearly__c >= details.CJA_Mortgage__Calls_Made_Yearly__c + 1;
        
    }
    
    public static void updateAndDeployMetadata() {
        CJA_Mortgage__Plan_Details__mdt  cmd = New CJA_Mortgage__Plan_Details__mdt();
        // Setup custom metadata to be created in the subscriber org.
        //Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
        //customMetadata.fullName = 'CJA_Mortgage__Plan_Details__mdt.Clients_Plan_Details';
        //
        decimal newCallsMadeDaily = details.CJA_Mortgage__Calls_Made_Daily__c + 1;
        decimal newCallsMadeYearly = details.CJA_Mortgage__Calls_Made_Yearly__c + 1;
        
        cmd.label = 'Clients Plan Details';
        cmd.DeveloperName = 'Clients_Plan_Details';
        cmd.CJA_Mortgage__Calls_Made_Daily__c = newCallsMadeDaily;
        cmd.CJA_Mortgage__Calls_Made_Yearly__c = newCallsMadeYearly;
        cmd.CJA_Mortgage__Call_Date__c = date.today();
        
        /*system.debug('prev calls = '+ details.CJA_Mortgage__Calls_Made_Daily__c);
        Metadata.CustomMetadataValue dailyCalls = new Metadata.CustomMetadataValue();
        Metadata.CustomMetadataValue yearlyCalls = new Metadata.CustomMetadataValue();
        Metadata.CustomMetadataValue dateOfCalls = new Metadata.CustomMetadataValue();
        
        dailyCalls.field = 'CJA_Mortgage__Calls_Made_Daily__c';
        dailyCalls.value = newCallsMadeDaily;
        yearlyCalls.field = 'CJA_Mortgage__Calls_Made_Yearly__c';
        yearlyCalls.value = newCallsMadeYearly;
        dateOfCalls.field = 'CJA_Mortgage__Call_Date__c';
        dateOfCalls.value = datetime.now();*/
        
        /*customMetadata.values.add(dailyCalls);
        customMetadata.values.add(yearlyCalls);
        customMetadata.values.add(dateOfCalls);
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(customMetadata);*/
        
        UpdateCMD.getConfig();
        
        List<sObject> sOBjectList = New List <sObject>();       
        sOBjectList.add(cmd);
        UpdateCMD.Actions request = new UpdateCMD.Actions();
        request.data = sOBjectList;
        UpdateCMD.updateConfig(new List<UpdateCMD.Actions> {request});
        
        // Setup deploy callback, MyDeployCallback implements
        // the Metadata.DeployCallback interface (code for
        // this class not shown in this example)
        //UpdateCMD callback = new UpdateCMD();
        

    }
    
   
    
}