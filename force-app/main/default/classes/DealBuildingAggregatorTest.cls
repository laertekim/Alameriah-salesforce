@IsTest
private class DealBuildingAggregatorTest {
    private static Deal_Building__c dbWithValues(Map<String, Object> values) {
        return (Deal_Building__c) JSON.deserialize(
            JSON.serialize(values),
            Deal_Building__c.class
        );
    }

    @IsTest
    static void applyToOpportunity_shouldAggregateOfficeFields() {
        DealBuildingAggregator aggregator = new DealBuildingAggregator('Offices');

        Deal_Building__c db = dbWithValues(new Map<String, Object>{
            'Total_Selling_Price_SAR__c' => 1000,
            'Service_Area_Sqm__c' => 10,
            'Terrace_Area_Sqm__c' => 5,
            'Total_Prices_Services_Areas__c' => 200,
            'Total_Prices_Terraces_Areas__c' => 100,
            'Unit_Area_Sqm_NSA__c' => 20,
            'Total_NSA__c' => 400,
            'Lobby_Area_Sqm__c' => 2,
            'Total_Prices_Lobby__c' => 40,
            'Total_Leasable_Area_Sqm__c' => 50
        });

        aggregator.add(db);

        Opportunity opp = new Opportunity();
        aggregator.applyToOpportunity(opp);

        System.assertEquals(1000, opp.Amount);
        System.assertEquals(20, opp.Unit_Size_SQM__c);
        System.assertEquals(400, opp.Minimum_Acceptable_Rent__c);
        System.assertEquals(50, opp.Area_Sqm__c);
        System.assertEquals(1000, opp.Total_Annual_Rent_SR_Annum__c);
        System.assertEquals(20, opp.Price_Sqm_SAR_Unit__c);
        System.assertEquals(20, opp.Price_Sqm_SAR_Service__c);
        System.assertEquals(20, opp.Price_Sqm_SAR_Terrace__c);
        System.assertEquals(20, opp.Price_Sqm_SAR_Lobby__c);
        System.assertEquals(20, opp.Rate_per_Sqm_SR_Sqm__c);
    }

    @IsTest
    static void applyToOpportunity_shouldAggregateRetailFields() {
        DealBuildingAggregator aggregator = new DealBuildingAggregator('Retail');

        aggregator.add(dbWithValues(new Map<String, Object>{
            'Total_Selling_Price_SAR__c' => 500,
            'Unit_Area_Sqm__c' => 10,
            'Asking_Price__c' => 500,
            'Minimum_Annual_Rent__c' => 50,
            'Unit_No__c' => 'A1'
        }));
        aggregator.add(dbWithValues(new Map<String, Object>{
            'Total_Selling_Price_SAR__c' => 300,
            'Unit_Area_Sqm__c' => 10,
            'Asking_Price__c' => 300,
            'Minimum_Annual_Rent__c' => 30,
            'Unit_No__c' => 'B2'
        }));

        Opportunity opp = new Opportunity();
        aggregator.applyToOpportunity(opp);

        System.assertEquals(800, opp.Amount);
        System.assertEquals(20, opp.Unit_Size_SQM__c);
        System.assertEquals(20, opp.Area_Sqm__c);
        System.assertEquals(800, opp.Total_Annual_Rent__c);
        System.assertEquals(40, opp.Rate_per_Sqm_SR_Sqm__c);
        System.assertEquals('A1,B2', opp.Unit_Number__c);
        System.assertEquals(80, opp.Minimum_Acceptable_Rent__c);
    }

    @IsTest
    static void applyToOpportunity_shouldAggregateResidentialPropertyFields() {
        DealBuildingAggregator aggregator = new DealBuildingAggregator('Residential Property');

        aggregator.add(dbWithValues(new Map<String, Object>{
            'LandArea__c' => 100,
            'LandSellableAreaSqm__c' => 30,
            'LandSellableAmount__c' => 3000,
            'VillaArea__c' => 50,
            'VillaSellableAreaSqm__c' => 40,
            'PreLaunchPrice__c' => 700,
            'Asking_Price__c' => 5000,
            'Total_Selling_Price_SAR__c' => 5500
        }));

        Opportunity opp = new Opportunity();
        aggregator.applyToOpportunity(opp);

        System.assertEquals(100, opp.LandArea__c);
        System.assertEquals(30, opp.LandPricePerSqm__c);
        System.assertEquals(3000, opp.LandSellableAmount__c);
        System.assertEquals(50, opp.BuildUpArea__c);
        System.assertEquals(700, opp.PreLaunchPrice__c);
       // System.assertEquals(5000, opp.Amount);
       // System.assertEquals(5000, opp.TotalSellingPrice__c);
    }
}