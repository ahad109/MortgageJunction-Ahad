@isTest
public with sharing class CalloutHandler_Test {
    
    @testVisible static List<Plan_Details__mdt> customMetadata { 
    get {
        if ( customMetadata == null )
            customMetadata = [ SELECT Label, DeveloperName, Call_Date__c FROM Plan_Details__mdt where DeveloperName='Clients_Plan_Details' ]; 
        	//customMetadata = Plan_Details__mdt.getInstance('Clients_Plan_Details');
        return customMetadata;
    } set; }
    
    private class Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            
            // Call the method that performs the callout
            string reportBody = '{"monthlyReport":[{"_id":"606c5ca98765a896ee6ab987","FirmCode":"CLJT","month":"2_2021","subscriberId":"Org-123","count":1},{"_id":"606c67e38765a896ee6ef2f0","FirmCode":"CLJT","month":"3_2021","subscriberId":"Org-123","count":3}]}';
            
            if (req.getEndpoint().endsWith('token')) {
                HTTPResponse res = new HTTPResponse();
                res.setBody('{"accessToken": "450023da7754fee83af3f37090469b3e44fda9a9","accessTokenExpiresAt": "2023-04-25T08:47:37.137Z"}');
                res.setStatusCode(200);
                return res;
            }else if(req.getEndpoint().endsWith(UserInfo.getOrganizationId())){
                HTTPResponse res = new HTTPResponse();
                res.setBody(reportBody);
                res.setStatusCode(200);
                return res;
            } else {
                System.assert(false, 'unexpected endpoint ' + req.getEndpoint());
                return null;
            }
        }
    }
    
     @isTest static void getMonthlyReportTest() {
        // Set mock callout class 
        //Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.setMock(HttpCalloutMock.class, new Mock());
        
        // Call method to test.
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock. 
        List<String> arrayofMonths = new List<String>();
        arrayofMonths.add('2_2021');
        arrayofMonths.add('3_2021');
        
        String res = CalloutHandler.getMonthlyReport(arrayofMonths);
        
        // Verify response received contains fake values
        
        String actualValue = res;
         system.debug('res ' +res);
         
        String expectedValue = '{"monthlyReport":[{"_id":"606c5ca98765a896ee6ab987","FirmCode":"CLJT","month":"2_2021","subscriberId":"Org-123","count":1},{"_id":"606c67e38765a896ee6ef2f0","FirmCode":"CLJT","month":"3_2021","subscriberId":"Org-123","count":3}]}';
        System.assertEquals(actualValue, expectedValue);
        
    }
    
    static testmethod void CalloutHandler_Test(){
          
        customMetadata  = (List<Plan_Details__mdt>) JSON.deserialize('[{"CJA_Mortgage__Call_Date__c":"2022-12-19"}]', List<Plan_Details__mdt>.class );

        Plan_Details__mdt details = Plan_Details__mdt.getInstance('Clients_Plan_Details');
        //system.assertEquals(date.parse('2022-05-12'), customMetadata[0].Call_Date__c);
        
        CalloutHandler.limitExceeded();
        //UpdateCMD.getConfig();
        //List<sObject> sOBjectList = New List <sObject>();       
        //sOBjectList.add(cmd);
        
        //UpdateCMD.Actions request = new UpdateCMD.Actions();
        
        //request.data = sOBjectList;
        
        //UpdateCMD.updateConfig(new List<UpdateCMD.Actions> {request});
        //UpdateCMD.createCustomMetadata('Mortgage Junction Config','Mortgage Junction Config',fieldValuesMap);       
        
    }
    
    
    static testmethod void CalloutHandler_Test_DifferentDay(){
               
        /*Plan_Details__mdt cmd = New Plan_Details__mdt(); 
        Map<String, Object> fields = (Map<String,Object>) JSON.deserializeUntyped(JSON.serializePretty(cmd));
        fields.put(Plan_Details__mdt.Label.getDescribe().getName(),'Clients Plan Details'); 
        fields.put(Plan_Details__mdt.DeveloperName.getDescribe().getName(),'Clients_Plan_Details');
        fields.put(Plan_Details__mdt.Call_Date__c.getDescribe().getName(),date.parse('2020-05-11')); //2020-05-11
        fields.put(Plan_Details__mdt.CJA_Mortgage__Calls_Allowed_Yearly__c.getDescribe().getName(),1000);
        fields.put(Plan_Details__mdt.CJA_Mortgage__Calls_Made_Yearly__c.getDescribe().getName(),900);
        fields.put(Plan_Details__mdt.CJA_Mortgage__Calls_Allowed_Daily__c.getDescribe().getName(),50);
        fields.put(Plan_Details__mdt.CJA_Mortgage__Calls_Made_Daily__c.getDescribe().getName(),48);
        //Map<String, Object> fieldValuesMap = new Map<String, Object> {'UserId__c' => 'AGENT2'};
        cmd = (Plan_Details__mdt) JSON.deserialize(JSON.serialize(fields), Plan_Details__mdt.class);
        
        Plan_Details__mdt details = Plan_Details__mdt.getInstance('Clients_Plan_Details');
        system.assertEquals(date.parse('2020-05-11'), details.Call_Date__c);*/
        
        customMetadata  = (List<Plan_Details__mdt>) JSON.deserialize('[{"CJA_Mortgage__Call_Date__c":"2020-12-19"}]', List<Plan_Details__mdt>.class );

        Plan_Details__mdt details = Plan_Details__mdt.getInstance('Clients_Plan_Details');
        //system.assertEquals(date.parse('2020-05-11'), customMetadata[0].Call_Date__c);
        
        CalloutHandler.limitExceeded();
    }
    
    
	static testmethod void CalloutHandler_Test_DailyLimitExceeded(){
            
        customMetadata  = (List<Plan_Details__mdt>) JSON.deserialize('[{"CJA_Mortgage__Call_Date__c":"2021-05-11"}]', List<Plan_Details__mdt>.class );

        Plan_Details__mdt details = Plan_Details__mdt.getInstance('Clients_Plan_Details');
        //system.assertEquals(date.parse('2021-05-11'), customMetadata[0].Call_Date__c);
        
        CalloutHandler.limitExceeded();
        
       
    }        

    static testmethod void CalloutHandler_Test_DifferentYear(){
                        
        customMetadata  = (List<Plan_Details__mdt>) JSON.deserialize('[{"CJA_Mortgage__Call_Date__c":"2023-05-11"}]', List<Plan_Details__mdt>.class );

        Plan_Details__mdt details = Plan_Details__mdt.getInstance('Clients_Plan_Details');
        //system.assertEquals(date.parse('2023-05-11'), customMetadata[0].Call_Date__c);
        
        CalloutHandler.limitExceeded();
       
    }        
}