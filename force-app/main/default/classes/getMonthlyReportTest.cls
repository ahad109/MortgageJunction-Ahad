@isTest
private class getMonthlyReportTest {
     @isTest static void getMonthlyReportTest() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Call method to test.
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock. 
        List<String> arrayofMonths = new List<String>();
        arrayofMonths.add('2_2021');
        arrayofMonths.add('3_2021');
        
        String res = getMonthlyReport.getMonthlyReport(arrayofMonths);
        
        // Verify response received contains fake values
        
        String actualValue = res;
         system.debug('res ' +res);
         
        String expectedValue = '{"monthlyReport":[{"_id":"606c5ca98765a896ee6ab987","FirmCode":"CLJT","month":"2_2021","subscriberId":"Org-123","count":1},{"_id":"606c67e38765a896ee6ef2f0","FirmCode":"CLJT","month":"3_2021","subscriberId":"Org-123","count":3}]}';
        System.assertEquals(actualValue, expectedValue);
        
    }
}