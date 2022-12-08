global class FilogixApplicationSyncSchd implements Schedulable {
    global void execute(SchedulableContext sc) {
        /*//Querying Metadata record to for start and end date
        list<MortgageJunction_Config__mdt> listMDT = [select Start_Date__c, End_Date__c from MortgageJunction_Config__mdt 
                                                      where DeveloperName = 'Mortgage_Junction_Config'];
        
        //Checking condition if record exists
        if(listMDT.size() > 0)
        {
            //Assign a variable for today's date to check
            date todayDate = date.today();
            //Checking condition to run execute of scheduler if the today running schedule class is in 
            // the range of start and end date so the batch will run
            
            if(listMDT[0].Start_Date__c != null && listMDT[0].End_Date__c != null 
               && todayDate >= listMDT[0].Start_Date__c && todayDate <= listMDT[0].End_Date__c)
            {
                FilogixApplicationSyncBatch b = new FilogixApplicationSyncBatch(); 
                database.executebatch(b, 20);
            }
            //Checking condition if the end date has passed so to delete the scheduled job
            //from the system
            else if(listMDT[0].End_Date__c != null && todayDate > listMDT[0].End_Date__c)
            {
                for(CronTrigger schJobs: [select id from CronTrigger where CronJobDetail.Name = 'AppStatusSyncFromFilogix'])
                {
                    System.abortJob(schJobs.id);
                }
            }
        }*/
        
        
    }
}