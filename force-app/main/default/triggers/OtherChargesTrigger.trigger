trigger OtherChargesTrigger on Other_Charges__c (after insert, after update, after delete, after undelete) {
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            OtherChargesTriggerHandler.afterInsert(Trigger.new);
        }
        else if (Trigger.isUpdate) {
            OtherChargesTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
        else if (Trigger.isDelete) {
            OtherChargesTriggerHandler.afterDelete(Trigger.old);
        }
        else if (Trigger.isUndelete) {
            OtherChargesTriggerHandler.afterUndelete(Trigger.new);
        }
    }
}