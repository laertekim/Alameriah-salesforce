public class DealBildingTriggerHandler {
    public static void onBeforeInsert(list<Deal_Building__c> triggerNew){
        DealBuildingBeforeInsert.beforeInsert(triggerNew);
    }
    
    public static void onAfterInsert(list<Deal_Building__c> triggerNew){
        DealBuildingBeforeInsert.afterInsert(triggerNew);
    }
    
    public static void onAfterUpdate(list<Deal_Building__c> triggerNew, Map<Id,Deal_Building__c>oldMap){
        DealBuildingUpdate.afterUpdate(triggerNew, oldMap);
    }
    
    public static void onAfterDelete(list<Deal_Building__c> triggerOld){
        DealBuildingDelete.afterDelete(triggerOld);
    }
}