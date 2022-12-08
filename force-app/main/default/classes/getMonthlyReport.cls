//
//
//
public with sharing class getMonthlyReport {
    @AuraEnabled
    public static string getMonthlyReport(String [] ListOfMonths){
        try {
            
            String url = 'https://monthly-report-tracking.herokuapp.com/getMonthlyReport?month=';
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
                //+'&FirmCode='+(Firm.FirmCode__c).replaceAll(' ','%20')
                String firmCode =Firm.FirmCode__c.replaceAll(' ','%20');
                System.debug('firmCode ' +firmCode);
                url = url+'&FirmCode='+firmCode +'&subscriberId='+UserInfo.getOrganizationId();
                System.debug('URL RECIEVED '+url);
                req.setHeader('Content-type', 'application/json');
                req.setEndpoint(url);
                req.setMethod('GET');
                req.setTimeout(120000); // To Prevent System.CalloutException: Read timed out - Adding 20s of timeout.
                // Send the request, and return a response
                HttpResponse res = h.send(req);
                System.debug('res '+ res);
                System.debug('res.getBody() '+ res.getBody());
                return res.getBody();
            }
           return '';
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}