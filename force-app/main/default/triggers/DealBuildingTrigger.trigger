trigger DealBuildingTrigger on Deal_Building__c (before insert, after insert, after update, after delete) {
    
    if (Trigger.isBefore && Trigger.isInsert) {
        DealBuildingTriggerHandler.beforeInsert(Trigger.new);
    }
    
    if (Trigger.isAfter && Trigger.isInsert) {
        DealBuildingTriggerHandler.afterInsert(Trigger.new);
    }
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        DealBuildingTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
    }
    
    if (Trigger.isAfter && Trigger.isDelete) {
        DealBuildingTriggerHandler.onAfterDelete(Trigger.old);
    }
}