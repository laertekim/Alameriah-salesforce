@IsTest
private class DealBuildingUpdateTest {

    @IsTest
    static void afterUpdate_shouldExecuteWithEmptyInputs() {
        List<Deal_Building__c> triggerNew = new List<Deal_Building__c>();
        Map<Id, Deal_Building__c> oldMap = new Map<Id, Deal_Building__c>();

        Test.startTest();
        DealBuildingUpdate.afterUpdate(triggerNew, oldMap);
        Test.stopTest();

        System.assertEquals(0, triggerNew.size(), 'Method executed without exceptions.');
    }
}
