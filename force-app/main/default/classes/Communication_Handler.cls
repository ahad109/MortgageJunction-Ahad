/**
 * @description       : This class handles all the callouts to the middleware for filogix
 * @author            : M Hamza Siddiqui @ cloudjunction.cloud
 * @group             : Cloudjunction Advisors, Inc.
 * @last modified on  : 07-01-2022
 * @last modified by  : M Hamza Siddiqui
 * Modifications Log
 * -----------------
 * Ver   Date         Author                             		Modification
 * 1.0   01-13-2021   M Hamza Siddiqui @ cloudjunction.cloud   Initial Version
 **/
public with sharing class Communication_Handler implements Queueable {
  public virtual class BaseException extends Exception {
  }
  public class OtherException extends BaseException {
  }

  // Getting Current ORG's MJ Integration Info
  public static MortgageJunction_Config__mdt appConfig = MortgageJunction_Config__mdt.getInstance(
    'Mortgage_Junction_Config'
  );
  public static MJAuth__mdt authConfig = MJAuth__mdt.getInstance('MJ_Auth');
  public static MJ_Setting__mdt settingsRec = MJ_Setting__mdt.getInstance(
    'MJ_Setting'
  );
  public static string keyToVerify = 'accessToken';
  public static string expiryVariable = 'accessTokenExpiresAt';
  public static string accessToken;
  public static Datetime accessTokenExpiry;
  public static Boolean isTokenChanged = false;
  public String accToken;
  public Datetime accTokenExpiry;
  public static String appNameSpace = FilogixWrapperBinding.getAppNameSpace();

  public Communication_Handler(String accessToken, Datetime accessTokenExpiry) {
    this.accToken = accessToken;
    this.accTokenExpiry = accessTokenExpiry;
  }

  // AUTHCONFIG Generator
  public static String authConfigGenerator(String userFilogixId) {
    //System.debug('LoanAppId::' + appId);
    // Generating Filogix AuthConfig String with information provided by the customer.
    return 'clientSystem=CJUNCTION,orgId=' +
      appConfig.OrgId__c +
      ',firmCode=' +
      appConfig.FirmCode__c +
      ',userId=' +
      userFilogixId;
  }

  public static String getToken() {
    // define a response to caller
    String outcomeMsg;

    if (Test.isRunningTest() && isTokenChanged == false) {
      authConfig = new MJAuth__mdt();
      authConfig.Label = 'MJ Auth';
      authConfig.DeveloperName = 'MJ_Auth';
      authConfig.Username__c = 'CLJT';
      authConfig.Password__c = 'CLJT';
    }

    // Checking if authConfig is not null
    if (authConfig != null) {
      // Checking if authConfig.Token_Expiry__c is not expired and if it is, then we will generate a new token
      // Datetime.valueof(DateTime.now()) Generated current date and time in UTC
      if (
        authConfig.Token_Expiry__c != null &&
        authConfig.Token_Expiry__c > Datetime.valueof(DateTime.now())
      ) {
        accessToken = authConfig.Access_Token__c;
        accessTokenExpiry = authConfig.Token_Expiry__c;
        return authConfig.Access_Token__c;
      } else {
        if (
          !String.Isblank(authConfig.Username__c) &&
          !String.Isblank(authConfig.Password__c)
        ) {
          // define basic information for later, store these in a protected custom setting
          string endpoint = settingsRec.Endpoint__c; // be sure this is configured in "Remote Site Settings"
          string resource = '/oauth/token';
          string username = authConfig.Username__c;
          string password = authConfig.Password__c;
          string method = 'POST';
          // string keyToVerify = 'accessToken';
          // string expiryVariable = 'accessTokenExpiresAt';

          // check to ensure a callout can be performed using the Limits class.
          // This is 100 callouts per execution as of Spring 16 release
          if (Limits.getCallouts() >= Limits.getLimitCallouts()) {
            outcomeMsg = 'Error: Maximum number of callouts has been reached.';

            // check for credentials error
          } else if (endpoint == null || username == null || password == null) {
            outcomeMsg =
              'Error: Please verify your API Credentials from the <a target="_blank" href="/lightning/n/' +
              appNameSpace +
              'MortgageJunction_Setup">MortgageJunction Setup</a> screen.';

            // configure and perform the callout
          } else {
            // define transaction variables
            HttpRequest req = new HttpRequest();
            HttpResponse res = new HttpResponse();
            Http h = new Http();

            // Configure the request
            req.setEndpoint(endpoint + resource);
            req.setMethod(method);
            req.setTimeout(120000);

            // Add basic authentication to header
            // Create blob of user:pass
            Blob headerValue = Blob.valueOf(username + ':' + password);
            // Base 64 Encode the blob and prepend "Basic "
            String authorizationHeader =
              'Basic ' + EncodingUtil.base64Encode(headerValue);
            // Add the basic auth string to the Request Header
            req.setHeader('Authorization', authorizationHeader);

            // Configure standard headers
            req.setHeader('Accept', '*/*');
            // This tells the API that we are sending and receiving the data as a JSON object
            //req.setHeader('Content-Type', 'application/json');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

            // Set the body json with the description parameter, basically a string with a key value pair construction.
            req.setBody('grant_type=client_credentials');

            // Attempt the callout - create return error on exception
            try {
              // Perform callout and set response
              res = h.send(req);
              // check response
              if (
                (res.getStatusCode() == 200 ||
                res.getStatusCode() == 201) &&
                res.getBody() != null &&
                res.getBody() != null
              ) {
                // Deserialize the response untyped
                Map<String, Object> untypedMap = (Map<String, Object>) JSON.deserializeUntyped(
                  res.getBody()
                );

                // Check success of deserialization
                if (untypedMap.containsKey(keyToVerify)) {
                  // The deserialized response contains the expected key!
                  outcomeMsg = 'Success!';
                  DateTime dt = (DateTime) JSON.deserialize(
                    '"' + String.valueof(untypedMap.get(expiryVariable)) + '"',
                    DateTime.class
                  );
                  Datetime tokenExpiry = DateTime.newInstance(dt.getTime());
                  system.debug(
                    'Date: ' + String.valueof(untypedMap.get(expiryVariable))
                  );

                  //Updating Global Variables to update CMD later
                  isTokenChanged = true;
                  accessToken = String.valueof(untypedMap.get(keyToVerify));
                  accessTokenExpiry = tokenExpiry;

                  return String.valueof(untypedMap.get(keyToVerify));
                } else {
                  // Resposne doesn't contain the token
                  outcomeMsg =
                    'Error: Please verify your API Credentials from the <a target="_blank" href="/lightning/n/' +
                    appNameSpace +
                    'MortgageJunction_Setup">MortgageJunction Setup</a> screen.';
                }
              } else {
                // callout failed
                outcomeMsg =
                  'Error: Please verify your API Credentials from the <a target="_blank" href="/lightning/n/' +
                  appNameSpace +
                  'MortgageJunction_Setup">MortgageJunction Setup</a> screen.';
              }
            } catch (exception e) {
              // Unexpected exceptions will be caught here, like a deserialization error.
              outcomeMsg =
                'Error: An exception has been encountered while processing your request:  ' +
                e.getMessage();
            }
          }
        }
      }
    } else {
      outcomeMsg =
        'Error: Please setup the app first from the <a target="_blank" href="/lightning/n/' +
        appNameSpace +
        'MortgageJunction_Setup">MortgageJunction Setup</a> screen.';
    }
    // Return the response
    return outcomeMsg;
  }

  // Update Token in CMD

  //public static void updateToken(String accessToken, Datetime accessTokenExpiry) {
  public void execute(QueueableContext context) {
    // Update only when the token is not null
    if (accTokenExpiry != null && accToken != null) {
      sObject cmd = Schema.getGlobalDescribe()
        .get(appNameSpace + 'MJAuth__mdt')
        .newSObject();

      cmd.put('label', 'MJ Auth');
      cmd.put('DeveloperName', 'MJ_Auth');
      cmd.put(appNameSpace + 'Token_Expiry__c', accTokenExpiry);
      cmd.put(appNameSpace + 'Access_Token__c', accToken);

      //UpdateCMD.getConfig();

      List<sObject> sOBjectList = new List<sObject>();
      sOBjectList.add(cmd);
      UpdateCMD.Actions request = new UpdateCMD.Actions();
      request.data = sOBjectList;
      UpdateCMD.updateConfig(new List<UpdateCMD.Actions>{ request });
    }
  }
  // Get Filogix Application
  // Example: Communication_Handler.getFilogixApp(ResidentialLoanApplicationId);
  public static String getFilogixApp(
    string appId,
    String filogixId,
    String mode,
    String userFilogixId
  ) {
    FilogixResponseParsingUtil.checkHeapSize('Callout Entered');
    String tokenResponse = getToken();

    // Token Error Handling
    if (!tokenResponse.startsWith('Error')) {
      /* Removing Feature Param check as there's no need of it anymore */
      /*// Checking if Callouts are allowed
            if (System.FeatureManagement.checkPackageBooleanValue('RestrictFunctions')) {
                //Error exception if Functions are Restricted
                throw new OtherException(System.Label.Package_Restrict);
                //system.debug('Error');
                //return 'Error';
            } else {*/
      if (userFilogixId != null) {
        // Generating Filogix AuthConfig String with information provided by the customer.
        String authconfig = authConfigGenerator(userFilogixId);
        // Getting Subscriber's OrgId
        String subscriberId = UserInfo.getOrganizationId();
        string resBody = '';

        HttpRequest httpReq = new HttpRequest();
        HttpResponse httpRes = new HttpResponse();
        Http http = new Http();
        httpReq.setMethod('GET');

        String data =
          '?subscriberId=' +
          subscriberId +
          '&Live=' +
          appConfig.Is_Live__c +
          '&id=' +
          filogixId +
          '&authconfig=' +
          authconfig;
        system.debug('requestBody::' + data);
        httpReq.setEndPoint(settingsRec.Endpoint__c + '/api/v1/get' + data);
        httpReq.setHeader('Content-Type', 'application/json');
        httpReq.setHeader('Accept', 'application/json');
        // Access Token
        httpReq.setHeader('Authorization', 'Bearer ' + accessToken);
        //httpReq.setBody(requestBody);
        httpReq.setTimeout(120000);
        httpRes = http.send(httpReq);
        FilogixResponseParsingUtil.checkHeapSize('Callout executed');
        //system.debug(httpRes.getBody());
        FilogixResponseParsingUtil.checkHeapSize('Callout debug');

        // Since we're doing a GET request, we don't need to handle for
        // 201, other 'created' responses.
        if (httpRes.getStatusCode() == 200) {
          //system.debug('Response=' + httpRes.getBody());
          FilogixResponseParsingUtil.checkHeapSize(
            'Callout variable assignment'
          );
          resBody = httpRes.getBody();
          /*map<string,object> qbRes = (map<string,object>)JSON.deserializeUntyped(httpRes.getBody());
           String access_token = String.valueOf(qbRes.get('access_token'));*/

          //Once data is received, use the JSON parser to parse the data and update application status.
        }
        //// We're now managing the billing through middleware
        // Logging the Callout record.
        //insertCalloutTransaction((ID)appId,mode,'GET');

        //Updating Token
        if (isTokenChanged == true) {
          //updateToken(accessToken, accessTokenExpiry);
          ID jobID = System.enqueueJob(
            new Communication_Handler(accessToken, accessTokenExpiry)
          );
        }
        FilogixResponseParsingUtil.checkHeapSize('Before return');
        return resBody;
      } else {
        return '';
      }
      //} If END
    } else {
      FilogixResponseParsingUtil.appId = appId;
      FilogixResponseParsingUtil.filogixId = filogixId;
      FilogixResponseParsingUtil.sendNotification(false, tokenResponse);
      return '';
      //throw FilogixWrapperBinding.createCustomException(tokenResponse);
    }
  }

  // POST Filogix Application
  // Example: Communication_Handler.insertFilogixApp(JSON generated by someother class);
  public static String insertFilogixApp(
    String json,
    ID appId,
    String mode,
    String userFilogixId
  ) {
    String tokenResponse = getToken();

    // Token Error Handling
    if (tokenResponse.startsWith('Error')) {
      throw FilogixWrapperBinding.createCustomException(tokenResponse);
    }

    // Checking if Callouts are allowed
    //
    //System.debug('insert filogix app :: JSON ' + json);
    //System.debug('insert filogix app :: appId ' + appId);
    //System.debug('insert filogix app :: mode ' + mode);
    string resBody = '';
    //if(System.FeatureManagement.checkPackageBooleanValue('RestrictFunctions') == TRUE){
    // Error exception if Functions are Restricted
    //throw new OtherException(System.Label.Package_Restrict);
    //return 'Error';
    //} else {
    system.debug('Starting to get MDT values');
    // Generating Filogix AuthConfig String with information provided by the customer.
    String authconfig = authConfigGenerator(userFilogixId);
    // Getting Subscriber's OrgId
    String subscriberId = UserInfo.getOrganizationId();
    // Initializing POST call.
    HttpRequest httpReq = new HttpRequest();
    HttpResponse httpRes = new HttpResponse();
    Http http = new Http();
    httpReq.setMethod('POST');
    String requestBody =
      '{ "subscriberId":"' +
      subscriberId +
      '", "payload":' +
      json +
      ',"authconfig":"' +
      authconfig +
      '","Live":"' +
      appConfig.Is_Live__c +
      '"}';
    //system.debug('requestBody::' + requestBody);
    httpReq.setEndPoint(settingsRec.Endpoint__c + '/api/v1/post');
    httpReq.setHeader('Content-Type', 'application/json');
    httpReq.setHeader('Accept', 'application/json');
    //httpReq.setHeader('Authorization' , 'Basic '+encodedString);
    system.debug('Token::' + accessToken);

    // Access Token
    httpReq.setHeader('Authorization', 'Bearer ' + accessToken);

    httpReq.setTimeout(120000); // To Prevent System.CalloutException: Read timed out - Adding 20s of timeout.
    httpReq.setBody(requestBody);

    System.debug(httpReq);
    System.debug(httpReq.getBody());
    System.debug(httpReq.getHeader('Authorization'));
    System.debug(httpReq.getHeader('Accept'));
    System.debug(httpReq.getHeader('Content-Type'));

    httpRes = http.send(httpReq);

    system.debug(httpRes.getBody());
    system.debug(httpRes.getStatusCode());

    // FOR POST , Handling 201 and other 200 cases
    // if((httpRes.getStatusCode() >= 200 && httpRes.getStatusCode() < 300) && httpRes.getbody() != null)
    // // Removing 200 and other codes check because the LWC is handling the error/success
    if (httpRes.getbody() != null) {
      //system.debug('Response=' + httpRes.getBody());
      resBody = httpRes.getBody();
      /*map<string,object> qbRes = (map<string,object>)JSON.deserializeUntyped(httpRes.getBody());
       String access_token = String.valueOf(qbRes.get('result'));*/

      //Once data is received, use the JSON parser to parse the data and update application status.
    }
    //// We're now managing the billing through middleware
    // Logging the Callout record.
    //insertCalloutTransaction((ID)appId, mode, 'POST');

    //Updating Token
    if (isTokenChanged == true) {
      //updateToken(accessToken, accessTokenExpiry);
      ID jobID = System.enqueueJob(
        new Communication_Handler(accessToken, accessTokenExpiry)
      );
    }

    return resBody;
    //}
  }
}
