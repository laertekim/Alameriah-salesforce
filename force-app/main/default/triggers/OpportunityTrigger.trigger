trigger OpportunityTrigger on Opportunity (after update, before delete) {
	if(Trigger.isAfter) {
        if(Trigger.isUpdate) {
            OpportunityTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
       
    }
    //before deletion of opportunity, delete the other charges and the deal building
    if(Trigger.isBefore && Trigger.isDelete) {
        OpportunityTriggerHandler.beforeDelete(Trigger.old);
    }
}