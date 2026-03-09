trigger OpportunityTrigger on Opportunity (before update, after update, before insert, after insert, before delete) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        OpportunityTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    }
    if (Trigger.isBefore && Trigger.isInsert) {
        OpportunityTriggerHandler.beforeInsert(Trigger.new);
    }

    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            OpportunityTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }

    //before deletion of opportunity, delete the other charges and the deal building
    if (Trigger.isBefore && Trigger.isDelete) {
        OpportunityTriggerHandler.beforeDelete(Trigger.old);
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        OpportunityTriggerHandler.afterInsert(Trigger.new);
    }
}