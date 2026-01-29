public class OpportunityRepository {
    
    public Map<Id, Opportunity> getOpportunitiesWithRecordType(Set<Id> opportunityIds) {
        return new Map<Id, Opportunity>([
            SELECT Id, RecordType.Name 
            FROM Opportunity 
            WHERE Id IN :opportunityIds
        ]);
    }
    
    public Map<Id, Opportunity> getOpportunitiesWithFields(Set<Id> opportunityIds) {
        return new Map<Id, Opportunity>([
            SELECT Id,
                   RecordType.Name,
                   Amount,
                   Unit_Size_SQM__c,
                   Service_Area_Sqm__c,
                   Terrace_Area_Sqm__c,
                   Service_Area_SAR__c,
                   Terrace_Area_SAR__c,
                   Minimum_Acceptable_Rent__c,
                   Minimum_Acceptable_Rate_Sqm_SR_Sqm__c,
                   Asking_Rate_Sqm__c,
                   Total_Asking_Rent_SR__c,
                   Area_Sqm__c,
                   Rate_per_Sqm_SR_Sqm__c,
                   Total_Annual_Rent_SR_Annum__c,
                   Unit_Number__c,
                   Total_Annual_Rent__c,
                   Lobby_Area_Sqm__c,
                   Price_Sqm_SAR_Lobby__c,
                   Total_Prices_Lobby_Areas__c,
                   Unit_Area_Sqm__c,
                   Price_Sqm_SAR_Unit__c,
                   Total_Prices_Unit_Area__c,
                   Price_Sqm_SAR_Service__c,
                   Total_Prices_Service_Area__c,
                   Price_Sqm_SAR_Terrace__c,
                   Total_Prices_Terrace_Area__c,
                   PreLaunchPrice__c,
                   TotalSellingPrice__c,
                   LandArea__c,
                   LandSellableAmount__c,
                   BuildUpArea__c
            FROM Opportunity 
            WHERE Id IN :opportunityIds
        ]);
    }
}