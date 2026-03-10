@IsTest
private class DealBuildingRepositoryTest {

    @IsTest
    static void getDealBuildingsAllFields_shouldReturnRequestedRecord() {
        Opportunity opp = new Opportunity(
            Name = 'DB Repo Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(15)
        );
        insert opp;

        Building__c building = new Building__c(
            Name = 'DB Repo Building'
        );
        insert building;

        Deal_Building__c dealBuilding = new Deal_Building__c(
            Deal__c = opp.Id,
            Building__c = building.Id
        );
        insert dealBuilding;

        Test.startTest();
        Map<Id, Deal_Building__c> result =
            new DealBuildingRepository().getDealBuildingsAllFields(new Set<Id>{ dealBuilding.Id });
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return one deal building');
        System.assert(result.containsKey(dealBuilding.Id), 'Returned map should contain inserted deal building id');
    }
}