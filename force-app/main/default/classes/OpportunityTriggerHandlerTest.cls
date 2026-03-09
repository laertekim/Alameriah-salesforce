@IsTest
private class OpportunityTriggerHandlerTest {

    private static Opportunity createOpportunity(String stageName) {
        Opportunity opp = new Opportunity(
            Name = 'Opp Test ' + String.valueOf(DateTime.now().getTime()),
            StageName = stageName,
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
        return opp;
    }

    private static Building__c createBuilding() {
        Building__c b = new Building__c(
            Name = 'Building Test ' + String.valueOf(DateTime.now().getTime()),
            Status__c = 'Available Units'
        );
        insert b;
        return b;
    }

    @IsTest
    static void beforeUpdate_shouldCalculateSellableAmountsAndTotalSellingPrice() {
        Opportunity opp = createOpportunity('Prospecting');

        opp.LandArea__c = 10;
        opp.LandPricePerSqm__c = 20;
        opp.BuildUpArea__c = 5;
        opp.Rate_per_Sqm_SR_Sqm__c = 30;

        Test.startTest();
        update opp;
        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT LandSellableAmount__c,
                   TotalSellingPrice__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        // 10 * 20
        System.assertEquals(200, updatedOpp.LandSellableAmount__c);
        // (5 * 30) + (10 * 20)
        System.assertEquals(350, updatedOpp.TotalSellingPrice__c);
    }

    @IsTest
    static void afterUpdate_closedLostShouldSetBuildingStatusToAvailableUnits() {
        Opportunity opp = createOpportunity('Prospecting');
        Building__c b = createBuilding();

        Deal_Building__c dealBuilding = new Deal_Building__c(
            Deal__c = opp.Id,
            Building__c = b.Id
        );
        insert dealBuilding;

        opp.StageName = 'Closed Lost';

        Test.startTest();
        update opp;
        Test.stopTest();

        Building__c updatedBuilding = [
            SELECT Status__c
            FROM Building__c
            WHERE Id = :b.Id
        ];

        System.assertEquals('Available Units', updatedBuilding.Status__c);
    }

    @IsTest
    static void beforeDelete_shouldDeleteRelatedDealBuildings() {
        Opportunity opp = createOpportunity('Prospecting');
        Building__c b = createBuilding();

        Deal_Building__c dealBuilding = new Deal_Building__c(
            Deal__c = opp.Id,
            Building__c = b.Id
        );
        insert dealBuilding;

        Test.startTest();
        delete opp;
        Test.stopTest();

        Integer countDealBuildings = [
            SELECT COUNT()
            FROM Deal_Building__c
            WHERE Id = :dealBuilding.Id
        ];

        System.assertEquals(0, countDealBuildings);
    }
}
