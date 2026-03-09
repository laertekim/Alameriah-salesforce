@IsTest
private class DealBuildingBeforeInsertTest {

    @IsTest
    static void beforeInsert_shouldExecuteWithEmptyList() {
        List<Deal_Building__c> records = new List<Deal_Building__c>();

        Test.startTest();
        DealBuildingBeforeInsert.beforeInsert(records);
        Test.stopTest();

        System.assertEquals(0, records.size(), 'Method executed without exceptions.');
    }

    @IsTest
    static void afterInsert_shouldExecuteWithEmptyList() {
        List<Deal_Building__c> records = new List<Deal_Building__c>();

        Test.startTest();
        DealBuildingBeforeInsert.afterInsert(records);
        Test.stopTest();

        System.assertEquals(0, records.size(), 'Method executed without exceptions.');
    }
}
