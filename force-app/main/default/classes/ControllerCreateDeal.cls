public with sharing class ControllerCreateDeal {
 
 
    public static Id getRecordTypeId(String recordTypeName){
        return Schema.Sobjecttype.Opportunity.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
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
        
        Id recordTypeId = getRecordTypeId(recordTypeName);
        If(recordTypeId == null){
            throw new AuraHandledException('Record type not found');
        }

        Opportunity opp = new Opportunity();
        opp.Name = name;
        //if(!Test.isRunningTest()){
        	opp.RecordTypeId = recordTypeId;   
       // }
		opp.Site__c = siteId;
        opp.StageName = stage;
        opp.CloseDate = Date.valueOf(closeDate);
        opp.AccountId = tenantsName1;
        insert opp;
                                            
        Deal_Building__c db = new Deal_Building__c();
        db.Deal__c = opp.Id;
        db.Building__c = buildId;
        insert db;
                                            
        Building__c bg = [SELECT Id, Status__c FROM Building__c WHERE Id =:buildId limit 1];
        bg.Status__c = stage;
        update bg;
    }
}