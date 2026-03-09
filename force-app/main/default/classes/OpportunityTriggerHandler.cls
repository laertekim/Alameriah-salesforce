public class OpportunityTriggerHandler {

    /**
     * Before Update: recalculate TotalSellingPrice for Residential Property
     * whenever the four core pricing fields are changed directly on the Opportunity.
     * Running in before-update means no extra DML is needed for the Opportunity itself.
     */
    public static void beforeUpdate(List<Opportunity> newItems, Map<Id, Opportunity> oldMap) {
        // Build a cache of record-type names without a SOQL query
        Map<Id, Schema.RecordTypeInfo> rtInfoById =
            Schema.SObjectType.Opportunity.getRecordTypeInfosById();

        // Collect IDs of Residential Property opps where any pricing field changed
        Set<Id> affectedIds = new Set<Id>();
        for (Opportunity opp : newItems) {
            Opportunity old = oldMap.get(opp.Id);
            Schema.RecordTypeInfo rti = rtInfoById.get(opp.RecordTypeId);
            if (rti == null || rti.getName() != 'Residential Property') continue;

            if (opp.LandArea__c             != old.LandArea__c
                || opp.LandPricePerSqm__c   != old.LandPricePerSqm__c
                || opp.BuildUpArea__c        != old.BuildUpArea__c
                || opp.Rate_per_Sqm_SR_Sqm__c != old.Rate_per_Sqm_SR_Sqm__c) {
                affectedIds.add(opp.Id);
            }
        }

        if (!affectedIds.isEmpty()) {
            // Query Other Charges totals per Opportunity (1 SOQL)
            Map<Id, Decimal> otherChargesMap = new Map<Id, Decimal>();
            for (Other_Charges__c oc : [
                SELECT Deal__c, Amount__c
                FROM Other_Charges__c
                WHERE Deal__c IN :affectedIds
            ]) {
                Decimal current = otherChargesMap.containsKey(oc.Deal__c)
                    ? otherChargesMap.get(oc.Deal__c) : 0;
                otherChargesMap.put(oc.Deal__c, current + (oc.Amount__c != null ? oc.Amount__c : 0));
            }

            // Recompute TotalSellingPrice in-memory — no DML needed in before-update
            for (Opportunity opp : newItems) {
                if (!affectedIds.contains(opp.Id)) continue;

                Decimal landArea   = opp.LandArea__c            != null ? opp.LandArea__c            : 0;
                Decimal landPrice  = opp.LandPricePerSqm__c     != null ? opp.LandPricePerSqm__c     : 0;
                Decimal buildUp    = opp.BuildUpArea__c          != null ? opp.BuildUpArea__c          : 0;
                Decimal rate       = opp.Rate_per_Sqm_SR_Sqm__c != null ? opp.Rate_per_Sqm_SR_Sqm__c : 0;

                Decimal newTotal = (landArea * landPrice) + (buildUp * rate);

                if (otherChargesMap.containsKey(opp.Id)) {
                    newTotal += otherChargesMap.get(opp.Id);
                }

                if (opp.VAT_15__c == true && opp.VAT_Amount__c != null) {
                    newTotal += opp.VAT_Amount__c;
                }

                opp.TotalSellingPrice__c = newTotal;
            }
        }

        // Offices: recalculate price totals when area or rate fields change
        handleOfficesPriceCalculations(newItems, oldMap, rtInfoById);
    }

    private static void handleOfficesPriceCalculations(List<Opportunity> newItems, Map<Id, Opportunity> oldMap, Map<Id, Schema.RecordTypeInfo> rtInfoById) {
        Set<Id> reverseCalcCandidates = new Set<Id>();

        // First pass: forward calculations (area/rate changed -> derive total)
        // and identify opps that may need reverse calculation
        for (Opportunity opp : newItems) {
            Opportunity old = oldMap.get(opp.Id);
            Schema.RecordTypeInfo rti = rtInfoById.get(opp.RecordTypeId);
            if (rti == null || rti.getName() != 'Offices') continue;

            // Forward: area or rate changed -> recalculate total (takes precedence over reverse)
            if (opp.Unit_Area_Sqm__c != old.Unit_Area_Sqm__c || opp.Price_Sqm_SAR_Unit__c != old.Price_Sqm_SAR_Unit__c) {
                Decimal area = opp.Unit_Area_Sqm__c != null ? opp.Unit_Area_Sqm__c : 0;
                Decimal rate = opp.Price_Sqm_SAR_Unit__c != null ? opp.Price_Sqm_SAR_Unit__c : 0;
                opp.Total_Prices_Unit_Area__c = area * rate;
            }
            if (opp.Lobby_Area_Sqm__c != old.Lobby_Area_Sqm__c || opp.Price_Sqm_SAR_Lobby__c != old.Price_Sqm_SAR_Lobby__c) {
                Decimal area = opp.Lobby_Area_Sqm__c != null ? opp.Lobby_Area_Sqm__c : 0;
                Decimal rate = opp.Price_Sqm_SAR_Lobby__c != null ? opp.Price_Sqm_SAR_Lobby__c : 0;
                opp.Total_Prices_Lobby_Areas__c = area * rate;
            }
            if (opp.Service_Area_Sqm__c != old.Service_Area_Sqm__c || opp.Price_Sqm_SAR_Service__c != old.Price_Sqm_SAR_Service__c) {
                Decimal area = opp.Service_Area_Sqm__c != null ? opp.Service_Area_Sqm__c : 0;
                Decimal rate = opp.Price_Sqm_SAR_Service__c != null ? opp.Price_Sqm_SAR_Service__c : 0;
                opp.Total_Prices_Service_Area__c = area * rate;
            }
            if (opp.Terrace_Area_Sqm__c != old.Terrace_Area_Sqm__c || opp.Price_Sqm_SAR_Terrace__c != old.Price_Sqm_SAR_Terrace__c) {
                Decimal area = opp.Terrace_Area_Sqm__c != null ? opp.Terrace_Area_Sqm__c : 0;
                Decimal rate = opp.Price_Sqm_SAR_Terrace__c != null ? opp.Price_Sqm_SAR_Terrace__c : 0;
                opp.Total_Prices_Terrace_Area__c = area * rate;
            }

            // Update TotalSellingPrice whenever any total price field changed
            if (opp.Total_Prices_Unit_Area__c    != old.Total_Prices_Unit_Area__c
                || opp.Total_Prices_Lobby_Areas__c  != old.Total_Prices_Lobby_Areas__c
                || opp.Total_Prices_Service_Area__c != old.Total_Prices_Service_Area__c
                || opp.Total_Prices_Terrace_Area__c != old.Total_Prices_Terrace_Area__c) {
                opp.TotalSellingPrice__c =
                    (opp.Total_Prices_Unit_Area__c    != null ? opp.Total_Prices_Unit_Area__c    : 0)
                  + (opp.Total_Prices_Lobby_Areas__c  != null ? opp.Total_Prices_Lobby_Areas__c  : 0)
                  + (opp.Total_Prices_Service_Area__c != null ? opp.Total_Prices_Service_Area__c : 0)
                  + (opp.Total_Prices_Terrace_Area__c != null ? opp.Total_Prices_Terrace_Area__c : 0);
            }

            // Reverse candidate: a total changed but neither the area nor the rate changed
            Boolean needsReverse =
                (opp.Total_Prices_Unit_Area__c    != old.Total_Prices_Unit_Area__c    && opp.Unit_Area_Sqm__c    == old.Unit_Area_Sqm__c    && opp.Price_Sqm_SAR_Unit__c    == old.Price_Sqm_SAR_Unit__c)    ||
                (opp.Total_Prices_Lobby_Areas__c  != old.Total_Prices_Lobby_Areas__c  && opp.Lobby_Area_Sqm__c   == old.Lobby_Area_Sqm__c   && opp.Price_Sqm_SAR_Lobby__c   == old.Price_Sqm_SAR_Lobby__c)   ||
                (opp.Total_Prices_Service_Area__c != old.Total_Prices_Service_Area__c && opp.Service_Area_Sqm__c == old.Service_Area_Sqm__c && opp.Price_Sqm_SAR_Service__c == old.Price_Sqm_SAR_Service__c) ||
                (opp.Total_Prices_Terrace_Area__c != old.Total_Prices_Terrace_Area__c && opp.Terrace_Area_Sqm__c == old.Terrace_Area_Sqm__c && opp.Price_Sqm_SAR_Terrace__c == old.Price_Sqm_SAR_Terrace__c);

            if (needsReverse) {
                reverseCalcCandidates.add(opp.Id);
            }
        }

        if (reverseCalcCandidates.isEmpty()) return;

        // Query count of Deal_Building__c per candidate opportunity.
        // Reverse calc only applies when exactly 1 building is linked.
        Set<Id> singleBuildingOpps = new Set<Id>();
        for (AggregateResult ar : [
            SELECT Deal__c, COUNT(Id) cnt
            FROM Deal_Building__c
            WHERE Deal__c IN :reverseCalcCandidates
            GROUP BY Deal__c
        ]) {
            if ((Integer)ar.get('cnt') == 1) {
                singleBuildingOpps.add((Id)ar.get('Deal__c'));
            }
        }

        if (singleBuildingOpps.isEmpty()) return;

        // Second pass: apply reverse calculations using Opportunity area fields.
        // These are set by DealBuildingAggregator from the linked building, so for a
        // single-building deal they equal the building's area. Using them avoids
        // depending on Deal_Building formula fields that return 0 via BlankAsZero.
        for (Opportunity opp : newItems) {
            if (!singleBuildingOpps.contains(opp.Id)) continue;

            Opportunity old = oldMap.get(opp.Id);

            if (opp.Total_Prices_Unit_Area__c != old.Total_Prices_Unit_Area__c
                && opp.Unit_Area_Sqm__c == old.Unit_Area_Sqm__c
                && opp.Price_Sqm_SAR_Unit__c == old.Price_Sqm_SAR_Unit__c) {
                Decimal area = opp.Unit_Area_Sqm__c != null ? opp.Unit_Area_Sqm__c : 0;
                if (area != 0) opp.Price_Sqm_SAR_Unit__c = opp.Total_Prices_Unit_Area__c / area;
            }
            if (opp.Total_Prices_Lobby_Areas__c != old.Total_Prices_Lobby_Areas__c
                && opp.Lobby_Area_Sqm__c == old.Lobby_Area_Sqm__c
                && opp.Price_Sqm_SAR_Lobby__c == old.Price_Sqm_SAR_Lobby__c) {
                Decimal area = opp.Lobby_Area_Sqm__c != null ? opp.Lobby_Area_Sqm__c : 0;
                if (area != 0) opp.Price_Sqm_SAR_Lobby__c = opp.Total_Prices_Lobby_Areas__c / area;
            }
            if (opp.Total_Prices_Service_Area__c != old.Total_Prices_Service_Area__c
                && opp.Service_Area_Sqm__c == old.Service_Area_Sqm__c
                && opp.Price_Sqm_SAR_Service__c == old.Price_Sqm_SAR_Service__c) {
                Decimal area = opp.Service_Area_Sqm__c != null ? opp.Service_Area_Sqm__c : 0;
                if (area != 0) opp.Price_Sqm_SAR_Service__c = opp.Total_Prices_Service_Area__c / area;
            }
            if (opp.Total_Prices_Terrace_Area__c != old.Total_Prices_Terrace_Area__c
                && opp.Terrace_Area_Sqm__c == old.Terrace_Area_Sqm__c
                && opp.Price_Sqm_SAR_Terrace__c == old.Price_Sqm_SAR_Terrace__c) {
                Decimal area = opp.Terrace_Area_Sqm__c != null ? opp.Terrace_Area_Sqm__c : 0;
                if (area != 0) opp.Price_Sqm_SAR_Terrace__c = opp.Total_Prices_Terrace_Area__c / area;
            }
        }
    }

    public static void beforeInsert(List<Opportunity> newItems) {
       
        Map<Id, Schema.RecordTypeInfo> rtInfoById =
            Schema.SObjectType.Opportunity.getRecordTypeInfosById();

        for (Opportunity opp : newItems) {
           
            opp.Offer_Valid_till__c = Date.today().addDays(14);
           
        }
    }

    public static void afterUpdate(List<Opportunity> newItems, Map<Id,Opportunity>oldMap) {
        populateOwnerField(newItems, oldMap);
        handleVATChanges(newItems, oldMap);
        handlePaymentPlanChanges(newItems, oldMap);
        handleTotalSellingPriceChange(newItems, oldMap);
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
     * Handles PaymentPlan__c changes on an Opportunity.
     * Deletes all unpaid Payment Schedules and rebuilds them from the new Payment Plan.
     */
    private static void handlePaymentPlanChanges(List<Opportunity> newItems, Map<Id, Opportunity> oldMap) {
        Set<Id> changedOpportunityIds = new Set<Id>();
        Map<Id, Opportunity> opportunitiesWithNewPlan = new Map<Id, Opportunity>();

        for (Opportunity opp : newItems) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            if (opp.PaymentPlan__c != oldOpp.PaymentPlan__c) {
                changedOpportunityIds.add(opp.Id);
                if (opp.PaymentPlan__c != null) {
                    opportunitiesWithNewPlan.put(opp.Id, opp);
                }
            }
        }

        if (changedOpportunityIds.isEmpty()) {
            return;
        }

        // Delete existing unpaid schedules for affected opportunities
        List<Payment_Schedule__c> schedulesToDelete = [
            SELECT Id
            FROM Payment_Schedule__c
            WHERE Deal__c IN :changedOpportunityIds
            AND Payment_Status__c != 'Paid'
        ];
        if (!schedulesToDelete.isEmpty()) {
            delete schedulesToDelete;
        }

        if (opportunitiesWithNewPlan.isEmpty()) {
            return;
        }

        // Collect new Payment Plan IDs
        Set<Id> newPlanIds = new Set<Id>();
        for (Opportunity opp : opportunitiesWithNewPlan.values()) {
            newPlanIds.add(opp.PaymentPlan__c);
        }

        // Query Payment Plan Lines for the new plans
        List<PaymentPlanLine__c> planLines = [
            SELECT Id, PaymentPlan__c, Percentage__c, DaysAfterCreation__c, Description__c
            FROM PaymentPlanLine__c
            WHERE PaymentPlan__c IN :newPlanIds
        ];

        if (planLines.isEmpty()) {
            return;
        }

        Map<Id, List<PaymentPlanLine__c>> planLineMap = new Map<Id, List<PaymentPlanLine__c>>();
        for (PaymentPlanLine__c line : planLines) {
            if (!planLineMap.containsKey(line.PaymentPlan__c)) {
                planLineMap.put(line.PaymentPlan__c, new List<PaymentPlanLine__c>());
            }
            planLineMap.get(line.PaymentPlan__c).add(line);
        }

        // Build new Payment Schedules
        List<Payment_Schedule__c> newSchedules = new List<Payment_Schedule__c>();
        for (Opportunity opp : opportunitiesWithNewPlan.values()) {
            List<PaymentPlanLine__c> lines = planLineMap.get(opp.PaymentPlan__c);
            if (lines == null) continue;
            for (PaymentPlanLine__c line : lines) {
                Payment_Schedule__c schedule = new Payment_Schedule__c();
                schedule.Amount__c = (line.Percentage__c / 100) * (opp.TotalSellingPrice__c != null ? opp.TotalSellingPrice__c : 0);
                schedule.CurrencyIsoCode = opp.CurrencyIsoCode;
                schedule.Deal__c = opp.Id;
                schedule.Description__c = line.Description__c;
                schedule.Escalation__c = 1;
                schedule.Payment_Status__c = 'Not Paid';
                schedule.Percentage__c = line.Percentage__c;
                schedule.Year__c = String.valueOf(Date.today().year());
                schedule.Scheduled_Payment_Date__c = opp.CloseDate != null
                    ? opp.CloseDate.addDays((Integer)line.DaysAfterCreation__c)
                    : null;
                newSchedules.add(schedule);
            }
        }

        if (!newSchedules.isEmpty()) {
            insert newSchedules;
        }
    }

    /**
     * After TotalSellingPrice changes (for any reason), update all unpaid Payment Schedules
     * so their amounts stay in sync.
     */
    private static void handleTotalSellingPriceChange(List<Opportunity> newItems, Map<Id, Opportunity> oldMap) {
        Map<Id, Opportunity> changedOpps = new Map<Id, Opportunity>();

        for (Opportunity opp : newItems) {
            if (opp.TotalSellingPrice__c != oldMap.get(opp.Id).TotalSellingPrice__c) {
                changedOpps.put(opp.Id, opp);
            }
        }

        if (changedOpps.isEmpty()) return;

        List<Payment_Schedule__c> schedules = [
            SELECT Id, Deal__c, Percentage__c, Payment_Status__c
            FROM Payment_Schedule__c
            WHERE Deal__c IN :changedOpps.keySet()
            AND Payment_Status__c != 'Paid'
        ];

        if (schedules.isEmpty()) return;

        List<Payment_Schedule__c> toUpdate = new List<Payment_Schedule__c>();
        for (Payment_Schedule__c schedule : schedules) {
            Opportunity opp = changedOpps.get(schedule.Deal__c);
            if (opp != null && schedule.Percentage__c != null) {
                schedule.Amount__c = (schedule.Percentage__c / 100)
                    * (opp.TotalSellingPrice__c != null ? opp.TotalSellingPrice__c : 0);
                toUpdate.add(schedule);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
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
            service.recalculateTotalSellingPriceOnly(affectedOpportunityIds);
        }
    }
}