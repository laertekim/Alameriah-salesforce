public with sharing class ControllerCreateDeal {
 
 
    public static Id getRecordTypeId(String sObjectName, String recordTypeName) {
    if (String.isBlank(sObjectName) || String.isBlank(recordTypeName)) {
        return null;
    }

    Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

    if (!globalDescribe.containsKey(sObjectName)) {
        return null;
    }

    Schema.DescribeSObjectResult describeResult =
        globalDescribe.get(sObjectName).getDescribe();

    Map<String, Schema.RecordTypeInfo> recordTypeInfos =
        describeResult.getRecordTypeInfosByName();

    if (!recordTypeInfos.containsKey(recordTypeName)) {
        return null;
    }

    return recordTypeInfos.get(recordTypeName).getRecordTypeId();
}

    @AuraEnabled(cacheable=true)
    public static List<PaymentPlan__c> getAllPaymentPlans(String recordTypeId) {
        return [SELECT Id, Name 
                FROM PaymentPlan__c 
                WHERE RecordTypeId = :recordTypeId 
                ORDER BY Name];
    }


    @AuraEnabled(cacheable = true)
    public static Building__c getBulding(String oppId){
            return [SELECT Id, RecordType.Name, Center_Name__c, Center_Name__r.Name FROM Building__c WHERE Id =:oppId limit 1];
    }

    @AuraEnabled(cacheable = false)
    public static void createDeal(String buildId, 
                                        String name, 
                                        String closeDate,
                                        String stage,
                                 		String recordTypeName,
                                 		String siteId,
                                        String tenantsName1){
        
        Id recordTypeId = getRecordTypeId('Opportunity', recordTypeName);
        If(recordTypeId == null){
            throw new AuraHandledException('Record type not found');
        }

        BuildingRepository buildingRepository = new BuildingRepository();
        Map<Id, Building__c> buildings = buildingRepository.getAllFields(new Set<Id>{buildId});
        Building__c bg = buildings.get(buildId);
        bg.Status__c = stage;

        update bg;

        Opportunity opp = new Opportunity();
        opp.Name = name;
        //if(!Test.isRunningTest()){
        	opp.RecordTypeId = recordTypeId;   
       // }
		opp.Site__c = siteId;
        opp.StageName = stage;
        opp.CloseDate = Date.valueOf(closeDate);
        opp.AccountId = tenantsName1;
        opp.LandPricePerSqm__c = bg.LandSellableAreaSqm__c;
        opp.Rate_per_Sqm_SR_Sqm__c = bg.VillaSellableAreaSqm__c;
        opp.TotalSellingPrice__c  =bg.Asking_Price__c;
        opp.Deal_Offered_Date__c = Date.today();
        opp.Offer_Valid_till__c = Date.today().addDays(14);
        insert opp;
        
       
        
        Deal_Building__c db = new Deal_Building__c();
        db.Deal__c = opp.Id;
        db.Building__c = buildId;
        db.Total_Selling_Price_SAR__c = bg.Total_Selling_Price_SAR__c;
       
        insert db;
                                            
    }

//sample to call createDealWithPaymentPlan
//ControllerCreateDeal.createDealWithPaymentPlan('a00000000000000000000000', 'Test', String.valueOf(Date.today()), 'Offered', 'Offices', null, null, 'a00000000000000000000000');
    @AuraEnabled(cacheable = false)
    public static void createDealWithPaymentPlan(String buildId, 
                                        String name, 
                                        String closeDate,
                                        String stage,
                                 		String recordTypeName,
                                 		String siteId,
                                        String tenantsName1,
                                        String paymentPlanId){

        Id recordTypeId = getRecordTypeId('Opportunity', recordTypeName);
        If(recordTypeId == null){
            throw new AuraHandledException('Record type not found');
        }

        BuildingRepository buildingRepository = new BuildingRepository();
        Map<Id, Building__c> buildings = buildingRepository.getAllFields(new Set<Id>{buildId});
        Building__c bg = buildings.get(buildId);
        bg.Status__c = stage;

        update bg;

        Opportunity opp = new Opportunity();
        opp.Name = name;
        //if(!Test.isRunningTest()){
            opp.RecordTypeId = recordTypeId;   
        // }
        opp.Site__c = siteId;
        opp.StageName = stage;
        opp.CloseDate = Date.valueOf(closeDate);
        opp.AccountId = tenantsName1;
        opp.LandPricePerSqm__c = bg.LandSellableAreaSqm__c;
        opp.Rate_per_Sqm_SR_Sqm__c = bg.VillaSellableAreaSqm__c;
        opp.TotalSellingPrice__c  =bg.Asking_Price__c;
        opp.Deal_Offered_Date__c = Date.today();
        opp.Offer_Valid_till__c = Date.today().addDays(14);
        insert opp;
        
        
        
        Deal_Building__c db = new Deal_Building__c();
        db.Deal__c = opp.Id;
        db.Building__c = buildId;
        db.RecordTypeId = getRecordTypeId('Deal_Building__c', recordTypeName);
        db.Total_Selling_Price_SAR__c = bg.Total_Selling_Price_SAR__c;
        
        insert db;

        if (paymentPlanId != null){
            //query payment plan lines from payment plan
            List<PaymentPlanLine__c> paymentPlanLines = [SELECT 
                                                                Id, 
                                                                Name, 
                                                                PaymentPlan__c, 
                                                                PaymentPlan__r.Name, 
                                                                Sequence__c,
                                                                Percentage__c,
                                                                DaysAfterCreation__c,
                                                                Description__c
                                                                FROM PaymentPlanLine__c WHERE PaymentPlan__c =: paymentPlanId];
            if (paymentPlanLines.size() > 0){              
                List<Payment_Schedule__c> paymentSchedules = new List<Payment_Schedule__c>();
                for (PaymentPlanLine__c paymentPlanLine : paymentPlanLines){
                    Payment_Schedule__c paymentSchedule = new Payment_Schedule__c();
                    paymentSchedule.Amount__c = (paymentPlanLine.Percentage__c / 100) * opp.TotalSellingPrice__c;
                    //CurrencyIsoCode, Deal__c, Description__c, Escalation__c, Payment_Status__c,Percentage__c, Year__c
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
                insert paymentSchedules;
            }
        }
    }
}