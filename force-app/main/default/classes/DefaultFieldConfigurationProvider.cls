public class DefaultFieldConfigurationProvider implements IFieldConfigurationProvider {
    
    public List<String> getOpportunityFields() {
        return new List<String>{
            'Deal_Number__c',
            'Name',
            'Site__c',
            'LandArea__c',
            'LandPricePerSqm__c',
            'BuildUpArea__c',
            'PreLaunchPrice__c',
            'LandSellableAmount__c',
            'TotalScheduledPayment__c',
            'Rate_per_Sqm_SR_Sqm__c',
            'TotalSellingPrice__c',
            'VAT_15__c',
            'VAT_Amount__c',
            'Total_Contract_Value__c',
            'Offer_Valid_till__c',
            'Deal_Offered_Date__c',
            'AccountId',
            'Primary_Contact__c',
            'Edara_Agent__c',
            'Other_Agents__c'
        };
    }
    
    public List<String> getPaymentScheduleFields() {
        return new List<String>{
            'Amount__c',
            'Percentage__c',
            'Description__c'
        };
    }
    
    public List<String> getOtherChargeFields() {
        return new List<String>{
            'Amount__c',
            'Year__c',
            'Category__c'
        };
    }
    
    public List<String> getDealBuildingFields() {
        return new List<String>{
            'Building__r.Name',
            'LocationAndVisibility__c',
            'Unit_No__c'
        };
    }
}