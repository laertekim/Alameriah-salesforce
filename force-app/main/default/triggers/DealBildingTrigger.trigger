trigger DealBildingTrigger on Deal_Building__c (before insert, after insert, after update, after delete) {
   if(trigger.isBefore && trigger.isInsert) {
        DealBildingTriggerHandler.onBeforeInsert(Trigger.new);
    }
    if(trigger.isAfter && trigger.isInsert) {
        DealBildingTriggerHandler.onAfterInsert(Trigger.new);
    }
    
    if(trigger.isAfter && trigger.isUpdate) {
        DealBildingTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
    }
    
    if(trigger.isAfter && trigger.isDelete) {
        DealBildingTriggerHandler.onAfterDelete(Trigger.old);
        
    }
}