public class DealBuildingService {

    /**
     * Static guard that prevents recalculateTotalSellingPriceOnly from
     * re-entering itself via the Opportunity afterUpdate trigger.
     * (e.g. updating TotalSellingPrice causes VAT_Amount__c formula to recalc,
     *  which triggers handleVATChanges, which would call this method again.)
     */
    public static Boolean isRecalculating = false;

    private OpportunityRepository opportunityRepo = new OpportunityRepository();
    private BuildingRepository buildingRepo = new BuildingRepository();
    
    /**
     * Sets Total Selling Price based on Opportunity Record Type
     * For Residential Property: uses Asking_Price__c if Total_Selling_Price_SAR__c is empty
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
            
            // For Residential Property: use Asking_Price__c as fallback if Total_Selling_Price_SAR__c is empty
            if (opp != null && (opp.RecordType.Name == 'Residential Property' || opp.RecordType.Name == 'Residential')) {
                if (dealBuilding.Total_Selling_Price_SAR__c == null || dealBuilding.Total_Selling_Price_SAR__c == 0) {
                    dealBuilding.Total_Selling_Price_SAR__c = nvl(dealBuilding.Asking_Price__c);
                }
            }
        }
    }
    
    /**
     * Updates related Opportunities with aggregated data on insert.
     * Also sets the AtCreation snapshot fields because a new Deal_Building was added.
     */
    public void updateRelatedOpportunitiesOnInsert(List<Deal_Building__c> dealBuildings) {
        Set<Id> opportunityIds = extractOpportunityIds(dealBuildings);

        if (opportunityIds.isEmpty()) {
            return;
        }

        // FULL recalculation from DB — also update AtCreation fields on insert
        recalculateOpportunities(opportunityIds, true);
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
     * Handles after delete - recalculates opportunities that lost Deal Buildings.
     * Also refreshes AtCreation snapshot fields because the Deal_Building count changed.
     */
    public void handleDelete(List<Deal_Building__c> deletedRecords) {
        Set<Id> affectedOpportunityIds = extractOpportunityIds(deletedRecords);

        if (!affectedOpportunityIds.isEmpty()) {
            recalculateOpportunities(affectedOpportunityIds, true);
        }
    }
    
    /**
     * Recalculates all values for given opportunities from scratch.
     * AtCreation fields are NOT modified (preserved from DB).
     */
    public void recalculateOpportunities(Set<Id> opportunityIds) {
        recalculateOpportunities(opportunityIds, false);
    }

    /**
     * Recalculates all values for given opportunities from scratch.
     * When updateAtCreation=true (Deal_Building inserted or deleted),
     * the four AtCreation snapshot fields are also refreshed from the current sum.
     */
    public void recalculateOpportunities(Set<Id> opportunityIds, Boolean updateAtCreation) {
        // Get all Deal Buildings for these opportunities
        //get all fiends from Deal_Building__c object using schema describe

        Map<String, Schema.SObjectField> fieldMap = Deal_Building__c.sObjectType.getDescribe().fields.getMap();
        List<String> fields = new List<String>();
        for(Schema.SObjectField field : fieldMap.values()){
            fields.add(field.getDescribe().getName());
        }
        
        String query = 'SELECT ' + String.join(fields, ', ') + ' FROM Deal_Building__c WHERE Deal__c IN :opportunityIds';
        
        List<Deal_Building__c> allDealBuildings = Database.query(query);

        /*List<Deal_Building__c> allDealBuildings = [
            SELECT Id, Deal__c, Building__c, Total_Selling_Price_SAR__c,
                   Unit_Area_Sqm_NSA__c, Total_NSA__c, Service_Area_Sqm__c,
                   Terrace_Area_Sqm__c, Total_Prices_Services_Areas__c,
                   Total_Prices_Terraces_Areas__c, Lobby_Area_Sqm__c,
                   Total_Prices_Lobby__c, Leasing_Rate_Sqm_SAR__c,
                   Total_Leasable_Area_Sqm__c, Unit_Area_Sqm__c,
                   Asking_Price__c, Minimum_Annual_Rent__c, Unit_No__c,
                   PreLaunchPrice__c, LandArea__c, LandSellableAmount__c,
                   LandSellableAreaSqm__c, VillaArea__c, VillaSellableAreaSqm__c
            FROM Deal_Building__c
            WHERE Deal__c IN :opportunityIds
        ];*/

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

        // Get opportunities and reset their calculated values
        // NOTE: AtCreation fields are fetched but NOT included in resetOpportunityFields,
        // so they are preserved unless updateAtCreation=true is explicitly requested.
        Map<Id, Opportunity> opportunityMap = opportunityRepo.getOpportunitiesWithFields(opportunityIds);

        for (Opportunity opp : opportunityMap.values()) {
            resetOpportunityFields(opp);
        }

        // Rebuild aggregations from scratch
        Map<Id, DealBuildingAggregator> aggregatorMap = buildAggregatorMap(allDealBuildings, opportunityMap);

        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();

        for (Id oppId : opportunityIds) {
            Opportunity opp = opportunityMap.get(oppId);

            if (opp != null) {
                DealBuildingAggregator agg = aggregatorMap.get(oppId);

                // If there are Deal Buildings, apply aggregated values
                if (agg != null) {
                    agg.applyToOpportunity(opp);

                    // Update AtCreation snapshot only when a Deal_Building was inserted or deleted
                    if (updateAtCreation) {
                        agg.applyAtCreationFields(opp);
                    }
                } else if (updateAtCreation) {
                    // All Deal_Buildings were removed — reset AtCreation to zero
                    opp.LandAreaAtCreation__c = 0;
                    opp.LandPriceAtCreation__c = 0;
                    opp.BuildUpAreaAtCreation__c = 0;
                    opp.RatePerSqmSRSqmAtCreation__c = 0;
                    opp.AreaAtCreation__c = 0;
                }

                // Add Other Charges to TotalSellingPrice
                if (otherChargesMap.containsKey(oppId)) {
                    opp.TotalSellingPrice__c = nvl(opp.TotalSellingPrice__c) + otherChargesMap.get(oppId);
                }

                // Add VAT if VAT_15__c is checked
                if (opp.VAT_15__c == true && opp.VAT_Amount__c != null) {
                    opp.TotalSellingPrice__c = nvl(opp.TotalSellingPrice__c) + opp.VAT_Amount__c;
                }

                opportunitiesToUpdate.add(opp);
            }
        }

        if (!opportunitiesToUpdate.isEmpty()) {
            update opportunitiesToUpdate;

            // Re-query the final TotalSellingPrice after all triggers (beforeUpdate/afterUpdate)
            // have run, then always refresh payment schedules for every affected opportunity.
            Map<Id, Opportunity> freshOpps = new Map<Id, Opportunity>([
                SELECT Id, TotalSellingPrice__c
                FROM Opportunity
                WHERE Id IN :opportunityIds
            ]);
            recalculatePaymentSchedules(opportunityIds, freshOpps);
        }
    }
    
    /**
     * Recalculates TotalSellingPrice WITHOUT touching LandArea, LandPricePerSqm,
     * BuildUpArea or Rate_per_Sqm_SR_Sqm__c on the Opportunity.
     *
     * Used by OtherCharges and VAT changes so that manually-edited pricing fields
     * on Residential Property records are never overridden.
     *
     * Formula for Residential Property:
     *   TotalSellingPrice = (LandArea × LandPricePerSqm) + (BuildUpArea × RatePerSqm)
     *                       + OtherCharges + VAT
     *
     * Non-Residential-Property records fall back to the full recalculateOpportunities.
     */
    public void recalculateTotalSellingPriceOnly(Set<Id> opportunityIds) {
        if (isRecalculating) return;
        isRecalculating = true;
        try {
            recalculateTotalSellingPriceOnlyImpl(opportunityIds);
        } finally {
            isRecalculating = false;
        }
    }

    private void recalculateTotalSellingPriceOnlyImpl(Set<Id> opportunityIds) {
        // Separate Residential Property records from other record types
        List<Opportunity> allOpps = [
            SELECT Id, RecordType.Name,
                   LandArea__c, LandPricePerSqm__c, BuildUpArea__c, Rate_per_Sqm_SR_Sqm__c,
                   VAT_15__c, VAT_Amount__c, TotalSellingPrice__c
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ];

        Set<Id> residentialIds     = new Set<Id>();
        Set<Id> otherRecordTypeIds = new Set<Id>();
        Map<Id, Opportunity> residentialOpps = new Map<Id, Opportunity>();

        for (Opportunity opp : allOpps) {
            if (opp.RecordType.Name == 'Residential Property' || opp.RecordType.Name == 'Residential') {
                residentialIds.add(opp.Id);
                residentialOpps.put(opp.Id, opp);
            } else {
                otherRecordTypeIds.add(opp.Id);
            }
        }

        // Non-Residential Property: full recalculation from Deal_Buildings (unchanged behaviour)
        if (!otherRecordTypeIds.isEmpty()) {
            recalculateOpportunities(otherRecordTypeIds);
        }

        if (residentialIds.isEmpty()) return;

        // Residential Property: formula-based recalculation — never touches LandArea etc.
        Map<Id, Decimal> otherChargesMap = new Map<Id, Decimal>();
        for (Other_Charges__c oc : [
            SELECT Deal__c, Amount__c
            FROM Other_Charges__c
            WHERE Deal__c IN :residentialIds
        ]) {
            if (!otherChargesMap.containsKey(oc.Deal__c)) {
                otherChargesMap.put(oc.Deal__c, 0);
            }
            otherChargesMap.put(oc.Deal__c, otherChargesMap.get(oc.Deal__c) + nvl(oc.Amount__c));
        }

        List<Opportunity> toUpdate      = new List<Opportunity>();
        Set<Id> priceChangedIds         = new Set<Id>();
        Map<Id, Opportunity> changedMap = new Map<Id, Opportunity>();

        for (Opportunity opp : residentialOpps.values()) {
            Decimal newTotal = (nvl(opp.LandArea__c)            * nvl(opp.LandPricePerSqm__c))
                             + (nvl(opp.BuildUpArea__c)         * nvl(opp.Rate_per_Sqm_SR_Sqm__c));

            if (otherChargesMap.containsKey(opp.Id)) {
                newTotal += otherChargesMap.get(opp.Id);
            }

            if (opp.VAT_15__c == true && opp.VAT_Amount__c != null) {
                newTotal += opp.VAT_Amount__c;
            }

            if (opp.TotalSellingPrice__c != newTotal) {
                opp.TotalSellingPrice__c = newTotal;
                toUpdate.add(opp);
                priceChangedIds.add(opp.Id);
                changedMap.put(opp.Id, opp);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
            // handleTotalSellingPriceChange in OpportunityTrigger.afterUpdate will
            // also update payment schedules, but calling it here avoids a second DML
            // round-trip when the trigger fires.
            recalculatePaymentSchedules(priceChangedIds, changedMap);
        }
    }

    /**
     * Recalculates payment schedules based on updated TotalSellingPrice
     * Only updates schedules with Payment_Status__c != 'Paid'
     */
    private void recalculatePaymentSchedules(Set<Id> opportunityIds, Map<Id, Opportunity> opportunityMap) {
        // Query payment schedules that are not paid
        List<Payment_Schedule__c> schedules = [
            SELECT Id, Deal__c, Percentage__c, Payment_Status__c
            FROM Payment_Schedule__c
            WHERE Deal__c IN :opportunityIds
            AND Payment_Status__c != 'Paid'
        ];
        
        if (schedules.isEmpty()) {
            return;
        }
        
        List<Payment_Schedule__c> schedulesToUpdate = new List<Payment_Schedule__c>();
        
        for (Payment_Schedule__c schedule : schedules) {
            Opportunity opp = opportunityMap.get(schedule.Deal__c);
            
            if (opp != null && schedule.Percentage__c != null) {
                Decimal newAmount = (schedule.Percentage__c / 100) * nvl(opp.TotalSellingPrice__c);
                schedule.Amount__c = newAmount;
                schedulesToUpdate.add(schedule);
            }
        }
        
        if (!schedulesToUpdate.isEmpty()) {
            update schedulesToUpdate;
        }
    }
    
    /**
     * Resets all calculated fields to zero
     */
    private void resetOpportunityFields(Opportunity opp) {
        opp.Amount = 0;
        opp.TotalSellingPrice__c = 0;
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
        opp.LandArea__c = 0;
        opp.LandPricePerSqm__c = 0;
        opp.LandSellableAmount__c = 0;
        opp.BuildUpArea__c = 0;
        opp.Area__c = 0;
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
                return nvl(building.Total_Selling_Price_SAR__c);
            }
            when 'Retail' {
                return nvl(building.Asking_Annual_Rent__c);
            }
            when 'Special Leasing' {
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