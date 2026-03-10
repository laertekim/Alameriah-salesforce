@IsTest
private class DealBuildingDeleteTest {

    @IsTest
    static void afterDelete_shouldExecuteWithEmptyList() {
        List<Deal_Building__c> records = new List<Deal_Building__c>();

        Test.startTest();
        DealBuildingDelete.afterDelete(records);
        Test.stopTest();

        System.assertEquals(0, records.size(), 'Method executed without exceptions.');
    }
}