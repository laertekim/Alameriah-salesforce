public without sharing class OtherChargesTriggerHandler {
    
    /**
     * After Insert: Recalculate the entire Opportunity
     */
    public static void afterInsert(List<Other_Charges__c> triggerNew) {
        Set<Id> affectedOpportunityIds = extractOpportunityIds(triggerNew);
        
        if (!affectedOpportunityIds.isEmpty()) {
            DealBuildingService service = new DealBuildingService();
            service.recalculateOpportunities(affectedOpportunityIds);
        }
    }
    
    /**
     * After Update: Recalculate affected Opportunities
     */
    public static void afterUpdate(List<Other_Charges__c> triggerNew, Map<Id, Other_Charges__c> triggerOldMap) {
        Set<Id> affectedOpportunityIds = new Set<Id>();
        
        for (Other_Charges__c oc : triggerNew) {
            Other_Charges__c oldOc = triggerOldMap.get(oc.Id);
            
            // If Deal__c changed, both old and new opportunities are affected
            if (oc.Deal__c != oldOc.Deal__c) {
                if (oldOc.Deal__c != null) {
                    affectedOpportunityIds.add(oldOc.Deal__c);
                }
                if (oc.Deal__c != null) {
                    affectedOpportunityIds.add(oc.Deal__c);
                }
            } 
            // If Amount changed on the same opportunity
            else if (oc.Deal__c != null && oc.Amount__c != oldOc.Amount__c) {
                affectedOpportunityIds.add(oc.Deal__c);
            }
        }
        
        if (!affectedOpportunityIds.isEmpty()) {
            DealBuildingService service = new DealBuildingService();
            service.recalculateOpportunities(affectedOpportunityIds);
        }
    }
    
    /**
     * After Delete: Recalculate the Opportunity
     */
    public static void afterDelete(List<Other_Charges__c> triggerOld) {
        Set<Id> affectedOpportunityIds = extractOpportunityIds(triggerOld);
        
        if (!affectedOpportunityIds.isEmpty()) {
            DealBuildingService service = new DealBuildingService();
            service.recalculateOpportunities(affectedOpportunityIds);
        }
    }
    
    /**
     * After Undelete: Recalculate the Opportunity
     */
    public static void afterUndelete(List<Other_Charges__c> triggerNew) {
        Set<Id> affectedOpportunityIds = extractOpportunityIds(triggerNew);
        
        if (!affectedOpportunityIds.isEmpty()) {
            DealBuildingService service = new DealBuildingService();
            service.recalculateOpportunities(affectedOpportunityIds);
        }
    }
    
    /**
     * Extract unique Opportunity IDs from Other_Charges records
     */
    private static Set<Id> extractOpportunityIds(List<Other_Charges__c> otherCharges) {
        Set<Id> ids = new Set<Id>();
        for (Other_Charges__c oc : otherCharges) {
            if (oc.Deal__c != null) {
                ids.add(oc.Deal__c);
            }
        }
        return ids;
    }
}
