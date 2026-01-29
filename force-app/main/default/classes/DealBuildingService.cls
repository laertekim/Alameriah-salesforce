public class DealBuildingService {
    
    private OpportunityRepository opportunityRepo = new OpportunityRepository();
    private BuildingRepository buildingRepo = new BuildingRepository();
    
    /**
     * Sets Total Selling Price based on Opportunity Record Type
     */
    public void setTotalSellingPrice(List<Deal_Building__c> dealBuildings) {
        Set<Id> opportunityIds = extractOpportunityIds(dealBuildings);
        Set<Id> buildingIds = extractBuildingIds(dealBuildings);
        
        Map<Id, Opportunity> opportunityMap = opportunityRepo.getOpportunitiesWithRecordType(opportunityIds);
        Map<Id, Building__c> buildingMap = buildingRepo.getBuildingsWithPricing(buildingIds);
        
        for (Deal_Building__c dealBuilding : dealBuildings) {
            Opportunity opp = opportunityMap.get(dealBuilding.Deal__c);
            Building__c building = buildingMap.get(dealBuilding.Building__c);
            
            if (opp != null && building != null) {
                dealBuilding.Total_Selling_Price_SAR__c = 
                    calculateSellingPrice(opp.RecordType.Name, building);
            }
        }
    }
    
    /**
     * Updates related Opportunities with aggregated data on insert
     */
    public void updateRelatedOpportunitiesOnInsert(List<Deal_Building__c> dealBuildings) {
        Set<Id> opportunityIds = extractOpportunityIds(dealBuildings);
    
        if (opportunityIds.isEmpty()) {
            return;
        }
    
        // FULL recalculation from DB (same behavior as update/delete)
        recalculateOpportunities(opportunityIds);
    }
    
    
    /**
     * Handles after update - recalculates opportunities affected by changes
     */
    public void handleUpdate(List<Deal_Building__c> newRecords, Map<Id, Deal_Building__c> oldMap) {
        Set<Id> affectedOpportunityIds = new Set<Id>();
        
        // Collect all opportunities that need recalculation
        for (Deal_Building__c db : newRecords) {
            Deal_Building__c oldRecord = oldMap.get(db.Id);
            
            // If Deal__c changed, both old and new opportunities are affected
            if (db.Deal__c != oldRecord.Deal__c) {
                affectedOpportunityIds.add(db.Deal__c);
                affectedOpportunityIds.add(oldRecord.Deal__c);
            } else if (hasRelevantChanges(db, oldRecord)) {
                // If values changed but Deal__c didn't, only current opportunity is affected
                affectedOpportunityIds.add(db.Deal__c);
            }
        }
        
        if (!affectedOpportunityIds.isEmpty()) {
            recalculateOpportunities(affectedOpportunityIds);
        }
    }
    
    /**
     * Handles after delete - recalculates opportunities that lost Deal Buildings
     */
    public void handleDelete(List<Deal_Building__c> deletedRecords) {
        Set<Id> affectedOpportunityIds = extractOpportunityIds(deletedRecords);
        
        if (!affectedOpportunityIds.isEmpty()) {
            recalculateOpportunities(affectedOpportunityIds);
        }
    }
    
    /**
     * Recalculates all values for given opportunities from scratch
     */
    private void recalculateOpportunities(Set<Id> opportunityIds) {
        // Get all Deal Buildings for these opportunities
        List<Deal_Building__c> allDealBuildings = [
            SELECT Id, Deal__c, Building__c, Total_Selling_Price_SAR__c,
                   Unit_Area_Sqm_NSA__c, Total_NSA__c, Service_Area_Sqm__c,
                   Terrace_Area_Sqm__c, Total_Prices_Services_Areas__c,
                   Total_Prices_Terraces_Areas__c, Lobby_Area_Sqm__c,
                   Total_Prices_Lobby__c, Leasing_Rate_Sqm_SAR__c,
                   Total_Leasable_Area_Sqm__c, Unit_Area_Sqm__c,
                   Asking_Price__c, Minimum_Annual_Rent__c, Unit_No__c,
                   PreLaunchPrice__c, LandArea__c, LandSellableAmount__c,
                   VillaArea__c, VillaSellableAreaSqm__c
            FROM Deal_Building__c
            WHERE Deal__c IN :opportunityIds
        ];
        
        // Get all Other Charges for these opportunities
        List<Other_Charges__c> allOtherCharges = [
            SELECT Id, Deal__c, Amount__c
            FROM Other_Charges__c
            WHERE Deal__c IN :opportunityIds
        ];
        
        // Calculate total Other Charges per Opportunity
        Map<Id, Decimal> otherChargesMap = new Map<Id, Decimal>();
        for (Other_Charges__c oc : allOtherCharges) {
            if (!otherChargesMap.containsKey(oc.Deal__c)) {
                otherChargesMap.put(oc.Deal__c, 0);
            }
            otherChargesMap.put(oc.Deal__c, otherChargesMap.get(oc.Deal__c) + nvl(oc.Amount__c));
        }
        
        // Get opportunities and reset their values
        Map<Id, Opportunity> opportunityMap = opportunityRepo.getOpportunitiesWithFields(opportunityIds);
        
        // Reset all calculated fields to zero
        for (Opportunity opp : opportunityMap.values()) {
            resetOpportunityFields(opp);
        }
        
        // Rebuild aggregations from scratch
        Map<Id, DealBuildingAggregator> aggregatorMap = buildAggregatorMap(allDealBuildings, opportunityMap);
        
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        for (Id oppId : opportunityIds) {
            Opportunity opp = opportunityMap.get(oppId);
            
            if (opp != null) {
                // If there are Deal Buildings, apply aggregated values
                if (aggregatorMap.containsKey(oppId)) {
                    aggregatorMap.get(oppId).applyToOpportunity(opp);
                }
                
                // Add Other Charges to Amount
                if (otherChargesMap.containsKey(oppId)) {
                    opp.Amount = nvl(opp.Amount) + otherChargesMap.get(oppId);
                }
                
                // If no Deal Buildings, fields remain at zero (from reset)
                opportunitiesToUpdate.add(opp);
            }
        }
        
        if (!opportunitiesToUpdate.isEmpty()) {
            update opportunitiesToUpdate;
        }
    }
    
    /**
     * Resets all calculated fields to zero
     */
    private void resetOpportunityFields(Opportunity opp) {
        opp.Amount = 0;
        opp.Unit_Size_SQM__c = 0;
        opp.Service_Area_Sqm__c = 0;
        opp.Terrace_Area_Sqm__c = 0;
        opp.Service_Area_SAR__c = 0;
        opp.Terrace_Area_SAR__c = 0;
        opp.Minimum_Acceptable_Rent__c = 0;
        opp.Unit_Area_Sqm__c = 0;
        opp.Total_Prices_Unit_Area__c = 0;
        opp.Total_Prices_Service_Area__c = 0;
        opp.Total_Prices_Terrace_Area__c = 0;
        opp.Lobby_Area_Sqm__c = 0;
        opp.Total_Prices_Lobby_Areas__c = 0;
        opp.Total_Asking_Rent_SR__c = 0;
        opp.Area_Sqm__c = 0;
        opp.Total_Annual_Rent_SR_Annum__c = 0;
        opp.Total_Annual_Rent__c = 0;
        opp.Unit_Number__c = null;
        opp.Price_Sqm_SAR_Unit__c = 0;
        opp.Price_Sqm_SAR_Service__c = 0;
        opp.Price_Sqm_SAR_Terrace__c = 0;
        opp.Price_Sqm_SAR_Lobby__c = 0;
        opp.Rate_per_Sqm_SR_Sqm__c = 0;
        opp.Asking_Rate_Sqm__c = 0;
        opp.Minimum_Acceptable_Rate_Sqm_SR_Sqm__c = 0;
        opp.PreLaunchPrice__c = 0;
        opp.TotalSellingPrice__c = 0;
        opp.LandArea__c = 0;
        opp.LandSellableAmount__c = 0;
        opp.BuildUpArea__c = 0;
    }
    
    /**
     * Checks if any relevant fields changed
     */
    private Boolean hasRelevantChanges(Deal_Building__c newRecord, Deal_Building__c oldRecord) {
        return newRecord.Total_Selling_Price_SAR__c != oldRecord.Total_Selling_Price_SAR__c
            || newRecord.Unit_Area_Sqm_NSA__c != oldRecord.Unit_Area_Sqm_NSA__c
            || newRecord.Unit_Area_Sqm__c != oldRecord.Unit_Area_Sqm__c
            || newRecord.Total_NSA__c != oldRecord.Total_NSA__c
            || newRecord.Service_Area_Sqm__c != oldRecord.Service_Area_Sqm__c
            || newRecord.Terrace_Area_Sqm__c != oldRecord.Terrace_Area_Sqm__c
            || newRecord.Total_Prices_Services_Areas__c != oldRecord.Total_Prices_Services_Areas__c
            || newRecord.Total_Prices_Terraces_Areas__c != oldRecord.Total_Prices_Terraces_Areas__c
            || newRecord.Lobby_Area_Sqm__c != oldRecord.Lobby_Area_Sqm__c
            || newRecord.Total_Prices_Lobby__c != oldRecord.Total_Prices_Lobby__c
            || newRecord.Leasing_Rate_Sqm_SAR__c != oldRecord.Leasing_Rate_Sqm_SAR__c
            || newRecord.Total_Leasable_Area_Sqm__c != oldRecord.Total_Leasable_Area_Sqm__c
            || newRecord.Asking_Price__c != oldRecord.Asking_Price__c
            || newRecord.Minimum_Annual_Rent__c != oldRecord.Minimum_Annual_Rent__c
            || newRecord.Unit_No__c != oldRecord.Unit_No__c
            || newRecord.Building__c != oldRecord.Building__c
            || newRecord.PreLaunchPrice__c != oldRecord.PreLaunchPrice__c
            || newRecord.LandArea__c != oldRecord.LandArea__c
            || newRecord.LandSellableAmount__c != oldRecord.LandSellableAmount__c
            || newRecord.VillaArea__c != oldRecord.VillaArea__c
            || newRecord.VillaSellableAreaSqm__c != oldRecord.VillaSellableAreaSqm__c;
    }
    
    // ========================================================================
    // PRIVATE HELPER METHODS
    // ========================================================================
    
    private Decimal calculateSellingPrice(String recordTypeName, Building__c building) {
        switch on recordTypeName {
            when 'Offices' {
                return nvl(building.Gross_Leasable_Amount_SAR__c);
            }
            when 'Residential' {
                return nvl(building.Client_Asking_Price_SAR__c);
            }
            when 'Retail' {
                return nvl(building.Asking_Annual_Rent__c);
            }
            when 'Residential Property' {
                return nvl(building.Total_Selling_Price_SAR__c);
            }
            when else {
                return 0;
            }
        }
    }
    
    private Map<Id, DealBuildingAggregator> buildAggregatorMap(
        List<Deal_Building__c> dealBuildings, 
        Map<Id, Opportunity> opportunityMap
    ) {
        Map<Id, DealBuildingAggregator> aggregatorMap = new Map<Id, DealBuildingAggregator>();
        
        for (Deal_Building__c db : dealBuildings) {
            if (!aggregatorMap.containsKey(db.Deal__c)) {
                String recordTypeName = opportunityMap.get(db.Deal__c)?.RecordType.Name;
                aggregatorMap.put(db.Deal__c, new DealBuildingAggregator(recordTypeName));
            }
            aggregatorMap.get(db.Deal__c).add(db);
        }
        
        return aggregatorMap;
    }
    
    private Set<Id> extractOpportunityIds(List<Deal_Building__c> dealBuildings) {
        Set<Id> ids = new Set<Id>();
        for (Deal_Building__c db : dealBuildings) {
            ids.add(db.Deal__c);
        }
        return ids;
    }
    
    private Set<Id> extractBuildingIds(List<Deal_Building__c> dealBuildings) {
        Set<Id> ids = new Set<Id>();
        for (Deal_Building__c db : dealBuildings) {
            ids.add(db.Building__c);
        }
        return ids;
    }
    
    private Decimal nvl(Decimal value) {
        return value == null ? 0 : value;
    }
}