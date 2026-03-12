public with sharing class PaymentScheduleTriggerHandler {

    public static void beforeInsert(List<Payment_Schedule__c> newItems) {
        for (Payment_Schedule__c schedule : newItems) {
            if (schedule.Escalation__c == null && schedule.Percentage__c != null) {
                schedule.Escalation__c = schedule.Percentage__c;
            }
        }
    }
}
