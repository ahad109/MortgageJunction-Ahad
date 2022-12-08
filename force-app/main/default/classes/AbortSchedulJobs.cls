global class AbortSchedulJobs {

    global class ActionRequest {
        @InvocableVariable(required = true)
        public string scheduleJobName;
    }
    
    @InvocableMethod(label = 'Abort Schedule Job')
    global static void invokeService(List < ActionRequest > requests) {
        List<String> JobName = new List<String>();
        for (ActionRequest requestObj: requests) {
            //Accessing the values from process builder when record is inserted
            System.debug('requestObj.leadId@@:' + requestObj.scheduleJobName);
            JobName.add(requestObj.scheduleJobName);
        }
        
        for(CronTrigger schJobs: [select id from CronTrigger where CronJobDetail.Name IN : JobName]){
                System.abortJob(schJobs.id);
        }
	}
        
}