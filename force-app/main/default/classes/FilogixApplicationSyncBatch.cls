/**
 * @description       : 
 * @author            : M Hamza Siddiqui @ mhamzas.com
 * @group             : 
 * @last modified on  : 06-14-2022
 * @last modified by  : M Hamza Siddiqui
 * Modifications Log 
 * Ver   Date         Author                           Modification
 * 1.0   03-03-2021   M Hamza Siddiqui @ mhamzas.com   Initial Version
**/
global class FilogixApplicationSyncBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
        
        String query = 'Select id, FilogixId__c from ResidentialLoanApplication where FilogixId__c != null WITH SECURITY_ENFORCED';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<ResidentialLoanApplication> scope) {
        
        map<string, string> mapOfFxIDandStatus = new map<string, string>();
        map<string, string> mapOfFxIDandRlaId = new map<string, string>();
        list<ResidentialLoanApplication> listRLAToUpdate = new list<ResidentialLoanApplication>();
        
        if(scope.size() > 0)
        {
            for(ResidentialLoanApplication rla :scope)
            {
                mapOfFxIDandRlaId.put(rla.FilogixId__c, rla.Id);
                
                /*//Calling Web Service Callout
                string appStatus = FilogixResponseParsingUtil.parseResponseGETApp(mapOfFxIDandRlaId.get(rla.FilogixId__c),rla.FilogixId__c);
                //Checking if the response i.e. status is not empty
                //string appStatus='';
                if(!string.isBlank(appStatus))
                {
                    mapOfFxIDandStatus.put(rla.FilogixId__c, appStatus);
                }*/
            }
            
            if(!mapOfFxIDandStatus.isEmpty())
            {
                for(string fxId: mapOfFxIDandStatus.keyset())
                {
                    if(mapOfFxIDandRlaId.containsKey(fxId))
                    {
                        ResidentialLoanApplication rla = new ResidentialLoanApplication();
                        rla.Id = mapOfFxIDandRlaId.get(fxId);
                        rla.Status = mapOfFxIDandStatus.get(fxId);
                        listRLAToUpdate.add(rla);
                    }
                }
            }
            
            if(listRLAToUpdate.size() > 0)
                update listRLAToUpdate;
        }
        
        
    }   
    
    global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations
    }
}