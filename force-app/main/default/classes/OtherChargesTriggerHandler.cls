public without sharing class OtherChargesTriggerHandler {
    
    /**
     * After Insert: Add the Other_Charges amount to the Opportunity
     */
    public static void afterInsert(List<Other_Charges__c> triggerNew) {
        Map<Id, Decimal> oppAdjustments = new Map<Id, Decimal>();
        
        for (Other_Charges__c oc : triggerNew) {
            if (oc.Deal__c != null && oc.Amount__c != null) {
                if (!oppAdjustments.containsKey(oc.Deal__c)) {
                    oppAdjustments.put(oc.Deal__c, 0);
                }
                oppAdjustments.put(oc.Deal__c, oppAdjustments.get(oc.Deal__c) + oc.Amount__c);
            }
        }
        
        if (!oppAdjustments.isEmpty()) {
            // Query current amounts
            Map<Id, Opportunity> oppsMap = new Map<Id, Opportunity>([
                SELECT Id, Amount 
                FROM Opportunity 
                WHERE Id IN :oppAdjustments.keySet()
            ]);
            
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            for (Id oppId : oppAdjustments.keySet()) {
                Opportunity opp = oppsMap.get(oppId);
                Decimal currentAmount = opp.Amount != null ? opp.Amount : 0;
                Decimal adjustment = oppAdjustments.get(oppId);
                
                oppsToUpdate.add(new Opportunity(
                    Id = oppId,
                    Amount = currentAmount + adjustment
                ));
            }
            
            if (!oppsToUpdate.isEmpty()) {
                Database.update(oppsToUpdate, false);
            }
        }
    }
    
    /**
     * After Update: Adjust the Opportunity amount based on the difference
     */
    public static void afterUpdate(List<Other_Charges__c> triggerNew, Map<Id, Other_Charges__c> triggerOldMap) {
        Map<Id, Decimal> oppAdjustments = new Map<Id, Decimal>();
        
        for (Other_Charges__c oc : triggerNew) {
            Other_Charges__c oldOc = triggerOldMap.get(oc.Id);
            
            Decimal newAmount = oc.Amount__c != null ? oc.Amount__c : 0;
            Decimal oldAmount = oldOc.Amount__c != null ? oldOc.Amount__c : 0;
            Decimal difference = newAmount - oldAmount;
            
            // Handle Deal__c change (moved to different opportunity)
            if (oc.Deal__c != oldOc.Deal__c) {
                // Subtract from old opportunity
                if (oldOc.Deal__c != null && oldAmount != 0) {
                    if (!oppAdjustments.containsKey(oldOc.Deal__c)) {
                        oppAdjustments.put(oldOc.Deal__c, 0);
                    }
                    oppAdjustments.put(oldOc.Deal__c, oppAdjustments.get(oldOc.Deal__c) - oldAmount);
                }
                
                // Add to new opportunity
                if (oc.Deal__c != null && newAmount != 0) {
                    if (!oppAdjustments.containsKey(oc.Deal__c)) {
                        oppAdjustments.put(oc.Deal__c, 0);
                    }
                    oppAdjustments.put(oc.Deal__c, oppAdjustments.get(oc.Deal__c) + newAmount);
                }
            } 
            // Same opportunity, just amount changed
            else if (oc.Deal__c != null && difference != 0) {
                if (!oppAdjustments.containsKey(oc.Deal__c)) {
                    oppAdjustments.put(oc.Deal__c, 0);
                }
                oppAdjustments.put(oc.Deal__c, oppAdjustments.get(oc.Deal__c) + difference);
            }
        }
        
        if (!oppAdjustments.isEmpty()) {
            // Query current amounts
            Map<Id, Opportunity> oppsMap = new Map<Id, Opportunity>([
                SELECT Id, Amount 
                FROM Opportunity 
                WHERE Id IN :oppAdjustments.keySet()
            ]);
            
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            for (Id oppId : oppAdjustments.keySet()) {
                Opportunity opp = oppsMap.get(oppId);
                Decimal currentAmount = opp.Amount != null ? opp.Amount : 0;
                Decimal adjustment = oppAdjustments.get(oppId);
                
                oppsToUpdate.add(new Opportunity(
                    Id = oppId,
                    Amount = currentAmount + adjustment
                ));
            }
            
            if (!oppsToUpdate.isEmpty()) {
                Database.update(oppsToUpdate, false);
            }
        }
    }
    
    /**
     * After Delete: Subtract the Other_Charges amount from the Opportunity
     */
    public static void afterDelete(List<Other_Charges__c> triggerOld) {
        Map<Id, Decimal> oppAdjustments = new Map<Id, Decimal>();
        
        for (Other_Charges__c oc : triggerOld) {
            if (oc.Deal__c != null && oc.Amount__c != null) {
                if (!oppAdjustments.containsKey(oc.Deal__c)) {
                    oppAdjustments.put(oc.Deal__c, 0);
                }
                oppAdjustments.put(oc.Deal__c, oppAdjustments.get(oc.Deal__c) - oc.Amount__c);
            }
        }
        
        if (!oppAdjustments.isEmpty()) {
            // Query current amounts
            Map<Id, Opportunity> oppsMap = new Map<Id, Opportunity>([
                SELECT Id, Amount 
                FROM Opportunity 
                WHERE Id IN :oppAdjustments.keySet()
            ]);
            
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            for (Id oppId : oppAdjustments.keySet()) {
                Opportunity opp = oppsMap.get(oppId);
                Decimal currentAmount = opp.Amount != null ? opp.Amount : 0;
                Decimal adjustment = oppAdjustments.get(oppId);
                
                oppsToUpdate.add(new Opportunity(
                    Id = oppId,
                    Amount = currentAmount + adjustment
                ));
            }
            
            if (!oppsToUpdate.isEmpty()) {
                Database.update(oppsToUpdate, false);
            }
        }
    }
    
    /**
     * After Undelete: Add the Other_Charges amount back to the Opportunity
     */
    public static void afterUndelete(List<Other_Charges__c> triggerNew) {
        Map<Id, Decimal> oppAdjustments = new Map<Id, Decimal>();
        
        for (Other_Charges__c oc : triggerNew) {
            if (oc.Deal__c != null && oc.Amount__c != null) {
                if (!oppAdjustments.containsKey(oc.Deal__c)) {
                    oppAdjustments.put(oc.Deal__c, 0);
                }
                oppAdjustments.put(oc.Deal__c, oppAdjustments.get(oc.Deal__c) + oc.Amount__c);
            }
        }
        
        if (!oppAdjustments.isEmpty()) {
            // Query current amounts
            Map<Id, Opportunity> oppsMap = new Map<Id, Opportunity>([
                SELECT Id, Amount 
                FROM Opportunity 
                WHERE Id IN :oppAdjustments.keySet()
            ]);
            
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            for (Id oppId : oppAdjustments.keySet()) {
                Opportunity opp = oppsMap.get(oppId);
                Decimal currentAmount = opp.Amount != null ? opp.Amount : 0;
                Decimal adjustment = oppAdjustments.get(oppId);
                
                oppsToUpdate.add(new Opportunity(
                    Id = oppId,
                    Amount = currentAmount + adjustment
                ));
            }
            
            if (!oppsToUpdate.isEmpty()) {
                Database.update(oppsToUpdate, false);
            }
        }
    }
}