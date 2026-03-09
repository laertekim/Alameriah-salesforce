@IsTest
private class DealJunkTableControllerTest {

    private static Opportunity createOpportunity(Id siteId) {
        Opportunity opp = new Opportunity(
            Name = 'Deal Junk Opp',
            StageName = 'Offered',
            CloseDate = Date.today().addDays(10),
            Site__c = siteId
        );
        insert opp;
        return opp;
    }

    private static Building__c createBuilding(String name) {
        Building__c building = new Building__c(
            Name = name,
            Status__c = 'Available Units'
        );
        insert building;
        return building;
    }

    @IsTest
    static void getRelatedDealBuilding_shouldReturnRecords() {
        Opportunity opp = createOpportunity(null);
        Building__c building = createBuilding('Deal Junk Building 1');

        insert new Deal_Building__c(
            Deal__c = opp.Id,
            Building__c = building.Id
        );

        Test.startTest();
        List<Deal_Building__c> result = DealJunkTableController.getRelatedDealBuilding(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(1, result.size());
    }

    @IsTest
    static void createJunctionObject_shouldCreateJunctionAndUpdateStatus() {
        Opportunity opp = createOpportunity(null);
        Building__c building = createBuilding('Deal Junk Building 2');

        Test.startTest();
        DealJunkTableController.createJunctionObject(opp.Id, building.Id);
        Test.stopTest();

        Integer countJunction = [
            SELECT COUNT()
            FROM Deal_Building__c
            WHERE Deal__c = :opp.Id
            AND Building__c = :building.Id
        ];
        System.assertEquals(1, countJunction, 'Should create one Deal_Building__c');

        Building__c updatedBuilding = [
            SELECT Status__c
            FROM Building__c
            WHERE Id = :building.Id
        ];
        System.assertEquals('Offered', updatedBuilding.Status__c);
    }

    @IsTest
    static void searchMethods_shouldReturnWithoutExceptions() {
        Opportunity opp = createOpportunity(null);
        createBuilding('Deal Junk Building 3');

        Test.startTest();
        List<Building__c> residentialResult = DealJunkTableController.getAllBuildingsResidentialProperty(
            '{"fieldAndValue":{}}'
        );
        List<Building__c> buildingsResult = DealJunkTableController.getAllBuildings(
            opp.Id,
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            ''
        );
        Test.stopTest();

        System.assertNotEquals(null, residentialResult);
        System.assertNotEquals(null, buildingsResult);
    }
}