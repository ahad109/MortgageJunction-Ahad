@isTest
public class MockHttpResponseForGetFilogix implements HttpCalloutMock {
    // Implement this interface method
    // 
     String resBody;
    
    public MockHttpResponseForGetFilogix(String resBody){
	this.resBody = resBody;
    }
    public HTTPResponse respond(HTTPRequest req) {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
      	res.setBody(resBody);
        res.setStatusCode(200);
        return res;
    }
       
}