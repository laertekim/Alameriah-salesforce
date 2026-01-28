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
        insert opp;
        
       
        
        Deal_Building__c db = new Deal_Building__c();
        db.Deal__c = opp.Id;
        db.Building__c = buildId;
        db.RecordTypeId = getRecordTypeId('Deal_Building__c', recordTypeName);
        db.Total_Selling_Price_SAR__c = bg.Total_Selling_Price_SAR__c;
       
        insert db;
                                            
    }
}