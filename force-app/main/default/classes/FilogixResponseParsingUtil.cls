/**
 * @description       :
 * @author            : M Hamza Siddiqui @ mhamzas.com
 * @group             :
 * @last modified on  : 07-15-2022
 * @last modified by  : M Hamza Siddiqui
 * Modifications Log
 * Ver   Date         Author                           Modification
 * 1.0   03-03-2021   M Hamza Siddiqui @ mhamzas.com   Initial Version
 * 1.1   08-29-2021   M Hamza Siddiqui @ mhamzas.com   Other Property and Mortgages Mapping
 * 1.2   12-30-2021   M Hamza Siddiqui @ mhamzas.com   Dynamic Loan Applicants
 * 1.3   02-26-2022   M Hamza Siddiqui @ mhamzas.com   Bug & Mapping Fixes + Account Mapping code change
 **/
public without sharing class FilogixResponseParsingUtil implements Queueable, Database.AllowsCallouts {
  //ErrorJSON Wrapper Class
  public class errorJSON {
    public result result { get; set; }
  }
  public class status {
    public String message { get; set; }
    public String code { get; set; }
  }
  public class result {
    public error error { get; set; }
  }
  public class error {
    public list<status> status { get; set; }
  }
  // End Wrapper Class

  public static String appId;
  public static String filogixId;
  public String filogix_Id;
  public static map<string, sObject> mapOfFXIDandAppId;
  public String rlaId;
  public FilogixGETJSONWrapper app;
  public sObject rla;
  public string rlaOwnerId;

  public FilogixResponseParsingUtil(
    String rlaId,
    String filogix_Id,
    FilogixGETJSONWrapper app,
    String rlaOwner_Id
  ) {
    this.rlaId = rlaId;
    this.app = app;
    this.filogix_Id = filogix_Id;
    this.rlaOwnerId = rlaOwner_Id;
  }

  public static void checkHeapSize(String tag) {
    system.debug(
      tag +
        ': Heap size is ' +
        limits.getHeapSize() +
        ' enforced is ' +
        limits.getLimitHeapSize()
    );
  }

  public static FilogixGETJSONWrapper parseResponseGETApp(sObject rla) {
    //string appId,string ownerId,String filogixId) {
    FilogixGETJSONWrapper deal;
    String appNameSpace = MJ_Helper.getAppNameSpace();
    // Getting Filogix Mapping for this User
    String userFilogixId = [
      SELECT Id, Filogix_Id__c
      FROM User
      WHERE Id = :String.valueof(rla.get('OwnerId'))
      WITH SECURITY_ENFORCED
    ]
    .Filogix_Id__c;
    //checkHeapSize('Before Callout');
    appId = String.valueof(rla.get('Id'));
    filogixId = String.valueof(rla.get(appNameSpace + 'FilogixId__c')).toUppercase();
    string res;
    try {
      res = Communication_Handler.getFilogixApp(
        appId,
        filogixId,
        'User',
        userFilogixId
      );
    } catch (DmlException e) {
      System.debug('DmlException caught: ' + e.getMessage());
    } catch (SObjectException e) {
      System.debug('SObjectException caught: ' + e.getMessage());
    } catch (Exception e) {
      System.debug('Exception caught: ' + e.getMessage());
      // Initiating the custom notification
      //String errorMessage = e.getMessage()!=null?e.getMessage():'An error has occured. Please contact MortgageJunction support.';
      //sendNotification(false,'An error has occured. Please contact MortgageJunction support.');
    }
    //checkHeapSize('Response received');
    //system.debug('Res::'+res);
    if (!string.isBlank(res)) {
      if (!res.contains('"error":{"status"')) {
        checkHeapSize('Parsing');
        return (FilogixGETJSONWrapper) System.JSON.deserialize(
          res,
          FilogixGETJSONWrapper.class
        );
        // DealStatus = r.result.mortgageApplication.deal.statusDd;
        // System.debug('r1='+r);
        // System.debug('r2='+r.result);
        // System.debug('r3='+r.result.mortgageApplication);
        // System.debug('r4='+r.result.mortgageApplication.deal);
        // System.debug('r5='+r.result.mortgageApplication.deal.statusDd);
      } else {
        errorJSON er = (errorJSON) System.JSON.deserialize(
          res,
          errorJSON.class
        );
        sendNotification(
          false,
          String.valueof(er.result.error.status[0].message)
        );
        //throw FilogixWrapperBinding.createCustomException(er.result.error.status[0].message);
      }
    }

    return deal;
  }

  public static void getAppStatus(map<string, sObject> mapOfFXIDandAppId) {
    String appNameSpace = MJ_Helper.getAppNameSpace();
    if (!mapOfFXIDandAppId.isEmpty()) {
      // Creating a map to get JSON response for each APPID
      map<string, FilogixGETJSONWrapper> mapOfFxIDandResponse = new Map<string, FilogixGETJSONWrapper>();
      sObject rla = mapOfFXIDandAppId.values();
      FilogixGETJSONWrapper deal = FilogixResponseParsingUtil.parseResponseGETApp(
        rla
      );
      if (deal != null) {
        ID jobID = System.enqueueJob(
          new FilogixResponseParsingUtil(
            String.valueof(rla.get('Id')),
            String.valueof(rla.get(appNameSpace + 'FilogixId__c')).toUppercase(),
            deal,
            String.valueof(rla.get('ownerId'))
          )
        );
      }
    }
  }

  public static void isPersonAccountEnabled() {
    //return Schema.sObjectType.Account.fields.getMap().containsKey( 'isPersonAccount' );
    // Checking is Person Account is enabled in the org
    if (
      !Schema.sObjectType.Account.fields.getMap().containsKey('isPersonAccount')
    ) {
      String errorMsg = 'Please <a target="_blank" href="https://developer.salesforce.com/docs/atlas.en-us.financial_services_cloud_admin_guide.meta/financial_services_cloud_admin_guide/fsc_admin_enable_person_acct.htm">Enable the Person Account</a>.';
      throw MJ_Helper.createCustomException(errorMsg);
    }
  }

  public static boolean getEnvironmentType() {
    // Getting current class' namespace
    String appNameSpace = MJ_Helper.getAppNameSpace();
    system.debug('NameSpace::' + appNameSpace);

    //String appNameSpace = '';//MJ_Helper.getAppNameSpace();
    // Retrieving custom metadata to get env type
    boolean isNonFSC = false;
    String envType;
    //Map<String, MJ_Environment_Type__mdt> EnvTypeMap = MJ_Environment_Type__mdt.getAll();

    String metaDataName = 'Enviroment_Type';
    String query =
      'Select Id, ' +
      appNameSpace +
      'Type__c, Label,DeveloperName from ' +
      appNameSpace +
      'MJ_Environment_Type__mdt where DeveloperName=:metaDataName Limit 1';
    System.debug('Query::' + query);
    sObject config = database.query(String.escapeSingleQuotes(query));

    //if(EnvTypeMap.containsKey('Enviroment_Type')){
    envType = String.valueof(config.get(appNameSpace + 'Type__c'));
    //}
    //Show Error when Custom Metadata record is not found
    /*else{
            String errorMsg = 'Please specify environment type under Custom MetaData Type.';
            throw FilogixWrapperBinding.createCustomException(errorMsg);  
        }*/

    if (envType == null || envType == '') {
      String errorMsg = 'Please specify environment type under Custom MetaData Type.';
      throw MJ_Helper.createCustomException(errorMsg);
    }

    if (envType == 'NON-FSC') {
      return isNonFSC = true;
    }
    return isNonFSC;
  }

  public void execute(QueueableContext context) {
    FilogixGETJSONWrapper deal;
    String appNameSpace = MJ_Helper.getAppNameSpace();
    appId = rlaId;
    filogixId = filogix_Id;

    //Check the subscriber's org status
    boolean isNonFSC = getEnvironmentType();
    //If Non-FSC populate suffix with __c
    string objNameSuffix = '';
    string objNamePrefix = '';
    string customFieldSuffix = '';

    if (isNonFSC == true) {
      objNameSuffix = '__c';
      customFieldSuffix = '__c';
      objNamePrefix = appNameSpace;
    }
    if (appId != null) {
      // Checking is Person Account is enabled in the org
      isPersonAccountEnabled();

      /* Storing API Names for all the objects */
      String opportuntiyObjectApiName = 'Opportunity';
      String loanApplicationObjectApiName =
        objNamePrefix +
        'ResidentialLoanApplication' +
        objNameSuffix;
      String loanapplicantObjectApiName =
        objNamePrefix +
        'LoanApplicant' +
        objNameSuffix;
      String loanPropertyObjectApiName =
        objNamePrefix +
        'LoanApplicationProperty' +
        objNameSuffix;
      String loanAppAddressObjectApiName =
        objNamePrefix +
        'LoanApplicantAddress' +
        objNameSuffix;
      String propertyExpenseObjectApiName = appNameSpace + 'PropertyExpense__c';
      String downpaymentObjectApiName = appNameSpace + 'Down_Payment_Source__c';
      String accountObjectApiName = 'Account';
      String contactObjectApiName = 'Contact';
      String loanAppEmploymentObjectApiName =
        objNamePrefix +
        'LoanApplicantEmployment' +
        objNameSuffix;
      String loanAppIncomeObjectApiName =
        objNamePrefix +
        'LoanApplicantIncome' +
        objNameSuffix;
      String loanAppAssetObjectApiName =
        objNamePrefix +
        'LoanApplicantAsset' +
        objNameSuffix;
      String loanAssetObjectApiName =
        objNamePrefix +
        'LoanApplicationAsset' +
        objNameSuffix;
      String loanAppLiabilityObjectApiName =
        objNamePrefix +
        'LoanApplicantLiability' +
        objNameSuffix;
      String loanLiabilityObjectApiName =
        objNamePrefix +
        'LoanApplicationLiability' +
        objNameSuffix;
      String loanAppFeeObjectApiName = appNameSpace + 'Application_Fee__c';
      String loanAppSubmissionObjectApiName = appNameSpace + 'Submission__c';
      String loanAppConditionObjectApiName = appNameSpace + 'Condition__c';
      String loanSubmissionObjectApiName = appNameSpace + 'Submission__c';
      String loanConditionUpdateObjectApiName =
        appNameSpace + 'Condition_Update__c';
      String loanDealUpdateObjectApiName =
        appNameSpace + 'Application_Status_Update__c';
      String loanDealObjectApiName = appNameSpace + 'Application_Status__c';
      String mortgageObjectApiName = appNameSpace + 'Mortgage__c';
      String loanAppIdentificationObjectApiName =
        appNameSpace + 'Identification__c';
      String subjectProp_FilogixId;

      /* End */

      string myExternalIDField = appNameSpace + 'FilogixId__c';
      List<sObject> updateApp = new List<sObject>();
      //If LastChangeDate is not Blank, which means application has been updated on Filogix.
      //if (!String.isEmpty((String) app.result.mortgageApplication.lastChangeDate)) {
      system.debug('Status=' + app.result.mortgageApplication.deal.statusDd);
      // Residential Loan Application
      string sQuery =
        'Select Name' +
        ',' +
        appNameSpace +
        'Last_Sync_Date__c, AccountId' +
        customFieldSuffix +
        ' from ';
      //
      //sObject rla = Database.query(String.escapeSingleQuotes('Select Name,OpportunityId,'+appNameSpace+'Last_Sync_Date__c, AccountId from ' +loanApplicationObjectApiName +' where id=: appId WITH SECURITY_ENFORCED limit 1 '));
      sObject rla = Database.query(
        String.escapeSingleQuotes(
          sQuery +
            loanApplicationObjectApiName +
            ' where id=: appId WITH SECURITY_ENFORCED limit 1 '
        )
      );

      //ResidentialLoanApplication rla = [];
      //ResidentialLoanApplication rla = new ResidentialLoanApplication();
      //rla.Id = appId; // app.result.mortgageApplication.sourceApplicationId;

      /*if((Datetime.valueof(rla.get(appNameSpace+'Last_Sync_Date__c')).getTime() - datetime.now().getTime()) /3600000 < 2 ){
String errorMsg = 'The application has been updated recently. Please try again in a while.';
throw FilogixWrapperBinding.createCustomException(errorMsg);
}*/

      rla.put(
        'Filogix_Status__c',
        app.result.mortgageApplication.deal.statusDd
      );
      rla.put(appNameSpace + 'Last_Sync_Date__c', datetime.now()); // Last Sync Date

      rla.put(
        appNameSpace + 'Deal_Type__c',
        app.result.mortgageApplication.deal.dealTypeDd
      );
      rla.put(
        appNameSpace + 'Deal_Purpose__c',
        app.result.mortgageApplication.deal.dealPurposeDd
      );
      rla.put(
        appNameSpace + 'Estimated_Closing_Date__c',
        MJ_Helper.returnGMTformat(
          app.result.mortgageApplication.deal.estimatedClosingDate
        )
      );
      rla.put(
        appNameSpace + 'Financing_Waiver_Date__c',
        MJ_Helper.returnGMTformat(
          app.result.mortgageApplication.deal.financingWaiverDate
        )
      );
      rla.put(
        appNameSpace + 'Referral_Reference_Number__c',
        app.result.mortgageApplication.deal.referralReferenceNo
      );
      rla.put(
        appNameSpace + 'Ref_Improvements_Flag__c',
        booleanFormatting(
          app.result.mortgageApplication.deal.refiImprovementsFlag
        )
      );
      rla.put(
        appNameSpace + 'Ref_Purpose__c',
        app.result.mortgageApplication.deal.refiPurpose
      );
      rla.put(
        appNameSpace + 'Ref_Improvement_Amount__c',
        app.result.mortgageApplication.deal.refiImprovementAmount
      );
      rla.put(
        appNameSpace + 'Ref_Improvement_Description__c',
        app.result.mortgageApplication.deal.refiImprovementsDesc
      );
      rla.put(
        appNameSpace + 'Third_Party_Application_Flag__c',
        booleanFormatting(
          app.result.mortgageApplication.deal.thirdPartyApplicationFlag
        )
      );
      rla.put(
        appNameSpace + 'Tax_Payor__c',
        app.result.mortgageApplication.deal.taxPayorDd
      );
      rla.put(
        appNameSpace + 'FilogixId__c',
        String.valueof(app.result.mortgageApplication.deal.applicationId)
      );
      //rla.put('Id',app.result.mortgageApplication.sourceApplicationId);
      //rla.put(appNameSpace+'Tax_Payor__c', app.result.mortgageApplication.deal.taxPayorDd);

      /*Added by Zain Abbas - Start*/
      rla.put(
        appNameSpace + 'Application_Date__c',
        MJ_Helper.returnGMTformat(
          app.result.mortgageApplication.deal.applicationDate
        )
      );
      rla.put(
        appNameSpace + 'Combined_Gds__c',
        app.result.mortgageApplication.deal.combinedGds != null
          ? app.result.mortgageApplication.deal.combinedGds * 100
          : 0
      );
      rla.put(
        appNameSpace + 'Combined_Ltv__c',
        app.result.mortgageApplication.deal.combinedLtv != null
          ? app.result.mortgageApplication.deal.combinedLtv * 100
          : 0
      );
      rla.put(
        appNameSpace + 'Combined_Tds__c',
        app.result.mortgageApplication.deal.combinedTds != null
          ? app.result.mortgageApplication.deal.combinedTds * 100
          : 0
      );
      rla.put(
        appNameSpace + 'Copy_Id__c',
        app.result.mortgageApplication.deal.copyId
      );
      rla.put(
        appNameSpace + 'Copy_Type__c',
        app.result.mortgageApplication.deal.copyType
      );
      rla.put(
        appNameSpace + 'Status_Date__c',
        MJ_Helper.returnGMTformat(
          app.result.mortgageApplication.deal.statusDate
        )
      );
      /*Added by Zain Abbas - End*/

      // SUBJECT PROPERTY Clone for RLA for Lookup
      sObject lAproperty_Lookup = Schema.getGlobalDescribe()
        .get(loanPropertyObjectApiName)
        .newSObject();
      lAproperty_Lookup.put(
        appNameSpace + 'FilogixId__c',
        String.valueof(
          app.result.mortgageApplication.subjectProperty.propertyId
        )
      );
      // Now assigning this variable there
      //SObjectField SubjPropertyLookup = Schema.getGlobalDescribe().get(l
      //oanApplicationObjectApiName).getDescribe().fields.getMap().get(appNameSpace+'Subject_Property__c');
      // Removing it to prevent error: INVALID_FIELD - Foreign key external ID: 173825 not found for field CJA_Mortgage__FilogixId__c in entity LoanApplicationProperty
      //rla.putSObject(SubjPropertyLookup.getDescribe().getRelationshipName(),lAproperty_Lookup);

      // Requesting Mortgage
      List<FilogixGETJSONWrapper.Mortgage_Z> mortgages = (List<FilogixGETJSONWrapper.Mortgage_Z>) app.result.mortgageApplication.mortgage;
      if (mortgages != null) {
        system.debug('mortgages=' + mortgages);
        for (FilogixGETJSONWrapper.Mortgage_Z mortgage : mortgages) {
          sObject propMortgage = Schema.getGlobalDescribe()
            .get(mortgageObjectApiName)
            .newSObject();
          system.debug('mortgage=' + mortgage);
          propMortgage.put(
            'Name',
            mortgage.mortgageTypeDd + ' - ' + mortgage.loanTypeDd
          );
            
          // Setting RLA OwnerId as Record OwnerId
          PropMortgage.put('ownerId',rlaOwnerId);
            
          propMortgage.put(
            appNameSpace + 'Actual_Payment_Term__c',
            mortgage.actualPaymentTerm
          );
          propMortgage.put(
            appNameSpace + 'Amortization_Term__c',
            mortgage.amortizationTerm
          );
          propMortgage.put(
            appNameSpace + 'Balance_Remaining__c',
            mortgage.balanceRemaining
          );
          propMortgage.put(
            appNameSpace + 'Cash_Back_Amount__c',
            mortgage.cashBackAmt
          );
          propMortgage.put(
            appNameSpace + 'Cash_Back_Override__c',
            booleanFormatting(mortgage.cashBackOverride)
          );
          propMortgage.put(
            appNameSpace + 'Cash_Back_Percentage__c',
            mortgage.cashBackPercentage
          );
          propMortgage.put(
            appNameSpace + 'Commercial__c',
            booleanFormatting(mortgage.commercialFlag)
          );
          propMortgage.put(
            appNameSpace + 'Construction__c',
            booleanFormatting(mortgage.constructionFlag)
          );
          propMortgage.put(
            appNameSpace + 'Existing_Mortgage__c',
            booleanFormatting(mortgage.existingMortgageFlag)
          );
          propMortgage.put(
            appNameSpace + 'Heloc__c',
            booleanFormatting(mortgage.helocFlag)
          );
          propMortgage.put(
            appNameSpace + 'Is_Insured__c',
            booleanFormatting(mortgage.insuredFlag)
          );
          datetime insuranceAdjustDate = MJ_Helper.returnGMTformat(
            mortgage.interestAdjustmentDate
          );
          //propMortgage.put(appNameSpace+'Insurance_Adjustment_Date__c', insuranceAdjustDate);
          propMortgage.put(
            appNameSpace + 'Interest_Adj_Date__c',
            insuranceAdjustDate
          );
          propMortgage.put(
            appNameSpace + 'Interest_Adj_Amount__c',
            mortgage.interestAdjustmentAmount
          );
          propMortgage.put(
            appNameSpace + 'Interest_Compound__c',
            mortgage.interestCompoundDd
          );
          propMortgage.put(
            appNameSpace + 'Is_Interest_Only__c',
            booleanFormatting(mortgage.interestOnlyFlag)
          );
          propMortgage.put(
            appNameSpace + 'Interest_Type__c',
            mortgage.interestTypeDd
          );
          propMortgage.put(
            appNameSpace + 'Line_Of_Business__c',
            mortgage.lineOfBusinessDd
          );
          propMortgage.put(appNameSpace + 'Loan_Type__c', mortgage.loanTypeDd);
          propMortgage.put(
            appNameSpace + 'Mortgage_Type__c',
            mortgage.mortgageTypeDd
          );
          propMortgage.put(
            appNameSpace + 'Mortgage_Insurance_Included__c',
            booleanFormatting(mortgage.mtgInsIncludeFlag)
          );
          propMortgage.put(
            appNameSpace + 'Net_Loan_Amount__c',
            mortgage.netLoanAmount
          );
          propMortgage.put(
            appNameSpace + 'Payment_Frequency__c',
            mortgage.paymentFrequencyDd
          );
          propMortgage.put(
            appNameSpace + 'Payment_Term__c',
            mortgage.paymentTermDd
          );
          propMortgage.put(
            appNameSpace + 'Ref_Blended_Amortization__c',
            booleanFormatting(mortgage.refiBlendedAmortization)
          );
          propMortgage.put(
            appNameSpace + 'Interest_Rate__c',
            mortgage.requestedRate
          );
          propMortgage.put(
            appNameSpace + 'Reverse_Flag__c',
            booleanFormatting(mortgage.reverseFlag)
          );
          propMortgage.put(
            appNameSpace + 'Single_Progressive_Type__c',
            mortgage.singleProgressiveTypeDd
          );
          propMortgage.put(
            appNameSpace + 'Sub_Prime__c',
            booleanFormatting(mortgage.subprimeFlag)
          );
          propMortgage.put(
            appNameSpace + 'Qualify_Rate__c',
            mortgage.qualifyRate
          );
          propMortgage.put(
            appNameSpace + 'FilogixId__c',
            String.valueof(mortgage.mortgageId)
          );
          propMortgage.put(appNameSpace + 'Loan_Application__c', appId);
          propMortgage.put(
            appNameSpace + 'Maturity_Date__c',
            Date.valueof(
              MJ_Helper.returnGMTformat(mortgage.maturityDate)
            )
          );

          propMortgage.put(appNameSpace + 'Premium__c', mortgage.miPremiumPst);
          propMortgage.put(
            appNameSpace + 'Premium_Amount__c',
            mortgage.miPremiumAmount
          );
          propMortgage.put(
            appNameSpace + 'Total_Loan_Amount__c',
            mortgage.totalLoanAmount
          );
          propMortgage.put(
            appNameSpace + 'ltv__c',
            mortgage.ltv != null ? mortgage.ltv * 100 : 0
          );
          propMortgage.put(
            appNameSpace + 'PAndIPaymentAmount__c',
            mortgage.PAndIPaymentAmount
          );
          propMortgage.put(
            appNameSpace + 'PAndIPaymentAmount_Monthly__c',
            mortgage.PAndIPaymentAmountMonthly
          );
          propMortgage.put(
            appNameSpace + 'qualifyingGds__c',
            mortgage.qualifyingGds != null ? mortgage.qualifyingGds * 100 : 0
          );
          propMortgage.put(
            appNameSpace + 'qualifyingTds__c',
            mortgage.qualifyingTds != null ? mortgage.qualifyingTds * 100 : 0
          );

          propMortgage.put(
            appNameSpace + 'First_Payment_Date__c',
            mortgage.firstPaymentDate != null
              ? Date.valueof(MJ_Helper.returnGMTformat(mortgage.firstPaymentDate))
              : null
          );

          /*Added by Zain Abbas - Start*/
          propMortgage.put(
            appNameSpace + 'Current_Mortgage_Number__c',
            mortgage.currentMortgageNumber
          );
          propMortgage.put(
            appNameSpace + 'Effective_Amortization__c',
            mortgage.effectiveAmortization
          );
          propMortgage.put(
            appNameSpace + 'Existing_Mortgage_Holder__c',
            mortgage.existingMortgageHolder
          );
          propMortgage.put(
            appNameSpace + 'Lender_Response_Id__c',
            mortgage.lenderResponseId
          );
          propMortgage.put(
            appNameSpace + 'Lender_Submission_Id__c',
            mortgage.lenderSubmissionId
          );
          propMortgage.put(
            appNameSpace + 'LOC_Repayment_Type__c',
            mortgage.locRepaymentTypeDd
          );
          propMortgage.put(
            appNameSpace + 'Market_Submission__c',
            booleanFormatting(mortgage.marketSubmission)
          );
          propMortgage.put(
            appNameSpace + 'Market_Submission_Number__c',
            mortgage.marketSubmissionNumber
          );
          propMortgage.put(
            appNameSpace + 'MI_Reference_Number__c',
            mortgage.miReferenceNumber
          );
          propMortgage.put(
            appNameSpace + 'Mortgage_Insurer__c',
            mortgage.mortgageInsurerId
          );
          if (mortgage.mtgProd != null) {
            propMortgage.put(
              appNameSpace + 'Prod_MP_Business_Id__c',
              mortgage.mtgProd.mpBusinessId
            );
          }
          propMortgage.put(
            appNameSpace + 'Prod_MP_Business_Id__c',
            mortgage.mtgProductId
          );
          propMortgage.put(
            appNameSpace + 'MTG_Provider_Id__c',
            mortgage.mtgProviderId
          );
          propMortgage.put(
            appNameSpace + 'PAndIPaymentAmountQualify__c',
            mortgage.PAndIPaymentAmountQualify
          );
          propMortgage.put(
            appNameSpace + 'Payoff_Type__c',
            mortgage.payoffTypeDd
          );
          if (mortgage.pricingRateInventory != null) {
            propMortgage.put(
              appNameSpace + 'PRIIndexEffectiveDate__c',
              MJ_Helper.returnGMTformat(
                mortgage.pricingRateInventory.indexEffectiveDate
              )
            );
          }

          propMortgage.put(
            appNameSpace + 'Rate_Guarantee_Length__c',
            mortgage.rateGuaranteeLength
          );
          propMortgage.put(
            appNameSpace + 'Ref_Additional_Information__c',
            mortgage.refiAdditionalInformation
          );
          propMortgage.put(
            appNameSpace + 'Repayment_Type__c',
            mortgage.repaymentTypeDd
          );

          propMortgage.put(
              appNameSpace + 'Status__c',
              mortgage.statusDd
          );

          propMortgage.put(
            appNameSpace + 'Status_Date__c',
            MJ_Helper.returnGMTformat(mortgage.statusDate)
          );
          propMortgage.put(appNameSpace + 'Status__c', mortgage.statusDd);
          if (mortgage.rate != null) {
            propMortgage.put(
              appNameSpace + 'BuyDown_Rate__c',
              mortgage.rate.buyDownRate
            );

            propMortgage.put(
              appNameSpace + 'Discount__c',
              mortgage.rate.discount
            );
            propMortgage.put(
              appNameSpace + 'Premium__c',
              mortgage.rate.premium
            );
            propMortgage.put(
              appNameSpace + 'Net_Rate__c',
              mortgage.rate.netRate
            );
            
          }

          if (mortgage.qualifyDetail != null) {
            propMortgage.put(
              appNameSpace + 'Qualify_Amortization_Term__c',
              mortgage.qualifyDetail.amortizationTerm
            );
            propMortgage.put(
              appNameSpace + 'Qualify_Interest_Compound__c',
              mortgage.qualifyDetail.interestCompoundDd
            );
            propMortgage.put(
              appNameSpace + 'Qualify_Is_Interest_Only__c',
              booleanFormatting(mortgage.qualifyDetail.interestOnlyFlag)
            );
            propMortgage.put(
              appNameSpace + 'Repayment_Type__c',
              mortgage.qualifyDetail.repaymentTypeDd
            );
          }
          propMortgage.put(
            appNameSpace + 'Original_Mortgage_Amount__c',
            mortgage.originalMortgageAmount
          );
          /*Added by Zain Abbas - End*/

          //propMortgage.put(appNameSpace+'Loan_Application_Property__c',rla.get(appNameSpace+'Subject_Property__c'));
          //propMortgage.put(appNameSpace+'Original_Mortgage_Amount__c', mortgage.originalMortgageAmount);

          SObjectField propLookupforMortgage = Schema.getGlobalDescribe()
            .get(mortgageObjectApiName)
            .getDescribe()
            .fields.getMap()
            .get(appNameSpace + 'Loan_Application_Property__c');
          propMortgage.putSObject(
            propLookupforMortgage.getDescribe().getRelationshipName(),
            lAproperty_Lookup
          );

          updateApp.add(propMortgage);

          //Duplicate for Lookup
          sObject propMortgage1 = Schema.getGlobalDescribe()
            .get(mortgageObjectApiName)
            .newSObject();
          propMortgage1.put(
            appNameSpace + 'FilogixId__c',
            String.valueof(mortgage.mortgageId)
          );

          // Application Fee
          List<FilogixGETJSONWrapper.Fees> loanFees = (List<FilogixGETJSONWrapper.Fees>) mortgage.fees;
          if (loanFees != null) {
            for (FilogixGETJSONWrapper.Fees loanFee : loanFees) {
              sObject loanAppFee = Schema.getGlobalDescribe()
                .get(loanAppFeeObjectApiName)
                .newSObject();
              loanAppFee.put(
                appNameSpace + 'Deduct__c',
                booleanFormatting(loanFee.deduct)
              );
              loanAppFee.put(
                appNameSpace + 'FilogixId__c',
                String.valueof(loanFee.dealFeeId)
              );
              loanAppFee.put(appNameSpace + 'Type__c', loanFee.feeId);
              loanAppFee.put(appNameSpace + 'Comments__c', loanFee.feeComments);
              loanAppFee.put(
                appNameSpace + 'Description__c',
                loanFee.feeDescription
              );
              loanAppFee.put('Application__c', appId);
              loanAppFee.put(appNameSpace + 'Amount__c', loanFee.feeAmount);

              // Mapping Lookup
              // Method to dynamically add parent-child lookup (having ExternalID)
              // https://salesforce.stackexchange.com/questions/161801/add-dynamic-lookup-on-contact-to-sobject-with-external-id
              SObjectField mortgageLookup = Schema.getGlobalDescribe()
                .get(loanAppFeeObjectApiName)
                .getDescribe()
                .fields.getMap()
                .get(appNameSpace + 'Mortgage__c');
              loanAppFee.putSObject(
                mortgageLookup.getDescribe().getRelationshipName(),
                propMortgage1
              );
              updateApp.add(loanAppFee);
            }
          }
          // Submissions
          List<FilogixGETJSONWrapper.Submissions> loanSubmissions = (List<FilogixGETJSONWrapper.Submissions>) mortgage.submissions;
          if (loanSubmissions != null) {
            for (
              FilogixGETJSONWrapper.Submissions loanSubmission : loanSubmissions
            ) {
              sObject loanAppSubmission = Schema.getGlobalDescribe()
                .get(loanSubmissionObjectApiName)
                .newSObject();
              loanAppSubmission.put('Application__c', appId);
              SObjectField mortgageLookup = Schema.getGlobalDescribe()
                .get(loanSubmissionObjectApiName)
                .getDescribe()
                .fields.getMap()
                .get(appNameSpace + 'Mortgage__c');
              loanAppSubmission.putSObject(
                mortgageLookup.getDescribe().getRelationshipName(),
                propMortgage1
              );
              loanAppSubmission.put(
                appNameSpace + 'Extended_Review__c',
                booleanFormatting(loanSubmission.submission.extendedReviewFlag)
              );
              loanAppSubmission.put(
                appNameSpace + 'FilogixId__c',
                String.valueof(loanSubmission.submission.lenderSubmissionId)
              );
              loanAppSubmission.put(
                appNameSpace + 'Language__c',
                loanSubmission.submission.language
              );
              loanAppSubmission.put(
                appNameSpace + 'Lender_Name__c',
                loanSubmission.submission.lenderProfile.lenderName
              );
              //loanAppSubmission.put('Name',loanSubmission.submission.lenderProfile.lenderName);

              loanAppSubmission.put(
                appNameSpace + 'Lender_LinkId__c',
                loanSubmission.submission.lenderProfile.linkId
              );
              //loanAppSubmission.put(appNameSpace+'Market_Submission',loanSubmission.submission.marketSubmission);
              loanAppSubmission.put(
                appNameSpace + 'Originator_Notes__c',
                loanSubmission.submission.originatorNotes
              );
              loanAppSubmission.put(
                appNameSpace + 'Request_Time__c',
                MJ_Helper.returnGMTformat(
                  loanSubmission.submission.submitRequestTime
                )
              );
              loanAppSubmission.put(
                appNameSpace + 'Routing_Receiver__c',
                loanSubmission.submission.routingReceiver
              );
              loanAppSubmission.put(
                appNameSpace + 'Routing_Sender__c',
                loanSubmission.submission.routingSender
              );
              loanAppSubmission.put(
                appNameSpace + 'Status__c',
                loanSubmission.submission.submissionStatusDd
              );
              updateApp.add(loanAppSubmission);

              //Duplicate for Lookup
              //To Prevent "MORE THAN 1 External Foriegn Key provided" error
              sObject loanAppSubmission1 = Schema.getGlobalDescribe()
                .get(loanSubmissionObjectApiName)
                .newSObject();
              loanAppSubmission1.put(
                appNameSpace + 'FilogixId__c',
                String.valueof(loanSubmission.submission.lenderSubmissionId)
              );

              // Conditions Update
              List<FilogixGETJSONWrapper.conditionStatusUpdate> loanconditionStatusUpdates = (List<FilogixGETJSONWrapper.conditionStatusUpdate>) loanSubmission.submission.conditionStatusUpdate;
              if (loanconditionStatusUpdates != null) {
                for (
                  FilogixGETJSONWrapper.conditionStatusUpdate loanconditionStatusUpdate : loanconditionStatusUpdates
                ) {
                  sObject loanAppConditionUpdate = Schema.getGlobalDescribe()
                    .get(loanConditionUpdateObjectApiName)
                    .newSObject();
                  // Mapping Lookup
                  // Method to dynamically add parent-child lookup (having ExternalID)
                  // https://salesforce.stackexchange.com/questions/161801/add-dynamic-lookup-on-contact-to-sobject-with-external-id
                  //SObjectField submissionLookup = CJA_Mortgage__Condition_Update__c.CJA_Mortgage__Submission__c;
                  SObjectField submissionLookup = Schema.getGlobalDescribe()
                    .get(loanConditionUpdateObjectApiName)
                    .getDescribe()
                    .fields.getMap()
                    .get(appNameSpace + 'Submission__c');
                  loanAppConditionUpdate.putSObject(
                    submissionLookup.getDescribe().getRelationshipName(),
                    loanAppSubmission1
                  );
                  //Working
                  //loanAppConditionUpdate.putSObject(appNameSpace+'Submission__r',loanAppSubmission);
                  // Mapping Rest of the fields
                  loanAppConditionUpdate.put('Application__c', appId);
                  loanAppConditionUpdate.put(
                    appNameSpace + 'Branch_Address__c',
                    loanconditionStatusUpdate.branchAddressLine
                  );
                  loanAppConditionUpdate.put(
                    appNameSpace + 'Branch_Fax__c',
                    loanconditionStatusUpdate.branchLocalFax
                  );
                  loanAppConditionUpdate.put(
                    appNameSpace + 'Branch_Phone__c',
                    loanconditionStatusUpdate.branchLocalPhone
                  );
                  loanAppConditionUpdate.put(
                    appNameSpace + 'Branch_Toll_Free_Fax__c',
                    loanconditionStatusUpdate.branchTollFreeFax
                  );
                  //loanAppConditionUpdate.put(appNameSpace+'Branch_Toll_Free-Phone__c',loanconditionStatusUpdate.branchTollFreePhone);
                  loanAppConditionUpdate.put(
                    appNameSpace + 'Condition_Time__c',
                    MJ_Helper.returnGMTformat(
                      loanconditionStatusUpdate.conditionTimeStamp
                    )
                  );
                  loanAppConditionUpdate.put(
                    appNameSpace + 'Contact_Email__c',
                    loanconditionStatusUpdate.contactEmail
                  );
                  loanAppConditionUpdate.put(
                    appNameSpace + 'Contact_Fax__c',
                    loanconditionStatusUpdate.contactFax
                  );
                  loanAppConditionUpdate.put(
                    appNameSpace + 'Contact_FirstName__c',
                    loanconditionStatusUpdate.contactFirstName
                  );
                  loanAppConditionUpdate.put(
                    appNameSpace + 'Contact_LastName__c',
                    loanconditionStatusUpdate.contactLastName
                  );
                  loanAppConditionUpdate.put(
                    appNameSpace + 'Contact_Phone__c',
                    loanconditionStatusUpdate.contactPhone
                  );
                  loanAppConditionUpdate.put(
                    appNameSpace + 'Contact_Role__c',
                    loanconditionStatusUpdate.contactRole
                  );
                  loanAppConditionUpdate.put(
                    appNameSpace + 'Description__c',
                    loanconditionStatusUpdate.conditionUpdateNote
                  );
                  loanAppConditionUpdate.put(
                    appNameSpace + 'FilogixId__c',
                    String.valueof(loanconditionStatusUpdate.conditionUpdateId)
                  );
                  loanAppConditionUpdate.put(
                    appNameSpace + 'Ingestion_Time__c',
                    MJ_Helper.returnGMTformat(
                      loanconditionStatusUpdate.ingestionTimeStamp
                    )
                  );
                  loanAppConditionUpdate.put(
                    appNameSpace + 'Lender_Name__c',
                    loanconditionStatusUpdate.lenderName
                  );
                  updateApp.add(loanAppConditionUpdate);

                  //Duplicate for Lookup
                  //To Prevent "MORE THAN 1 External Foriegn Key provided" error
                  sObject loanAppConditionUpdate1 = Schema.getGlobalDescribe()
                    .get(loanConditionUpdateObjectApiName)
                    .newSObject();
                  loanAppConditionUpdate1.put(
                    appNameSpace + 'FilogixId__c',
                    String.valueof(loanconditionStatusUpdate.conditionUpdateId)
                  );

                  // Conditions
                  List<FilogixGETJSONWrapper.conditions> loanconditions = (List<FilogixGETJSONWrapper.conditions>) loanconditionStatusUpdate.conditions;
                  if (loanconditions != null) {
                    for (
                      FilogixGETJSONWrapper.conditions loancondition : loanconditions
                    ) {
                      sObject loanAppCondition = Schema.getGlobalDescribe()
                        .get(loanAppConditionObjectApiName)
                        .newSObject();
                      // Mapping Lookup
                      // Method to dynamically add parent-child lookup (having ExternalID)
                      // https://salesforce.stackexchange.com/questions/161801/add-dynamic-lookup-on-contact-to-sobject-with-external-id
                      //SObjectField submissionLookup = CJA_Mortgage__Condition_Update__c.CJA_Mortgage__Submission__c;
                      String relationFieldCond =
                        appNameSpace + 'Condition_Update__c';
                      SObjectField AppConditionLookup = Schema.getGlobalDescribe()
                        .get(loanAppConditionObjectApiName)
                        .getDescribe()
                        .fields.getMap()
                        .get(relationFieldCond);
                      loanAppCondition.putSObject(
                        AppConditionLookup.getDescribe().getRelationshipName(),
                        loanAppConditionUpdate1
                      );
                      //Working
                      //loanAppConditionUpdate.putSObject(appNameSpace+'Submission__r',loanAppSubmission);
                      // Mapping Rest of the fields
                      //loanAppCondition.put(appNameSpace+'Condition_Update__c',new CJA_Mortgage__Condition_Update__c(CJA_Mortgage__FilogixId__c = String.valueof(loancondition.conditionUpdateId)));
                      loanAppCondition.put(
                        appNameSpace + 'Description__c',
                        loancondition.conditionText
                      );
                      loanAppCondition.put(
                        appNameSpace + 'FilogixId__c',
                        String.valueof(loancondition.conditionId)
                      );
                      loanAppCondition.put(
                        appNameSpace + 'Label__c',
                        loancondition.conditionLabel
                      );
                      loanAppCondition.put(
                        appNameSpace + 'Section_Code__c',
                        loancondition.sectionCode
                      );
                      loanAppCondition.put(
                        appNameSpace + 'Status__c',
                        loancondition.conditionStatus
                      );
                      loanAppCondition.put(
                        appNameSpace + 'Type__c',
                        loancondition.conditionType
                      );
                      updateApp.add(loanAppCondition);
                    }
                  }
                }
              }

              // Deal Status Update
              List<FilogixGETJSONWrapper.DealStatusUpdate> loanSubmissionDealUpdates = (List<FilogixGETJSONWrapper.DealStatusUpdate>) loanSubmission.submission.DealStatusUpdate;
              if (loanSubmissionDealUpdates != null) {
                for (
                  FilogixGETJSONWrapper.DealStatusUpdate loanSubmissionDealUpdate : loanSubmissionDealUpdates
                ) {
                  sObject loanAppDealUpdate = Schema.getGlobalDescribe()
                    .get(loanDealUpdateObjectApiName)
                    .newSObject();
                  // Mapping Lookup
                  // Method to dynamically add parent-child lookup (having ExternalID)
                  // https://salesforce.stackexchange.com/questions/161801/add-dynamic-lookup-on-contact-to-sobject-with-external-id
                  //SObjectField submissionLookup = CJA_Mortgage__Condition_Update__c.CJA_Mortgage__Submission__c;
                  String relationFieldSubm = appNameSpace + 'Submission__c';
                  SObjectField submissionLookup1 = Schema.getGlobalDescribe()
                    .get(loanDealUpdateObjectApiName)
                    .getDescribe()
                    .fields.getMap()
                    .get(relationFieldSubm);
                  loanAppDealUpdate.putSObject(
                    submissionLookup1.getDescribe().getRelationshipName(),
                    loanAppSubmission1
                  );
                  //Working
                  //loanAppConditionUpdate.putSObject(appNameSpace+'Submission__r',loanAppSubmission);
                  // Mapping Rest of the fields
                  //loanAppDealUpdate.put(appNameSpace+'Submission__c',new CJA_Mortgage__Submission__c(CJA_Mortgage__FilogixId__c=String.valueof(loanSubmission.submission.lenderSubmissionId)));
                  loanAppDealUpdate.put('Application__c', appId);
                  String externalId;
                  // Reason: Schema has the field value but not on the SAMPLE Response. As a precautionary getting the external ID from the 1st child.
                  if (loanSubmissionDealUpdate.dealStatusUpdateId != null) {
                    externalId = String.valueof(
                      loanSubmissionDealUpdate.dealStatusUpdateId
                    );
                  } else {
                    externalId = String.valueof(
                      loanSubmissionDealUpdate.dealStatus[0].dealStatusUpdateId
                    );
                  }
                  loanAppDealUpdate.put(
                    appNameSpace + 'FilogixId__c',
                    externalId
                  );
                  loanAppDealUpdate.put(
                    appNameSpace + 'Ingestion_Time__c',
                    MJ_Helper.returnGMTformat(
                      loanSubmissionDealUpdate.ingestionTimeStamp
                    )
                  );
                  loanAppDealUpdate.put(
                    appNameSpace + 'Lender_Name__c',
                    loanSubmissionDealUpdate.lenderName
                  );
                  loanAppDealUpdate.put(
                    appNameSpace + 'Status_Time__c',
                    MJ_Helper.returnGMTformat(
                      loanSubmissionDealUpdate.dealStatusTimeStamp
                    )
                  );
                  updateApp.add(loanAppDealUpdate);

                  //Duplicate for Lookup
                  //To Prevent "MORE THAN 1 External Foriegn Key provided" error
                  sObject loanAppDealUpdate1 = Schema.getGlobalDescribe()
                    .get(loanDealUpdateObjectApiName)
                    .newSObject();
                  loanAppDealUpdate1.put(
                    appNameSpace + 'FilogixId__c',
                    String.valueof(externalId)
                  );

                  // Deal Status
                  List<FilogixGETJSONWrapper.DealStatus> loanSubmissionDeals = (List<FilogixGETJSONWrapper.DealStatus>) loanSubmissionDealUpdate.dealStatus;
                  if (loanSubmissionDeals != null) {
                    for (
                      FilogixGETJSONWrapper.DealStatus loanSubmissionDeal : loanSubmissionDeals
                    ) {
                      sObject loanAppSubmissionDeal = Schema.getGlobalDescribe()
                        .get(loanDealObjectApiName)
                        .newSObject();
                      // Mapping Lookup
                      // Method to dynamically add parent-child lookup (having ExternalID)
                      // https://salesforce.stackexchange.com/questions/161801/add-dynamic-lookup-on-contact-to-sobject-with-external-id
                      //SObjectField submissionLookup = CJA_Mortgage__Condition_Update__c.CJA_Mortgage__Submission__c;
                      String relationFieldAppStatus =
                        appNameSpace + 'Application_Status_Update__c';
                      SObjectField dealUpdateLookup = Schema.getGlobalDescribe()
                        .get(loanDealObjectApiName)
                        .getDescribe()
                        .fields.getMap()
                        .get(relationFieldAppStatus);
                      //loanAppSubmissionDeal.putSObject(dealUpdateLookup.getDescribe().getRelationshipName(),loanAppDealUpdate);
                      //system.debug('loanAppDealUpdate::'+loanAppDealUpdate);
                      loanAppSubmissionDeal.putSObject(
                        appNameSpace + 'Application_Status_Update__r',
                        loanAppDealUpdate1
                      );
                      //Working
                      //loanAppConditionUpdate.putSObject(appNameSpace+'Submission__r',loanAppSubmission);
                      // Mapping Rest of the fields
                      //loanAppSubmissionDeal.put(appNameSpace+'Application_Status_Update__c',new CJA_Mortgage__Application_Status_Update__c(CJA_Mortgage__FilogixId__c = String.valueof(loanSubmissionDealUpdate.dealStatusUpdateId)));
                      loanAppSubmissionDeal.put(
                        appNameSpace + 'Description__c',
                        loanSubmissionDeal.statusText
                      );
                      loanAppSubmissionDeal.put(
                        appNameSpace + 'FilogixId__c',
                        String.valueof(loanSubmissionDeal.dealStatusId)
                      );
                      loanAppSubmissionDeal.put(
                        appNameSpace + 'Type__c',
                        loanSubmissionDeal.statusType
                      );
                      loanAppSubmissionDeal.put(
                        appNameSpace + 'TypeId__c',
                        loanSubmissionDeal.statusTypeDd
                      );
                      updateApp.add(loanAppSubmissionDeal);
                    }
                  }
                }
              }

              // Responses
              List<FilogixGETJSONWrapper.Responses> loanResponses = (List<FilogixGETJSONWrapper.Responses>) loanSubmission.submission.responses;
              if (loanResponses != null) {
                for (
                  FilogixGETJSONWrapper.Responses loanResponse : loanResponses
                ) {
                  String loanResponsesObjectApiName =
                    appNameSpace + 'Response__c';
                  sObject loanAppResponse = Schema.getGlobalDescribe()
                    .get(loanResponsesObjectApiName)
                    .newSObject();
                  // Mapping Lookup
                  // Method to dynamically add parent-child lookup (having ExternalID)
                  // https://salesforce.stackexchange.com/questions/161801/add-dynamic-lookup-on-contact-to-sobject-with-external-id
                  //SObjectField submissionLookup = CJA_Mortgage__Condition_Update__c.CJA_Mortgage__Submission__c;
                  String relationFieldSubmission =
                    appNameSpace + 'Submission__c';
                  SObjectField submissionLookup2 = Schema.getGlobalDescribe()
                    .get(loanResponsesObjectApiName)
                    .getDescribe()
                    .fields.getMap()
                    .get(relationFieldSubmission);
                  loanAppResponse.putSObject(
                    submissionLookup2.getDescribe().getRelationshipName(),
                    loanAppSubmission1
                  );
                  //Working
                  //loanAppConditionUpdate.putSObject(appNameSpace+'Submission__r',loanAppSubmission);
                  // Mapping Rest of the fields
                  loanAppResponse.put(
                    appNameSpace + 'affiliation_Group__c',
                    loanResponse.affiliationGroup
                  );
                  loanAppResponse.put(
                    appNameSpace + 'AIG_Reference_Number__c',
                    loanResponse.aigRefNum
                  );
                  loanAppResponse.put(
                    appNameSpace + 'Amortization_Months__c',
                    loanResponse.amortMonths
                  );
                  loanAppResponse.put(appNameSpace + 'Application__c', appId); //loanResponse.appNum);
                  loanAppResponse.put(
                    appNameSpace + 'App_Version__c',
                    loanResponse.appVersion
                  );
                  if (loanResponse.approvalType != null) {
                    loanAppResponse.put(
                      appNameSpace + 'Approval_type__c',
                      loanResponse.approvalType.code
                    );
                  }
                  loanAppResponse.put(
                    appNameSpace + 'Basic_Loan_Amount__c',
                    loanResponse.basicLoanAmt
                  );
                  loanAppResponse.put(
                    appNameSpace + 'Bid_Summary__c',
                    loanResponse.bidSummary
                  );
                  loanAppResponse.put(
                    appNameSpace + 'Broker_Commission__c',
                    loanResponse.brokerCommission
                  );
                  loanAppResponse.put(
                    appNameSpace + 'CashBack_Amount__c',
                    loanResponse.cashBackAmount
                  );
                  loanAppResponse.put(
                    appNameSpace + 'CashBack_Percent__c',
                    loanResponse.cashBackPercent
                  );
                  loanAppResponse.put(
                    appNameSpace + 'Closing_Date__c',
                    MJ_Helper.returnGMTformat(
                      loanResponse.closingDate
                    )
                  );
                  loanAppResponse.put(
                    appNameSpace + 'CMHC_Reference_Number__c',
                    loanResponse.cmhcRefNum
                  );
                  loanAppResponse.put(
                    appNameSpace + 'Commit_Expiry_Date__c',
                    MJ_Helper.returnGMTformat(
                      loanResponse.commitExpiryDate
                    )
                  );
                  if (loanResponse.commitType != null) {
                    loanAppResponse.put(
                      appNameSpace + 'Commit_Type__c',
                      loanResponse.commitType.code
                    );
                  }
                  loanAppResponse.put(
                    appNameSpace + 'Decision_Date__c',
                    MJ_Helper.returnGMTformat(
                      loanResponse.decisionDate
                    )
                  );
                  loanAppResponse.put(
                    appNameSpace + 'Decision_Version__c',
                    loanResponse.decisionVersion
                  );
                  if (loanResponse.decline != null) {
                    loanAppResponse.put(
                      appNameSpace + 'Comments__c',
                      loanResponse.decline.reason
                    );
                  }
                  loanAppResponse.put(
                    appNameSpace + 'Equity__c',
                    loanResponse.equity
                  );
                  loanAppResponse.put(
                    appNameSpace + 'Gemmi_Reference_Number__c',
                    loanResponse.gemiRefNum
                  );
                  if (loanResponse.insurer != null) {
                    loanAppResponse.put(
                      appNameSpace + 'Insurer__c',
                      loanResponse.insurer.code
                    );
                  }
                  if (loanResponse.interestComp != null) {
                    loanAppResponse.put(
                      appNameSpace + 'Interest_Comp__c',
                      loanResponse.interestComp.code
                    );
                  }
                  loanAppResponse.put(
                    appNameSpace + 'Lender_Reference_Number__c',
                    loanResponse.lenderRefNum
                  );
                  //loanAppResponse.put(appNameSpace+'Submission__c',loanResponse.lenderSubmissionId);
                  loanAppResponse.put(
                    appNameSpace + 'FilogixId__c',
                    String.valueof(loanResponse.loanDecisionId)
                  );
                  if (loanResponse.loanType != null) {
                    loanAppResponse.put(
                      appNameSpace + 'Loan_Type__c',
                      loanResponse.loanType.code
                    );
                  }
                  loanAppResponse.put(
                    appNameSpace + 'Market_Type__c',
                    loanResponse.marketType
                  );
                  loanAppResponse.put(
                    appNameSpace + 'MI_Policy_Number__c',
                    loanResponse.miPolicyNumber
                  );
                  loanAppResponse.put(
                    appNameSpace + 'Offer_Expiry_Date__c',
                    MJ_Helper.returnGMTformat(
                      loanResponse.offerExpiryDate
                    )
                  );
                  loanAppResponse.put(
                    appNameSpace + 'Offline_Submit__c',
                    booleanFormatting(loanResponse.offlineSubmitFlag)
                  );
                  loanAppResponse.put(
                    appNameSpace + 'Other_Mortgage__c',
                    loanResponse.otherMortgage
                  );
                  if (loanResponse.paymentFreq != null) {
                    loanAppResponse.put(
                      appNameSpace + 'Payment_Frequency__c',
                      loanResponse.paymentFreq.code
                    );
                  }
                  loanAppResponse.put(
                    appNameSpace + 'Payment_Amount__c',
                    loanResponse.pmtAmt
                  );
                  loanAppResponse.put(
                    appNameSpace + 'Prepay_Privs__c',
                    loanResponse.prePayPrivs
                  );
                  //loanAppResponse.put(appNameSpace+'Product__c',loanResponse.product);
                  loanAppResponse.put(
                    appNameSpace + 'Product_Code__c',
                    loanResponse.productCode
                  );
                  if (loanResponse.progressAdvance != null) {
                    loanAppResponse.put(
                      appNameSpace + 'Progress_Advance__c',
                      loanResponse.progressAdvance.code
                    );
                  }
                  loanAppResponse.put(
                    appNameSpace + 'Purchase_Price__c',
                    loanResponse.purchasePrice
                  );
                  if (loanResponse.purpose != null) {
                    loanAppResponse.put(
                      appNameSpace + 'Purpose__c',
                      loanResponse.purpose.code
                    );
                  }
                  if (loanResponse.rate != null) {
                    loanAppResponse.put(
                      appNameSpace + 'Rate_Applied__c',
                      loanResponse.rate.applied
                    );
                    loanAppResponse.put(
                      appNameSpace + 'BuyDown_Percent__c',
                      loanResponse.rate.buyDownPercent
                    );
                    loanAppResponse.put(
                      appNameSpace + 'Discount__c',
                      loanResponse.rate.discount
                    );
                    loanAppResponse.put(
                      appNameSpace + 'Premium_Percent__c',
                      loanResponse.rate.premiumPercent
                    );
                    loanAppResponse.put(
                      appNameSpace + 'Type__c',
                      loanResponse.rate.rateTypeDd
                    );
                  }
                  loanAppResponse.put(
                    appNameSpace + 'Rate_Hold_Days__c',
                    loanResponse.rateHoldDays
                  );
                  if (loanResponse.repaymentType != null) {
                    loanAppResponse.put(
                      appNameSpace + 'Repayment_Type__c',
                      loanResponse.repaymentType.code
                    );
                  }
                  loanAppResponse.put(
                    appNameSpace + 'Response_Time__c',
                    MJ_Helper.returnGMTformat(
                      loanResponse.responseTime
                    )
                  );
                  loanAppResponse.put(
                    appNameSpace + 'Service_Branch_Transit__c',
                    loanResponse.serviceBranchTransit
                  );
                  loanAppResponse.put(
                    appNameSpace + 'Survey_Required__c',
                    loanResponse.surveyRequired
                  );
                  if (loanResponse.taxesPaidBy != null) {
                    loanAppResponse.put(
                      appNameSpace + 'Taxes_Paid_By__c',
                      loanResponse.taxesPaidBy.code
                    );
                  }
                  loanAppResponse.put(
                    appNameSpace + 'Term_Months__c',
                    loanResponse.termMonths
                  );
                  if (loanResponse.termType != null) {
                    loanAppResponse.put(
                      appNameSpace + 'Term_Type__c',
                      loanResponse.termType.code
                    );
                  }
                  loanAppResponse.put(
                    appNameSpace + 'Total_Loan_Amount__c',
                    loanResponse.totalLoanAmt
                  );

                  mDebugUntruncated(
                    'Response===:`JSON.serialize(loanAppResponse)=' +
                      JSON.serialize(loanAppResponse) +
                      '`'
                  );
                  updateApp.add(loanAppResponse);

                  //Duplicate for Lookup
                  //To Prevent "MORE THAN 1 External Foriegn Key provided" error
                  sObject loanAppResponse1 = Schema.getGlobalDescribe()
                    .get(loanResponsesObjectApiName)
                    .newSObject();
                  loanAppResponse1.put(
                    appNameSpace + 'FilogixId__c',
                    String.valueof(loanResponse.loanDecisionId)
                  );

                  // applicantList
                  List<FilogixGETJSONWrapper.applicantList> loanResApplicants = (List<FilogixGETJSONWrapper.applicantList>) loanResponse.applicantList;
                  if (loanResApplicants != null) {
                    for (
                      FilogixGETJSONWrapper.applicantList loanResApplicant : loanResApplicants
                    ) {
                      String loanResApplicantsObjectApiName =
                        appNameSpace + 'Applicant__c';
                      sObject loanResApplicantRec = Schema.getGlobalDescribe()
                        .get(loanResApplicantsObjectApiName)
                        .newSObject();
                      // Mapping Lookup
                      // Method to dynamically add parent-child lookup (having ExternalID)
                      // https://salesforce.stackexchange.com/questions/161801/add-dynamic-lookup-on-contact-to-sobject-with-external-id
                      //SObjectField submissionLookup = CJA_Mortgage__Condition_Update__c.CJA_Mortgage__Submission__c;

                      SObjectField loanAppResponseLookup = Schema.getGlobalDescribe()
                        .get(loanResApplicantsObjectApiName)
                        .getDescribe()
                        .fields.getMap()
                        .get(appNameSpace + 'Response__c');
                      loanResApplicantRec.putSObject(
                        loanAppResponseLookup.getDescribe()
                          .getRelationshipName(),
                        loanAppResponse1
                      );
                      //Working
                      //loanAppConditionUpdate.putSObject(appNameSpace+'Submission__r',loanAppSubmission);
                      // Mapping Rest of the fields
                      //loanAppCondition.put(appNameSpace+'Condition_Update__c',new CJA_Mortgage__Condition_Update__c(CJA_Mortgage__FilogixId__c = String.valueof(loancondition.conditionUpdateId)));
                      //loanResApplicantRec.put(appNameSpace+'Is_On_Title__c',loanResApplicant.isOnTitle?.code);
                      if (loanResApplicant.languagePreference != null) {
                        loanResApplicantRec.put(
                          appNameSpace + 'Language_Preference__c',
                          loanResApplicant.languagePreference.code
                        );
                      }
                      if (loanResApplicant.isOnTitle != null) {
                        loanResApplicantRec.put(
                          appNameSpace + 'Is_On_Title__c',
                          loanResApplicant.isOnTitle.code
                        );
                      }
                      loanResApplicantRec.put(
                        appNameSpace + 'FilogixId__c',
                        String.valueof(loanResApplicant.applicantId)
                      );
                      loanResApplicantRec.put(
                        'Name',
                        String.valueof(loanResApplicant.name?.first)
                      );

                      updateApp.add(loanResApplicantRec);
                    }
                  }

                  // AdJustments
                  List<FilogixGETJSONWrapper.AdjustmentList> loanAdjustments = (List<FilogixGETJSONWrapper.AdjustmentList>) loanResponse.adjustmentList;
                  if (loanAdjustments != null) {
                    for (
                      FilogixGETJSONWrapper.AdjustmentList loanAdjustment : loanAdjustments
                    ) {
                      String loanAppAdjustmentObjectApiName =
                        appNameSpace + 'Adjustment__c';
                      sObject loanAppAdjustment = Schema.getGlobalDescribe()
                        .get(loanAppAdjustmentObjectApiName)
                        .newSObject();
                      // Mapping Lookup
                      // Method to dynamically add parent-child lookup (having ExternalID)
                      // https://salesforce.stackexchange.com/questions/161801/add-dynamic-lookup-on-contact-to-sobject-with-external-id
                      //SObjectField submissionLookup = CJA_Mortgage__Condition_Update__c.CJA_Mortgage__Submission__c;
                      String relationFieldRes = appNameSpace + 'Response__c';
                      SObjectField loanAppResponseLookup = Schema.getGlobalDescribe()
                        .get(loanAppAdjustmentObjectApiName)
                        .getDescribe()
                        .fields.getMap()
                        .get(relationFieldRes);
                      loanAppAdjustment.putSObject(
                        loanAppResponseLookup.getDescribe()
                          .getRelationshipName(),
                        loanAppResponse1
                      );
                      //Working
                      //loanAppConditionUpdate.putSObject(appNameSpace+'Submission__r',loanAppSubmission);
                      // Mapping Rest of the fields
                      //loanAppCondition.put(appNameSpace+'Condition_Update__c',new CJA_Mortgage__Condition_Update__c(CJA_Mortgage__FilogixId__c = String.valueof(loancondition.conditionUpdateId)));
                      loanAppAdjustment.put(
                        appNameSpace + 'Amount__c',
                        loanAdjustment.amt
                      );
                      if (loanAdjustment.description != null) {
                        loanAppAdjustment.put(
                          appNameSpace + 'Description__c',
                          loanAdjustment.description.code
                        );
                      }
                      if (loanAdjustment.feesPmtMethod != null) {
                        loanAppAdjustment.put(
                          appNameSpace + 'Fee_Payment_Method__c',
                          loanAdjustment.feesPmtMethod.desc_Z
                        );
                      }
                      loanAppAdjustment.put(
                        appNameSpace + 'FilogixId__c',
                        String.valueof(loanAdjustment.adjustmentId)
                      );
                      //loanAppAdjustment.put(appNameSpace+'Response__c',loanAdjustment.loanDecisionId);
                      //loanAppAdjustment.put(appNameSpace+'Applicant_Code__c',loanAdjustment.applicantCode);
                      updateApp.add(loanAppAdjustment);
                    }
                  }

                  // Clauses
                  List<FilogixGETJSONWrapper.ClauseList> loanClauses = (List<FilogixGETJSONWrapper.ClauseList>) loanResponse.ClauseList;
                  if (loanClauses != null) {
                    for (
                      FilogixGETJSONWrapper.ClauseList loanClause : loanClauses
                    ) {
                      String loanAppClauseObjectApiName =
                        appNameSpace + 'Clause__c';
                      sObject loanAppClause = Schema.getGlobalDescribe()
                        .get(loanAppClauseObjectApiName)
                        .newSObject();
                      // Mapping Lookup
                      // Method to dynamically add parent-child lookup (having ExternalID)
                      // https://salesforce.stackexchange.com/questions/161801/add-dynamic-lookup-on-contact-to-sobject-with-external-id
                      //SObjectField submissionLookup = CJA_Mortgage__Condition_Update__c.CJA_Mortgage__Submission__c;
                      String relationFieldRes1 = appNameSpace + 'Response__c';
                      SObjectField loanAppResponseLookup = Schema.getGlobalDescribe()
                        .get(loanAppClauseObjectApiName)
                        .getDescribe()
                        .fields.getMap()
                        .get(relationFieldRes1);
                      loanAppClause.putSObject(
                        loanAppResponseLookup.getDescribe()
                          .getRelationshipName(),
                        loanAppResponse1
                      );
                      //Working
                      //loanAppConditionUpdate.putSObject(appNameSpace+'Submission__r',loanAppSubmission);
                      // Mapping Rest of the fields
                      //loanAppCondition.put(appNameSpace+'Condition_Update__c',new CJA_Mortgage__Condition_Update__c(CJA_Mortgage__FilogixId__c = String.valueof(loancondition.conditionUpdateId)));
                      loanAppClause.put(
                        appNameSpace + 'Code__c',
                        loanClause.code
                      );
                      loanAppClause.put(
                        appNameSpace + 'Description__c',
                        loanClause.text
                      );
                      loanAppClause.put(
                        appNameSpace + 'FilogixId__c',
                        String.valueof(loanClause.clauseId)
                      );
                      loanAppClause.put(
                        appNameSpace + 'Item_Number__c',
                        String.valueof(loanClause.itemNumber)
                      );
                      loanAppClause.put(
                        appNameSpace + 'Section_Code__c',
                        loanClause.sectionCode.code
                      );
                      updateApp.add(loanAppClause);
                    }
                  }

                  // Pending Messages
                  List<FilogixGETJSONWrapper.PendingMessages> loanResPendingMsgs = (List<FilogixGETJSONWrapper.PendingMessages>) loanResponse.pendingMessages;
                  if (loanResPendingMsgs != null) {
                    for (
                      FilogixGETJSONWrapper.PendingMessages loanResPendingMsg : loanResPendingMsgs
                    ) {
                      String loanAppPendingMsgObjectApiName =
                        appNameSpace + 'Pending_Message__c';
                      sObject loanAppPendingMsg = Schema.getGlobalDescribe()
                        .get(loanAppPendingMsgObjectApiName)
                        .newSObject();
                      // Mapping Lookup
                      // Method to dynamically add parent-child lookup (having ExternalID)
                      // https://salesforce.stackexchange.com/questions/161801/add-dynamic-lookup-on-contact-to-sobject-with-external-id
                      //SObjectField submissionLookup = CJA_Mortgage__Condition_Update__c.CJA_Mortgage__Submission__c;
                      String relationFieldRes01 = appNameSpace + 'Response__c';
                      SObjectField loanAppResponseLookup = Schema.getGlobalDescribe()
                        .get(loanAppPendingMsgObjectApiName)
                        .getDescribe()
                        .fields.getMap()
                        .get(relationFieldRes01);
                      loanAppPendingMsg.putSObject(
                        loanAppResponseLookup.getDescribe()
                          .getRelationshipName(),
                        loanAppResponse1
                      );
                      //Working
                      //loanAppConditionUpdate.putSObject(appNameSpace+'Submission__r',loanAppSubmission);
                      // Mapping Rest of the fields
                      //loanAppCondition.put(appNameSpace+'Condition_Update__c',new CJA_Mortgage__Condition_Update__c(CJA_Mortgage__FilogixId__c = String.valueof(loancondition.conditionUpdateId)));
                      //loanAppClause.put(appNameSpace+'Code__c',loanResPendingMsg.code);
                      loanAppPendingMsg.put(
                        appNameSpace + 'Message__c',
                        loanResPendingMsg.message
                      );
                      loanAppPendingMsg.put(
                        appNameSpace + 'FilogixId__c',
                        String.valueof(loanResPendingMsg.pendingMessageId)
                      );

                      updateApp.add(loanAppPendingMsg);
                    }
                  }

                  // Offices
                  List<FilogixGETJSONWrapper.OfficeList> loanOffices = (List<FilogixGETJSONWrapper.OfficeList>) loanResponse.OfficeList;
                  if (loanClauses != null) {
                    for (
                      FilogixGETJSONWrapper.OfficeList loanOffice : loanOffices
                    ) {
                      String loanAppOfficeObjectApiName =
                        appNameSpace + 'Office__c';
                      sObject loanAppOffice = Schema.getGlobalDescribe()
                        .get(loanAppOfficeObjectApiName)
                        .newSObject();
                      // Mapping Lookup
                      // Method to dynamically add parent-child lookup (having ExternalID)
                      // https://salesforce.stackexchange.com/questions/161801/add-dynamic-lookup-on-contact-to-sobject-with-external-id
                      //SObjectField submissionLookup = CJA_Mortgage__Condition_Update__c.CJA_Mortgage__Submission__c;
                      String relationFieldRes2 = appNameSpace + 'Response__c';
                      SObjectField loanAppResponseLookup = Schema.getGlobalDescribe()
                        .get(loanAppOfficeObjectApiName)
                        .getDescribe()
                        .fields.getMap()
                        .get(relationFieldRes2);
                      loanAppOffice.putSObject(
                        loanAppResponseLookup.getDescribe()
                          .getRelationshipName(),
                        loanAppResponse1
                      );
                      //Working
                      //loanAppConditionUpdate.putSObject(appNameSpace+'Submission__r',loanAppSubmission);
                      // Mapping Rest of the fields
                      //loanAppCondition.put(appNameSpace+'Condition_Update__c',new CJA_Mortgage__Condition_Update__c(CJA_Mortgage__FilogixId__c = String.valueof(loancondition.conditionUpdateId)));
                      //loanAppOffice.put(appNameSpace+'Address__c',representativeList[0].address);
                      //loanAppOffice.put(appNameSpace+'Email__c',loanOffice.representativeList[0].email);
                      //loanAppOffice.put(appNameSpace+'Fax__c',loanOffice.fax);
                      //mDebugUntruncated('representative::'+loanOffice.representativeList);
                      loanAppOffice.put(
                        appNameSpace + 'FilogixId__c',
                        String.valueof(loanOffice.officeId)
                      );
                      loanAppOffice.put('Name', loanOffice.officeName);
                      //loanAppOffice.put(appNameSpace+'Office_Code__c',loanOffice.officeCode);
                      //loanAppOffice.put(appNameSpace+'Phone__c',loanOffice.representativeList[0].phone.areaCode+loanOffice.representativeList[0].phone.number_Z);
                      loanAppOffice.put(
                        appNameSpace + 'Type__c',
                        loanOffice.officeType
                      );
                      updateApp.add(loanAppOffice);

                      //Duplicate for Lookup
                      //To Prevent "MORE THAN 1 External Foriegn Key provided" error
                      sObject loanAppOffice1 = Schema.getGlobalDescribe()
                        .get(loanAppOfficeObjectApiName)
                        .newSObject();
                      loanAppOffice1.put(
                        appNameSpace + 'FilogixId__c',
                        String.valueof(loanOffice.officeId)
                      );

                      // Representatives
                      List<FilogixGETJSONWrapper.RepresentativeList> loanResponseRepresentatives = (List<FilogixGETJSONWrapper.RepresentativeList>) loanOffice.RepresentativeList;
                      if (loanResponseRepresentatives != null) {
                        for (
                          FilogixGETJSONWrapper.RepresentativeList loanResponseRepresentative : loanResponseRepresentatives
                        ) {
                          String loanAppRepObjectApiName =
                            appNameSpace + 'Representative__c';
                          sObject loanAppRepresentative = Schema.getGlobalDescribe()
                            .get(loanAppRepObjectApiName)
                            .newSObject();
                          // Mapping Lookup
                          // Method to dynamically add parent-child lookup (having ExternalID)
                          // https://salesforce.stackexchange.com/questions/161801/add-dynamic-lookup-on-contact-to-sobject-with-external-id
                          //SObjectField submissionLookup = CJA_Mortgage__Condition_Update__c.CJA_Mortgage__Submission__c;
                          String relationFieldOffice =
                            appNameSpace + 'Office__c';
                          SObjectField loanAppOfficeLookup = Schema.getGlobalDescribe()
                            .get(loanAppRepObjectApiName)
                            .getDescribe()
                            .fields.getMap()
                            .get(relationFieldOffice);
                          loanAppRepresentative.putSObject(
                            loanAppOfficeLookup.getDescribe()
                              .getRelationshipName(),
                            loanAppOffice1
                          );
                          // Mapping Rest of the fields
                          //loanAppRepresentative.put(appNameSpace+'Address__c',address);
                          if (loanResponseRepresentative.address != null) {
                            loanAppRepresentative.put(
                              appNameSpace + 'PostalCode__c',
                              loanResponseRepresentative.address.postalZipCode
                            );
                            loanAppRepresentative.put(
                              appNameSpace + 'City__c',
                              loanResponseRepresentative.address.city
                            );
                            loanAppRepresentative.put(
                              appNameSpace + 'State__c',
                              loanResponseRepresentative.address.provState.code
                            );
                            loanAppRepresentative.put(
                              appNameSpace + 'Street_Address__c',
                              loanResponseRepresentative.address.streetAddr1 +
                                ' ' +
                                loanResponseRepresentative.address.streetAddr2
                            );
                          }
                          loanAppRepresentative.put(
                            appNameSpace + 'Email__c',
                            loanResponseRepresentative.email
                          );
                          loanAppRepresentative.put(
                            appNameSpace + 'Fax__c',
                            loanResponseRepresentative.fax?.number_Z
                          );
                          loanAppRepresentative.put(
                            appNameSpace + 'FilogixId__c',
                            String.valueof(
                              loanResponseRepresentative.representativeId
                            )
                          );
                          loanAppRepresentative.put(
                            'Name',
                            loanResponseRepresentative.name.first =
                              ' ' + loanResponseRepresentative.name.last
                          );
                          //loanAppRepresentative.put(appNameSpace+'Phone__c',loanResponseRepresentative.phone);
                          loanAppRepresentative.put(
                            appNameSpace + 'Phone__c',
                            String.valueof(
                              loanResponseRepresentative.phone.areaCode +
                              loanResponseRepresentative.phone.number_Z
                            )
                          );
                          loanAppRepresentative.put(
                            appNameSpace + 'Representative_Code__c',
                            loanResponseRepresentative.representativeCode
                          );
                          loanAppRepresentative.put(
                            appNameSpace + 'Role__c',
                            loanResponseRepresentative.role.code
                          );

                          updateApp.add(loanAppRepresentative);
                        }
                      }
                    }
                  }

                  // Subject Property
                  List<FilogixGETJSONWrapper.SubjectPropertyList> loanSubjectProperties = (List<FilogixGETJSONWrapper.SubjectPropertyList>) loanResponse.SubjectPropertyList;
                  if (loanSubjectProperties != null) {
                    for (
                      FilogixGETJSONWrapper.SubjectPropertyList loanSubjectProperty : loanSubjectProperties
                    ) {
                      //subjectProp_FilogixId = String.valueof(loanSubjectProperty.subjectPropertyId);
                      String loanAppResSubjectPropObjectApiName =
                        appNameSpace + 'Subject_Property__c';
                      sObject loanAppSubjProp = Schema.getGlobalDescribe()
                        .get(loanAppResSubjectPropObjectApiName)
                        .newSObject();
                      // Mapping Lookup
                      // Method to dynamically add parent-child lookup (having ExternalID)
                      // https://salesforce.stackexchange.com/questions/161801/add-dynamic-lookup-on-contact-to-sobject-with-external-id
                      //SObjectField submissionLookup = CJA_Mortgage__Condition_Update__c.CJA_Mortgage__Submission__c;
                      String relationFieldRes3 = appNameSpace + 'Response__c';
                      SObjectField loanAppResponseLookup = Schema.getGlobalDescribe()
                        .get(loanAppResSubjectPropObjectApiName)
                        .getDescribe()
                        .fields.getMap()
                        .get(relationFieldRes3);
                      loanAppSubjProp.putSObject(
                        loanAppResponseLookup.getDescribe()
                          .getRelationshipName(),
                        loanAppResponse1
                      );
                      //Working
                      //loanAppConditionUpdate.putSObject(appNameSpace+'Submission__r',loanAppSubmission);
                      // Mapping Rest of the fields
                      //loanAppSubjProp.put(appNameSpace+'Address__c',loanSubjectProperty.address);
                      loanAppSubjProp.put(
                        appNameSpace + 'Annual_Tax_Amount__c',
                        loanSubjectProperty.annualTaxAmt
                      );
                      loanAppSubjProp.put(
                        appNameSpace + 'Building__c',
                        loanSubjectProperty.building.type_Z
                      );
                      loanAppSubjProp.put(
                        appNameSpace + 'FilogixId__c',
                        String.valueof(loanSubjectProperty.subjectPropertyId)
                      );
                      updateApp.add(loanAppSubjProp);
                    }
                  }
                }
              }
            }
          }
        }
      }

      // Opportunity
      // Removing Opportunity Mapping - Hamza Dec, 1 -2021
      //Opportunity opp = new Opportunity();
      // sObject opp = Schema.getGlobalDescribe().get(opportuntiyObjectApiName).newSObject();
      // opp.put(appNameSpace+'Deal_Type__c', app.result.mortgageApplication.deal.dealTypeDd);
      // //opp.put('CloseDate',app.result.mortgageApplication.deal.estimatedClosingDate);
      // //opp.put('Financing_Waiver_Date__c',app.result.mortgageApplication.deal.financingWaiverDate);
      // opp.put(appNameSpace+'Referral_Reference_Number__c',app.result.mortgageApplication.deal.referralReferenceNo);
      // opp.put(appNameSpace+'Ref_Improvements_Flag__c',booleanFormatting(app.result.mortgageApplication.deal.refiImprovementsFlag));
      // opp.put(appNameSpace+'Ref_Purpose__c',app.result.mortgageApplication.deal.refiPurpose);
      // opp.put('Id', rla.get('OpportunityId'));
      // opp.put(appNameSpace+'FilogixId__c',String.valueof(app.result.mortgageApplication.deal.dealId));
      // //opp.put('Id',app.result.mortgageApplication.sourceApplicationId);
      // opp.put(appNameSpace+'Tax_Payor__c', app.result.mortgageApplication.deal.taxPayorDd);

      // SUBJECT PROPERTY
      //LoanApplicationProperty lAproperty = new LoanApplicationProperty();
      sObject lAproperty = Schema.getGlobalDescribe()
        .get(loanPropertyObjectApiName)
        .newSObject();
      // Only Add the ID if Subject Property is available
      //system.debug('SubjectProp::'+JSON.serialize(rla.get(appNameSpace+'Subject_Property__c')));
      //if(rla.get(appNameSpace+'Subject_Property__c') !=null){
      //    lAproperty.put('Id',(ID) rla.get(appNameSpace+'Subject_Property__c'));
      //} else {
      //system.debug('Subject Property is null');
      lAproperty.put(
        objNamePrefix + 'LoanApplicationId' + customFieldSuffix,
        appId
      );
      lAproperty.put(
        'Name',
        'Subject Property - ' +
        String.valueof(
          app.result.mortgageApplication.subjectProperty.propertyId
        )
      );
      //}
      lAproperty.put(
        appNameSpace + 'FilogixId__c',
        String.valueof(
          app.result.mortgageApplication.subjectProperty.propertyId
        )
      );
      lAproperty.put(
        appNameSpace + 'AppraisedValue__c',
        app.result.mortgageApplication.subjectProperty.actualAppraisalValue
      );
      lAproperty.put(
        'Appraisal_Date__c',
        MJ_Helper.returnGMTformat(
          app.result.mortgageApplication.subjectProperty.appraisalDateAct
        )
      ); // Illegal assignment from String to Datetime
      lAproperty.put(
        appNameSpace + 'Style__c',
        app.result.mortgageApplication.subjectProperty.dwellingStyleDd
      );
      lAproperty.put(
        appNameSpace + 'Structure_Type__c',
        app.result.mortgageApplication.subjectProperty.dwellingTypeDd
      );
      lAproperty.put(
        'PropertyValue' + customFieldSuffix,
        app.result.mortgageApplication.subjectProperty.estimatedAppraisalValue
      );
        
      lAproperty.put(
        appNameSpace + 'feesIncludeHeat__c',
        booleanFormatting(
          app.result.mortgageApplication.subjectProperty.feesIncludeHeat
        )
      );
      lAproperty.put(
        appNameSpace + 'Garage_Size__c',
        app.result.mortgageApplication.subjectProperty.garageSizeDd
      );
      lAproperty.put(
        appNameSpace + 'Garage_Type__c',
        app.result.mortgageApplication.subjectProperty.garageTypeDd
      );
      lAproperty.put(
        appNameSpace + 'Heat__c',
        app.result.mortgageApplication.subjectProperty.heatTypeDd
      );
      lAproperty.put(
        appNameSpace + 'includetds__c',
        booleanFormatting(
          app.result.mortgageApplication.subjectProperty.includetds
        )
      );
      lAproperty.put(
        appNameSpace + 'insulatedWithUffi__c',
        booleanFormatting(
          app.result.mortgageApplication.subjectProperty.insulatedWithUffi
        )
      );
      lAproperty.put(
        appNameSpace + 'lot__c',
        app.result.mortgageApplication.subjectProperty.legalLine1
      );
      lAproperty.put(
        appNameSpace + 'block__c',
        app.result.mortgageApplication.subjectProperty.legalLine2
      );
      lAproperty.put(
        appNameSpace + 'Conc_Township__c',
        app.result.mortgageApplication.subjectProperty.legalLine3
      );
      lAproperty.put(
        appNameSpace + 'livingSpace__c',
        app.result.mortgageApplication.subjectProperty.livingSpace
      );
      lAproperty.put(
        appNameSpace + 'livingSpaceUnitOfMeasurDd__c',
        app.result.mortgageApplication.subjectProperty.livingSpaceUnitOfMeasurDd
      );
      lAproperty.put(
        appNameSpace + 'lotSize__c',
        app.result.mortgageApplication.subjectProperty.lotSize
      );
      lAproperty.put(
        appNameSpace + 'lotSizeUnitOfMeasure__c',
        app.result.mortgageApplication.subjectProperty.lotSizeUnitOfMeasureDd
      );
      lAproperty.put(
        appNameSpace + 'mlsListingFlag__c',
        booleanFormatting(
          app.result.mortgageApplication.subjectProperty.mlsListingFlag
        )
      );
      lAproperty.put(
        appNameSpace + 'Construction_Type__c',
        app.result.mortgageApplication.subjectProperty.newConstructionDd
      );
      lAproperty.put(
        appNameSpace + 'numberOfUnits__c',
        app.result.mortgageApplication.subjectProperty.numberOfUnits
      );
      lAproperty.put(
        'PropertyUseType' + customFieldSuffix,
        app.result.mortgageApplication.subjectProperty.occupancyTypeDd
      );
      lAproperty.put(
        appNameSpace + 'Property_Type__c',
        app.result.mortgageApplication.subjectProperty.propertyTypeDd
      );
      lAproperty.put(
        appNameSpace + 'propertyValueIndexId__c',
        app.result.mortgageApplication.subjectProperty.propertyValueIndexId
      );
      lAproperty.put(
        appNameSpace + 'Original_Purchase_Price__c',
        app.result.mortgageApplication.subjectProperty.originalPurchasePrice
      );
      lAproperty.put(
        appNameSpace + 'realtorInfo__c',
        app.result.mortgageApplication.subjectProperty.realtorInfo
      );
      if (app.result.mortgageApplication.subjectProperty.rentalIncome != null) {
        lAproperty.put(
          'ExpMonthlyRentalIncome' + customFieldSuffix,
          app.result.mortgageApplication.subjectProperty.rentalIncome.incomeAmount
        );
        lAproperty.put(
          appNameSpace + 'Rental_IncPercentInTds__c',
          app.result.mortgageApplication.subjectProperty.rentalIncome.incPercentInGds
        );

        lAproperty.put(
          appNameSpace + 'Rental_Income_Period__c',
          app.result.mortgageApplication.subjectProperty.rentalIncome.incomePeriodDd
        );
        lAproperty.put(
          appNameSpace + 'Rental_Income_Type__c',
          app.result.mortgageApplication.subjectProperty.rentalIncome.incomeTypeDd
        );
      }

      lAproperty.put(
        appNameSpace + 'rentalOffsetOption__c',
        app.result.mortgageApplication.subjectProperty.rentalOffsetOption
      );
      lAproperty.put(
        appNameSpace + 'Sewage_Type__c',
        app.result.mortgageApplication.subjectProperty.sewageTypeDd
      );
      lAproperty.put(
        appNameSpace + 'structureAge__c',
        app.result.mortgageApplication.subjectProperty.structureAge
      );
      lAproperty.put(
        appNameSpace + 'taxationYear__c',
        app.result.mortgageApplication.subjectProperty.taxationYear
      );
      lAproperty.put(
        appNameSpace + 'Water_Type__c',
        app.result.mortgageApplication.subjectProperty.waterTypeDd
      );
      system.debug(
        'SubjectPropertyFlag::' +
        app.result.mortgageApplication.subjectProperty.subjectPropertyFlag
      );
      system.debug(
        'SubjectPropertyFlagAfter::' +
        booleanFormatting(
          app.result.mortgageApplication.subjectProperty.subjectPropertyFlag
        )
      );
      lAproperty.put(
        appNameSpace + 'Is_Subject_Property__c',
        booleanFormatting(
          app.result.mortgageApplication.subjectProperty.subjectPropertyFlag
        )
      );

      /*Added by Zain Abbas - Start*/
      lAproperty.put(
        appNameSpace + 'purchasePrice__c',
        app.result.mortgageApplication.subjectProperty.purchasePrice
      );
      lAproperty.put(
        appNameSpace + 'Purchase_Date__c',
        MJ_Helper.returnGMTformat(
          app.result.mortgageApplication.subjectProperty.refiOrigPurchaseDate
        )
      );
      /*Added by Zain Abbas - End*/

      // Address Fields
      // Checking if Address fields are available
      if (app.result.mortgageApplication.subjectProperty.address != null) {
        lAproperty.put(
          appNameSpace + 'PropertyUnitNumber__c',
          String.valueof(
            app.result.mortgageApplication.subjectProperty.address.unitNumber
          )
        );
        //lAproperty.put(appNameSpace+'PropertyStreetNumber__c',String.valueof(app.result.mortgageApplication.subjectProperty.address.streetNumber));
        //lAproperty.put('PropertyStreet',String.valueof(app.result.mortgageApplication.subjectProperty.address.streetNumber)+' '+String.valueof(app.result.mortgageApplication.subjectProperty.address.streetName));
        lAproperty.put(
          appNameSpace + 'Street_Type__c',
          String.valueof(
            app.result.mortgageApplication.subjectProperty.address.streetTypeDd
          )
        );
        lAproperty.put(
          appNameSpace + 'Direction__c',
          String.valueof(
            app.result.mortgageApplication.subjectProperty.address.streetDirectionDd
          )
        );
        lAproperty.put(
          appNameSpace + 'City__c',
          String.valueof(
            app.result.mortgageApplication.subjectProperty.address.city
          )
        );
        //lAproperty.put('PropertyPostalCode',String.valueof(app.result.mortgageApplication.subjectProperty.address.postalFsa)+String.valueof(app.result.mortgageApplication.subjectProperty.address.postalLdu));
        lAproperty.put(
          appNameSpace + 'Country__c',
          String.valueof(
            app.result.mortgageApplication.subjectProperty.address.countryTypeDd
          )
        );
        lAproperty.put(
          appNameSpace + 'Province__c',
          String.valueof(
            app.result.mortgageApplication.subjectProperty.address.provinceDd
          )
        );
        String postalFsa = '';
        String postalLdu = '';
        String streetNumber = '';
        String streetName = '';
        if (
          app.result.mortgageApplication.subjectProperty.address.streetNumber !=
          null
        ) {
          streetNumber = app.result.mortgageApplication.subjectProperty.address.streetNumber;
        }
        if (
          app.result.mortgageApplication.subjectProperty.address.streetName !=
          null
        ) {
          streetName = app.result.mortgageApplication.subjectProperty.address.streetName;
        }
        if (
          app.result.mortgageApplication.subjectProperty.address.postalFsa !=
          null
        ) {
          postalFsa = app.result.mortgageApplication.subjectProperty.address.postalFsa;
        }
        if (
          app.result.mortgageApplication.subjectProperty.address.postalLdu !=
          null
        ) {
          postalLdu = app.result.mortgageApplication.subjectProperty.address.postalLdu;
        }

        lAproperty.put(appNameSpace + 'PostalCode__c', postalFsa + postalLdu);
        //lAproperty.put('PropertyStreet',streetNumber+' '+streetName);
        lAproperty.put(appNameSpace + 'Street_Name__c', streetName);
        lAproperty.put(appNameSpace + 'Street_Number__c', streetNumber);

        /*Added by Zain Abbas - Start*/
        //lAproperty.put(appNameSpace+'PropertyStreetNumber__c',String.valueof(app.result.mortgageApplication.subjectProperty.address.streetNumber));
        /*Added by Zain Abbas - End*/
      }

      // Property Expenses now adding as a field
      List<FilogixGETJSONWrapper.propertyExpense> propertyExpenses = (List<FilogixGETJSONWrapper.propertyExpense>) app.result.mortgageApplication.subjectProperty.propertyExpense;
      if (propertyExpenses != null) {
        system.debug('propertyExpenses=' + propertyExpenses);
        for (
          FilogixGETJSONWrapper.propertyExpense pExpense : propertyExpenses
        ) {
          system.debug('pExpense=' + pExpense);

          if (pExpense.propertyExpenseTypeDd == 'Insurance') {
            lAproperty.put(
              appNameSpace + 'Insurance_Expenses__c',
              pExpense.propertyExpenseAmount
            );
          } else if (pExpense.propertyExpenseTypeDd == 'Heating Expense') {
            lAproperty.put(
              appNameSpace + 'Heating_Expenses__c',
              pExpense.propertyExpenseAmount
            );
          } else if (pExpense.propertyExpenseTypeDd == 'Hydro') {
            lAproperty.put(
              appNameSpace + 'Hydro_Expenses__c',
              pExpense.propertyExpenseAmount
            );
          } else if (pExpense.propertyExpenseTypeDd == 'Interest Charges') {
            lAproperty.put(
              appNameSpace + 'Interest_Expenses__c',
              pExpense.propertyExpenseAmount
            );
          } else if (pExpense.propertyExpenseTypeDd == 'Management Expenses') {
            lAproperty.put(
              appNameSpace + 'Management_Expenses__c',
              pExpense.propertyExpenseAmount
            );
          } else if (pExpense.propertyExpenseTypeDd == 'General Expenses') {
            lAproperty.put(
              appNameSpace + 'Other_Expenses__c',
              pExpense.propertyExpenseAmount
            );
          } else if (pExpense.propertyExpenseTypeDd == 'Repairs') {
            lAproperty.put(
              appNameSpace + 'Repairs_Expenses__c',
              pExpense.propertyExpenseAmount
            );
          } else if (pExpense.propertyExpenseTypeDd == 'Condo Fees') {
            lAproperty.put(
              appNameSpace + 'Total_Condo_Fees__c',
              pExpense.propertyExpenseAmount
            );
          } else if (pExpense.propertyExpenseTypeDd == 'Municipal Taxes') {
            lAproperty.put(
              appNameSpace + 'Annual_Taxes__c',
              pExpense.propertyExpenseAmount
            );
          }

          //lAproperty.put(appNameSpace+'propertyExpenseAmount__c',pExpense.propertyExpenseAmount);
          //pe.put(appNameSpace+'propertyExpensePeriod__c',pExpense.propertyExpensePeriodDd);
          //lAproperty.put(appNameSpace+'propertyExpenseType__c',pExpense.propertyExpenseTypeDd);
          // NEW FIelds
          //lAproperty.put(appNameSpace+'Loan_Application__c',appId);
          //pe.put(appNameSpace+'Include_In_GDS__c',booleanFormatting(pExpense.includeInGDS));
          //pe.put(appNameSpace+'Include_In_TDS__c',booleanFormatting(pExpense.includeInTDS));
          //lAproperty.put(appNameSpace+'Monthly_Expense_Amount__c',pExpense.monthlyExpenseAmount);
          //pe.put(appNameSpace+'Percent_In_GDS__c',pExpense.percentInGDS);
          //pe.put(appNameSpace+'Percent_In_TDS__c',pExpense.percentInTDS);
          //pe.put(appNameSpace+'FilogixId__c',String.valueof(pExpense.propertyExpenseId));
        }
      }
      //mDebugUntruncated('lAproperty::'+lAproperty);
      updateApp.add(lAproperty);

      /*// Property Expenses
List<FilogixGETJSONWrapper.propertyExpense> propertyExpenses = (List<FilogixGETJSONWrapper.propertyExpense>) app.result.mortgageApplication.subjectProperty.propertyExpense;
if (propertyExpenses != null) {
system.debug('propertyExpenses=' + propertyExpenses);
for (
FilogixGETJSONWrapper.propertyExpense pExpense : propertyExpenses
) {
system.debug('pExpense=' + pExpense);

//PropertyExpense__c pe = new PropertyExpense__c();
sObject pe = Schema.getGlobalDescribe().get(propertyExpenseObjectApiName).newSObject();
pe.put(appNameSpace+'Loan_Application_Property__c',lAproperty.Id);
pe.put(appNameSpace+'propertyExpenseAmount__c',pExpense.propertyExpenseAmount);
pe.put(appNameSpace+'propertyExpensePeriod__c',pExpense.propertyExpensePeriodDd);
pe.put(appNameSpace+'propertyExpenseType__c',pExpense.propertyExpenseTypeDd);
// NEW FIelds
pe.put(appNameSpace+'Loan_Application__c',appId);
pe.put(appNameSpace+'Include_In_GDS__c',booleanFormatting(pExpense.includeInGDS));
pe.put(appNameSpace+'Include_In_TDS__c',booleanFormatting(pExpense.includeInTDS));
pe.put(appNameSpace+'Monthly_Expense_Amount__c',pExpense.monthlyExpenseAmount);
pe.put(appNameSpace+'Percent_In_GDS__c',pExpense.percentInGDS);
pe.put(appNameSpace+'Percent_In_TDS__c',pExpense.percentInTDS);
pe.put(appNameSpace+'FilogixId__c',String.valueof(pExpense.propertyExpenseId));
updateApp.add(pe);
}
}*/

      //Down Payment Source
      List<FilogixGETJSONWrapper.downPaymentSource> downPaymentSources = (List<FilogixGETJSONWrapper.downPaymentSource>) app.result.mortgageApplication.deal.downPaymentSource;
      if (downPaymentSources != null) {
        system.debug('downPaymentSources=' + downPaymentSources);
        for (
          FilogixGETJSONWrapper.downPaymentSource downPaymentSource : downPaymentSources
        ) {
          system.debug('dSource=' + downPaymentSource);

          //Down_Payment_Source__c dp = new Down_Payment_Source__c();
          sObject dp = Schema.getGlobalDescribe()
            .get(downpaymentObjectApiName)
            .newSObject();
          dp.put(appNameSpace + 'Amount__c', downPaymentSource.amount);
          dp.put(
            appNameSpace + 'Description__c',
            downPaymentSource.description
          );
          dp.put(
            appNameSpace + 'Source_Type__c',
            downPaymentSource.downPaymentSourceTypeDd
          );
          dp.put('Name', downPaymentSource.downPaymentSourceTypeDd);
          dp.put(
            appNameSpace + 'FilogixId__c',
            String.valueof(downPaymentSource.downPaymentSourceId)
          );
          //dp.put(appNameSpace+'Opportunity__c',(ID) rla.get('OpportunityId'));
          dp.put(
            appNameSpace + 'FilogixId__c',
            String.valueof(downPaymentSource.downPaymentSourceId)
          );
          dp.put(appNameSpace + 'Application__c', appId);
          updateApp.add(dp);
        }
      }
      // Loan Applicants

      Map<String, String> loanApplicantAccount = new Map<String, String>();
      Map<String, set<String>> MapofSINandAccount = new Map<String, Set<String>>();
      Map<String, String> MapofNameandAccount = new Map<String, String>();
      Map<String, String> MapofFilogixIdandAccount = new Map<String, String>();
      Map<String, set<String>> MapofEmailandAccount = new Map<String, set<String>>();
      Map<String, String> MapofAccountandContact = new Map<String, String>();
      Map<String, String> MapofApplicantandApplication = new Map<String, String>();
      Set<String> SetofPersonAccounts = new Set<String>();
      Set<String> listofApplicantIds = new Set<String>();
      Set<String> ListofSIN = new Set<String>();
      Set<String> ListofFilogixIds = new Set<String>();
      Set<String> ListofEmail = new Set<String>();
      // Populating SET of Applicants IDs
      List<FilogixGETJSONWrapper.ApplicantGroup> applicantGroups = (List<FilogixGETJSONWrapper.ApplicantGroup>) app.result.mortgageApplication.applicantGroup;
      if (applicantGroups != null) {
        // ApplicantGroups
        for (
          FilogixGETJSONWrapper.ApplicantGroup applicantGroup : applicantGroups
        ) {
          List<FilogixGETJSONWrapper.Applicant> loanApplicants = (List<FilogixGETJSONWrapper.Applicant>) applicantGroup.applicant;
          // ApplicantGroup
          if (loanApplicants != null) {
            for (
              FilogixGETJSONWrapper.Applicant loanApplicant : loanApplicants
            ) {
              ListofApplicantIds.add(loanApplicant.clientReferenceNumber);
              ListofSIN.add(loanApplicant.socialInsuranceNumber);
              ListofEmail.add(loanApplicant.emailAddress);
              ListofFilogixIds.add(String.valueof(loanApplicant.borrowerId));
            }
          }
        }
      }

      // remove blanks and nulls
      ListofApplicantIds.remove('');
      ListofApplicantIds.remove(null);
      ListofSIN.remove('');
      ListofSIN.remove(null);
      ListofEmail.remove('');
      ListofEmail.remove(null);

      // Query to get all the Existing accounts having the Same SIN or Email
      String accountsQuery =
        'Select id, Name, IsPersonAccount,' +
        appNameSpace +
        'FilogixId__c, ' +
        appNameSpace +
        'Social_Insurance_Number__pc, PersonEmail, PersonContactId from Account where ' +
        appNameSpace +
        'Social_Insurance_Number__pc IN :ListofSIN OR PersonEmail IN :ListofEmail OR ' +
        appNameSpace +
        'FilogixId__c IN :ListofFilogixIds WITH SECURITY_ENFORCED';
      system.debug('accountsQuery=' + accountsQuery);
      List<sObject> accountRecords = database.query(
        String.escapeSingleQuotes(accountsQuery)
      );
      // Strip fields that are not readable
      SObjectAccessDecision accRecords = Security.stripInaccessible(
        AccessType.READABLE,
        accountRecords
      );
      system.debug('accountRecords=' + accRecords.getRecords().size());

      // Getting a MAP populated with LOAN APPLICANT ID against their AccountIds
      if (
        accRecords.getRecords() != null &&
        accRecords.getRecords().size() > 0
      ) {
        for (sObject acc : accRecords.getRecords()) {
          MapofAccountandContact.put(
            String.valueof(acc.get('Id')),
            String.valueof(acc.get('PersonContactId'))
          );
          system.debug('AccId' + String.valueof(acc.get('Id')));
          system.debug('AccoBject' + String.valueof(acc));

          if (string.valueof(acc.get('isPersonAccount')) == 'true') {
            SetofPersonAccounts.add(String.valueof(acc.get('id')));
          }

          if (acc.get(appNameSpace + 'Social_Insurance_Number__pc') != null) {
            system.debug(
              'Sin' + acc.get(appNameSpace + 'Social_Insurance_Number__pc')
            );
            System.debug('AccId:' + acc.get('Id'));
            //MapofSINandAccount.put(String.valueof(acc.get('Social_Insurance_Number__pc')),String.valueof(acc.get('Id')));

            //Adding AccountId against SIN
            if (
              MapofSINandAccount.containskey(
                string.valueof(
                  acc.get(appNameSpace + 'Social_Insurance_Number__pc')
                )
              )
            ) {
              set<string> tempsObjlist = MapofSINandAccount.get(
                string.valueof(
                  acc.get(appNameSpace + 'Social_Insurance_Number__pc')
                )
              );
              tempsObjlist.add(String.valueof(acc.get('Id')));
              MapofSINandAccount.put(
                string.valueof(
                  acc.get(appNameSpace + 'Social_Insurance_Number__pc')
                ),
                tempsObjlist
              );
            } else {
              set<string> tempsObjlist = new Set<string>();
              tempsObjlist.add(String.valueof(acc.get('Id')));
              MapofSINandAccount.put(
                string.valueof(
                  acc.get(appNameSpace + 'Social_Insurance_Number__pc')
                ),
                tempsObjlist
              );
            }
          }

          if (acc.get('PersonEmail') != null) {
            system.debug('Email' + acc.get('PersonEmail'));
            //MapofEmailandAccount.put(String.valueof(acc.get('PersonEmail')).toLowerCase(),String.valueof(acc.get('Id')));

            //Adding AccountId against EMAIL
            if (
              MapofEmailandAccount.containskey(
                string.valueof(acc.get('PersonEmail')).toLowerCase()
              )
            ) {
              set<string> tempsObjlist = MapofEmailandAccount.get(
                string.valueof(acc.get('PersonEmail')).toLowerCase()
              );
              tempsObjlist.add(String.valueof(acc.get('Id')));
              MapofEmailandAccount.put(
                string.valueof(acc.get('PersonEmail')).toLowerCase(),
                tempsObjlist
              );
            } else {
              set<string> tempsObjlist = new Set<string>();
              tempsObjlist.add(String.valueof(acc.get('Id')));
              MapofEmailandAccount.put(
                string.valueof(acc.get('PersonEmail')).toLowerCase(),
                tempsObjlist
              );
            }
          }

          if (acc.get(appNameSpace + 'FilogixId__c') != null) {
            system.debug(
              'FilogixId__c=' + acc.get(appNameSpace + 'FilogixId__c')
            );
            MapofFilogixIdandAccount.put(
              String.valueof(acc.get(appNameSpace + 'FilogixId__c')),
              String.valueof(acc.get('Id'))
            );
          }

          if (acc.get('Name') != null) {
            system.debug('Name=' + acc.get('Name'));
            MapofNameandAccount.put(
              String.valueof(acc.get('Name')).toLowerCase(),
              String.valueof(acc.get('Id'))
            );
          }

          //system.debug('FilogixId='+acc.get(appNameSpace+'FilogixId__c'));
          //system.debug('AccountId='+MapofFilogixIdandAccount.get(String.valueof(acc.get(appNameSpace+'FilogixId__c'))));
        }
      }

      /*// Query to get all the Existing loan applicants having the Same SIN or Email in current Application              
System.debug('ApplicantIds::'+ListofApplicantIds);
String applicantRecordsQuery = 'SELECT Id, '+appNameSpace+'FilogixId__c, LoanApplicationId, Social_Insurance_Number__c, Email__c, ContactId, Contact.AccountId, Contact.Email FROM LoanApplicant WHERE Social_Insurance_Number__c IN :ListofSIN OR Email__c IN :ListofEmail OR id IN :ListofApplicantIds OR '+appNameSpace+'FilogixId__c IN :ListofFilogixIds';
List<sObject> loanApplicantRecords = database.query(applicantRecordsQuery);

// Getting a MAP populated with LOAN APPLICANT ID against their AccountIds  
if(loanApplicantRecords!=NULL && loanApplicantRecords.size() > 0){
for(sObject la : loanApplicantRecords){
system.debug('ApplicantId'+String.valueof(la.get('Id')));
system.debug('LAoBject'+String.valueof(la));
if(la.getSObject('Contact')!=null){
system.debug('Contact oBject'+String.valueof(la.getSObject('Contact')));
system.debug('PersonAccountId'+String.valueof(la.getSObject('Contact').get('AccountId')));
loanApplicantAccount.put(String.valueof(la.get('Id')),String.valueof(la.getSObject('Contact').get('AccountId')));
MapofApplicantandApplication.put(String.valueof(la.get('Id')),String.valueof(la.get('LoanApplicationId')));
MapofAccountandContact.put(String.valueof(la.getSObject('Contact').get('AccountId')),String.valueof(la.get('ContactId')));

if(la.get('Social_Insurance_Number__c')!=null){
system.debug('Sin'+la.get('Social_Insurance_Number__c'));
//MapofSINandAccount.put(String.valueof(la.get('Social_Insurance_Number__c')),String.valueof(la.getSObject('Contact').get('AccountId')));

//Adding AccountId against SIN 
if(MapofSINandAccount.containskey(string.valueof(la.get('Social_Insurance_Number__c')))){
set<string> tempsObjlist = MapofSINandAccount.get(string.valueof(la.get('Social_Insurance_Number__c')));
tempsObjlist.add(String.valueof(la.getSObject('Contact').get('AccountId')));
MapofSINandAccount.put(string.valueof(la.get('Social_Insurance_Number__c')),tempsObjlist);
}else{
set<string> tempsObjlist = new set<string>();
tempsObjlist.add(String.valueof(la.getSObject('Contact').get('AccountId')));
MapofSINandAccount.put(string.valueof(la.get('Social_Insurance_Number__c')),tempsObjlist);
}

}
if(la.get('Email__c')!=null){
system.debug('Email'+la.get('Email__c'));
//MapofEmailandAccount.put(String.valueof(la.get('Email__c')).toLowerCase(),String.valueof(la.getSObject('Contact').get('AccountId')));

//Adding AccountId against EMAIL 
if(MapofEmailandAccount.containskey(string.valueof(la.get('Email__c')).toLowerCase())){
set<string> tempsObjlist = MapofEmailandAccount.get(string.valueof(la.get('Email__c')).toLowerCase());
tempsObjlist.add(String.valueof(la.getSObject('Contact').get('AccountId')));
MapofEmailandAccount.put(string.valueof(la.get('Email__c')).toLowerCase(),tempsObjlist);
}else{
set<string> tempsObjlist = new set<string>();
tempsObjlist.add(String.valueof(la.getSObject('Contact').get('AccountId')));
MapofEmailandAccount.put(string.valueof(la.get('Email__c')).toLowerCase(),tempsObjlist);
}
}
}
//if(la.get(appNameSpace+'FilogixId__c')!=null){
//    system.debug('FilogixId__c'+appNameSpace+'FilogixId__c');
//   MapofFilogixIdandAccount.put(String.valueof(appNameSpace+'FilogixId__c'),String.valueof(la.getSObject('Contact').get('AccountId')));
//}
}
}*/

      //List<FilogixGETJSONWrapper.ApplicantGroup> applicantGroups = (List<FilogixGETJSONWrapper.ApplicantGroup>) app.result.mortgageApplication.applicantGroup;
      if (applicantGroups != null) {
        system.debug('applicantGroups=' + applicantGroups);
        system.debug('applicantGroupsSize=' + applicantGroups.size());
        Set<String> SetofAccExistInDML = new Set<string>();
        // ApplicantGroups
        for (
          FilogixGETJSONWrapper.ApplicantGroup applicantGroup : applicantGroups
        ) {
          List<FilogixGETJSONWrapper.Applicant> loanApplicants = (List<FilogixGETJSONWrapper.Applicant>) applicantGroup.applicant;
          // ApplicantGroup
          if (loanApplicants != null) {
            system.debug('loanApplicants=' + loanApplicants);
            for (
              FilogixGETJSONWrapper.Applicant loanApplicant : loanApplicants
            ) {
              // Applicant
              system.debug('applicant=' + loanApplicant);
              sObject lApp = Schema.getGlobalDescribe()
                .get(loanapplicantObjectApiName)
                .newSObject();
              sObject Acc = Schema.getGlobalDescribe()
                .get(accountObjectApiName)
                .newSObject();
              system.debug(
                'BorrowerId=' + String.valueof(loanApplicant.borrowerId)
              );
              lApp.put(
                appNameSpace + 'FilogixId__c',
                String.valueof(loanApplicant.borrowerId)
              ); //+'|'+String.valueof(app.result.mortgageApplication.deal.applicationId));
              Acc.put(
                appNameSpace + 'FilogixId__c',
                String.valueof(loanApplicant.borrowerId)
              );
              System.debug('Adding LoanApplicationID against LoanApplicant');
              lApp.put(
                objNamePrefix + 'LoanApplicationId' + customFieldSuffix,
                appId
              );
              System.debug('Added LoanApplicationID against LoanApplicant');
              mDebugUntruncated('JSON(lApp::' + JSON.serialize(lApp));
              lApp.put(
                appNameSpace + 'Applicant_Group_Type__c',
                applicantGroup.applicantGroupTypeDd
              );
              // Record Mapping

              //Parent/Actual Data Mapping
              if (
                !String.isEmpty(
                  String.valueof(loanApplicant.clientReferenceNumber)
                ) &&
                loanApplicantAccount.containsKey(
                  loanApplicant.clientReferenceNumber
                )
              ) {
                // Check if ID exists?
                //Only Add the ID if the Applicant is associated with the current AppId
                if (
                  MapofApplicantandApplication.get(
                    String.valueof(loanApplicant.clientReferenceNumber)
                  ) == appId
                ) {
                  lApp.put('id', (ID) loanApplicant.clientReferenceNumber);
                }
                Acc.put(
                  'Id',
                  loanApplicantAccount.get(loanApplicant.clientReferenceNumber)
                );
              }

              //Matching SIN
              if (
                !String.isEmpty(
                  String.valueof(loanApplicant.socialInsuranceNumber)
                )
              ) {
                // Check if SIN exists?
                if (
                  MapofSINandAccount.containsKey(
                    String.valueof(loanApplicant.socialInsuranceNumber)
                  ) && !lApp.isSet('Id')
                ) {
                  lApp.put(
                    'ContactId' + customFieldSuffix,
                    MapofAccountandContact.get(
                      new List<String>(
                          MapofSINandAccount.get(
                            String.valueof(loanApplicant.socialInsuranceNumber)
                          )
                        )
                        .get(0)
                    )
                  );
                }

                // Checking if map contains the SIN and Accountid haven't mapped already
                if (
                  MapofSINandAccount.containsKey(
                    String.valueof(loanApplicant.socialInsuranceNumber)
                  ) && !Acc.isSet('Id')
                ) {
                  system.debug(
                    'SIN::' +
                    String.valueof(loanApplicant.socialInsuranceNumber)
                  );
                  //system.debug('AccID::'+MapofSINandAccount.get(String.valueof(loanApplicant.socialInsuranceNumber)));
                  //Checking if Map has accountIds
                  if (
                    MapofSINandAccount.get(
                      String.valueof(loanApplicant.socialInsuranceNumber)
                    ) != null &&
                    MapofSINandAccount.get(
                        String.valueof(loanApplicant.socialInsuranceNumber)
                      )
                      .size() > 0
                  ) {
                    // Looping on map results i.e. Unique Account ids
                    for (
                      String accIdtoMap : MapofSINandAccount.get(
                        String.valueof(loanApplicant.socialInsuranceNumber)
                      )
                    ) {
                      // Checking if the account is already being mapped for another applicant under same application
                      // If not,
                      if (
                        !SetofAccExistInDML.contains(accIdtoMap) &&
                        !Acc.isSet('Id')
                      ) {
                        SetofAccExistInDML.add(accIdtoMap); // Adding Accountid in a set to track if added for this application
                        Acc.put('Id', accIdtoMap); // Adding the mapping
                      }
                    }
                  }
                }
              }

              //Matching Email
              if (!String.isEmpty(String.valueof(loanApplicant.emailAddress))) {
                // Check if Email exists?
                if (
                  MapofEmailandAccount.containsKey(
                    String.valueof(loanApplicant.emailAddress).toLowerCase()
                  ) && !lApp.isSet('Id')
                ) {
                  lApp.put(
                    'ContactId' + customFieldSuffix,
                    MapofAccountandContact.get(
                      new List<String>(
                          MapofEmailandAccount.get(
                            String.valueof(loanApplicant.emailAddress)
                              .toLowerCase()
                          )
                        )
                        .get(0)
                    )
                  );
                }

                // Checking if map contains the EMAIL and Accountid haven't mapped already
                if (
                  MapofEmailandAccount.containsKey(
                    String.valueof(loanApplicant.emailAddress).toLowerCase()
                  ) && !Acc.isSet('Id')
                ) {
                  system.debug(
                    'Email::' +
                    String.valueof(loanApplicant.emailAddress).toLowerCase()
                  );
                  //system.debug('AccID::'+MapofEmailandAccount.get(String.valueof(loanApplicant.emailAddress).toLowerCase()));
                  //Acc.put('Id', MapofEmailandAccount.get(String.valueof(loanApplicant.emailAddress).toLowerCase()));

                  //Checking if Map has accountIds
                  if (
                    MapofEmailandAccount.get(
                      String.valueof(loanApplicant.emailAddress).toLowerCase()
                    ) != null &&
                    MapofEmailandAccount.get(
                        String.valueof(loanApplicant.emailAddress).toLowerCase()
                      )
                      .size() > 0
                  ) {
                    // Looping on map results i.e. Unique Account ids
                    for (
                      String accIdtoMap : MapofEmailandAccount.get(
                        String.valueof(loanApplicant.emailAddress).toLowerCase()
                      )
                    ) {
                      // Checking if the account is already being mapped for another applicant under same application
                      system.debug('SetofAccExistInDML=' + SetofAccExistInDML);
                      // If not,
                      system.debug(
                        'SetofAccExistInDML.contains(' +
                          accIdtoMap +
                          ')=' +
                          SetofAccExistInDML.contains(accIdtoMap)
                      );
                      if (
                        !SetofAccExistInDML.contains(accIdtoMap) &&
                        !Acc.isSet('Id')
                      ) {
                        system.debug(
                          'Adding AccID=' +
                            accIdtoMap +
                            ' against=' +
                            String.valueof(loanApplicant.emailAddress)
                              .toLowerCase()
                        );
                        SetofAccExistInDML.add(accIdtoMap); // Adding Accountid in a set to track if added for this application
                        Acc.put('Id', accIdtoMap); // Adding the mapping
                      }
                    }
                  }
                }
              }

              // Matching Filogix ID
              if (!String.isEmpty(String.valueof(loanApplicant.borrowerId))) {
                // Check if BorrowerId exists?
                system.debug(
                  'Map has the key=' +
                  MapofFilogixIdandAccount.containsKey(
                    String.valueof(loanApplicant.borrowerId)
                  )
                );
                system.debug('AccId is set already? =' + Acc.isSet('Id'));
                mDebugUntruncated('Acc::' + Acc);
                if (
                  MapofFilogixIdandAccount.containsKey(
                    String.valueof(loanApplicant.borrowerId)
                  ) && !Acc.isSet('Id')
                ) {
                  system.debug(
                    'FilogixId::' + String.valueof(loanApplicant.borrowerId)
                  );
                  system.debug(
                    'AccID::' +
                    MapofFilogixIdandAccount.get(
                      String.valueof(loanApplicant.borrowerId)
                    )
                  );
                  Acc.put(
                    'Id',
                    MapofFilogixIdandAccount.get(
                      String.valueof(loanApplicant.borrowerId)
                    )
                  );
                }
              }

              //Matching Name
              if (loanApplicant.name != null) {
                // Check if Borrower Name exists?
                // Addiitonal Check to prevent any error on either first or last name being null
                if (
                  loanApplicant.name.firstname != null &&
                  loanApplicant.name.lastname != null
                ) {
                  system.debug(
                    'Map has the key=' +
                    MapofNameandAccount.containsKey(
                      String.valueof(loanApplicant.name.firstname)
                          .toLowerCase() +
                        ' ' +
                        String.valueof(loanApplicant.name.lastname)
                          .toLowerCase()
                    )
                  );
                  system.debug('AccId is set already? =' + Acc.isSet('Id'));
                  if (
                    MapofNameandAccount.containsKey(
                      String.valueof(loanApplicant.name.firstname)
                          .toLowerCase() +
                        ' ' +
                        String.valueof(loanApplicant.name.lastname)
                          .toLowerCase()
                    ) && !Acc.isSet('Id')
                  ) {
                    system.debug(
                      'FilogixId::' + String.valueof(loanApplicant.borrowerId)
                    );
                    system.debug(
                      'AccID::' +
                      MapofNameandAccount.get(
                        String.valueof(loanApplicant.name.firstname)
                            .toLowerCase() +
                          ' ' +
                          String.valueof(loanApplicant.name.lastname)
                            .toLowerCase()
                      )
                    );
                    Acc.put(
                      'Id',
                      MapofNameandAccount.get(
                        String.valueof(loanApplicant.name.firstname)
                            .toLowerCase() +
                          ' ' +
                          String.valueof(loanApplicant.name.lastname)
                            .toLowerCase()
                      )
                    );
                  }
                }
              }

              // If Account is NOT a Person Account, then update the Business Account Lookup
              if (
                !SetofPersonAccounts.contains(string.valueof(Acc.get('id'))) &&
                Acc.isSet('id')
              ) {
                // When Business Account isn't populated already
                if (!lApp.isSet(appNameSpace + 'Business_Account__c')) {
                  // Populating the contactID for LoanApplicant
                  // New Instance for Contact
                  sObject bacc = Schema.getGlobalDescribe()
                    .get(AccountObjectApiName)
                    .newSObject();
                  bacc.put(
                    appNameSpace + 'FilogixId__c',
                    String.valueof(loanApplicant.borrowerId)
                  );
                  // Populating contact dynamically
                  SObjectField loanApplicantParentLookupx = Schema.getGlobalDescribe()
                    .get(loanapplicantObjectApiName)
                    .getDescribe()
                    .fields.getMap()
                    .get(appNameSpace + 'Business_Account__c');
                  lApp.putSObject(
                    loanApplicantParentLookupx.getDescribe()
                      .getRelationshipName(),
                    bacc
                  );
                }

                // Else, populate the CONTACT lookup
              } else {
                // When ContactId isn't populated already
                if (!lApp.isSet('ContactId' + customFieldSuffix)) {
                  // Populating the contactID for LoanApplicant
                  // New Instance for Contact
                  sObject con = Schema.getGlobalDescribe()
                    .get(contactObjectApiName)
                    .newSObject();
                  con.put(
                    appNameSpace + 'FilogixId__c',
                    String.valueof(loanApplicant.borrowerId)
                  );
                  // Populating contact dynamically
                  SObjectField loanApplicantParentLookup = Schema.getGlobalDescribe()
                    .get(loanapplicantObjectApiName)
                    .getDescribe()
                    .fields.getMap()
                    .get(objNamePrefix + 'ContactId' + customFieldSuffix);
                  lApp.putSObject(
                    loanApplicantParentLookup.getDescribe()
                      .getRelationshipName(),
                    con
                  );
                }
              }

              lApp.put(
                'MaritalStatus' + customFieldSuffix,
                loanApplicant.maritalStatusDd
              );
              lApp.put(
                'PreferredLanguage' + customFieldSuffix,
                loanApplicant.languagePreferenceDd
              );
              if (loanApplicant.name != null) {
                lApp.put(
                  'Name',
                  loanApplicant.name.firstName +
                    ' ' +
                    loanApplicant.name.lastName
                );
                //Acc.put('Name', loanApplicant.name.firstName +' ' +loanApplicant.name.lastName);
                Acc.put('FirstName', loanApplicant.name.firstName);
                Acc.put('lastName', loanApplicant.name.lastName);
                system.debug('##1==' + loanApplicant.name.firstName);
                system.debug('##2==' + loanApplicant.name.lastName);
                system.debug('##3==' + loanApplicant.name.first);
                system.debug('##4==' + loanApplicant.name.last);
                if (
                  loanApplicant.name.lastName == null &&
                  loanApplicant.name.firstname == null
                ) {
                  Acc.put('Firstname', loanApplicant.name.first);
                  Acc.put('LastName', loanApplicant.name.last);
                }

                // Salutation Mapping
                if (loanApplicant.name.salutationDd != null) {
                  Acc.put('Salutation', loanApplicant.name.salutationDd); //+'.'); //Appending "." because Salesforce has . in Salutations and Filogix doesn't.
                }
              } else {
                lApp.put('Name', 'Empty/Null Name');
                //Acc.put('Name', loanApplicant.name.firstName +' ' +loanApplicant.name.lastName);
                Acc.put('FirstName', 'Empty/Null');
                Acc.put('lastName', 'Name');
              }
              Acc.put(
                appNameSpace + 'FilogixId__pc',
                String.valueof(loanApplicant.borrowerId)
              );
              Acc.put(
                appNameSpace + 'Social_Insurance_Number__pc',
                loanApplicant.socialInsuranceNumber
              );
              //lApp.put(appNameSpace+'Social_Insurance_Number__pc', loanApplicant.socialInsuranceNumber);
              Acc.put('PersonMobilePhone', loanApplicant.borrowerCellNumber);
              //lApp.put('Phone__c', loanApplicant.borrowerCellNumber);
              Acc.put('Fax', loanApplicant.borrowerFaxNumber);
              Acc.put('PersonHomePhone', loanApplicant.borrowerHomePhoneNumber);

              //Id personAccountRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
              // Because the Person Account RecordType can have a differrent name.
              Id personAccountRecordTypeId;
              String personAccountRecordTypeName='PersonAccount'; // Setting default RecordType DeveloperName
              // Error Handling for Multiple Record Type
              // Now Using a DEFAULT RECORD TYPE field and Keeping the PERSONACCOUNT default where NONE selected.
              // Getting Current ORG's MJ Integration Info
  			  MortgageJunction_Config__mdt appConfig = MJ_Helper.getMJConfig();
                
              
                
              try {
                  
                  personAccountRecordTypeName = appConfig?.PersonAccount_RecordType__c!=null?appConfig?.PersonAccount_RecordType__c:personAccountRecordTypeName;
                  
                  String personAccountQuery = 'SELECT Id, Name, SobjectType,IsPersonType FROM RecordType WHERE DeveloperName=:personAccountRecordTypeName AND IsPersonType=True limit 1';
                  sObject personAccountData = Database.query(String.escapeSingleQuotes(personAccountQuery));
                    
                  if (personAccountData != null) {
                    personAccountRecordTypeId = String.valueof(personAccountData.get('Id'));
                  } 
              } catch(Exception e){
                //String errorMsg = 'Please <a target="_blank" href="/n/MJ_Setup">Enable the Set Default Person Account</a>.';
                String errorMsg = 'Error: Please set the Default Person Account Record Type from the <a target="_blank" href="/lightning/n/' +appNameSpace +'MortgageJunction_Setup">MortgageJunction Setup</a> screen.';
                throw MJ_Helper.createCustomException(errorMsg);
              }
                
                // Only set the RecordType & OwnerId for New Record.
                if(!Acc.isSet('Id')){
                    Acc.put('RecordTypeID', personAccountRecordTypeId); //Assigning Record Type
                    Acc.put('ownerId', rlaOwnerId); // Assigning Owner.
                }
                
              Acc.put(
                'Work_Phone_Extension__pc',
                loanApplicant.borrowerWorkPhoneExtension
              );
              Acc.put('Work_Phone__pc', loanApplicant.borrowerWorkPhoneNumber);
              Acc.put('PersonEmail', loanApplicant.emailAddress);
              //lApp.put('Email__c', loanApplicant.emailAddress);
              if (loanApplicant.birthDate != null) {
                //lApp.put(appNameSpace+'Birthday__c', Date.valueOf(loanApplicant.birthDate)); // Converting "1983-04-15" to the SF date format
                Acc.put(
                  'PersonBirthDate',
                  Date.valueOf(loanApplicant.birthDate)
                );
              }
              lApp.put(
                appNameSpace + 'Preferred_Contact_Method__c',
                loanApplicant.preferredContactMethodDd
              );
              //Acc.put('FinServ__ContactPreference__pc', loanApplicant.preferredContactMethodDd);
              //lApp.put(appNameSpace+'Social_Insurance_Number__c', loanApplicant.socialInsuranceNumber);

              /*if(loanApplicant.addressDetail !=null){
//Acc.put('PersonMailingStreet', loanApplicant.addressDetail[0].address.streetNumber+' '+loanApplicant.addressDetail[0].address.streetName);
Acc.put(appNameSpace+'Street_Name__c',loanApplicant.addressDetail[0].address?.streetName);
Acc.put(appNameSpace+'Street_Number__c',loanApplicant.addressDetail[0].address?.streetNumber);
Acc.put('PersonMailingCity', loanApplicant.addressDetail[0].address.city);
Acc.put('PersonMailingState', loanApplicant.addressDetail[0].address.provinceDd);
Acc.put('PersonMailingCountry', loanApplicant.addressDetail[0].address.countryTypeDd);
}*/

              /*Added by Zain Abbas - Start*/
              lApp.put(
                appNameSpace + 'Bankruptcy_Status__c',
                loanApplicant.bankruptcyStatusDd
              );
              lApp.put(
                appNameSpace + 'Citizenship_Type__c',
                loanApplicant.citizenshipTypeDd
              );
              lApp.put(
                appNameSpace + 'Credit_Score__c',
                loanApplicant.creditScore
              );
              lApp.put(
                appNameSpace + 'Current_Address_Same_As__c',
                booleanFormatting(loanApplicant.currentAddressSameAs)
              );
              lApp.put(
                appNameSpace + 'Employee_Number__c',
                loanApplicant.employeeNumber
              );
              lApp.put('GenderType' + customFieldSuffix, loanApplicant.gender);
              lApp.put(
                appNameSpace + 'Is_Employee__c',
                booleanFormatting(loanApplicant.citizenshipTypeDd)
              );
              lApp.put(appNameSpace + 'Pair_Order__c', loanApplicant.pairOrder);
              lApp.put(
                appNameSpace + 'Smoker__c',
                booleanFormatting(loanApplicant.smokerDd)
              );
              lApp.put(
                appNameSpace + 'Solicitation__c',
                booleanFormatting(loanApplicant.solicitationDd)
              );
              if (applicantGroup.borrowerGroupId != null) {
                lApp.put(
                  appNameSpace + 'Borrower_Group_Id__c',
                  string.valueOf(applicantGroup.borrowerGroupId)
                );
              }
              lApp.put(
                appNameSpace + 'Mailing_Address_Indicator__c',
                applicantGroup.mailingAddressIndicator
              );
              lApp.put(
                'DependentCount' + customFieldSuffix,
                loanApplicant.numberOfDependents
              );
              lApp.put(
                appNameSpace + 'Primary_Applicant__c',
                booleanFormatting(loanApplicant.primaryApplicantFlag)
              );
              lApp.put(
                appNameSpace + 'Relationship_To_Primary_Applicant__c',
                loanApplicant.relationshipToPrimaryApplicant
              );
              lApp.put(
                appNameSpace + 'Existing_Client__c',
                booleanFormatting(loanApplicant.existingClient)
              );
              lApp.put(
                appNameSpace + 'First_Time_Buyer__c',
                booleanFormatting(loanApplicant.firstTimeBuyer)
              );
              /*Added by Zain Abbas - End */

              //Updating RLA record
              /*if(String.valueof(loanApplicant.primaryApplicantFlag) == 'Y'){
// Removing the current value of Account
// To prevent INVALID_FIELD - Cannot specify both an external ID reference Account and a salesforce id, AccountId
rla = removeElementfromSObject(rla,'AccountId');
// Populating the contactID for LoanApplicant
// New Instance for Contact
sObject AccClone = Schema.getGlobalDescribe().get(accountObjectApiName).newSObject();
AccClone.put(appNameSpace+'FilogixId__c',String.valueof(loanApplicant.borrowerId));
// Populating contact dynamically
SObjectField loanAppParentLookupforApplicant = Schema.getGlobalDescribe().get(loanApplicationObjectApiName).getDescribe().fields.getMap().get('AccountId');
rla.putSObject(loanAppParentLookupforApplicant.getDescribe().getRelationshipName(),AccClone);  
}*/

              // New Instance for LA References
              sObject lAppClone = Schema.getGlobalDescribe()
                .get(loanapplicantObjectApiName)
                .newSObject();
              lAppClone.put(
                appNameSpace + 'FilogixId__c',
                String.valueof(loanApplicant.borrowerId)
              );
              //To Map use the following lines
              //SObjectField loanApplicantLookup = Schema.getGlobalDescribe().get(loanapplicantObjectApiName).getDescribe().fields.getMap().get('ContactId');
              //lApp.putSObject(loanApplicantParentLookup.getDescribe().getRelationshipName(),lAppClone);

              mDebugUntruncated('lApp END::' + JSON.serialize(lApp));
              // Adding records to a list
              updateApp.add(Acc);
              updateApp.add(lApp);

              // End Applicant Mapping

              // Applicant Identification
              List<FilogixGETJSONWrapper.Identification> loanApplicantIdentifications = (List<FilogixGETJSONWrapper.Identification>) loanApplicant.identification;
              if (loanApplicantIdentifications != null) {
                for (
                  FilogixGETJSONWrapper.Identification loanApplicantIdentification : loanApplicantIdentifications
                ) {
                  sObject loanAppIdentity = Schema.getGlobalDescribe()
                    .get(loanAppIdentificationObjectApiName)
                    .newSObject();
                  //Loan Applicant Record Mapping
                  SObjectField loanApplicantLookup1Ident = Schema.getGlobalDescribe()
                    .get(loanAppIdentificationObjectApiName)
                    .getDescribe()
                    .fields.getMap()
                    .get(appNameSpace + 'Loan_Applicant__c');
                  loanAppIdentity.putSObject(
                    loanApplicantLookup1Ident.getDescribe()
                      .getRelationshipName(),
                    lAppClone
                  );

                  loanAppIdentity.put(
                    appNameSpace + 'IdentificationNumber__c',
                    String.valueof(
                      loanApplicantIdentification.identificationNumber
                    )
                  );
                  loanAppIdentity.put(
                    appNameSpace + 'Country__c',
                    loanApplicantIdentification.identificationCountry
                  );
                  loanAppIdentity.put(
                    appNameSpace + 'Type__c',
                    loanApplicantIdentification.identificationTypeDd
                  );
                  loanAppIdentity.put(
                    appNameSpace + 'FilogixId__c',
                    String.valueof(loanApplicantIdentification.identificationId)
                  );
                  loanAppIdentity.put(
                    'Name',
                    loanApplicantIdentification.identificationTypeDd +
                      ' - ' +
                      String.valueof(
                        loanApplicantIdentification.identificationId
                      )
                  );
                  //mDebugUntruncated('=== Identity:`JSON.serialize(loanAppIdentity)=' + JSON.serialize(loanAppIdentity));
                  updateApp.add(loanAppIdentity);
                }
              }
                
                
                
                /*system.debug('applicantGroup.mailingAddressIndicator='+applicantGroup.mailingAddressIndicator);
                // Mailing Address Handling for Group When indicator is missing.
                if(applicantGroup.mailingAddressIndicator==null || applicantGroup.mailingAddressIndicator=='O' && applicantGroup.mailingAddr!=null){
                    FilogixGETJSONWrapper.MailingAddr mailingaddressDetails = (FilogixGETJSONWrapper.MailingAddr) applicantGroup.MailingAddr;
              		
                    sObject mailingAdd = Schema.getGlobalDescribe()
                    .get(loanAppAddressObjectApiName)
                    .newSObject();
                  //Loan Applicant Record Mapping
                  SObjectField loanApplicantLookup1a1 = Schema.getGlobalDescribe()
                    .get(loanAppAddressObjectApiName)
                    .getDescribe()
                    .fields.getMap()
                    .get(objNamePrefix + 'LoanApplicantId' + customFieldSuffix);
                  mailingAdd.putSObject(
                    loanApplicantLookup1a1.getDescribe().getRelationshipName(),
                    lAppClone
                  );
                  mailingAdd.put(
                    objNamePrefix + 'LoanApplicationId' + customFieldSuffix,
                    appId
                  );

                  mailingAdd.put('Name', 'Mailing Address');
                    
                    mailingAdd.put(
                      appNameSpace + 'FilogixId__c',
                      String.valueof(mailingaddressDetails.addrId)
                    );
                    
                    mailingAdd.put(
                      appNameSpace + 'Unit_Number__c',
                      mailingaddressDetails.unitNumber
                    );
                    mailingAdd.put(
                      appNameSpace + 'Street_Number__c',
                      mailingaddressDetails.streetNumber
                    );
                    mailingAdd.put(
                      appNameSpace + 'Street_Name__c',
                      mailingaddressDetails.streetName
                    );
                    mailingAdd.put(
                      appNameSpace + 'Street_Type__c',
                      mailingaddressDetails.streetTypeDd
                    );
                    mailingAdd.put(
                      appNameSpace + 'Street_Direction__c',
                      mailingaddressDetails.streetDirectionDd
                    );
                    mailingAdd.put(
                      appNameSpace + 'City__c',
                      mailingaddressDetails.city
                    );
                    mailingAdd.put(
                      appNameSpace + 'Province__c',
                      mailingaddressDetails.provinceDd
                    );
                    mailingAdd.put(
                      appNameSpace + 'PostalCode__c',
                      mailingaddressDetails.internationalPostalCode
                    );
                    mailingAdd.put(
                      appNameSpace + 'Country__c',
                      mailingaddressDetails.countryTypeDd
                    );
                    
                    String postalFSA = '';
                    String postalLDU = '';

                    if (mailingaddressDetails.postalFsa != null) {
                      postalFSA = mailingaddressDetails.postalFsa;
                    }
                    if (mailingaddressDetails.postalLdu != null) {
                      postalLDU = mailingaddressDetails.postalLdu;
                    }
                    mailingAdd.put(
                      appNameSpace + 'PostalCode__c',
                      postalFSA + postalLDU
                    );
                   
                   
                  updateApp.add(mailingAdd);
                }*/	

              // Applicant Address
              List<FilogixGETJSONWrapper.addressDetail> loanApplicantaddressDetails = (List<FilogixGETJSONWrapper.addressDetail>) loanApplicant.addressDetail;
              if (loanApplicantaddressDetails != null) {
                for (
                  FilogixGETJSONWrapper.addressDetail loanApplicantaddress : loanApplicantaddressDetails
                ) {
                  sObject loanAppAdd = Schema.getGlobalDescribe()
                    .get(loanAppAddressObjectApiName)
                    .newSObject();
                  //Loan Applicant Record Mapping
                  SObjectField loanApplicantLookup1a = Schema.getGlobalDescribe()
                    .get(loanAppAddressObjectApiName)
                    .getDescribe()
                    .fields.getMap()
                    .get(objNamePrefix + 'LoanApplicantId' + customFieldSuffix);
                  loanAppAdd.putSObject(
                    loanApplicantLookup1a.getDescribe().getRelationshipName(),
                    lAppClone
                  );
                  loanAppAdd.put(
                    objNamePrefix + 'LoanApplicationId' + customFieldSuffix,
                    appId
                  );

                  loanAppAdd.put(
                    'ResidencyType' + customFieldSuffix,
                    loanApplicantaddress.addressTypeDd
                  );
                  loanAppAdd.put(
                    'MonthlyRentPayment' + customFieldSuffix,
                    loanApplicantaddress.rentPaymentAmount
                  );
                  if (loanApplicantaddress.monthsAtAddress != null) {
                    loanAppAdd.put(
                      'ResidenceAdditionalMonthCount' + customFieldSuffix,
                      Integer.valueof(
                        Decimal.valueof(
                            Math.Mod(
                              Integer.valueof(
                                loanApplicantaddress.monthsAtAddress
                              ),
                              12
                            )
                          )
                          .setScale(0)
                      )
                    );
                    loanAppAdd.put(
                      'ResidenceYearCount' + customFieldSuffix,
                      Integer.valueof(
                        Decimal.valueof(
                            loanApplicantaddress.monthsAtAddress / 12
                          )
                          .setScale(0)
                      )
                    );
                  }
                  loanAppAdd.put(
                    'AddressOwnership' + customFieldSuffix,
                    loanApplicantaddress.residentialStatusDd
                  );
				  String AddressName = loanApplicantaddress.address.streetNumber + ' ' +loanApplicantaddress.address.streetName;
                  //Replacing null from AddressName - Ticket#5693 - v1.45
                  AddressName = AddressName.replaceAll('null','');
                  if (loanApplicantaddress.address != null) {
                    loanAppAdd.put(
                      'Name',
                      AddressName.trim()==''?'null':AddressName.trim()
                    );
                    loanAppAdd.put(
                      appNameSpace + 'FilogixId__c',
                      String.valueof(loanApplicantaddress.address.addrId)
                    );
                    loanAppAdd.put(
                      appNameSpace + 'Unit_Number__c',
                      loanApplicantaddress.address.unitNumber
                    );
                    loanAppAdd.put(
                      appNameSpace + 'Street_Number__c',
                      loanApplicantaddress.address.streetNumber
                    );
                    loanAppAdd.put(
                      appNameSpace + 'Street_Name__c',
                      loanApplicantaddress.address.streetName
                    );
                    loanAppAdd.put(
                      appNameSpace + 'Street_Type__c',
                      loanApplicantaddress.address.streetTypeDd
                    );
                    loanAppAdd.put(
                      appNameSpace + 'Street_Direction__c',
                      loanApplicantaddress.address.streetDirectionDd
                    );
                    loanAppAdd.put(
                      appNameSpace + 'City__c',
                      loanApplicantaddress.address.city
                    );
                    loanAppAdd.put(
                      appNameSpace + 'Province__c',
                      loanApplicantaddress.address.provinceDd
                    );
                    loanAppAdd.put(
                      appNameSpace + 'PostalCode__c',
                      loanApplicantaddress.address.postalFsa +
                      loanApplicantaddress.address.postalLdu
                    );
                    loanAppAdd.put(
                      appNameSpace + 'Country__c',
                      loanApplicantaddress.address.countryTypeDd
                    );
                    String postalFSA = '';
                    String postalLDU = '';

                    if (loanApplicantaddress.address.postalFsa != null) {
                      postalFSA = loanApplicantaddress.address.postalFsa;
                    }
                    if (loanApplicantaddress.address.postalLdu != null) {
                      postalLDU = loanApplicantaddress.address.postalLdu;
                    }
                    loanAppAdd.put(
                      appNameSpace + 'PostalCode__c',
                      postalFSA + postalLDU
                    );
                  } else {
                    loanAppAdd.put('Name', loanApplicantaddress.addressTypeDd);
                  }
                  /*Added by Zain Abbas - Start*/
                  //loanAppAdd.put(appNameSpace+'Street_Number__c', loanApplicantaddress.address.streetNumber);
                  /*Added by Zain Abbas - End*/
                  updateApp.add(loanAppAdd);
                }
              }

              // Applicant employmentHistory
              List<FilogixGETJSONWrapper.employmentHistory> loanApplicantEmploymentHistories = (List<FilogixGETJSONWrapper.employmentHistory>) loanApplicant.employmentHistory;
              if (loanApplicantEmploymentHistories != null) {
                for (
                  FilogixGETJSONWrapper.employmentHistory loanApplicantEmploymentHistory : loanApplicantEmploymentHistories
                ) {
                  //LoanApplicantEmployment loanAppEmp = new LoanApplicantEmployment();

                  sObject loanAppEmp = Schema.getGlobalDescribe()
                    .get(loanAppEmploymentObjectApiName)
                    .newSObject();
                  loanAppEmp.put(
                    appNameSpace + 'FilogixId__c',
                    String.valueof(
                      loanApplicantEmploymentHistory.employmentHistoryId
                    )
                  );
                  //loanAppEmp.put('LoanApplicantId', (ID) loanApplicant.clientReferenceNumber);
                  //Loan Applicant Record Mapping
                  system.debug(
                    'EmplRel::' +
                      loanAppEmploymentObjectApiName +
                      ' => ' +
                      objNamePrefix +
                      'LoanApplicantId' +
                      customFieldSuffix
                  );
                  SObjectField loanApplicantLookup1 = Schema.getGlobalDescribe()
                    .get(loanAppEmploymentObjectApiName)
                    .getDescribe()
                    .fields.getMap()
                    .get(objNamePrefix + 'LoanApplicantId' + customFieldSuffix);
                  loanAppEmp.putSObject(
                    loanApplicantLookup1.getDescribe().getRelationshipName(),
                    lAppClone
                  );

                  loanAppEmp.put(
                    objNamePrefix + 'LoanApplicationId' + customFieldSuffix,
                    appId
                  );
                  if (loanApplicantEmploymentHistory.contact != null) {
                    if (
                      loanApplicantEmploymentHistory.contact.address != null
                    ) {
                      loanAppEmp.put(
                        'EmployerStreet' + customFieldSuffix,
                        loanApplicantEmploymentHistory.contact.address.addressLine1
                      );
                      loanAppEmp.put(
                        'Address_Line_2__c',
                        loanApplicantEmploymentHistory.contact.address.addressLine2
                      );
                      loanAppEmp.put(
                        'EmployerCity' + customFieldSuffix,
                        loanApplicantEmploymentHistory.contact.address.city
                      );
                      //loanAppEmp.put('EmployerPostalCode', loanApplicantEmploymentHistory.contact.address.internationalPostalCode);
                      loanAppEmp.put(
                        'EmployerCountry' + customFieldSuffix,
                        loanApplicantEmploymentHistory.contact.address.countryTypeDd
                      );
                      loanAppEmp.put(
                        'EmployerState' + customFieldSuffix,
                        loanApplicantEmploymentHistory.contact.address.provinceDd
                      );

                      String postalFSA = '';
                      String postalLDU = '';

                      if (
                        loanApplicantEmploymentHistory.contact.address.postalFsa !=
                        null
                      ) {
                        postalFSA = loanApplicantEmploymentHistory.contact.address.postalFsa;
                      }
                      if (
                        loanApplicantEmploymentHistory.contact.address.postalLdu !=
                        null
                      ) {
                        postalLDU = loanApplicantEmploymentHistory.contact.address.postalLdu;
                      }
                      loanAppEmp.put(
                        'EmployerPostalCode' + customFieldSuffix,
                        postalFSA + postalLDU
                      );
                    }
                    System.debug('Employmer Phone='+loanApplicantEmploymentHistory.contact.contactPhoneNumber);
                    loanAppEmp.put(
                      'EmployerPhone' + customFieldSuffix,
                      loanApplicantEmploymentHistory.contact.contactPhoneNumber
                    );
                  }
                  loanAppEmp.put(
                    'Amount__c',
                    loanApplicantEmploymentHistory.income.incomeAmount
                  );
                  loanAppEmp.put(
                    appNameSpace + 'Income_Frequency__c',
                    loanApplicantEmploymentHistory.income.incomePeriodDd
                  );
                  loanAppEmp.put(
                    appNameSpace + 'Type__c',
                    loanApplicantEmploymentHistory.income.incomeTypeDd
                  );
                  loanAppEmp.put(
                    appNameSpace + 'Gross_Revenue__c',
                    loanApplicantEmploymentHistory.grossRevenue
                  );
                  loanAppEmp.put(
                    appNameSpace + 'Operating_As__c',
                    loanApplicantEmploymentHistory.operatingAs
                  );
                  loanAppEmp.put(
                    appNameSpace + 'Company_Type__c',
                    loanApplicantEmploymentHistory.companyType
                  );
                  loanAppEmp.put(
                    'EmployerName' + customFieldSuffix,
                    loanApplicantEmploymentHistory.employerName
                  );
                  string loanAppEmpName = loanApplicantEmploymentHistory.employerName !=
                    null
                    ? String.valueof(
                        loanApplicantEmploymentHistory.employerName
                      )
                    : String.valueof(
                        loanApplicantEmploymentHistory.employmentHistoryId
                      );
                  loanAppEmp.put('Name', loanAppEmpName);
                  loanAppEmp.put(
                    appNameSpace + 'History_Status__c',
                    loanApplicantEmploymentHistory.employmentHistoryStatusDd
                  );
                  loanAppEmp.put(
                    appNameSpace + 'History_Type__c',
                    loanApplicantEmploymentHistory.employmentHistoryTypeDd
                  );
                  //loanAppEmp.put('MonthlyTotalIncomeAmount',loanApplicantEmploymentHistory.grossRevenue);//Field is not writeable
                  loanAppEmp.put(
                    appNameSpace + 'Industry_Sector__c',
                    loanApplicantEmploymentHistory.industrySectorDd
                  );
                  loanAppEmp.put(
                    'JobTitle' + customFieldSuffix,
                    loanApplicantEmploymentHistory.jobTitle
                  );
                  loanAppEmp.put(
                    'CurrentJobAdditionalMonthCount' + customFieldSuffix,
                    loanApplicantEmploymentHistory.monthsOfService
                  );
                  loanAppEmp.put(
                    appNameSpace + 'Occupation__c',
                    loanApplicantEmploymentHistory.occupationDd
                  );
                  //loanAppEmp.put('Name',loanApplicantEmploymentHistory.operatingAs);
                  loanAppEmp.put(
                    'IsSelfEmployed' + customFieldSuffix,
                    booleanFormatting(
                      loanApplicantEmploymentHistory.selfEmploymentFlag
                    )
                  );
                  loanAppEmp.put(
                    'Time_In_Industry__c',
                    loanApplicantEmploymentHistory.timeInIndustry
                  );
                  // Calculation
                  //loanAppEmp.put('CurrentJobYearCount',Integer.valueof(loanApplicantEmploymentHistory.monthsOfService/12));
                  if (loanApplicantEmploymentHistory.monthsOfService != null) {
                    loanAppEmp.put(
                      'CurrentJobAdditionalMonthCount' + customFieldSuffix,
                      Integer.valueof(
                        Decimal.valueof(
                            Math.Mod(
                              Integer.valueof(
                                loanApplicantEmploymentHistory.monthsOfService
                              ),
                              12
                            )
                          )
                          .setScale(0)
                      )
                    );
                    loanAppEmp.put(
                      'CurrentJobYearCount' + customFieldSuffix,
                      Integer.valueof(
                        Decimal.valueof(
                            loanApplicantEmploymentHistory.monthsOfService / 12
                          )
                          .setScale(0)
                      )
                    );
                  }
                  //if (loanApplicant.clientReferenceNumber != null) {
                  //Only update if LoanApplicantId is available
                  updateApp.add(loanAppEmp);
                  //}
                }
              }
              // Applicant OtherIncome
              List<FilogixGETJSONWrapper.otherIncome> loanApplicantotherIncomes = (List<FilogixGETJSONWrapper.otherIncome>) loanApplicant.otherIncome;
              system.debug(
                'Income::' + String.valueof(loanApplicantotherIncomes)
              );

              if (loanApplicantotherIncomes != null) {
                system.debug('Income not null');
                for (
                  FilogixGETJSONWrapper.otherIncome loanApplicantotherIncome : loanApplicantotherIncomes
                ) {
                  //LoanApplicantIncome loanAppOI = new LoanApplicantIncome();
                  system.debug(
                    'Income::' +
                    String.valueof(loanApplicantotherIncome.incomeId)
                  );
                  sObject loanAppOI = Schema.getGlobalDescribe()
                    .get(loanAppIncomeObjectApiName)
                    .newSObject();
                  loanAppOI.put(
                    appNameSpace + 'FilogixId__c',
                    String.valueof(loanApplicantotherIncome.incomeId)
                  );
                  loanAppOI.put(
                    objNamePrefix + 'LoanApplicationId' + customFieldSuffix,
                    appId
                  );
                  //loanAppOI.put('LoanApplicantId',(ID) loanApplicant.clientReferenceNumber);
                  SObjectField loanApplicantLookup2 = Schema.getGlobalDescribe()
                    .get(loanAppIncomeObjectApiName)
                    .getDescribe()
                    .fields.getMap()
                    .get(objNamePrefix + 'LoanApplicantId' + customFieldSuffix);
                  loanAppOI.putSObject(
                    loanApplicantLookup2.getDescribe().getRelationshipName(),
                    lAppClone
                  );

                  loanAppOI.put(
                    'Income_Amount__c',
                    loanApplicantotherIncome.incomeAmount
                  );
                  string IncName = !string.isBlank(
                      loanApplicantotherIncome.incomeDescription
                    )
                    ? loanApplicantotherIncome.incomeDescription
                    : (!string.isBlank(loanApplicantotherIncome.incomeTypeDd)
                        ? loanApplicantotherIncome.incomeTypeDd
                        : String.valueof(loanApplicantotherIncome.incomeId));
                  loanAppOI.put('Name', IncName);
                  loanAppOI.put('Description__c', loanApplicantotherIncome.incomeDescription);
                  loanAppOI.put(
                    appNameSpace + 'Income_Period__c',
                    loanApplicantotherIncome.incomePeriodDd
                  );
                  loanAppOI.put(
                    'IncomeSourceType' + customFieldSuffix,
                    loanApplicantotherIncome.incomeTypeDd
                  );
                  updateApp.add(loanAppOI);
                }
              }
              // Applicant Asset
              List<FilogixGETJSONWrapper.asset> loanApplicantAssets = (List<FilogixGETJSONWrapper.asset>) loanApplicant.asset;
              if (loanApplicantAssets != null) {
                for (
                  FilogixGETJSONWrapper.asset loanApplicantAsset : loanApplicantAssets
                ) {
                  //if(!String.isEmpty(String.valueof(loanApplicant.clientReferenceNumber))){
                  //LoanApplicantAsset loanAppAss = new LoanApplicantAsset();
                  // First we've to add LoanApplication Asset before Applicant Asset as they've Parent-Child relationship
                  system.debug('@@@loanApplicantAsset==' + loanApplicantAsset);
                  sObject loanAppAssParent = Schema.getGlobalDescribe()
                    .get(loanAssetObjectApiName)
                    .newSObject();
                  loanAppAssParent.put(
                    appNameSpace + 'FilogixId__c',
                    String.valueof(loanApplicantAsset.assetId)
                  );
                  loanAppAssParent.put(
                    'AssetType' + customFieldSuffix,
                    loanApplicantAsset.assetTypeDd
                  );
                  loanAppAssParent.put(
                    'CashOrMarketValue' + customFieldSuffix,
                    loanApplicantAsset.assetValue
                  );
                  string AssetName = !string.isBlank(
                      loanApplicantAsset.assetTypeDd
                    )
                    ? loanApplicantAsset.assetTypeDd
                    : 'Empty String';
                  loanAppAssParent.put('Name', AssetName);
                  loanAppAssParent.put(
                    appNameSpace + 'Down_Payment_Amount__c',
                    loanApplicantAsset.downpaymentAmount
                  );
                  boolean jointAsset = loanApplicantAsset.shared == 'Y'
                    ? true
                    : false;
                  loanAppAssParent.put(
                    'IsJointAsset' + customFieldSuffix,
                    jointAsset
                  );
                  loanAppAssParent.put(
                    objNamePrefix + 'LoanApplicationId' + customFieldSuffix,
                    appId
                  );
                  loanAppAssParent.put(
                    appNameSpace + 'Description__c',
                    loanApplicantAsset.assetDescription
                  );
                  updateApp.add(loanAppAssParent);

                  // Duplicate for Lookup
                  sObject loanAppAssParent1 = Schema.getGlobalDescribe()
                    .get(loanAssetObjectApiName)
                    .newSObject();
                  loanAppAssParent1.put(
                    appNameSpace + 'FilogixId__c',
                    String.valueof(loanApplicantAsset.assetId)
                  );

                  // Applicant Asset
                  sObject loanAppAss = Schema.getGlobalDescribe()
                    .get(loanAppAssetObjectApiName)
                    .newSObject();
                  //loanAppAss.put(appNameSpace+'FilogixId__c',String.valueof(loanApplicantAsset.assetId));
                  //loanAppAss.put('LoanApplicantId',(ID) loanApplicant.clientReferenceNumber);
                  //Loan Applicant Record Mapping
                  SObjectField loanApplicantLookup3 = Schema.getGlobalDescribe()
                    .get(loanAppAssetObjectApiName)
                    .getDescribe()
                    .fields.getMap()
                    .get(objNamePrefix + 'LoanApplicantId' + customFieldSuffix);
                  loanAppAss.putSObject(
                    loanApplicantLookup3.getDescribe().getRelationshipName(),
                    lAppClone
                  );
                  //loanAppAss.put(objNamePrefix+'LoanApplicationId',appId);
                  SObjectField loanAppAssParentLookup = Schema.getGlobalDescribe()
                    .get(loanAppAssetObjectApiName)
                    .getDescribe()
                    .fields.getMap()
                    .get(
                      objNamePrefix +
                        'LoanApplicationAssetId' +
                        customFieldSuffix
                    );
                  loanAppAss.putSObject(
                    loanAppAssParentLookup.getDescribe().getRelationshipName(),
                    loanAppAssParent1
                  );
                  loanAppAss.put(
                    appNameSpace + 'FilogixId__c',
                    'a' + String.valueof(loanApplicantAsset.assetId)
                  );
                  updateApp.add(loanAppAss);
                  mDebugUntruncated(
                    'AssetP===:`JSON.serialize(loanAppAssParent)=' +
                      JSON.serialize(loanAppAssParent) +
                      '`'
                  );
                  mDebugUntruncated(
                    'Asset===:`JSON.serialize(loanAppAss)=' +
                      JSON.serialize(loanAppAss) +
                      '`'
                  );

                  //}
                }
              }
              // Applicant Liability
              List<FilogixGETJSONWrapper.liability> loanApplicantliabilities = (List<FilogixGETJSONWrapper.liability>) loanApplicant.liability;
              if (loanApplicantliabilities != null) {
                for (
                  FilogixGETJSONWrapper.liability loanApplicantLiability : loanApplicantliabilities
                ) {
                  //LoanApplicantLiability loanAppLiability = new LoanApplicantLiability();
                  // First we've to add LoanApplication Liability before Applicant Liability as they've Parent-Child relationship

                  sObject loanAppLiabilityParent = Schema.getGlobalDescribe()
                    .get(loanLiabilityObjectApiName)
                    .newSObject();
                  loanAppLiabilityParent.put(
                    appNameSpace + 'FilogixId__c',
                    String.valueof(loanApplicantLiability.liabilityId)
                  );
                  loanAppLiabilityParent.put(
                    'CreditLimitAmount' + customFieldSuffix,
                    loanApplicantLiability.creditLimit
                  );
                  loanAppLiabilityParent.put(
                    appNameSpace + 'Liability_Amount__c',
                    loanApplicantLiability.liabilityAmount
                  );
                  //Trimming to prevent spaces in the value as test class has
                  String nameVal = loanApplicantLiability.liabilityTypeDd !=
                    null
                    ? String.valueof(loanApplicantLiability.liabilityTypeDd)
                    : String.valueof(
                        loanApplicantLiability.liabilityDescription
                      );
                  loanAppLiabilityParent.put(
                    'Name',
                    nameVal != null
                      ? nameVal.trim()
                      : String.valueof(loanApplicantLiability.liabilityId)
                  );
                  loanAppLiabilityParent.put(
                    'MonthlyPaymentAmount' + customFieldSuffix,
                    loanApplicantLiability.liabilityMonthlyPayment
                  );
                  loanAppLiabilityParent.put(
                    'OtherLiabilityType' + customFieldSuffix,
                    String.valueof(loanApplicantLiability.liabilityTypeDd)
                  );
                  boolean jointLiability = loanApplicantLiability.shared == 'Y'
                    ? true
                    : false;
                  loanAppLiabilityParent.put(
                    'IsJointLiability' + customFieldSuffix,
                    jointLiability
                  );
                  //Illegal assignment from String to Date
                  loanAppLiabilityParent.put(
                    appNameSpace + 'Maturity_Date__c',
                    Date.valueof(
                      MJ_Helper.returnGMTformat(
                        (loanApplicantLiability.maturityDate)
                      )
                    )
                  );
                  loanAppLiabilityParent.put(
                    appNameSpace + 'Monthly_Payment_Override__c',
                    booleanFormatting(
                      loanApplicantLiability.monthlyPaymentOverride
                    )
                  );
                  loanAppLiabilityParent.put(
                    appNameSpace + 'Credit_Bureau__c',
                    booleanFormatting(loanApplicantLiability.cbScraped)
                  );
                  loanAppLiabilityParent.put(
                    objNamePrefix + 'LoanApplicationId' + customFieldSuffix,
                    appId
                  );

                  /*Added by Zain - Start*/
                  loanAppLiabilityParent.put(
                    appNameSpace + 'Liability_Description__c',
                    loanApplicantLiability.liabilityDescription
                  );
                  /*Added by Zain - End*/

                  updateApp.add(loanAppLiabilityParent);

                  // Duplicate for Lookup
                  sObject loanAppLiabilityParent1 = Schema.getGlobalDescribe()
                    .get(loanLiabilityObjectApiName)
                    .newSObject();
                  loanAppLiabilityParent1.put(
                    appNameSpace + 'FilogixId__c',
                    String.valueof(loanApplicantLiability.liabilityId)
                  );

                  // Applicant Liability
                  sObject loanAppLiability = Schema.getGlobalDescribe()
                    .get(loanAppLiabilityObjectApiName)
                    .newSObject();
                  //loanAppLiability.put(appNameSpace+'FilogixId__c',String.valueof(loanApplicantLiability.liabilityId));
                  //loanAppLiability.put('LoanApplicantId',(ID) loanApplicant.clientReferenceNumber);
                  //Loan Applicant Record Mapping
                  SObjectField loanApplicantLookup4 = Schema.getGlobalDescribe()
                    .get(loanAppLiabilityObjectApiName)
                    .getDescribe()
                    .fields.getMap()
                    .get(objNamePrefix + 'LoanApplicantId' + customFieldSuffix);
                  loanAppLiability.putSObject(
                    loanApplicantLookup4.getDescribe().getRelationshipName(),
                    lAppClone
                  );

                  loanAppLiability.put(
                    appNameSpace + 'FilogixId__c',
                    'l' + String.valueof(loanApplicantLiability.liabilityId)
                  );
                  //loanAppLiability.put(objNamePrefix+'LoanApplicationId',appId);
                  SObjectField loanAppLiabilityParentLookup = Schema.getGlobalDescribe()
                    .get(loanAppLiabilityObjectApiName)
                    .getDescribe()
                    .fields.getMap()
                    .get(
                      objNamePrefix +
                        'LoanApplicationLiabilityId' +
                        customFieldSuffix
                    );
                  loanAppLiability.putSObject(
                    loanAppLiabilityParentLookup.getDescribe()
                      .getRelationshipName(),
                    loanAppLiabilityParent1
                  );

                  //LoanAppLiability.put(appNameSpace+'Credit_Bureau__c',booleanFormatting(loanApplicantLiability.cbScraped));

                  // loanAppLiability.LoanApplicationLiability.CreditLimitAmount = loanApplicantLiability.creditLimit;
                  // loanAppLiability.LoanApplicationLiability.Liability_Amount__c = loanApplicantLiability.liabilityAmount;
                  // loanAppLiability.LoanApplicationLiability.Liability_Description__c = loanApplicantLiability.liabilityDescription;
                  // loanAppLiability.LoanApplicationLiability.MonthlyPaymentAmount = loanApplicantLiability.liabilityMonthlyPayment;
                  // loanAppLiability.LoanApplicationLiability.OtherLiabilityType = loanApplicantLiability.liabilityTypeDd;
                  //Illegal assignment from String to Date
                  //loanAppLiability.LoanApplicationLiability.Maturity_Date__c = loanApplicantLiability.maturityDate;
                  //loanAppLiability.LoanApplicationLiability.Monthly_Payment_Override__c = booleanFormatting(loanApplicantLiability.monthlyPaymentOverride);

                  updateApp.add(loanAppLiability);
                }
              }
              // Applicant Other Property
              List<FilogixGETJSONWrapper.otherProperty> loanApplicantotherProperties = (List<FilogixGETJSONWrapper.otherProperty>) loanApplicant.otherProperty;
              if (loanApplicantotherProperties != null) {
                for (
                  FilogixGETJSONWrapper.otherProperty loanApplicantotherProperty : loanApplicantotherProperties
                ) {
                  // Excluding Subject Property to add AGAIN on Upsert as Filogix providers all the Applicant Properties under this section
                  //system.debug('SubjectProp Check='+subjectProp_FilogixId+'!='+String.valueof(loanApplicantotherProperty.property.propertyId));
                  if (
                    String.valueof(
                      loanApplicantotherProperty.property.primaryPropertyFlag
                    ) == 'N'
                  ) {
                    sObject loanOtherProp = Schema.getGlobalDescribe()
                      .get(loanPropertyObjectApiName)
                      .newSObject();
                    //loanOtherProp.put(appNameSpace+'Loan_Applicant__c',(ID) loanApplicant.clientReferenceNumber);
                    //Loan Applicant Record Mapping
                    SObjectField loanApplicantLookup5 = Schema.getGlobalDescribe()
                      .get(loanPropertyObjectApiName)
                      .getDescribe()
                      .fields.getMap()
                      .get(appNameSpace + 'Loan_Applicant__c');
                    loanOtherProp.putSObject(
                      loanApplicantLookup5.getDescribe().getRelationshipName(),
                      lAppClone
                    );
                    loanOtherProp.put(
                      objNamePrefix + 'LoanApplicationId' + customFieldSuffix,
                      appId
                    );
                    loanOtherProp.put(
                      'Name',
                      String.valueof(
                        loanApplicantotherProperty.property.propertyId
                      )
                    );
                    loanOtherProp.put(
                      appNameSpace + 'FilogixId__c',
                      String.valueof(
                        loanApplicantotherProperty.property.propertyId
                      )
                    );
                    loanOtherProp.put(
                      appNameSpace + 'AppraisedValue__c',
                      loanApplicantotherProperty.property.actualAppraisalValue
                    );
                    loanOtherProp.put(
                      appNameSpace + 'Appraisal_Date__c',
                      MJ_Helper.returnGMTformat(
                        loanApplicantotherProperty.property.appraisalDateAct
                      )
                    ); // Illegal assignment from String to Datetime
                    loanOtherProp.put(
                      appNameSpace + 'Style__c',
                      loanApplicantotherProperty.property.dwellingStyleDd
                    );
                    loanOtherProp.put(
                      appNameSpace + 'Structure_Type__c',
                      loanApplicantotherProperty.property.dwellingTypeDd
                    );
                    loanOtherProp.put(
                      'PropertyValue' + customFieldSuffix,
                      loanApplicantotherProperty.property.estimatedAppraisalValue
                    );
                    loanOtherProp.put(
                      appNameSpace + 'feesIncludeHeat__c',
                      booleanFormatting(
                        loanApplicantotherProperty.property.feesIncludeHeat
                      )
                    );
                    loanOtherProp.put(
                      appNameSpace + 'Garage_Size__c',
                      loanApplicantotherProperty.property.garageSizeDd
                    );
                    loanOtherProp.put(
                      appNameSpace + 'Garage_Type__c',
                      loanApplicantotherProperty.property.garageTypeDd
                    );
                    loanOtherProp.put(
                      appNameSpace + 'Heat__c',
                      loanApplicantotherProperty.property.heatTypeDd
                    );
                    loanOtherProp.put(
                      appNameSpace + 'includetds__c',
                      booleanFormatting(
                        loanApplicantotherProperty.property.includetds
                      )
                    );
                    loanOtherProp.put(
                      appNameSpace + 'insulatedWithUffi__c',
                      booleanFormatting(
                        loanApplicantotherProperty.property.insulatedWithUffi
                      )
                    );
                    loanOtherProp.put(
                      appNameSpace + 'lot__c',
                      loanApplicantotherProperty.property.legalLine1
                    );
                    loanOtherProp.put(
                      appNameSpace + 'block__c',
                      loanApplicantotherProperty.property.legalLine2
                    );
                    loanOtherProp.put(
                      appNameSpace + 'Conc_Township__c',
                      loanApplicantotherProperty.property.legalLine3
                    );
                    loanOtherProp.put(
                      appNameSpace + 'livingSpace__c',
                      loanApplicantotherProperty.property.livingSpace
                    );
                    loanOtherProp.put(
                      appNameSpace + 'livingSpaceUnitOfMeasurDd__c',
                      loanApplicantotherProperty.property.livingSpaceUnitOfMeasurDd
                    );
                    loanOtherProp.put(
                      appNameSpace + 'lotSize__c',
                      loanApplicantotherProperty.property.lotSize
                    );
                    loanOtherProp.put(
                      appNameSpace + 'lotSizeUnitOfMeasure__c',
                      loanApplicantotherProperty.property.lotSizeUnitOfMeasureDd
                    );
                    loanOtherProp.put(
                      appNameSpace + 'mlsListingFlag__c',
                      booleanFormatting(
                        loanApplicantotherProperty.property.mlsListingFlag
                      )
                    );
                    loanOtherProp.put(
                      appNameSpace + 'Construction_Type__c',
                      loanApplicantotherProperty.property.newConstructionDd
                    );
                    loanOtherProp.put(
                      appNameSpace + 'numberOfUnits__c',
                      loanApplicantotherProperty.property.numberOfUnits
                    );
                    loanOtherProp.put(
                      'PropertyUseType' + customFieldSuffix,
                      loanApplicantotherProperty.property.occupancyTypeDd
                    );
                    loanOtherProp.put(
                      appNameSpace + 'Property_Type__c',
                      loanApplicantotherProperty.property.propertyTypeDd
                    );
                    loanOtherProp.put(
                      appNameSpace + 'propertyValueIndexId__c',
                      loanApplicantotherProperty.property.propertyValueIndexId
                    );
                    loanOtherProp.put(
                      appNameSpace + 'Original_Purchase_Price__c',
                      loanApplicantotherProperty.property.originalPurchasePrice
                    );
                    loanOtherProp.put(
                      appNameSpace + 'realtorInfo__c',
                      loanApplicantotherProperty.property.realtorInfo
                    );
                    loanOtherProp.put(
                      appNameSpace + 'rentalOffsetOption__c',
                      loanApplicantotherProperty.property.rentalOffsetOption
                    );
                    loanOtherProp.put(
                      appNameSpace + 'Sewage_Type__c',
                      loanApplicantotherProperty.property.sewageTypeDd
                    );
                    loanOtherProp.put(
                      appNameSpace + 'structureAge__c',
                      loanApplicantotherProperty.property.structureAge
                    );
                    loanOtherProp.put(
                      appNameSpace + 'taxationYear__c',
                      loanApplicantotherProperty.property.taxationYear
                    );
                    loanOtherProp.put(
                      appNameSpace + 'Water_Type__c',
                      loanApplicantotherProperty.property.waterTypeDd
                    );
                    loanOtherProp.put(
                      appNameSpace + 'Is_Subject_Property__c',
                      booleanFormatting(
                        loanApplicantotherProperty.property.subjectPropertyFlag
                      )
                    );
                    /*Added by Zain Abbas - Start*/
                    loanOtherProp.put(
                      appNameSpace + 'Purchase_Date__c',
                      MJ_Helper.returnGMTformat(
                        loanApplicantotherProperty.property.refiOrigPurchaseDate
                      )
                    );
                    loanOtherProp.put(
                      appNameSpace + 'purchasePrice__c',
                      loanApplicantotherProperty.property.purchasePrice
                    );

                    // Address Fields
                    if (loanApplicantotherProperty.property.address != null) {
                      loanOtherProp.put(
                        appNameSpace + 'PropertyUnitNumber__c',
                        String.valueof(
                          loanApplicantotherProperty.property.address.unitNumber
                        )
                      );
                      //loanOtherProp.put(appNameSpace+'PropertyStreetNumber__c',String.valueof(loanApplicantotherProperty.property.address.streetNumber));
                      //loanOtherProp.put('PropertyStreet',String.valueof(loanApplicantotherProperty.property.address.streetNumber)+''+String.valueof(loanApplicantotherProperty.property.address.streetName));
                      loanOtherProp.put(
                        appNameSpace + 'Street_Type__c',
                        String.valueof(
                          loanApplicantotherProperty.property.address.streetTypeDd
                        )
                      );
                      loanOtherProp.put(
                        appNameSpace + 'Direction__c',
                        String.valueof(
                          loanApplicantotherProperty.property.address.streetDirectionDd
                        )
                      );
                      loanOtherProp.put(
                        appNameSpace + 'City__c',
                        String.valueof(
                          loanApplicantotherProperty.property.address.city
                        )
                      );
                      loanOtherProp.put(
                        appNameSpace + 'Province__c',
                        String.valueof(
                          loanApplicantotherProperty.property.address.provinceDd
                        )
                      );
                      //loanOtherProp.put('PropertyPostalCode',String.valueof(loanApplicantotherProperty.property.address.postalFsa)+String.valueof(loanApplicantotherProperty.property.address.postalLdu));
                      loanOtherProp.put(
                        appNameSpace + 'Country__c',
                        String.valueof(
                          loanApplicantotherProperty.property.address.countryTypeDd
                        )
                      );

                      String opostalFsa = '';
                      String opostalLdu = '';
                      String ostreetNumber = '';
                      String ostreetName = '';
                      if (
                        loanApplicantotherProperty.property.address.streetNumber !=
                        null
                      ) {
                        ostreetNumber = loanApplicantotherProperty.property.address.streetNumber;
                      }
                      if (
                        loanApplicantotherProperty.property.address.streetName !=
                        null
                      ) {
                        ostreetName = loanApplicantotherProperty.property.address.streetName;
                      }
                      if (
                        loanApplicantotherProperty.property.address.postalFsa !=
                        null
                      ) {
                        opostalFsa = loanApplicantotherProperty.property.address.postalFsa;
                      }
                      if (
                        loanApplicantotherProperty.property.address.postalLdu !=
                        null
                      ) {
                        opostalLdu = loanApplicantotherProperty.property.address.postalLdu;
                      }
                      loanOtherProp.put(
                        appNameSpace + 'PostalCode__c',
                        opostalFsa + opostalLdu
                      );
                      loanOtherProp.put(
                        appNameSpace + 'Street_Number__c',
                        ostreetNumber
                      );
                      loanOtherProp.put(
                        appNameSpace + 'Street_Name__c',
                        ostreetName
                      );

                      loanOtherProp.put(
                        'Name',
                        String.valueof(
                            loanApplicantotherProperty.property.address.city
                          ) +
                          ' - ' +
                          opostalFsa +
                          opostalLdu
                      );
                    }

                    // Property Expenses
                    List<FilogixGETJSONWrapper.propertyExpense> otherPropertyExpenses = (List<FilogixGETJSONWrapper.propertyExpense>) loanApplicantotherProperty.property.propertyExpense;
                    if (otherPropertyExpenses != null) {
                      for (
                        FilogixGETJSONWrapper.propertyExpense oPExpense : otherPropertyExpenses
                      ) {
                        if (oPExpense.propertyExpenseTypeDd == 'Insurance') {
                          loanOtherProp.put(
                            appNameSpace + 'Insurance_Expenses__c',
                            oPExpense.propertyExpenseAmount
                          );
                        } else if (
                          oPExpense.propertyExpenseTypeDd == 'Heating Expense'
                        ) {
                          loanOtherProp.put(
                            appNameSpace + 'Heating_Expenses__c',
                            oPExpense.propertyExpenseAmount
                          );
                        } else if (oPExpense.propertyExpenseTypeDd == 'Hydro') {
                          loanOtherProp.put(
                            appNameSpace + 'Hydro_Expenses__c',
                            oPExpense.propertyExpenseAmount
                          );
                        } else if (
                          oPExpense.propertyExpenseTypeDd == 'Interest Charges'
                        ) {
                          loanOtherProp.put(
                            appNameSpace + 'Interest_Expenses__c',
                            oPExpense.propertyExpenseAmount
                          );
                        } else if (
                          oPExpense.propertyExpenseTypeDd ==
                          'Management Expenses'
                        ) {
                          loanOtherProp.put(
                            appNameSpace + 'Management_Expenses__c',
                            oPExpense.propertyExpenseAmount
                          );
                        } else if (
                          oPExpense.propertyExpenseTypeDd == 'General Expenses'
                        ) {
                          loanOtherProp.put(
                            appNameSpace + 'Other_Expenses__c',
                            oPExpense.propertyExpenseAmount
                          );
                        } else if (
                          oPExpense.propertyExpenseTypeDd == 'Repairs'
                        ) {
                          loanOtherProp.put(
                            appNameSpace + 'Repairs_Expenses__c',
                            oPExpense.propertyExpenseAmount
                          );
                        } else if (
                          oPExpense.propertyExpenseTypeDd == 'Condo Fees'
                        ) {
                          loanOtherProp.put(
                            appNameSpace + 'Total_Condo_Fees__c',
                            oPExpense.propertyExpenseAmount
                          );
                        } else if (
                          oPExpense.propertyExpenseTypeDd == 'Municipal Taxes'
                        ) {
                          loanOtherProp.put(
                            appNameSpace + 'Annual_Taxes__c',
                            oPExpense.propertyExpenseAmount
                          );
                        }
                      }
                    }

                    updateApp.add(loanOtherProp);

                    /*// Property Expenses
List<FilogixGETJSONWrapper.propertyExpense> otherPropertyExpenses = (List<FilogixGETJSONWrapper.propertyExpense>) loanApplicantotherProperty.property.propertyExpense;
if (otherPropertyExpenses != null) {
system.debug('propertyExpenses=' + otherPropertyExpenses);
for (FilogixGETJSONWrapper.propertyExpense oPExpense : otherPropertyExpenses) {
system.debug('pExpense=' + oPExpense);
system.debug('PEOP='+appNameSpace);
//PropertyExpense__c pe = new PropertyExpense__c();
sObject peOtherProp = Schema.getGlobalDescribe().get(propertyExpenseObjectApiName).newSObject();
//peOtherProp.put(appNameSpace+'Loan_Application_Property__c',lAproperty.Id);
peOtherProp.put(appNameSpace+'propertyExpenseAmount__c',oPExpense.propertyExpenseAmount);
// Mapping Lookup
// Facing the error with the dynamic method
// initializing same object with different variable having externalId only and assigning here
sObject loanOtherPropLookup = Schema.getGlobalDescribe().get(loanPropertyObjectApiName).newSObject();
loanOtherPropLookup.put(appNameSpace+'FilogixId__c',String.valueof(loanApplicantotherProperty.property.propertyId));
// Now assigning this variable there
SObjectField loanAppPropertyLookup = Schema.getGlobalDescribe().get(propertyExpenseObjectApiName).getDescribe().fields.getMap().get(appNameSpace+'Loan_Application_Property__c');
peOtherProp.putSObject(loanAppPropertyLookup.getDescribe().getRelationshipName(),loanOtherPropLookup);

peOtherProp.put(appNameSpace+'propertyExpensePeriod__c',oPExpense.propertyExpensePeriodDd);
peOtherProp.put(appNameSpace+'propertyExpenseType__c',oPExpense.propertyExpenseTypeDd);
peOtherProp.put(appNameSpace+'Loan_Application__c',appId);
peOtherProp.put(appNameSpace+'Include_In_GDS__c',booleanFormatting(oPExpense.includeInGDS));
peOtherProp.put(appNameSpace+'Include_In_TDS__c',booleanFormatting(oPExpense.includeInTDS));
peOtherProp.put(appNameSpace+'Monthly_Expense_Amount__c',oPExpense.monthlyExpenseAmount);
peOtherProp.put(appNameSpace+'Percent_In_GDS__c',oPExpense.percentInGDS!=null?oPExpense.percentInGDS*100:0);
peOtherProp.put(appNameSpace+'Percent_In_TDS__c',oPExpense.percentInTDS!=null?oPExpense.percentInTDS*100:0);
peOtherProp.put(appNameSpace+'FilogixId__c',String.valueof(oPExpense.propertyExpenseId));
//updateApp.add(peOtherProp);
}
}*/

                    // Other Property Mortgages
                    List<FilogixGETJSONWrapper.Mortgage> otherPropMortgages = (List<FilogixGETJSONWrapper.Mortgage>) loanApplicantotherProperty.mortgage;
                    if (otherPropMortgages != null) {
                      system.debug('mortgages=' + otherPropMortgages);
                      for (
                        FilogixGETJSONWrapper.Mortgage oPMortgage : otherPropMortgages
                      ) {
                        sObject oPropMortgage = Schema.getGlobalDescribe()
                          .get(mortgageObjectApiName)
                          .newSObject();
                        system.debug('mortgage=' + oPMortgage);
                          
                        // Setting RLA OwnerId as Record OwnerId
                        oPropMortgage.put('ownerId',rlaOwnerId);
                          
                        oPropMortgage.put(
                          'Name',
                          oPMortgage.mortgageTypeDd +
                            ' - ' +
                            oPMortgage.loanTypeDd
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Actual_Payment_Term__c',
                          oPMortgage.actualPaymentTerm
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Amortization_Term__c',
                          oPMortgage.amortizationTerm
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Balance_Remaining__c',
                          oPMortgage.balanceRemaining
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Cash_Back_Amount__c',
                          oPMortgage.cashBackAmt
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Cash_Back_Override__c',
                          booleanFormatting(oPMortgage.cashBackOverride)
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Cash_Back_Percentage__c',
                          oPMortgage.cashBackPercentage
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Commercial__c',
                          booleanFormatting(oPMortgage.commercialFlag)
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Construction__c',
                          booleanFormatting(oPMortgage.constructionFlag)
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Existing_Mortgage__c',
                          booleanFormatting(oPMortgage.existingMortgageFlag)
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Heloc__c',
                          booleanFormatting(oPMortgage.helocFlag)
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Is_Insured__c',
                          booleanFormatting(oPMortgage.insuredFlag)
                        );
                        datetime insuranceAdjustDate = MJ_Helper.returnGMTformat(
                          oPMortgage.interestAdjustmentDate
                        );
                        //oPropMortgage.put(appNameSpace+'Insurance_Adjustment_Date__c', insuranceAdjustDate);
                        oPropMortgage.put(
                          appNameSpace + 'Interest_Adj_Date__c',
                          insuranceAdjustDate
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Interest_Adj_Amount__c',
                          oPMortgage.interestAdjustmentAmount
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Interest_Compound__c',
                          oPMortgage.interestCompoundDd
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Is_Interest_Only__c',
                          booleanFormatting(oPMortgage.interestOnlyFlag)
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Interest_Type__c',
                          oPMortgage.interestTypeDd
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Line_Of_Business__c',
                          oPMortgage.lineOfBusinessDd
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Loan_Type__c',
                          oPMortgage.loanTypeDd
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Mortgage_Type__c',
                          oPMortgage.mortgageTypeDd
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Mortgage_Insurance_Included__c',
                          booleanFormatting(oPMortgage.mtgInsIncludeFlag)
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Net_Loan_Amount__c',
                          oPMortgage.netLoanAmount
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Payment_Frequency__c',
                          oPMortgage.paymentFrequencyDd
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Payment_Term__c',
                          oPMortgage.paymentTermDd
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Ref_Blended_Amortization__c',
                          booleanFormatting(oPMortgage.refiBlendedAmortization)
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Interest_Rate__c',
                          oPMortgage.requestedRate
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Reverse_Flag__c',
                          booleanFormatting(oPMortgage.reverseFlag)
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Single_Progressive_Type__c',
                          oPMortgage.singleProgressiveTypeDd
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Sub_Prime__c',
                          booleanFormatting(oPMortgage.subprimeFlag)
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Qualify_Rate__c',
                          oPMortgage.qualifyRate
                        );
                        oPropMortgage.put(
                          appNameSpace + 'FilogixId__c',
                          String.valueof(oPMortgage.mortgageId)
                        );
                        //oPropMortgage.put('Name', String.valueof(oPMortgage.mortgageTypeDd)+' - '+String.valueof(oPMortgage.mortgageId));
                        oPropMortgage.put(
                          appNameSpace + 'Loan_Application__c',
                          appId
                        );
                        oPropMortgage.put(
                          appNameSpace + 'First_Payment_Date__c',
                          oPMortgage.firstPaymentDate != null
                            ? Date.valueof(MJ_Helper.returnGMTformat(oPMortgage.firstPaymentDate))
                            : null
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Premium__c',
                          oPMortgage.miPremiumPst
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Premium_Amount__c',
                          oPMortgage.miPremiumAmount
                        );
                        oPropMortgage.put(
                          appNameSpace + 'Total_Loan_Amount__c',
                          oPMortgage.totalLoanAmount
                        );
                        oPropMortgage.put(
                          appNameSpace + 'ltv__c',
                          oPMortgage.ltv != null ? oPMortgage.ltv * 100 : 0
                        );
                        oPropMortgage.put(
                          appNameSpace + 'PAndIPaymentAmount__c',
                          oPMortgage.PAndIPaymentAmount
                        );
                        oPropMortgage.put(
                          appNameSpace + 'PAndIPaymentAmount_Monthly__c',
                          oPMortgage.PAndIPaymentAmountMonthly
                        );
                        oPropMortgage.put(
                          appNameSpace + 'qualifyingGds__c',
                          oPMortgage.qualifyingGds != null
                            ? oPMortgage.qualifyingGds * 100
                            : 0
                        );
                        oPropMortgage.put(
                          appNameSpace + 'qualifyingTds__c',
                          oPMortgage.qualifyingTds != null
                            ? oPMortgage.qualifyingTds * 100
                            : 0
                        );

                        //oPropMortgage.put(appNameSpace+'Loan_Applicant__c',(ID) loanApplicant.clientReferenceNumber);
                        //propMortgage.put(appNameSpace+'Loan_Application_Property__c',rla.get(appNameSpace+'Subject_Property__c'));
                        // Mapping Lookup
                        // Method to dynamically add parent-child lookup (having ExternalID)
                        // https://salesforce.stackexchange.com/questions/161801/add-dynamic-lookup-on-contact-to-sobject-with-external-id
                        sObject loanOtherPropLookup_Mort = Schema.getGlobalDescribe()
                          .get(loanPropertyObjectApiName)
                          .newSObject();
                        loanOtherPropLookup_Mort.put(
                          appNameSpace + 'FilogixId__c',
                          String.valueof(
                            loanApplicantotherProperty.property.propertyId
                          )
                        );
                        SObjectField loanAppPropertyLookup_Mortgage = Schema.getGlobalDescribe()
                          .get(mortgageObjectApiName)
                          .getDescribe()
                          .fields.getMap()
                          .get(appNameSpace + 'Loan_Application_Property__c');
                        oPropMortgage.putSObject(
                          loanAppPropertyLookup_Mortgage.getDescribe()
                            .getRelationshipName(),
                          loanOtherPropLookup_Mort
                        );

                        //propMortgage.put(appNameSpace+'Original_Mortgage_Amount__c', oPMortgage.originalMortgageAmount);

                        /*Added by Zain Abbas - Start*/
                        if (oPMortgage.rate != null) {
                          oPropMortgage.put(
                            appNameSpace + 'BuyDown_Rate__c',
                            oPMortgage.rate.buyDownRate
                          );
                          oPropMortgage.put(
                            appNameSpace + 'Discount__c',
                            oPMortgage.rate.discount
                          );
                          oPropMortgage.put(
                            appNameSpace + 'Premium__c',
                            oPMortgage.rate.premium
                          );
                          oPropMortgage.put(
                            appNameSpace + 'Net_Rate__c',
                            oPMortgage.rate.netRate
                          );
                        }

                        if (oPMortgage.qualifyDetail != null) {
                          oPropMortgage.put(
                            appNameSpace + 'Qualify_Amortization_Term__c',
                            oPMortgage.qualifyDetail.amortizationTerm
                          );
                          oPropMortgage.put(
                            appNameSpace + 'Qualify_Interest_Compound__c',
                            oPMortgage.qualifyDetail.interestCompoundDd
                          );
                          oPropMortgage.put(
                            appNameSpace + 'Qualify_Is_Interest_Only__c',
                            booleanFormatting(
                              oPMortgage.qualifyDetail.interestOnlyFlag
                            )
                          );
                          oPropMortgage.put(
                            appNameSpace + 'Repayment_Type__c',
                            oPMortgage.qualifyDetail.repaymentTypeDd
                          );
                        }
                        oPropMortgage.put(
                          appNameSpace + 'Original_Mortgage_Amount__c',
                          oPMortgage.originalMortgageAmount
                        );
                        /*Added by Zain Abbas - End*/
                        updateApp.add(oPropMortgage);
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      //Adding all the records in a list.
      updateApp.add(rla);
      //updateApp.add(opp);

      if (updateApp.size() > 0) {
        //system.debug('UpdateApp=' + updateApp);
        mDebugUntruncated(
          'UpdateApp===:`JSON.serialize(UpdateApp)=' +
            JSON.serialize(UpdateApp) +
            '`'
        );
        //https://salesforce.stackexchange.com/questions/61340/is-it-possible-to-upsert-a-listsobject-with-external-id-specified
        //https://trailblazer.salesforce.com/ideaView?id=08730000000aNhVAAU
        ////Starting in the Summer '20 release. Mixed types of SObject within the argument list are also supported.
        //datbase.upsert(updateApp, filogixId__c, true); // Supports sObject - WorkAround
        //
        //https://www.mhamzas.com/blog/2019/12/13/upserts-with-generic-sobjects-salesforce/
        //upsert updateApp;
        //Database.UpsertResult[] results = Database.upsert(updateApp,false); //THIS SHOULD ALSO WORK
        //If Environment is NON-FSC append __c in FSC Standard Mortgage Objects
        upsertRecords(updateApp, objNameSuffix, objNamePrefix);
      }
      // Updating records not having filogixID (means old records)
      // If Environment is NON-FSC append __c in FSC Standard Mortgage Objects
      updateOldRecords(appId, objNameSuffix, objNamePrefix);
    }
  }

  // Updating old records
  public static void updateOldRecords(
    String appId,
    string objNameSuffix,
    string objNamePrefix
  ) {
    system.debug('Updating old Records');
    String appNameSpace = MJ_Helper.getAppNameSpace();

    //Check the subscriber's org status
    boolean isNonFSC = getEnvironmentType();
    //If Non-FSC populate suffix with __c
    string customRelationSuffix = '';

    if (isNonFSC == true) {
      customRelationSuffix = '__r';
    }

    List<SObject> listOFRecordsToUpdate = new List<SObject>();

    //Set of RelationShips (for only object where we need to update the old records)
    Set<String> relationships = new Set<String>();
    relationships.add(objNamePrefix + 'LoanApplicants' + customRelationSuffix);
    relationships.add(
      objNamePrefix + 'LoanApplicationProperties' + customRelationSuffix
    );
    relationships.add(objNamePrefix + 'Application_Fees__r');
    relationships.add(objNamePrefix + 'Down_Payment_Sources__r');
    relationships.add(
      objNamePrefix + 'LoanApplicantEmployments' + customRelationSuffix
    );
    //relationships.add('LoanApplicationAssets');
    //relationships.add('LoanApplicationLiabilities');
    relationships.add(
      objNamePrefix + 'LoanApplicantIncomes' + customRelationSuffix
    );
    relationships.add('Mortgages__r');
    //relationships.add('LoanApplicationFinancials');

    // Getting all the child records of this AppId
    String allRecordsQuery =
      'SELECT Id, Name, ' +
      appNameSpace +
      'FilogixId__c ';
    // Building a Query
    for (String objName : relationships) {
      allRecordsQuery +=
        ', (SELECT Id, Name, ' +
        appNameSpace +
        'FilogixId__c FROM ' +
        objName +
        ')';
    }
    //If Environment in FSC, ResidentialLoanApplication is passed, if not ResidentialLoanApplication__c is passed.
    string rlaObjName = 'ResidentialLoanApplication' + objNameSuffix;
    allRecordsQuery +=
      ' FROM ' +
      rlaObjName +
      ' where id=:appId WITH SECURITY_ENFORCED';
    // Loop on the records with condition to check if FilogixId is emptry

    for (
      Sobject sobj : Database.query(String.escapeSingleQuotes(allRecordsQuery))
    ) {
      system.debug('sobj::--' + sobj);
      if (sobj != null) {
        for (string childRelationShipName : relationships) {
          List<sObject> childRecords = sobj.getSObjects(childRelationShipName);

          system.debug('childRecords::--' + childRecords);

          if (childRecords != null && childRecords.size() > 0) {
            for (sObject childRec : childRecords) {
              if (String.isblank((String) childRec.get('FilogixId__c'))) {
                // Updating a checkbox to inactivate
                Boolean toupdate = false;
                //Getting the sObject Type
                String sObjType = String.valueOf(childRec.getSObjectType());
                String inActiveField = appNameSpace + 'inactive__c';
                system.debug('inActiveField=' + inActiveField);
                //Checking if field exists
                Set<String> objectFields = Schema.getGlobalDescribe()
                  .get(sObjType)
                  .getDescribe()
                  .fields.getMap()
                  .keySet();
                system.debug('objFields=' + JSON.serialize(objectFields));
                //If Field Exists, then update
                if (objectFields.contains(inActiveField.toLowercase())) {
                  system.debug('Inactive Field exists.');
                  //if(Boolean.valueof(childRec.get(inActiveField))==false){ // Only when the field is false
                  childRec.put(inActiveField, true); //Updating the checkbox to true
                  toupdate = true;
                  //}
                }
                //Faced errors to updating the name field so serialized and deseariled the sobject.
                //Was getting the folllowing errors.
                //1 -  Name is not a variable
                //2 -  Name is not editable
                //Answer found: https://developer.salesforce.com/forums/?id=906F000000091KxIAI
                string s = json.serialize(childRec);
                //system.debug('jsonhamza0='+s);
                // Checking if FilogixID is empty and name doesn't have DEPRECATED
                if (
                  !String.valueOf(childRec.get('Name')).contains('Deprecated')
                ) {
                  // String name = childRec.get('Name') + ' - Deprecated';
                  s = s.replaceFirst('"Name":"', '"Name":"[Deprecated] - ');
                  //s = String.join(splitString,',');
                  system.debug('jsonhamza=' + s);
                  childRec = (sobject) json.deserialize(s, sobject.class);
                  system.debug(childRec);
                  toupdate = true;
                }

                if (toupdate == true) {
                  // Adding record in a list to update
                  listOFRecordsToUpdate.add(childRec);
                }
              }
            }
          }
        }
      }
    }

    System.debug('listOFRecordsToUpdate::' + listOFRecordsToUpdate);

    if (listOFRecordsToUpdate != null & listOFRecordsToUpdate.size() > 0) {
      saveSobjectSet(
        listOFRecordsToUpdate,
        'update',
        objNameSuffix,
        objNamePrefix
      );
    }
  }

  // Converting Boolean string to salesforce Boolean value
  public static Boolean booleanFormatting(String value) {
    if (!String.isEmpty(value)) {
      if (value == 'Y' || value == 'Yes') {
        return true;
      }
    }
    return false;
  }

  // Parsing FilogixID after POST
  public static string parseResponsePOSTAppId(string respBody) {
    string filogixExtID = '';
    JSONParser parser = JSON.createParser(respBody);
    while (parser.nextToken() != null) {
      if (
        (parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
        (parser.getText() == 'mortgageApplicationId')
      ) {
        parser.nextToken();
        system.debug('id=' + parser.getText());
        filogixExtID = parser.getText();
      }
    }
    return filogixExtID;
  }

  // Upserts with Generic sObjects
  public static void upsertRecords(
    list<sObject> sObjList,
    string objNameSuffix,
    String objNamePrefix
  ) {
    String appNameSpace = MJ_Helper.getAppNameSpace();
    saveSobjectSet(sObjList, '', objNameSuffix, objNamePrefix);
  }

  // Success/Failure check for saved DMLs - For upsert
  public static String debugUpsertDMLTransactions(
    Database.UpsertResult[] srList
  ) {
    String errorMessage = '';
    // Iterate through each returned result
    if (srList != null && srList.size() > 0) {
      for (Database.UpsertResult sr : srList) {
        if (sr.isSuccess()) {
          // Operation was successful, so get the ID of the record that was processed
          System.debug('Successfull - Rec ID: ' + sr.getId());
        } else {
          //errorMessage = 'The following error(s) occurred:';
          // Operation failed, so get all errors
          for (Database.Error err : sr.getErrors()) {
            System.debug('The following error has occurred.');
            System.debug(err.getStatusCode() + ': ' + err.getMessage());
            System.debug('fields that affected this error: ' + err.getFields());

            errorMessage +=
              '<br>' +
              err.getStatusCode() +
              ' - ' +
              err.getMessage();
            if (err.getFields().size() > 0) {
              errorMessage +=
                ' - ' +
                'Field(s) that caused this error: ' +
                err.getFields();
            }
          }
          //throw FilogixWrapperBinding.createCustomException(errorMessage);
          //return errorMessage;
        }
      }
    }
    return errorMessage;
  }

  // Success/Failure check for saved DMLs
  public static String debugDMLTransactions(Database.SaveResult[] srList) {
    String errorMessage = '';
    // Iterate through each returned result
    if (srList != null && srList.size() > 0) {
      for (Database.SaveResult sr : srList) {
        if (sr.isSuccess()) {
          // Operation was successful, so get the ID of the record that was processed
          System.debug('Successfull - Rec ID: ' + sr.getId());
        } else {
          //errorMessage = 'The following error(s) occurred:';
          // Operation failed, so get all errors
          for (Database.Error err : sr.getErrors()) {
            System.debug('The following error has occurred.');
            System.debug(err.getStatusCode() + ': ' + err.getMessage());
            System.debug('fields that affected this error: ' + err.getFields());

            errorMessage +=
              '<br>' +
              err.getStatusCode() +
              ' - ' +
              err.getMessage();
            if (err.getFields().size() > 0) {
              errorMessage +=
                ' - ' +
                'Field(s) that caused this error: ' +
                err.getFields();
            }
          }
          //throw FilogixWrapperBinding.createCustomException(errorMessage);
          //return errorMessage;
        }
      }
    }
    return errorMessage;
  }

  // Pre-work before upsert
  public static void saveSobjectSet(
    List<Sobject> listforAction,
    String action,
    string objNameSuffix,
    String objNamePrefix
  ) {
    String appNameSpace = MJ_Helper.getAppNameSpace();

    Integer SFDC_CHUNK_LIMIT = 10;
    Map<String, List<Sobject>> dynamicMapWithObjNames = new Map<String, List<Sobject>>();
    // Developed this part due to System.TypeException: Cannot have more than 10 chunks in a single operation
    Map<String, List<Sobject>> sortedMapPerObjectType = new Map<String, List<Sobject>>();

    Map<String, Integer> numberOf200ChunkPerObject = new Map<String, Integer>();
    // List of Object API Names to set Priority
    Set<String> objectPriortity = new Set<String>{
      'Account',
      'Opportunity',
      objNamePrefix +
      'ResidentialLoanApplication' +
      objNameSuffix,
      objNamePrefix +
      'LoanApplicant' +
      objNameSuffix,
      objNamePrefix +
      'LoanApplicantAddress' +
      objNameSuffix,
      objNamePrefix +
      'LoanApplicationProperty' +
      objNameSuffix,
      objNamePrefix +
      'LoanApplicationAsset' +
      objNameSuffix,
      objNamePrefix +
      'LoanApplicantAsset' +
      objNameSuffix,
      objNamePrefix +
      'LoanApplicationLiability' +
      objNameSuffix,
      objNamePrefix +
      'LoanApplicantLiability' +
      objNameSuffix,
      objNamePrefix +
      'LoanApplicantEmployment' +
      objNameSuffix,
      objNamePrefix +
      'LoanApplicantIncome' +
      objNameSuffix,
      appNameSpace + 'Identification__c',
      appNameSpace + 'Mortgage__c',
      appNameSpace + 'Application_Fee__c',
      appNameSpace + 'Submission__c',
      appNameSpace + 'Response__c',
      appNameSpace + 'Adjustment__c',
      appNameSpace + 'Clause__c',
      appNameSpace + 'Office__c',
      appNameSpace + 'Representative__c',
      appNameSpace + 'Subject_Property__c',
      appNameSpace + 'Condition_Update__c',
      appNameSpace + 'Condition__c',
      appNameSpace + 'Application_Status_Update__c',
      appNameSpace + 'Application_Status__c',
      appNameSpace + 'PropertyExpense__c',
      appNameSpace + 'Applicant__c',
      appNameSpace + 'Pending_Message__c',
      appNameSpace + 'Down_Payment_Source__c'
    };

    //Adding this additonal loop to prioritize the Parent object to prevent : Foreign key external ID xyz not found
    for (String objectApiName : objectPriortity) {
      for (Sobject obj : listforAction) {
        if (obj != null) {
          String objTypeREAL = String.valueOf(obj.getSObjectType());
          // To run the code on Priority
          //   system.debug('Comparison: ' +objectApiName+ '==' + objTypeREAL);
          if (objectApiName.equals(objTypeREAL)) {
            //dynamic map logic
            if (
              dynamicMapWithObjNames.containskey(string.valueof(objectApiName))
            ) {
              list<sObject> tempsObjlist = dynamicMapWithObjNames.get(
                string.valueof(objectApiName)
              );
              tempsObjlist.add(obj);
              dynamicMapWithObjNames.put(
                string.valueof(objectApiName),
                tempsObjlist
              );
            } else {
              list<sObject> tempsObjlist = new List<sObject>();
              tempsObjlist.add(obj);
              dynamicMapWithObjNames.put(
                string.valueof(objectApiName),
                tempsObjlist
              );
            }

            //Chunking stuff
            if (!numberOf200ChunkPerObject.containsKey(objTypeREAL)) {
              numberOf200ChunkPerObject.put(objTypeREAL, 1);
            }
            // Number of 200 chunk for a given Object
            Integer numnberOf200Record = numberOf200ChunkPerObject.get(
              objTypeREAL
            );
            // Object type + number of 200 records chunk
            String objTypeCURRENT =
              String.valueOf(obj.getSObjectType()) +
              String.valueOf(numnberOf200Record);
            // CurrentList
            List<sObject> currentList = sortedMapPerObjectType.get(
              objTypeCURRENT
            );

            if (currentList == null || currentList.size() > 199) {
              if (currentList != null && currentList.size() > 199) {
                numberOf200ChunkPerObject.put(
                  objTypeREAL,
                  numnberOf200Record + 1
                );
                objTypeCURRENT =
                  String.valueOf(obj.getSObjectType()) +
                  String.valueOf(numnberOf200Record);
              }
              sortedMapPerObjectType.put(objTypeCURRENT, new List<Sobject>());
            }
            sortedMapPerObjectType.get(objTypeCURRENT).add(obj);
          }
        }
      }
    }

    while (sortedMapPerObjectType.size() > 0) {
      // Create a new list, which can contain a max of chunking limit, and sorted, so we don't get any errors
      List<Sobject> safeListForChunking = new List<Sobject>();
      List<String> keyListSobjectType = new List<String>(
        sortedMapPerObjectType.keySet()
      );
      for (
        Integer i = 0;
        i < SFDC_CHUNK_LIMIT && !sortedMapPerObjectType.isEmpty();
        i++
      ) {
        List<Sobject> listSobjectOfOneType = sortedMapPerObjectType.remove(
          keyListSobjectType.remove(0)
        );
        safeListForChunking.addAll(listSobjectOfOneType);
      }

      if (action == 'update') {
        database.Update(safeListForChunking);
      }
    }

    if (action != 'update') {
      //Debug
      for (String objectNametoshow : dynamicMapWithObjNames.keyset()) {
        mDebugUntruncated(
          '=== ' +
            objectNametoshow +
            ':`JSON.serialize(safeListForChunking)=' +
            JSON.serialize(dynamicMapWithObjNames.get(objectNametoshow)) +
            '`'
        );
      }
      //Upserting Records
      getSpecificObjectListToUpsert(
        dynamicMapWithObjNames,
        appNameSpace + 'FilogixId__c'
      );
    }
  }

  // Debugging Method to show complete list in logs
  // Example: mDebugUntruncated('Debug::'+JSON.Seralize(XYZ));
  public static void mDebugUntruncated(String sMsg) {
    for (Integer i = 0; i < sMsg.length(); i = i + 300) {
      Integer iEffectiveEnd = (i + 300 > (sMsg.length())
        ? sMsg.length() - 1
        : i + 300);
      System.debug(sMsg.substring(i, iEffectiveEnd));
    }
  }

  // https://salesforce.stackexchange.com/questions/199784/remove-a-field-from-an-sobject-object-in-apex/199839#199839
  public static sObject removeElementfromSObject(
    sObject rec,
    String fieldName
  ) {
    // Get map of the sobject fields
    Map<String, Object> recMap = (Map<String, Object>) JSON.deserializeUntyped(
      JSON.serialize(rec)
    );
    //System.debug( 'Another way to do Step 2. Account serialized as json then deserialized back into untyped map: ' + acctMap2 );

    // Step 3. Remove any fields you don't want
    recMap.remove(fieldName);
    //System.debug( 'Step 3. Remove undesired field "Type" from map: ' + recMap );

    // Step 4. Convert the map into sobject using the good ol' serialize/deserialize trick
    return (sObject) JSON.deserialize(JSON.serialize(recMap), sObject.class);
    //System.debug( 'Step 4. Account after serializing map of our desired fields into json then deserializing the json back into sobject: ' + acct2 );
  }

  // Dynamic upsert
  public static void getSpecificObjectListToUpsert(
    map<string, list<sObject>> mapOfsObjects,
    string myExternalIDField
  ) {
    // Filtering the data based on Object and Fields access level before DML
    //map<string, list<sObject>> dynamicMapOfsObjects = preDMLActivities(mapOfsObjects);
   
      
      // Bypassing the Security (as the code is running in System Mode - Feb 13,2023)
      map<string, list<sObject>> dynamicMapOfsObjects = mapOfsObjects; //preDMLActivities(mapOfsObjects);

    String errorMessage = '';

    for (string sObjName : dynamicMapOfsObjects.keySet()) {
      List<SObject> toUpsert;
      List<sObject> recordstoInsert = new List<sObject>();
      List<sObject> recordstoUpdate = new List<sObject>();
      Schema.SobjectField theExtIDField = Schema.getGlobalDescribe()
        .get(sObjName)
        .getDescribe()
        .fields.getMap()
        .get(myExternalIDField);
      toUpsert = (List<SObject>) Type.ForName('List<' + sObjName + '>')
        .newInstance();

      // Loop on all the sObject Types
      for (sObject sObjItem : dynamicMapOfsObjects.get(sObjName)) {
        //mDebugUntruncated('sObjItem before upsert::'+sObjItem);
        // Removing ID (if any) before Upserting to make sure upsert works fine.
        if (sObjItem.isSet('Id') && sObjName == 'ResidentialLoanApplication') {
          sObjItem = removeElementfromSObject(sObjItem, 'Id');
        }
        toUpsert.add(sObjItem);
        //system.debug('sObjItem='+sObjItem);
        if (sObjName == 'Account') {
          if (sObjItem.isSet('Id')) {
            recordstoUpdate.add(sObjItem);
          } else {
            recordstoInsert.add(sObjItem);
          }
        }
      }

      Database.SaveResult[] resultList;

      //Bypassing Duplication Rules for both Insert/Update as per Mohsin's Instructions
      Database.DMLOptions dml = new Database.DMLOptions();
      dml.DuplicateRuleHeader.allowSave = true;
      dml.DuplicateRuleHeader.runAsCurrentUser = true;

      if (recordstoInsert.size() > 0 && recordstoInsert != null) {
        try {
          //mDebugUntruncated('recordstoInsert::'+recordstoInsert);
          resultList = database.insert(recordstoInsert, dml);
          // Debugging Saved records
          errorMessage += debugDMLTransactions(resultList);
        } catch (Exception e) {
          sendNotification(false, String.valueOf(e.getMessage()));
        }
      }

      if (recordstoUpdate.size() > 0 && recordstoUpdate != null) {
        try {
          //mDebugUntruncated('recordstoUpdate::'+recordstoUpdate);
          resultList = database.update(recordstoUpdate, dml);
          // Debugging Saved records
          errorMessage += debugDMLTransactions(resultList);
        } catch (Exception e) {
          sendNotification(false, String.valueOf(e.getMessage()));
        }
      }

      // Removing Upsert for Account to prevent the error: cannot specify Id in an insert call
      if (toUpsert != null && sObjName != 'Account') {
        try {
          Database.UpsertResult[] srList = database.upsert(
            toUpsert,
            theExtIDField,
            true
          );
          // Debugging Saved records
          errorMessage += debugUpsertDMLTransactions(srList);
        } catch (Exception e) {
          sendNotification(false, String.valueOf(e.getMessage()));
        }
      }
    }

    if (!String.isBlank(errorMessage)) {
      system.debug('errorMessage::' + errorMessage);
      // Initiating the custom notification
      sendNotification(false, errorMessage);
      //throw FilogixWrapperBinding.createCustomException('The following error(s) occurred:'+errorMessage);
    } else {
      // Initiating the custom notification
      sendNotification(true, '');
    }
  }

  /* This method is to check all the Object and fields per object has the access
Obj & FLS secuity checker 
and Remove all the objects and fields doesn't have the create/update rights */
  public static map<string, list<sObject>> preDMLActivities(
    map<string, list<sObject>> dynamicMapOfsObjects
  ) {
    map<string, list<sObject>> newdynamicMapOfsObjects = new Map<string, list<sObject>>();
    // Loop on all the sObject Types to get Object Api Name
    for (string sObjName : dynamicMapOfsObjects.keySet()) {
      mDebugUntruncated(
        'Data::' + JSON.serialize(dynamicMapOfsObjects.get(sObjName))
      );
      SObjectAccessDecision securityCreateableDecision = Security.stripInaccessible(
        AccessType.CREATABLE,
        dynamicMapOfsObjects.get(sObjName)
      );
      mDebugUntruncated(
        'Fields of Object::' +
          sObjName +
          ' are not assessible::' +
          JSON.serialize(securityCreateableDecision.getRemovedFields())
      );
      newdynamicMapOfsObjects.put(
        sObjName,
        securityCreateableDecision.getRecords()
      );
    }
    return newdynamicMapOfsObjects;
  }

  //This method is used to send notification when the process is complete.
  public static void sendNotification(Boolean success, String error) {
    system.debug('AppId::' + appId + ' & filogixId::' + filogixId);

    //Get the custom Notification type
    CustomNotificationType TemplateInfoDetail = [
      SELECT Id, DeveloperName
      FROM CustomNotificationType
      WHERE DeveloperName = 'MJ_Notify'
      LIMIT 1
    ]; // Removed WITH SECURITY_ENFORCED due to the issue for non-admin users 
    if (TemplateInfoDetail != null) {
      Set<String> currentUser = new Set<String>{ UserInfo.getUserId() };
      // Create a new custom notification
      Messaging.CustomNotification currNotification = new Messaging.CustomNotification();
      // Set the contents for the delinking notification
      if (success == true) {
        currNotification.setTitle(filogixId + ' Updated from Filoigx');
        currNotification.setBody(
          'The application ' +
            filogixId +
            ' has been updated. Click here to go to the application.'
        );
      } else {
        currNotification.setTitle(
          'Error on ' + filogixId + ' - update from Filogix'
        );
        currNotification.setBody(error);
      }

      // Set the notification type and target
      currNotification.setNotificationTypeId(TemplateInfoDetail.Id);
      currNotification.setTargetId(appId);
      // Send the notification
      try {
        currNotification.send(currentUser);
      } catch (Exception ex) {
        System.debug('Notification Failed: ' + ex.getMessage());
      }
    }
  }
}