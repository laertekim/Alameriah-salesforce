@IsTest
private class BuildingRepositoryTest {

    // ─── Test Data Setup ─────────────────────────────────────────────────────

    @TestSetup
    static void makeData() {
        insert new List<Building__c>{
            new Building__c(
                Name                         = 'Test Building A',
                
                Total_Selling_Price_SAR__c   = 200000
            ),
            new Building__c(
                Name                         = 'Test Building B',
                
                Total_Selling_Price_SAR__c   = 400000
                
            )
        };
    }

    // ─── getBuildingsWithPricing ─────────────────────────────────────────────

    @IsTest
    static void getBuildingsWithPricing_allIds_returnsBothRecords() {
        Set<Id> ids = new Map<Id, Building__c>([SELECT Id FROM Building__c]).keySet();

        Test.startTest();
        Map<Id, Building__c> result = new BuildingRepository().getBuildingsWithPricing(ids);
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Should return one record per requested Id');
    }

    @IsTest
    static void getBuildingsWithPricing_returnsCorrectPricingValues() {
        Building__c b = [SELECT Id FROM Building__c WHERE Name = 'Test Building A' LIMIT 1];

        Test.startTest();
        Map<Id, Building__c> result = new BuildingRepository().getBuildingsWithPricing(new Set<Id>{ b.Id });
        Test.stopTest();

        System.assertEquals(1,      result.size(),                                  'Should return exactly one record');
        System.assertEquals(200000, result.get(b.Id).Total_Selling_Price_SAR__c,   'Total_Selling_Price_SAR__c mismatch');
        
        
    }

    @IsTest
    static void getBuildingsWithPricing_singleId_excludesOtherRecords() {
        List<Building__c> buildings = [SELECT Id FROM Building__c ORDER BY Name ASC];
        Id requestedId = buildings[0].Id;

        Test.startTest();
        Map<Id, Building__c> result = new BuildingRepository().getBuildingsWithPricing(new Set<Id>{ requestedId });
        Test.stopTest();

        System.assertEquals(1, result.size(),                    'Only the requested record should be returned');
        System.assert(result.containsKey(requestedId),           'Result map must contain the requested Id');
        System.assert(!result.containsKey(buildings[1].Id),      'Result map must not contain unrequested Ids');
    }

    @IsTest
    static void getBuildingsWithPricing_emptySet_returnsEmptyMap() {
        Test.startTest();
        Map<Id, Building__c> result = new BuildingRepository().getBuildingsWithPricing(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Empty Id set should return an empty map');
    }

    @IsTest
    static void getBuildingsWithPricing_unknownId_returnsEmptyMap() {
        // Manufacture an Id that does not exist in the database
        Id fakeId = (Id)(Building__c.SObjectType.getDescribe().getKeyPrefix() + '000000000000AAA');

        Test.startTest();
        Map<Id, Building__c> result = new BuildingRepository().getBuildingsWithPricing(new Set<Id>{ fakeId });
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Non-existent Id should return an empty map');
    }

    // ─── getAllFields ─────────────────────────────────────────────────────────

    @IsTest
    static void getAllFields_allIds_returnsBothRecords() {
        Set<Id> ids = new Map<Id, Building__c>([SELECT Id FROM Building__c]).keySet();

        Test.startTest();
        Map<Id, Building__c> result = new BuildingRepository().getAllFields(ids);
        Test.stopTest();

        System.assertEquals(2, result.size(), 'getAllFields should return one record per requested Id');
    }

    @IsTest
    static void getAllFields_returnsCorrectNameField() {
        Building__c b = [SELECT Id FROM Building__c WHERE Name = 'Test Building A' LIMIT 1];

        Test.startTest();
        Map<Id, Building__c> result = new BuildingRepository().getAllFields(new Set<Id>{ b.Id });
        Test.stopTest();

        System.assertEquals(1,               result.size(),                'Should return exactly one record');
        System.assertEquals('Test Building A', result.get(b.Id).Name,     'Name field value mismatch');
    }

    @IsTest
    static void getAllFields_singleId_excludesOtherRecords() {
        List<Building__c> buildings = [SELECT Id FROM Building__c ORDER BY Name ASC];
        Id requestedId = buildings[0].Id;

        Test.startTest();
        Map<Id, Building__c> result = new BuildingRepository().getAllFields(new Set<Id>{ requestedId });
        Test.stopTest();

        System.assertEquals(1, result.size(),               'Only the requested record should be returned');
        System.assert(result.containsKey(requestedId),      'Result map must contain the requested Id');
        System.assert(!result.containsKey(buildings[1].Id), 'Result map must not contain unrequested Ids');
    }

    @IsTest
    static void getAllFields_emptySet_returnsEmptyMap() {
        Test.startTest();
        Map<Id, Building__c> result = new BuildingRepository().getAllFields(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Empty Id set should return an empty map');
    }

    @IsTest
    static void getAllFields_unknownId_returnsEmptyMap() {
        Id fakeId = (Id)(Building__c.SObjectType.getDescribe().getKeyPrefix() + '000000000000AAA');

        Test.startTest();
        Map<Id, Building__c> result = new BuildingRepository().getAllFields(new Set<Id>{ fakeId });
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Non-existent Id should return an empty map');
    }
}
