trigger OpportunityTrigger on Opportunity (after update) {
	if(Trigger.isAfter) {
        if(Trigger.isUpdate) {
            OpportunityTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}