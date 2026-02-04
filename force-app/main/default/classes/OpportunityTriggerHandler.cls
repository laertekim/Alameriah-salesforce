public class OpportunityTriggerHandler {
	public static void afterUpdate(List<Opportunity> newItems, Map<Id,Opportunity>oldMap) {
        populateOwnerField(newItems, oldMap);
        handleVATChanges(newItems, oldMap);
    }

    public static void afterInsert(List<Opportunity> newItems){
        //check for each opportunity, if there is a payment plan, create payment schedules
        Map<Id, Id> opportunityPaymentPlanMap = new Map<Id, Id>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        for (Opportunity opp : newItems){
            if (opp.PaymentPlan__c != null){
                //add into a map of opportunity id and payment plan id
                opportunityPaymentPlanMap.put(opp.Id, opp.PaymentPlan__c);
                
                oppMap.put(opp.Id, opp);
                
            }
        }

        if (opportunityPaymentPlanMap.keySet().size() == 0){
            return;
        }
        
        //query payment plan lines from payment plans
        List<PaymentPlanLine__c> paymentPlanLines = [SELECT 
                                                            Id, 
                                                            Name, 
                                                            PaymentPlan__c, 
                                                            PaymentPlan__r.Name, 
                                                            Sequence__c,
                                                            Percentage__c,
                                                            DaysAfterCreation__c,
                                                            Description__c FROM PaymentPlanLine__c WHERE PaymentPlan__c IN: opportunityPaymentPlanMap.values()];
        
        if (paymentPlanLines.size() == 0){
            return;
        }
        //map payment plan id and payment plan lines
        Map<Id, List<PaymentPlanLine__c>> paymentPlanLineMap = new Map<Id, List<PaymentPlanLine__c>>();
        for (PaymentPlanLine__c paymentPlanLine : paymentPlanLines){
            if (paymentPlanLineMap.containsKey(paymentPlanLine.PaymentPlan__c)){
                paymentPlanLineMap.get(paymentPlanLine.PaymentPlan__c).add(paymentPlanLine);
            } else {
                paymentPlanLineMap.put(paymentPlanLine.PaymentPlan__c, new List<PaymentPlanLine__c>{paymentPlanLine});
            }
        }

        //create payment schedules
        List<Payment_Schedule__c> paymentSchedules = new List<Payment_Schedule__c>();
        for (Id opportunityId : opportunityPaymentPlanMap.keySet()){
            if (paymentPlanLineMap.containsKey(opportunityPaymentPlanMap.get(opportunityId))){
                Opportunity opp = oppMap.get(opportunityId);
                for (PaymentPlanLine__c paymentPlanLine : paymentPlanLineMap.get(opportunityPaymentPlanMap.get(opportunityId))){
                    Payment_Schedule__c paymentSchedule = new Payment_Schedule__c();
                    paymentSchedule.Amount__c = (paymentPlanLine.Percentage__c / 100) * opp.TotalSellingPrice__c;
                    paymentSchedule.CurrencyIsoCode = opp.CurrencyIsoCode;
                    paymentSchedule.Deal__c = opp.Id;
                    paymentSchedule.Description__c = paymentPlanLine.Description__c;
                    paymentSchedule.Escalation__c = 1;
                    paymentSchedule.Payment_Status__c = 'Not Paid';
                    paymentSchedule.Percentage__c = paymentPlanLine.Percentage__c;
                    paymentSchedule.Year__c = String.valueOf(Date.today().year());
                    paymentSchedule.Scheduled_Payment_Date__c =   opp.CloseDate.addDays((Integer)paymentPlanLine.DaysAfterCreation__c);
                    paymentSchedules.add(paymentSchedule);
                }
            }
        }
        insert paymentSchedules;
    }
    
    private static void populateOwnerField(List<Opportunity> newItems, Map<Id,Opportunity>oldMap) {
        Map<String, Opportunity> oppMap = new Map<String, Opportunity>();
        Map<String, String> mapDelBuildings = new Map<String, String>();
        for(Opportunity opp :newItems){
            if(opp.StageName != oldMap.get(opp.Id).StageName){
            	oppMap.put(opp.Id, opp);
            }
           
        }
        if(oppMap.keySet().size() > 0){
            for(Deal_Building__c db :[SELECT Id, Deal__c, Building__c FROM Deal_Building__c WHERE Deal__c IN: oppMap.keySet()]){
                mapDelBuildings.put(db.Building__c, db.Deal__c);
           
            }
            
            List<Building__c> lstBDoupdate = new List<Building__c>();
            
            for(Building__c bd :[SELECT Id, Status__c FROM Building__c WHERE Id IN :mapDelBuildings.keySet()]){
                if(oppMap.get(mapDelBuildings.get(bd.Id)).StageName != 'Closed Lost'){
           
                    bd.Status__c = oppMap.get(mapDelBuildings.get(bd.Id)).StageName;
           
                }
                if(oppMap.get(mapDelBuildings.get(bd.Id)).StageName == 'Closed Lost'){
                    bd.Status__c = 'Available Units';
                }
                    lstBDoupdate.add(bd); 	   
            }
            
            update lstBDoupdate;
    	}
    }

    //before deletion of opportunity, delete the deal building related to the opportunity
    public static void beforeDelete(List<Opportunity> triggerOld){
        Set<Id> dealIdList = new Set<Id>();
        for(Opportunity opp : triggerOld){
            dealIdList.add(opp.Id);
        }
       
       
        List<Deal_Building__c> dealBuildingsList = new List<Deal_Building__c>();    
       
        for(Deal_Building__c db : [SELECT Id, Deal__c FROM Deal_Building__c WHERE Deal__c IN: dealIdList]){
            dealBuildingsList.add(db);
        }
       
        if(dealBuildingsList.size() > 0){
            delete dealBuildingsList;
        }
    }
    
    /**
     * Handles VAT field changes to recalculate TotalSellingPrice
     */
    private static void handleVATChanges(List<Opportunity> newItems, Map<Id, Opportunity> oldMap) {
        Set<Id> affectedOpportunityIds = new Set<Id>();
        
        for (Opportunity opp : newItems) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            
            // Check if VAT_15__c or VAT_Amount__c changed
            if (opp.VAT_15__c != oldOpp.VAT_15__c || opp.VAT_Amount__c != oldOpp.VAT_Amount__c) {
                affectedOpportunityIds.add(opp.Id);
            }
        }
        
        if (!affectedOpportunityIds.isEmpty()) {
            DealBuildingService service = new DealBuildingService();
            service.recalculateOpportunities(affectedOpportunityIds);
        }
    }
}