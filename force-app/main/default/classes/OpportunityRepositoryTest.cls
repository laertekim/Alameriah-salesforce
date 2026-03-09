@IsTest
private class OpportunityRepositoryTest {

    @IsTest
    static void getOpportunitiesWithRecordType_shouldReturnRequestedOpportunities() {
        Opportunity opp = new Opportunity(
            Name = 'Opp Repo RT Test',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(15)
        );
        insert opp;

        Test.startTest();
        Map<Id, Opportunity> result =
            new OpportunityRepository().getOpportunitiesWithRecordType(new Set<Id>{ opp.Id });
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return one opportunity');
        System.assert(result.containsKey(opp.Id), 'Result should contain inserted opportunity');
        System.assertNotEquals(null, result.get(opp.Id).RecordType, 'RecordType should be loaded');
    }

    @IsTest
    static void getOpportunitiesWithFields_shouldReturnRequestedOpportunities() {
        Opportunity opp = new Opportunity(
            Name = 'Opp Repo Fields Test',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(20),
            Amount = 1234
        );
        insert opp;

        Test.startTest();
        Map<Id, Opportunity> result =
            new OpportunityRepository().getOpportunitiesWithFields(new Set<Id>{ opp.Id });
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return one opportunity');
        System.assert(result.containsKey(opp.Id), 'Result should contain inserted opportunity');
        System.assertEquals(1234, result.get(opp.Id).Amount, 'Amount should match inserted value');
    }
}
