public class DealBuildingAggregator {
    
    private String recordTypeName;
    
    // Accumulated values
    private Decimal totalAmount = 0;
    private Decimal totalUnitSize = 0;
    private Decimal totalServiceAreaSqm = 0;
    private Decimal totalTerraceAreaSqm = 0;
    private Decimal totalServiceAreaSAR = 0;
    private Decimal totalTerraceAreaSAR = 0;
    private Decimal totalMinimumAcceptableRent = 0;
    
    // Office-specific fields
    private Decimal totalUnitAreaSqmNSA = 0;
    private Decimal totalNSA = 0;
    private Decimal totalPricesServicesAreas = 0;
    private Decimal totalPricesTerraceAreas = 0;
    private Decimal totalLobbyAreaSqm = 0;
    private Decimal totalPricesLobby = 0;
    private Decimal totalLeasingRate = 0;
    private Decimal totalLeasableAreaSqm = 0;
    private Decimal totalSellingPriceForRate = 0;
    
    // Retail-specific fields
    private List<String> unitNumbers = new List<String>();
    private Decimal totalUnitAreaSqm = 0;
    private Decimal totalAskingPrice = 0;
    private Decimal totalAnnualRent = 0;

    //Residential property-specific fields
    private Decimal totalLandArea = 0;
    private Decimal totalLandSellableAmount = 0;
    private Decimal totalVillaArea = 0;
    private Decimal totalVillaSellableAreaSqm = 0;
    private Decimal totalPreLaunchPrice = 0;
    private Decimal totalSellingPrice = 0;
    
    public DealBuildingAggregator(String recordTypeName) {
        this.recordTypeName = recordTypeName;
    }
    
    /**
     * Adds a Deal_Building record to the aggregation
     */
    public void add(Deal_Building__c db) {
        // Common fields
        totalAmount += nvl(db.Total_Selling_Price_SAR__c);
        totalServiceAreaSqm += nvl(db.Service_Area_Sqm__c);
        totalTerraceAreaSqm += nvl(db.Terrace_Area_Sqm__c);
        totalServiceAreaSAR += nvl(db.Total_Prices_Services_Areas__c);
        totalTerraceAreaSAR += nvl(db.Total_Prices_Terraces_Areas__c);
        
        //switch case for record type
        switch on recordTypeName {
            when 'Offices' {
                addOfficeFields(db);
            }
            when 'Retail' {
                addRetailFields(db);
            }
            when 'Residential Property' {
                addResidentialPropertyFields(db);
            }
        }
       
    }
    
    /**
     * Applies aggregated values to an Opportunity
     */
    public void applyToOpportunity(Opportunity opp) {
        // Common fields - use replace instead of addTo for recalculation scenarios
        opp.Amount = totalAmount;
        opp.Service_Area_Sqm__c = totalServiceAreaSqm;
        opp.Terrace_Area_Sqm__c = totalTerraceAreaSqm;
        opp.Service_Area_SAR__c = totalServiceAreaSAR;
        opp.Terrace_Area_SAR__c = totalTerraceAreaSAR;
        opp.Unit_Size_SQM__c = totalUnitSize;
        opp.Minimum_Acceptable_Rent__c = totalMinimumAcceptableRent;
        
        //switch case for record type
        switch on recordTypeName {
            when 'Offices' {
                applyOfficeFields(opp);
            }
            when 'Retail' {
                applyRetailFields(opp);
            }
            when 'Residential Property' {
                applyResidentialPropertyFields(opp);
            }
        }
       
    }
    
    // ========================================================================
    // PRIVATE HELPER METHODS
    // ========================================================================
    
    private void addOfficeFields(Deal_Building__c db) {
        totalUnitSize += nvl(db.Unit_Area_Sqm_NSA__c);
        totalUnitAreaSqmNSA += nvl(db.Unit_Area_Sqm_NSA__c);
        totalNSA += nvl(db.Total_NSA__c);
        totalPricesServicesAreas += nvl(db.Total_Prices_Services_Areas__c);
        totalPricesTerraceAreas += nvl(db.Total_Prices_Terraces_Areas__c);
        totalLobbyAreaSqm += nvl(db.Lobby_Area_Sqm__c);
        totalPricesLobby += nvl(db.Total_Prices_Lobby__c);
        totalLeasingRate += nvl(db.Leasing_Rate_Sqm_SAR__c);
        totalLeasableAreaSqm += nvl(db.Total_Leasable_Area_Sqm__c);
        totalMinimumAcceptableRent += nvl(db.Total_NSA__c);
        
        if (db.Total_Selling_Price_SAR__c != 0 && db.Total_Leasable_Area_Sqm__c != 0) {
            totalSellingPriceForRate += db.Total_Selling_Price_SAR__c;
        }
    }
    
    private void addRetailFields(Deal_Building__c db) {
        totalUnitSize += nvl(db.Unit_Area_Sqm__c);
        totalUnitAreaSqm += nvl(db.Unit_Area_Sqm__c);
        totalAskingPrice += nvl(db.Asking_Price__c);
        totalAnnualRent += nvl(db.Total_Selling_Price_SAR__c);
        totalMinimumAcceptableRent += nvl(db.Minimum_Annual_Rent__c);
        
        if (String.isNotBlank(db.Unit_No__c)) {
            unitNumbers.add(db.Unit_No__c);
        }
    }

    //add residential property fields
    private void addResidentialPropertyFields(Deal_Building__c db) {
        
        
        totalLandArea += nvl(db.LandArea__c);
        totalLandSellableAmount += nvl(db.LandSellableAmount__c);
        totalVillaArea += nvl(db.VillaArea__c);
        totalVillaSellableAreaSqm += nvl(db.VillaSellableAreaSqm__c);
        totalPreLaunchPrice += nvl(db.PreLaunchPrice__c);
        totalAskingPrice += nvl(db.Asking_Price__c);
        totalSellingPrice += nvl(db.Total_Selling_Price_SAR__c);
        
    }
    
    private void applyOfficeFields(Opportunity opp) {
        opp.Unit_Area_Sqm__c = totalUnitAreaSqmNSA;
        opp.Total_Prices_Unit_Area__c = totalNSA;
        opp.Total_Prices_Service_Area__c = totalPricesServicesAreas;
        opp.Total_Prices_Terrace_Area__c = totalPricesTerraceAreas;
        opp.Lobby_Area_Sqm__c = totalLobbyAreaSqm;
        opp.Total_Prices_Lobby_Areas__c = totalPricesLobby;
        opp.Total_Asking_Rent_SR__c = totalNSA;
        opp.Area_Sqm__c = totalLeasableAreaSqm;
        opp.Total_Annual_Rent_SR_Annum__c = totalAmount;
        
        // Calculate derived fields
        opp.Price_Sqm_SAR_Unit__c = safeDivide(opp.Total_Prices_Unit_Area__c, opp.Unit_Area_Sqm__c);
        opp.Price_Sqm_SAR_Service__c = safeDivide(opp.Total_Prices_Service_Area__c, opp.Service_Area_Sqm__c);
        opp.Price_Sqm_SAR_Terrace__c = safeDivide(opp.Total_Prices_Terrace_Area__c, opp.Terrace_Area_Sqm__c);
        opp.Price_Sqm_SAR_Lobby__c = safeDivide(opp.Total_Prices_Lobby_Areas__c, opp.Lobby_Area_Sqm__c);
        opp.Rate_per_Sqm_SR_Sqm__c = safeDivide(opp.Total_Annual_Rent_SR_Annum__c, opp.Area_Sqm__c);
        opp.Asking_Rate_Sqm__c = safeDivide(opp.Total_Asking_Rent_SR__c, opp.Unit_Size_SQM__c);
        opp.Minimum_Acceptable_Rate_Sqm_SR_Sqm__c = safeDivide(opp.Total_Asking_Rent_SR__c, opp.Unit_Size_SQM__c);
    }
    
    private void applyRetailFields(Opportunity opp) {
        opp.Area_Sqm__c = totalUnitAreaSqm;
        opp.Total_Annual_Rent__c = totalAnnualRent;
        
        if (!unitNumbers.isEmpty()) {
            opp.Unit_Number__c = String.join(unitNumbers, ',');
        }
        
        opp.Rate_per_Sqm_SR_Sqm__c = safeDivide(opp.Total_Annual_Rent__c, opp.Area_Sqm__c);
    }

    private void applyResidentialPropertyFields(Opportunity opp) {
        opp.LandArea__c = totalLandArea;
        opp.LandSellableAmount__c = totalLandSellableAmount;
        opp.BuildUpArea__c = totalVillaArea;
        //opp.VillaSellableAreaSqm__c = totalVillaSellableAreaSqm;
        opp.PreLaunchPrice__c = totalPreLaunchPrice;
        opp.Amount = totalAskingPrice;
        opp.TotalSellingPrice__c = totalAskingPrice;
    }
    
  
    private Decimal addTo(Decimal existing, Decimal toAdd) {
        return nvl(existing) + toAdd;
    }
    
    private Decimal safeDivide(Decimal numerator, Decimal denominator) {
        if (numerator == null || denominator == null || denominator == 0) {
            return 0;
        }
        return numerator / denominator;
    }
    
    private Decimal nvl(Decimal value) {
        return value == null ? 0 : value;
    }
}