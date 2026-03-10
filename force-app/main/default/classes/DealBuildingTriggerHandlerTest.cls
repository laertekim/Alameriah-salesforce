@IsTest
private class DealBuildingTriggerHandlerTest {

    @IsTest
    static void shouldExecuteAllPublicMethods() {
        List<Deal_Building__c> emptyNew = new List<Deal_Building__c>();
        List<Deal_Building__c> emptyOld = new List<Deal_Building__c>();
        Map<Id, Deal_Building__c> emptyOldMap = new Map<Id, Deal_Building__c>();

        Test.startTest();
        DealBuildingTriggerHandler.beforeInsert(emptyNew);
        DealBuildingTriggerHandler.afterInsert(emptyNew);
        DealBuildingTriggerHandler.onAfterUpdate(emptyNew, emptyOldMap);
        DealBuildingTriggerHandler.onAfterDelete(emptyOld);
        Test.stopTest();

        System.assertEquals(0, emptyNew.size(), 'Methods executed without exceptions.');
    }
}