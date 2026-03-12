trigger PaymentScheduleTrigger on Payment_Schedule__c (before insert) {
    PaymentScheduleTriggerHandler.beforeInsert(Trigger.new);
}
