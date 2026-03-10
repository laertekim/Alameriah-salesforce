trigger BuildingTrigger on Building__c (before insert, before update) {
    BuildingTriggerHandler.setResidentialMirrorFields(Trigger.new);
}