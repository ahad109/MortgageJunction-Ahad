/*
Author: Zain Abbas
Description : Based on Updated Schema by Filogix on 12-Jan-21
*/

public class FilogixPOSTJSONWrapper {

    public MortgageApplication mortgageApplication {get;set;} 
    
    public class MortgageApplication {
        public Deal deal {get;set;} 
        public List<ApplicantGroup> applicantGroup {get;set;} 
        public List<Mortgage_Existing> existing {get;set;} 
        public List<Mortgage_Requesting> requested {get;set;} 
        public SubjectProperty subjectProperty {get;set;} 
        public List<Notes> notes {get;set;}
        
    }
    
    public class ApplicantGroup {
        public String applicantGroupTypeDd {get;set;} 
        public List<Applicant> applicant {get;set;} 
        public MailingAddr mailingAddr {get;set;} 
        public String mailingAddressIndicator {get;set;} 

    }
    
    public class SubjectProperty {
        public double actualAppraisalValue {get;set;} 
        public Address address {get;set;} 
        public String appraisalDateAct {get;set;} 
        public String dwellingStyleDd {get;set;} 
        public String dwellingTypeDd {get;set;} 
        public Decimal estimatedAppraisalValue {get;set;} 
        public String feesIncludeHeat {get;set;} 
        public String garageSizeDd {get;set;} 
        public String garageTypeDd {get;set;} 
        public String heatTypeDd {get;set;} 
        public String includetds {get;set;} 
        public RentalIncome rentalIncome {get;set;} 
        public String insulatedWithUffi {get;set;} 
        public String legalLine1 {get;set;} 
        public String legalLine2 {get;set;} 
        public String legalLine3 {get;set;} 
        public double livingSpace {get;set;} 
        public String livingSpaceUnitOfMeasurDd {get;set;} 
        public double lotSize {get;set;} 
        public String lotSizeUnitOfMeasureDd {get;set;} 
        public String mlsListingFlag {get;set;} 
        public String newConstructionDd {get;set;} 
        public double numberOfUnits {get;set;} 
        public String occupancyTypeDd {get;set;} 
        public String propertyTypeDd {get;set;} 
        public String propertyValueIndexId {get;set;} 
        public Double purchasePrice {get;set;} 
        public String realtorInfo {get;set;} 
        public String rentalOffsetOption {get;set;} 
        public String sewageTypeDd {get;set;} 
        public double structureAge {get;set;} 
        public double taxationYear {get;set;} 
        public String waterTypeDd {get;set;} 
        public Decimal originalPurchasePrice {get;set;}
        public List<PropertyExpense> propertyExpense {get;set;} 

    }
    
    
    
    public class Address {
        public String unitNumber {get;set;} 
        public String streetNumber {get;set;} 
        public String streetName {get;set;} 
        public String streetTypeDd {get;set;} 
        public String streetDirectionDd {get;set;} 
        public String city {get;set;} 
        public String provinceDd {get;set;} 
        public String postalFsa {get;set;} 
        public String postalLdu {get;set;} 
        public String countryTypeDd {get;set;} 

    }
    
    public class Income {
        public Decimal incomeAmount {get;set;} 
        public String incomePeriodDd {get;set;} 
        public String incomeTypeDd {get;set;} 

    }
    
    public class Identification {
        public String identificationNumber {get;set;} 
        public String identificationCountry {get;set;} 
        public String identificationTypeDd {get;set;} 

    }
    
    public class PropertyExpense {
        public Decimal propertyExpenseAmount {get;set;} 
        public String propertyExpensePeriodDd {get;set;} 
        public String propertyExpenseTypeDd {get;set;} 

    }
    
    public class DownPaymentSource {
        public Double amount {get;set;} 
        public String description {get;set;} 
        public String downPaymentSourceTypeDd {get;set;} 

        
    }
    
    public class Name {
        public String salutationDd {get;set;} 
        public String firstName {get;set;} 
        public String middleInitial {get;set;} 
        public String lastName {get;set;} 
        public String suffixDd {get;set;} 

    }
    
 /*   public class EmploymentHistory_Z {
        public Contact_Z contact {get;set;} 
        public String employerName {get;set;} 
        public String employmentHistoryStatusDd {get;set;} 
        public String employmentHistoryTypeDd {get;set;} 
        public Income income {get;set;} 
        public String industrySectorDd {get;set;} 
        public String jobTitle {get;set;} 
        public double monthsOfService {get;set;} 
        public String occupationDd {get;set;} 
        public double timeInIndustry {get;set;} 

        
    }*/
    
    public class QualifyDetail_Z {
        public double amortizationTerm {get;set;} 
        public String interestCompoundDd {get;set;} 
        public String interestOnlyFlag {get;set;} 


    }
    
    public class AddressDetail {
        public Address address {get;set;} 
        public String addressTypeDd {get;set;} 
        public double monthsAtAddress {get;set;} 
        public String residentialStatusDd {get;set;} 
        public Double rentPaymentAmount {get;set;} 

        
    }
    
    public class OtherProperty {
        public Property property {get;set;} 
        public List<OtherPropMortgage> mortgage {get;set;} 

        
    }
    
    public class EmploymentHistory {
        public String companyType {get;set;} 
        public Contact contact {get;set;} 
        public String employerName {get;set;} 
        public String employmentHistoryStatusDd {get;set;} 
        public String employmentHistoryTypeDd {get;set;} 
        public Decimal grossRevenue {get;set;} 
        public Income income {get;set;} 
        public String industrySectorDd {get;set;} 
        public String jobTitle {get;set;} 
        public double monthsOfService {get;set;} 
        public String occupationDd {get;set;} 
        public String operatingAs {get;set;} 
        public String selfEmploymentFlag {get;set;} 
        public double timeInIndustry {get;set;} 

    }
    
    /*public class Mortgage {
        public double actualPaymentTerm {get;set;} 
        public double balanceRemaining {get;set;} 
        
        public String refiAdditionalInformation {get;set;} 
        public String payoffTypeDd {get;set;} 
        public String miReferenceNumber {get;set;} 
        public String mortgageInsurerId {get;set;} 

        public String refiBlendedAmortization {get;set;} 

        public String repaymentTypeDd {get;set;} 

        public String existingMortgageFlag {get;set;} 

        public String existingMortgageHolder {get;set;} 
        public String currentMortgageNumber {get;set;}

        public String insuredFlag {get;set;} 
        public String interestTypeDd {get;set;} 
        public String loanTypeDd {get;set;} 
        public String mortgageTypeDd {get;set;} 
        public String paymentFrequencyDd {get;set;} 
        public String paymentTermDd {get;set;} 
        public String interestOnlyFlag {get;set;} 
        
        public String mtgInsIncludeFlag {get;set;} 
        public Decimal netLoanAmount {get;set;} 
        public Decimal originalMortgageAmount {get;set;} 
        
        public Rate rate {get;set;} 
        
        

    }
    
    public class AddressDetail_Z {
        public Address address {get;set;} 
        public String addressTypeDd {get;set;} 
        public double monthsAtAddress {get;set;} 
        public String residentialStatusDd {get;set;} 

    }*/
    
    public class Asset {
        public String assetDescription {get;set;} 
        public String assetTypeDd {get;set;} 
        public double assetValue {get;set;} 
        public Decimal downpaymentAmount {get;set;} 

    }
    
    public class Property {
        public Address_Y address {get;set;} 
        public Decimal estimatedAppraisalValue {get;set;} 
        public String feesIncludeHeat {get;set;} 
        public String includetds {get;set;} 
        public RentalIncome rentalIncome {get;set;} 
        public String occupancyTypeDd {get;set;} 
        public Decimal originalPurchasePrice {get;set;} 
        public String refiOrigPurchaseDate {get;set;} 
        public double structureAge {get;set;}
        public double taxationYear {get;set;}

      //  public double actualAppraisalValue  {get;set;}
        public String appraisalDateAct {get;set;}
        public String dwellingStyleDd  {get;set;}
        public String dwellingTypeDd  {get;set;}
        public String garageSizeDd  {get;set;}
        public String garageTypeDd  {get;set;}
        public String heatTypeDd  {get;set;}
        public String legalLine1  {get;set;}
        public String legalLine2  {get;set;}
        public String legalLine3  {get;set;}
        public double livingSpace  {get;set;}
        public String livingSpaceUnitOfMeasurDd  {get;set;}
        public double lotSize  {get;set;}
        public String lotSizeUnitOfMeasureDd  {get;set;}
        public String mlsListingFlag  {get;set;}
        public String newConstructionDd  {get;set;}
        public double numberOfUnits  {get;set;}
        public String propertyTypeDd  {get;set;}
    //    public Decimal purchasePrice  {get;set;}
        public String realtorInfo  {get;set;}
        public String rentalOffsetOption  {get;set;}
        public String sewageTypeDd  {get;set;}
        public String waterTypeDd  {get;set;}
        
        public List<PropertyExpense> propertyExpense {get;set;} 

    }
    
    public class Notes {
        public String categoryDd {get;set;} 
        public String entryDate {get;set;} 
        public String text {get;set;} 

    }
    
    
    public class BorrowerIds {
        public double borrowerId {get;set;} 

    }
    
    public class Rate_Z {
        public Double discount {get;set;} 
        public Double premium {get;set;} 
        public Double buyDownRate {get;set;} 
        public Double interestRate {get;set;} 
        public Double netRate {get;set;} 
    }
    
   /* public class Name_Z {
        public String salutationDd {get;set;} 
        public String firstName {get;set;} 
        public String middleInitial {get;set;} 
        public String lastName {get;set;} 

    }*/
    
    public class Rate {
        public Double interestRate {get;set;} 

        
    }
    
    public class MailingAddr {
        public String unitNumber {get;set;} 
        public String streetNumber {get;set;} 
        public String streetName {get;set;} 
        public String streetTypeDd {get;set;} 
        public String streetDirectionDd {get;set;} 
        public String city {get;set;} 
        public String internationalPostalCode {get;set;} 
        public String postalFsa {get;set;}
        public String postalLdu {get;set;}
        public String countryTypeDd {get;set;} 
        public String provinceDd {get;set;} 

    }
    
    public class OtherIncome {
        public Double incomeAmount {get;set;} 
        public String incomeDescription {get;set;} 
        public String incomePeriodDd {get;set;} 
        public String incomeTypeDd {get;set;} 

    }
    
/*    public class Contact_Z {
        public Address_X address {get;set;} 
        public String contactPhoneNumber {get;set;} 
        public String contactPhoneNumberExtension {get;set;} 

    }*/
    
    public class Deal {
        public String dealPurposeDd {get;set;} 
        public String dealTypeDd {get;set;} 
        public List<DownPaymentSource> downPaymentSource {get;set;} 
        public String thirdPartyApplicationFlag {get;set;}
        public String estimatedClosingDate {get;set;} 
        public String financingWaiverDate {get;set;} 
        public String referralReferenceNo {get;set;} 
        public String refiImprovementsFlag {get;set;} 
        public String refiPurpose {get;set;} 
        public String sourceApplicationId {get;set;} 
        public String taxPayorDd {get;set;} 
        public Decimal refiImprovementAmount {get;set;} 
        public String refiImprovementsDesc {get;set;} 

    }
    
    public class QualifyDetail {
        public double amortizationTerm {get;set;} 
        public String interestCompoundDd {get;set;} 
        public String interestOnlyFlag {get;set;} 
     //   public String repaymentTypeDd {get;set;}

        
    }
    
    public class Contact {
        public Address_Z address {get;set;} 
        public String contactPhoneNumber {get;set;} 

        
    }
    
    public class Mortgage_Existing {
        public List<BorrowerIds> borrowerIds {get;set;} 
        public Double balanceRemaining {get;set;} 
        public String currentMortgageNumber {get;set;}
        public String existingMortgageFlag {get;set;} 
        public String existingMortgageHolder {get;set;} 
        public String insuredFlag {get;set;} 
        public String interestTypeDd {get;set;} 
        public String loanTypeDd {get;set;} 
        public String maturityDate {get;set;}
         public String miReferenceNumber {get;set;} 
         public String mortgageInsurerId {get;set;} 
         public String mortgageTypeDd {get;set;} 
         public Double originalMortgageAmount {get;set;} 
         public Double PAndIPaymentAmount {get;set;}
         public String paymentFrequencyDd {get;set;} 
         public String paymentTermDd {get;set;} 
         public String payoffTypeDd {get;set;} 
         public Rate_Z rate {get;set;} 
         public String refiAdditionalInformation {get;set;} 
         public String refiBlendedAmortization {get;set;} 

        
    }

    public Class OtherPropMortgage {
        public Double balanceRemaining {get;set;} 
        public String existingMortgageFlag {get;set;} 
        public String existingMortgageHolder {get;set;} 
        public String interestTypeDd {get;set;} 
        public String loanTypeDd {get;set;} 
        public String maturityDate {get;set;}
        public String mortgageTypeDd {get;set;} 
        public Double PAndIPaymentAmount {get;set;}
        public String paymentFrequencyDd {get;set;} 
        public String paymentTermDd {get;set;} 
        public String payoffTypeDd {get;set;} 
        public Rate_Z rate {get;set;} 

    }
    
    public class Mortgage_Requesting {
    public double actualPaymentTerm {get;set;} 
    public double amortizationTerm {get;set;} 
    public double cashBackAmt {get;set;} 
    public String cashBackOverride {get;set;} 
    public Double cashBackPercentage {get;set;} 
    public String commercialFlag {get;set;} 
    public String constructionFlag {get;set;} 
    public String existingMortgageFlag {get;set;} 
    public String helocFlag {get;set;} 
    public String insuredFlag {get;set;} 
    public String interestAdjustmentDate {get;set;} 
    public String interestCompoundDd {get;set;} 
    public String interestOnlyFlag {get;set;} 
    public String interestTypeDd {get;set;} 
    public String lineOfBusinessDd {get;set;} 
    public String loanTypeDd {get;set;}
    public String locRepaymentTypeDd {get;set;}
    public String mortgageTypeDd {get;set;} 
    public String mtgInsIncludeFlag {get;set;} 
    public Double netLoanAmount {get;set;} 
    public String paymentFrequencyDd {get;set;} 
    public String paymentTermDd {get;set;} 
    public QualifyDetail_Z qualifyDetail {get;set;} 
    public double qualifyRate {get;set;} 
    public Rate_Z rate {get;set;} 
    public String refiBlendedAmortization {get;set;} 
    public String repaymentTypeDd {get;set;}
    public Double requestedRate {get;set;} 
    public String reverseFlag {get;set;} 
    public String singleProgressiveTypeDd {get;set;} 
    public String subprimeFlag {get;set;} 
    
}


    public class Liability {
        public String cbScraped {get;set;} 
        public double creditLimit {get;set;} 
        public Decimal liabilityAmount {get;set;} 
        public String liabilityDescription {get;set;} 
        public Double liabilityMonthlyPayment {get;set;} 
        public String liabilityTypeDd {get;set;} 
        public String liabilityPayOffTypeDd {get;set;} 
        public String maturityDate {get;set;} 
        public String monthlyPaymentOverride {get;set;} 

        
    }
    
    public class Address_Y {
        public String streetNumber {get;set;} 
        public String streetName {get;set;} 
        public String streetTypeDd {get;set;} 
        public String streetDirectionDd {get;set;} 
        public String city {get;set;} 
        public String postalFsa {get;set;} 
        public String postalLdu {get;set;} 
        public String countryTypeDd {get;set;} 
        public String provinceDd {get;set;} 

        
    }
    
    public class Address_Z {
        public String addressLine1 {get;set;} 
        public String addressLine2 {get;set;} 
        public String city {get;set;} 
        public String internationalPostalCode {get;set;}
        public String postalFsa {get;set;} 
        public String postalLdu {get;set;} 
        public String countryTypeDd {get;set;} 
        public String provinceDd {get;set;} 

        
    }
    
    public class Applicant {
        public double borrowerId {get;set;} 
        public String borrowerCellNumber {get;set;} 
        public String borrowerFaxNumber {get;set;} 
        public String emailAddress {get;set;}
        public String borrowerHomePhoneNumber {get;set;} 
        public double borrowerSpouseId {get;set;} 
        public String borrowerWorkPhoneExtension {get;set;} 
        public String borrowerWorkPhoneNumber {get;set;} 
        public String birthDate {get;set;} 
        public String languagePreferenceDd {get;set;} 
        public String maritalStatusDd {get;set;} 
        public Name name {get;set;} 
        public double numberOfDependents {get;set;} 
        public String preferredContactMethodDd {get;set;} 
        public String socialInsuranceNumber {get;set;} 
        public List<AddressDetail> addressDetail {get;set;} 
        public String clientReferenceNumber {get;set;} 
        public String existingClient {get;set;} 
        public String firstTimeBuyer {get;set;} 
        public List<Identification> identification {get;set;} 
        public String primaryApplicantFlag {get;set;} 
        public String relationshipToPrimaryApplicant {get;set;} 
        public List<EmploymentHistory> employmentHistory {get;set;} 
        public List<OtherIncome> otherIncome {get;set;} 
        public List<Asset> asset {get;set;} 
        public List<Liability> liability {get;set;} 
        public List<OtherProperty> otherProperty {get;set;} 

        
    }
    
    public class RentalIncome {
        public Double incomeAmount {get;set;} 
        public String incomePeriodDd {get;set;} 
        public String incomeDescription {get;set;} 
        public String incomeTypeDd {get;set;} 
        public Double incPercentInTds {get;set;} 
        public Double incPercentInGds {get;set;}
    }
    
  /*  public class Address_X {
        public String addressLine1 {get;set;} 
        public String city {get;set;} 
        public String countryTypeDd {get;set;} 
        public String provinceDd {get;set;} 

        
    }*/


}