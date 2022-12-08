// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

// string tempvar = 'Enter_your_name_here';
// System.debug('Hello World!');
// System.debug('My name is ' + tempvar);

string sjson = '{"result": {"mortgageApplication": {"subjectProperty": {"address": {"countryTypeDd": "Canada"}}}}}';
system.debug('Data'+System.JSON.deserialize(sjson, CJA_Mortgage.FilogixGETJSONWrapper.class));


DecisionLogicWSDLtoApex.IntegrationSoap dli = new DecisionLogicWSDLtoApex.IntegrationSoap();
system.debug('First Test');
string response =dli.CreateRequest4('D23C5H7XFBHZ','8979607d-b995-4127-9297-412a2048f58a','04a939b9-07b3-4595-904a-e824228086f6','sya123','mini','Fatima Test', '56-4325647','999999963',0,'alice@gmail.com');
system.debug('Look!!!' + response);

String rlaId = '0cd4W000000PN54QAG';
CJA_Mortgage.FilogixWrapperBinding fwb = new CJA_Mortgage.FilogixWrapperBinding(rlaId);
system.debug(CJA_Mortgage.FilogixWrapperBinding.returnJSON());


ApplicationSync.updateApp('0cd4W000000PN2eQAG');


string query= 'select fields(all) from loanapplicant limit 10';
list<sObject> applicants = database.query(query);
system.debug(applicants[0].get('contactId'));

String a='1.90';
system.debug('Doubl='+double.valueOf(a));
system.debug('Int='+integer.valueOf(a));


date myDate = date.newInstance(9999, 7, 15);
date newDate = myDate.addYears(-1);
date expectedDate = date.newInstance(2021, 7, 15);
//system.assertEquals(expectedDate, newDate);


system.debug(FilogixGETJSONWrapper.returnGMTformat('9999-12-30T19:00:00-05:00'));




String PArecordTypeId = [SELECT Id, Name, SobjectType,IsPersonType FROM RecordType WHERE SobjectType='Account' AND IsPersonType=True].Id;
                            
String accountObjectApiName ='Account';
        sObject acc = Schema.getGlobalDescribe().get(accountObjectApiName).newSObject();
        
        //Account acc = New Account();
        acc.put('RecordtypeId', PArecordTypeId);
        acc.put('FirstName','Test First Name');
        acc.put('LastName', 'Test Last Name');
        acc.put('PersonMailingCity', 'Toronto');
        acc.put('PersonMailingState', 'Ontario');
        acc.put('PersonMailingCountry', 'CANADA');
        acc.put('PersonMailingPostalCode', 'ON 3131 31');
        acc.put('PersonEmail','test@email.com');
        acc.put('PersonBirthDate', date.today());
        
         
         insert acc;

Id personAccountRecordTypeId;
String sObjT = 'Account';
String personAccountQuery = 'SELECT Id, Name, SobjectType,IsPersonType FROM RecordType WHERE SobjectType=:sObjT AND IsPersonType=True limit 1';
List<sObject> personAccountData = Database.query(personAccountQuery);
if(personAccountData!=null){
    personAccountRecordTypeId = String.valueof(personAccountData[0].Id);
}

 

system.debug(Schema.getGlobalDescribe().get('residentialloanapplication').getDescribe().isCreateable());
system.debug(Schema.sObjectType.residentialloanapplication.isCreateable());

system.debug(Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap().get('PersonMailingAddress').getDescribe().isCreateable());
system.debug(Schema.getGlobalDescribe().get('Account').getDescribe().fields().Name.isCreateable());

FilogixWrapperBinding.permChecker('ResidentialLoanApplication','Account.CJA_Mortgage__Social_Insurance_Number__pc','read');
FilogixWrapperBinding.permChecker('USER','NAME,EMAIL,Department,CompanyName,CJA_Mortgage__Filogix_Id__c, profile.name', 'read');

system.debug(FilogixWrapperBinding.getFieldPerm('LoanApplicantEmployment','LoanApplicant.Contact.FirstName','read'));
FilogixWrapperBinding.permChecker('LoanApplicantEmployment','LoanApplicant.Contact.FirstName','read');
system.debug(Schema.getGlobalDescribe().get('ResidentialLoanApplication').getDescribe().fields.getMap().get('FilogixId__c').getDescribe());
                

List<String> fieldApi;
//String[] arrTest = fieldApiName.split('\.');
String fieldApiName= 'Account.Name';
fieldApi = fieldApiName.split('\\.');
system.debug(fieldApi);
system.debug(fieldApiName.split('\\.'));

 String sObjectName='LoanApplicantAddress'; // replace with your sobject
 String fieldName='LoanApplicant'; // replace with your reference field
 Schema.DescribeFieldResult f = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap().get(fieldName).getDescribe();
 system.debug(f.getType());
for(Schema.SObjectType reference : f.getReferenceTo()) {
    System.debug('Reference object name: ' + reference.getDescribe().getName());
    System.debug('Reference object label: ' + reference.getDescribe().getLabel());
}

public static Boolean GetObjectChildRelations(String objName, String relationshipName){
    List<Selectoption> ListOfChildObjects = new List<Selectoption>();
    SObjectType objObjectType = Schema.getGlobalDescribe().get(objName);
    //it gives object properties or describe results
    Schema.DescribeSObjectResult   describeresult = objObjectType.getDescribe();
    List<Schema.ChildRelationship>   lstchildrelationships =describeresult.getChildRelationships();
    system.debug(JSON.serialize(lstchildrelationships));

	for(Schema.ChildRelationship relname:lstchildrelationships){
        ListOfRelatedObjects.add(new SelectOption(relname.getChildSObject(),relname.getRelationshipName()));
        System.debug('Relationshipname:'+relname.getChildSObject());                      
    }
    return false;
}

public static void GetObjectParentRelations(String objName, String relationshipName){

    for(Schema.SobjectField strFld: Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap().Values()){
        if(strFld.getDescribe().getType() == Schema.DisplayType.REFERENCE){
            system.debug('==parent object Api='+strFld.getDescribe().getName()+' & Relationship name='+strFld.getDescribe().getReferenceTo());
        } 
    }
}
GetObjectParentRelations('LoanApplicantAddress','LoanApplicant');


/* This method will return the field Api Name against object and the parent relationship name 
        Example: getFieldApiNamefromParentRelationName('LoanApplicantAddress','LoanApplicant');
    */
    public static String getFieldApiNamefromParentRelationName(String objName, String relationshipName){
        String fieldApiName='';
        if(!String.isBlank(objName) && !String.isBlank(relationshipName)){

            fieldApiName = relationshipName;
            for(Schema.SobjectField strFld: Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap().Values()){
                if(strFld.getDescribe().getType() == Schema.DisplayType.REFERENCE){
                    system.debug('==parent object Api='+strFld.getDescribe().getName()+' & Relationship name='+strFld.getDescribe().getReferenceTo()[0]);
                    if(relationshipName == String.valueof(strFld.getDescribe().getReferenceTo()[0])){
                        system.debug('matched::'+strFld.getDescribe().getName());
						return strFld.getDescribe().getName();
                    }
                } 
            }
        }
        return fieldApiName;
    }

system.debug(FilogixWrapperBinding.getFieldApiNamefromParentRelationName('LoanApplicationProperty','CJA_Mortgage__Loan_Applicant__r'));

