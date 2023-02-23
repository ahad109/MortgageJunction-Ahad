@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {
  // Implement this interface method
  global HTTPResponse respond(HTTPRequest req) {
    // Optionally, only send a mock response for a specific endpoint
    // and method.

    // Create a fake response
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'application/json');
    res.setBody('{"monthlyReport":[{"_id":"606c5ca98765a896ee6ab987","FirmCode":"CLJT","month":"2_2021","subscriberId":"Org-123","count":1},{"_id":"606c67e38765a896ee6ef2f0","FirmCode":"CLJT","month":"3_2021","subscriberId":"Org-123","count":3}]}');
    res.setStatusCode(200);
    return res;
  }
}
