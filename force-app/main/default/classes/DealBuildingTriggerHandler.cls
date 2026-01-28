public class DealBuildingTriggerHandler {
    
    public static void beforeInsert(List<Deal_Building__c> newRecords) {
        DealBuildingService service = new DealBuildingService();
        service.setTotalSellingPrice(newRecords);
    }
    
    public static void afterInsert(List<Deal_Building__c> newRecords) {
        DealBuildingService service = new DealBuildingService();
        service.updateRelatedOpportunitiesOnInsert(newRecords);
    }
    
    public static void onAfterUpdate(List<Deal_Building__c> newRecords, Map<Id, Deal_Building__c> oldMap) {
        DealBuildingService service = new DealBuildingService();
        service.handleUpdate(newRecords, oldMap);
    }
    
    public static void onAfterDelete(List<Deal_Building__c> deletedRecords) {
        DealBuildingService service = new DealBuildingService();
        service.handleDelete(deletedRecords);
    }
}